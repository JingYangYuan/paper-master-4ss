"""NCPSSD (国家哲学社会科学文献中心) Chinese scholarly connector.

Serves the literature lens's Chinese tier directly: NCPSSD is the CASS-run
open-access index of Chinese social-science journals, and until now the only
route into it was ``search_literature`` steering a general search engine with
``site:ncpssd.cn`` — a path that depends on third-party engines tolerating
automated queries and that returns unstructured title/snippet pairs. This
connector talks to the site itself and returns structured records (title,
journal, year, authors, ISSN), which is what lets the CSSCI journal filter in
the lit_review skill work off a field instead of a guess.

Two-stage flow, both stages calibrated against the live site on 2026-08-26
(``ncpssd-calibration.md`` on branch ``claude/ncpssd-calibration-tqkgrm``:
browser XHR capture plus anonymous curl replay):

1. **Search**: ``POST /searchHandler/search`` (form-urlencoded), the JSON
   handler behind the site's JS-rendered results page. The ``search`` field
   is a Solr-style boolean expression; the site's default 题名/关键词 search
   is a five-field OR (``IKTE``/``IKPYTE``/``IKST``/``IKET``/``IKSE``) over
   the query, which this connector mirrors. The old server-rendered list
   page 404s — there is no GET route to these results. A response without
   the expected ``data.rows`` envelope is treated as a transport-level
   failure, not an empty result: the handler may have changed shape, and
   either way the emptiness would say nothing about the literature.
2. **Detail**: enrich each row through the article-page handler
   (``POST /articleinfoHandler/getjournalarticletable``), which serves the
   article's metadata — journal name, ISSN, authors, date, abstract, plus a
   ``pdfurl`` field. Enrichment is best-effort per item: a hit whose detail
   call fails keeps the metadata already present on its search row (the rows
   carry venue/year/authors/ISSN themselves).

   ⚠ ``pdfurl`` is **not** a full-text link: in the live data it mostly points
   at the retired ``nssd.org`` domain (parked, sold) and returns a ~4.6 KB HTML
   page. It is kept only as "this record claims to have full text"; never treat
   it as open access. Verified 2026-11 (18/18 hits).

Both handlers are anonymous: no cookie, no signature, no login. Search rows
mix in non-article chrome (journal team-intro pages and the like) which are
recognizable by their empty ``creator``; those are dropped rather than
half-supported. ``ik_*`` fields carry ``<font>`` highlight markup, so titles
are tag-stripped before use.

**Login is deliberately out of scope.** NCPSSD requires a (free) account only
to download full text; search and metadata are anonymous. Hits carry the
article's landing URL so the researcher signs in in their own browser — this
connector never sees or stores credentials.

Public internet, so httpx keeps ``trust_env`` ON (same posture as
``scholarly.py``, the opposite of loopback ``searxng.py``).
"""

from __future__ import annotations

import json
import os
import random
import re
import sys
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from dataclasses import dataclass, replace
from pathlib import Path

import httpx

try:  # POSIX only; elsewhere the throttle degrades to per-process pacing.
    import fcntl
except ImportError:  # pragma: no cover - Windows
    fcntl = None

# 站点把 publishdate 的旧记录填成 1900-01-01 占位，越界年份一律当缺失。
_MIN_YEAR, _MAX_YEAR = 1901, 2100

_MAX_LIMIT = 50
_TIMEOUT = 20.0
#: 默认每次请求之间的最小间隔（秒）。站点在突发访问后会从 iCloudWAF 下发
#: 一页「访问验证」的点击页（HTTP 200 + HTML），而不是 429，所以限速必须自己
#: 做。实测 1.2s 间隔可以把 50 条的详情补全摊到 ~1 分钟，全程不触发验证页。
_MIN_INTERVAL = 1.2
#: 单个请求最多尝试几次（含首试）。失败一次就重试的老写法等于没退避——两次
#: 尝试间隔只有毫秒级，验证页根本来不及过期。
_MAX_ATTEMPTS = 5
#: 连续失败时逐级拉长的冷却（秒）。跨进程共享，所以并发跑多个检索不会各自
#: 撞墙后一起重试。
_COOLDOWN_STEPS = (30.0, 60.0, 120.0, 240.0, 480.0)
_COOLDOWN_CAP = 900.0
#: 详情补全的默认并发。4 路并发在整批 50 条时会把瞬时速率顶到 10+/s。
_DETAIL_WORKERS = 3
#: WAF 验证页的识别指纹（HTTP 200，但正文是这张点击页）。
_CHALLENGE_MARKERS = ("waf_click_verify", "wzws-waf-cgi", "访问验证", "请完成安全验证")

_NCPSSD_BASE = "https://www.ncpssd.cn"
_SEARCH_PATH = "/searchHandler/search"
_DETAIL_PATH = "/articleinfoHandler/getjournalarticletable"
#: The article type the detail handler expects, verbatim from the site.
_JOURNAL_TYPENAME = "中文期刊文章"
#: The site's own result ordering, verbatim from its XHR: recency.
_SEARCH_SORT = "synUpdateType|DESC,date|DESC,ik_subject|DESC,id|DESC"
#: Result orderings this connector exposes.
#:
#: ``relevance`` is the search backend's Solr default (``score desc``) and is
#: reached by **omitting** the ``sort`` field entirely. Measured against the
#: live site on 2026-09-07: omitting ``sort``, sending ``sort=""``, and
#: sending ``sort="score|DESC"`` all return the identical ordering, which
#: means ``score|DESC`` is *not* recognised as a sort key — it falls through
#: to the same default. So the implementation must omit the field rather than
#: name the score column, and a future reader must not "fix" this into an
#: explicit ``score|DESC``.
#:
#: The two orderings answer different questions and neither dominates: on
#: 《数字普惠金融》 their first six hits do not overlap at all — recency
#: surfaces 2026 work including marginal venues, relevance surfaces the
#: 2019-2020 papers the field actually cites.
ORDER_RELEVANCE = "relevance"
ORDER_RECENCY = "recency"
_ORDERS: frozenset[str] = frozenset({ORDER_RELEVANCE, ORDER_RECENCY})
#: Field codes of the site's default 题名/关键词 search: Chinese title,
#: title pinyin, Chinese subject/keywords, English title, English subject.
_SEARCH_FIELDS = ("IKTE", "IKPYTE", "IKST", "IKET", "IKSE")
#: Query terms separate on any run of whitespace, U+3000 included — Chinese
#: input methods emit the full-width space, and it is not ASCII whitespace.
_TERM_SPLIT_RE = re.compile(r"[\s　]+")
#: An ISSN as the search handler's own help text codes it (``ISSN=…``, field
#: name verbatim). Same shape rule as scholarly.py: validated here so a
#: malformed value is refused rather than quietly ignored upstream, which
#: would widen a journal-targeted query to the whole index.
_ISSN_RE = re.compile(r"^\d{4}-\d{3}[\dxX]$")

#: Chinese top journals keyed by ISSN, verified against the live NCPSSD
#: site on 2026-11-15 (each ISSN's hits carry exactly this 刊名; every entry
#: below was probed with an ISSN-restricted search and the returned 刊名
#: matched the documented name, except 经济学(季刊) whose site-side 刊名 is
#: rendered 「经济学（季刊）」 — the ISSN is authoritative for targeting).
#: 社会学评论 = 2095-5154 added 2026-11-15 after an ISSN-restricted probe
#: ("劳动" → 5 hits, every row 刊名=社会学评论); the site's own record is the
#: authority here, and 2095-3275 (some external catalogues) is *not* what the
#: site files it under.
#:
#: 覆盖学科（均为公认 CSSCI 顶刊或权威 C 刊），共 64 种：
#:   综合社科 / 经济学 / 金融学 / 农业经济 / 社会学 / 政治学 /
#:   公共管理·行政管理 / 管理学 / 心理学 / 社会科学总论 / 高校学报
TIER1_CN_JOURNALS: dict[str, str] = {
    # ── 综合社科（最高层级）──
    "1002-4921": "中国社会科学",
    # ── 经济学 · 金融 ──
    "0577-9154": "经济研究",
    "1002-5502": "管理世界",
    "1002-9621": "世界经济",
    "2095-1086": "经济学(季刊)",
    "1002-7246": "金融研究",
    "1000-3894": "数量经济技术经济研究",
    "1006-480X": "中国工业经济",
    "1002-8102": "财贸经济",
    "1001-9952": "财经研究",
    "1005-3425": "经济评论",
    "1002-8390": "经济学动态",
    "1002-8870": "中国农村经济",
    "1006-4583": "中国农村观察",
    "1000-6389": "农业经济问题",
    # ── 管理学 ──
    "1007-9807": "管理科学学报",
    "1008-3448": "南开管理评论",
    # ── 社会学 ──
    "1002-5936": "社会学研究",
    "1004-8804": "社会",
    "2095-5154": "社会学评论",
    "1004-2563": "妇女研究论丛",
    "2095-8641": "社会建设",
    "1006-1789": "当代青年研究",
    "1002-9931": "中国青年研究",
    "1008-1437": "青年研究",
    "2095-9796": "中国青年社会科学",
    "1004-3780": "青年探索",
    "1000-6087": "人口研究",
    "1674-1668": "人口与发展",
    "1002-4360": "民俗研究",
    "1006-8287": "世界民族",
    "1002-5162": "华侨华人历史研究",
    # ── 政治学 · 国际关系 ──
    "1000-3355": "政治学研究",
    "1006-9550": "世界经济与政治",
    "1671-4709": "国际政治研究",
    "1002-1493": "科学社会主义",
    "1005-4812": "国际观察",
    "1003-3386": "外交评论：外交学院学报",
    "1000-6192": "现代国际关系",
    "1007-161X": "当代亚太",
    "1004-9789": "欧洲研究",
    "1009-721X": "俄罗斯研究",
    "1008-6099": "东南亚研究",
    "1002-8986": "美国研究",
    "1002-8404": "南亚研究",
    "1003-3947": "经济社会体制比较",
    # ── 人口学 ──
    "1000-7881": "中国人口科学",
    # ── 民族学 ──
    "1004-3926": "西南民族大学学报：人文社会科学版",
    # ── 公共管理 · 行政管理 ──
    "1006-0863": "中国行政管理",
    "1672-6162": "公共管理学报",
    "1674-2486": "公共行政评论",
    "1003-2606": "领导科学",
    # ── 心理学 ──
    "0439-755X": "心理学报",
    "1671-3710": "心理科学进展",
    # ── 教育学 ──
    "1002-4808": "中国教育学刊",
    # ── 社会科学总论 / 综合性人文社科期刊 ──
    "0257-5833": "社会科学",
    "0257-0246": "社会科学战线",
    "0447-662X": "人文杂志",
    "1000-4777": "国外社会科学",
    "1004-5961": "马克思主义与现实",
    "1006-5199": "马克思主义研究",
    "1002-7408": "理论导刊",
    # ── 高校学报（C 刊综合版代表） ──
    "1000-9639": "中山大学学报：社会科学版",
    "1000-0062": "清华大学学报：哲学社会科学版",
}


class NcpssdAPIError(ValueError):
    """NCPSSD could not be searched (unreachable, or answer shape unknown)."""


@dataclass(frozen=True, slots=True)
class NcpssdHit:
    title: str
    url: str
    snippet: str
    venue: str | None
    year: int | None
    authors: tuple[str, ...]
    issn: str | None
    pdf_url: str | None


def validate_search(
    query: str,
    *,
    issns: tuple[str, ...] = (),
    order: str = ORDER_RELEVANCE,
) -> str:
    """校验检索参数，返回 strip 后的 query；参数问题一律抛 ``NcpssdAPIError``。

    单独抽出来是为了让调用方能区分两类失败：参数错（用户输入问题，改参数）
    与 ``backend_error``（站点挂了/改版，改渠道）。两者混在一起会把
    "ISSN 写错"报成"后端不可用"，把人往错的排查方向引。
    """

    text = query.strip()
    if not text:
        raise NcpssdAPIError("query must be non-empty")
    if order not in _ORDERS:
        # Refused rather than silently defaulted: a typo'd ordering would
        # otherwise return a perfectly plausible page in the *other* order,
        # and nothing downstream could tell.
        raise NcpssdAPIError(f"unknown order: {order!r}")
    for issn in issns:
        if not _ISSN_RE.match(issn):
            raise NcpssdAPIError(f"malformed issn: {issn!r}")
    if not [term for term in _TERM_SPLIT_RE.split(text.replace('"', " ")) if term]:
        raise NcpssdAPIError("query must contain at least one searchable term")
    return text


def search_ncpssd(
    query: str,
    *,
    limit: int = 10,
    issns: tuple[str, ...] = (),
    order: str = ORDER_RELEVANCE,
    base: str = _NCPSSD_BASE,
    transport: httpx.BaseTransport | None = None,
    enrich: bool = True,
) -> tuple[NcpssdHit, ...]:
    """Search NCPSSD and return structured Chinese journal-article hits.

    ``order`` picks between the backend's relevance ranking (the default) and
    the site's own recency ordering; see :data:`ORDER_RELEVANCE` for why
    relevance is expressed by omitting the field rather than naming a sort key.
    Relevance is the default because the common task is finding what a
    literature says, not what appeared last week — recency is a request the
    caller makes explicitly.

    Never raises on genuinely empty results — returns an empty tuple so the
    caller can degrade to "文献待补". Raises ``NcpssdAPIError`` when the query
    is blank, ``order`` is not one of the two supported values, the site
    cannot be reached, or the search handler's response does not carry the
    expected ``data.rows`` envelope (which must read as "backend unavailable",
    never as "no such literature" — see module docstring).
    """

    text = validate_search(query, issns=issns, order=order)
    capped = max(1, min(int(limit), _MAX_LIMIT))

    form = {
        "search": _search_expression(text, issns=issns),
        "pageNum": "1",
        "pageSize": str(capped),
        "sType": "0",
    }
    if order == ORDER_RECENCY:
        form["sort"] = _SEARCH_SORT
    payload = _post_form(
        _SEARCH_PATH,
        form=form,
        base=base,
        transport=transport,
    )
    rows = _rows_of(payload)
    stubs: list[NcpssdHit] = []
    ids: list[str] = []
    for row in rows:
        stub = _stub_of(row, base=base)
        if stub is None:
            continue
        article_id = _opt_str(row.get("id")) or _opt_str(row.get("data_id"))
        if article_id is None:
            continue
        stubs.append(stub)
        ids.append(article_id)
        if len(stubs) == capped:
            break
    if not stubs:
        return ()

    # Detail calls are independent; wall time is the slowest single call, not
    # the sum. Each is best-effort: a failed enrichment keeps the row-derived
    # stub, because a title+URL the researcher can open beats a silently
    # dropped hit.
    if not enrich:
        # 搜索行本身就带刊名/年份/ISSN/摘要，详情请求只补更完整的字段。
        # 大批量扫库时关掉它，请求数直接降到 1/N（见 --no-detail）。
        return tuple(stubs)

    def enrich_one(pair: tuple[NcpssdHit, str]) -> NcpssdHit | None:
        stub, article_id = pair
        try:
            return _enrich(stub, article_id, base=base, transport=transport)
        except NcpssdThrottledError:
            return None  # 站点在挡：保留 stub，不把整批拖成分钟级等待

    # 分波补全：一波里出现两条被限流，就停止补全剩下的（宁可少摘要，也不
    # 让一次检索在退避里挂十几分钟）。
    enriched: list[NcpssdHit] = []
    throttled = 0
    workers = min(detail_workers(), len(ids))
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for start in range(0, len(ids), workers * 2):
            wave = list(zip(stubs[start : start + workers * 2], ids[start : start + workers * 2]))
            results = list(pool.map(enrich_one, wave))
            enriched.extend(item for item in results if item is not None)
            throttled += sum(1 for item in results if item is None)
            if throttled >= 2:
                _notice(f"详情补全被限流中断，{len(ids) - len(enriched)} 条保留检索行元数据")
                break
    by_url = {hit.url: hit for hit in enriched}
    return tuple(by_url.get(stub.url, stub) for stub in stubs)


# --- search handler ---------------------------------------------------------


def _search_expression(text: str, *, issns: tuple[str, ...] = ()) -> str:
    """Build the handler's boolean expression for a (possibly multi-word) query.

    The handler reads ``IKTE="a b"`` as one *phrase*, so putting a whole
    multi-keyword query in a single field match makes recall collapse as the
    caller adds keywords (measured against the live site: ``共同富裕`` → 5
    hits, ``数字普惠金融 城乡收入差距 共同富裕`` → 2). Each whitespace-separated
    term therefore gets its own five-field OR group, and the groups are
    AND-ed: a document must carry every term, in any of the searched fields.
    """

    terms = [term for term in _TERM_SPLIT_RE.split(text.replace('"', " ")) if term]
    if not terms:
        raise NcpssdAPIError("query must contain at least one searchable term")
    groups = [
        "(" + " OR ".join(f'{field}="{term}"' for field in _SEARCH_FIELDS) + ")"
        for term in terms
    ]
    if issns:
        groups.append("(" + " OR ".join(f'ISSN="{issn}"' for issn in issns) + ")")
    if len(groups) == 1:
        return groups[0]
    return "(" + " AND ".join(groups) + ")"


def _rows_of(payload: object) -> list[dict[str, object]]:
    # Fail closed: without the rows envelope we cannot distinguish "the site
    # answered with zero results" from "the site answered in a shape this
    # connector no longer understands", and only the first may become an
    # empty tuple.
    if isinstance(payload, dict):
        data = payload.get("data")
        if isinstance(data, dict):
            rows = data.get("rows")
            if isinstance(rows, list):
                return [row for row in rows if isinstance(row, dict)]
    raise NcpssdAPIError("NCPSSD search response missing data.rows envelope")


def _stub_of(row: dict[str, object], *, base: str) -> NcpssdHit | None:
    # Rows mix in non-article chrome (journal team-intro pages and the like);
    # those carry no creator, real articles always do.
    authors = _split_names(_strip_markup(_opt_str(row.get("creator"))))
    if not authors:
        return None
    title = _strip_markup(_opt_str(row.get("title")) or _opt_str(row.get("ik_title")))
    if not title:
        return None
    article_id = _opt_str(row.get("id")) or _opt_str(row.get("data_id"))
    if article_id is None:
        return None
    return NcpssdHit(
        title=title,
        url=f"{base}/Literature/articleinfo?id={article_id}"
        f"&type=journalArticle&nav=1&langType=1",
        snippet=_clean(_strip_markup(_opt_str(row.get("remark"))) or ""),
        venue=_opt_str(row.get("cbw_name")),
        year=_year_of(row.get("years")) or _year_of(row.get("date")),
        authors=authors,
        issn=_opt_str(row.get("issn")),
        pdf_url=_opt_str(row.get("pdfurl")),
    )


# --- detail handler --------------------------------------------------------


def _enrich(
    stub: NcpssdHit,
    article_id: str,
    *,
    base: str,
    transport: httpx.BaseTransport | None,
) -> NcpssdHit:
    try:
        row = _fetch_detail(article_id, base=base, transport=transport)
    except NcpssdThrottledError:
        raise  # 限流要让上层知道，否则 50 条会各自等满退避
    except (httpx.HTTPError, ValueError, KeyError, TypeError):
        return stub
    return replace(
        stub,
        title=_opt_str(row.get("titlec")) or stub.title,
        snippet=_clean(_opt_str(row.get("remarkc")) or "") or stub.snippet,
        venue=_opt_str(row.get("mediac")) or stub.venue,
        year=_year_of(row.get("publishdate")) or stub.year,
        authors=_split_names(_opt_str(row.get("showwriter"))) or stub.authors,
        issn=_opt_str(row.get("issn")) or stub.issn,
        pdf_url=_opt_str(row.get("pdfurl")) or stub.pdf_url,
    )


def _fetch_detail(
    article_id: str,
    *,
    base: str,
    transport: httpx.BaseTransport | None,
) -> dict[str, object]:
    payload = _post_json(
        _DETAIL_PATH,
        json_body={"lngid": article_id, "type": _JOURNAL_TYPENAME, "pageType": 2},
        base=base,
        transport=transport,
    )
    # The handler's envelope has shifted between site revisions; accept the
    # record at the top level or under the common wrapper keys rather than
    # pinning one shape and shedding metadata on the next deploy.
    if isinstance(payload, dict):
        for key in ("data", "result"):
            inner = payload.get(key)
            if isinstance(inner, dict):
                return inner
        return payload
    raise ValueError("NCPSSD detail response shape is unsupported")


# --- transport: 限速、WAF 验证页、退避重试 ---------------------------------
#
# 站点前面挂的是 iCloudWAF（响应头 wzws-ray、Cookie wzws_cid）。访问过密时它
# 不返回 429，而是 **HTTP 200 + 一页「访问验证」HTML**（要求点一下按钮，
# 页内 JS 再 POST /waf_click_verify）。旧实现有两个真问题：
#
#   1. 重试之间不 sleep，两次尝试相差毫秒，等于线性硬撞；
#   2. 200 的 HTML 走 `response.json()` 抛 ValueError，被归成「后端不可用」，
#      现场看上去像站点挂了，实际是请求太快。
#
# 现在：跨进程共享的最小间隔 + 递增冷却 + 验证页识别，全部落在
# 「先等、再退、最后才报错」这一条上。


class NcpssdThrottledError(NcpssdAPIError):
    """站点活着，但用限流/人机验证页挡住了请求（与「空结果」严格区分）。"""


def _env_float(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if not raw:
        return default
    try:
        return float(raw)
    except ValueError:
        return default


def _min_interval() -> float:
    return max(0.0, _env_float("LITDOWN_NCPSSD_MIN_INTERVAL", _MIN_INTERVAL))


def _max_attempts() -> int:
    return max(1, int(_env_float("LITDOWN_NCPSSD_ATTEMPTS", _MAX_ATTEMPTS)))


def detail_workers() -> int:
    """详情补全并发数（默认 3）。批量跑不动时降到 1 只会更慢，不会更稳。"""
    return max(1, int(_env_float("LITDOWN_NCPSSD_WORKERS", _DETAIL_WORKERS)))


def _ua() -> str:
    # WAF 按 UA 分流：缺 UA 直接 403，脚本自述型 UA 更容易被要求验证。
    return os.environ.get("LITDOWN_NCPSSD_UA") or (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    )


_THROTTLE_LOCK = threading.RLock()
_SESSION_LOCK = threading.RLock()
_SESSIONS: dict[tuple[str, str], httpx.Client] = {}
_MEM_STATE: dict[str, float] = {}
_LAST_NOTICE = 0.0


def _state_path() -> Path | None:
    """限速状态文件：默认在系统临时目录，跨进程共享；设 off 退回进程内。"""
    if (os.environ.get("LITDOWN_NCPSSD_STATE") or "").strip().lower() in {"off", "0", "none"}:
        return None
    root = os.environ.get("LITDOWN_NCPSSD_STATE_DIR")
    base = Path(root) if root else Path(tempfile.gettempdir()) / "litdown-ncpssd"
    return base / "throttle.json"


@contextmanager
def _throttle_state():
    """读-改-写一份跨进程共享的 {next_slot, cooldown_until, streak}。

    flock 保证并发进程不会各自抢到同一个时间片；文件只存几十字节，读写代价
    远小于一次网络请求。
    """
    path = _state_path()
    if path is None:
        yield _MEM_STATE
        return
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        fh = open(path, "a+", encoding="utf-8")
    except OSError:
        yield _MEM_STATE
        return
    with fh:
        locked = False
        if fcntl is not None:
            try:
                fcntl.flock(fh, fcntl.LOCK_EX)
                locked = True
            except OSError:
                pass
        fh.seek(0)
        try:
            state = json.loads(fh.read() or "{}")
        except json.JSONDecodeError:
            state = {}
        if not isinstance(state, dict):
            state = {}
        try:
            yield state
        finally:
            fh.seek(0)
            fh.truncate()
            fh.write(json.dumps(state))
            fh.flush()
            if locked:
                try:
                    fcntl.flock(fh, fcntl.LOCK_UN)
                except OSError:
                    pass


def _notice(message: str) -> None:
    global _LAST_NOTICE
    now = time.time()
    if now - _LAST_NOTICE < 5:
        return
    _LAST_NOTICE = now
    print(f"[ncpssd] {message}", file=sys.stderr, flush=True)


def _wait_for_slot() -> None:
    """占一个发送时间片；冷却期内先等，等完再评估。"""
    while True:
        with _THROTTLE_LOCK:
            with _throttle_state() as state:
                now = time.time()
                cooldown = float(state.get("cooldown_until") or 0.0)
                ready = max(float(state.get("next_slot") or 0.0), cooldown)
                if ready <= now:
                    state["next_slot"] = now + _min_interval() * random.uniform(0.85, 1.3)
                    return
                wait = ready - now
        # 普通限速间隔（1.2s）不吭声；只有真在冷却里才提示，免得刷屏成噪音。
        if cooldown > now and wait >= 3:
            _notice(f"限流冷却中，{wait:.0f}s 后再请求（站点在挡，不是没文献）")
        time.sleep(min(wait, 30.0))  # 分段睡：保持 Ctrl-C 与提示可响应


def _enter_cooldown(*, reason: str, retry_after: float | None = None) -> None:
    with _THROTTLE_LOCK:
        with _throttle_state() as state:
            streak = int(state.get("streak") or 0)
            step = _COOLDOWN_STEPS[min(streak, len(_COOLDOWN_STEPS) - 1)]
            wait = min(float(retry_after) if retry_after else step, _COOLDOWN_CAP)
            wait *= random.uniform(0.9, 1.15)
            state["streak"] = streak + 1
            state["cooldown_until"] = max(
                float(state.get("cooldown_until") or 0.0), time.time() + wait
            )
    _notice(f"{reason}；冷却 {wait:.0f}s（第 {streak + 1} 次）")


def _clear_streak() -> None:
    with _THROTTLE_LOCK:
        with _throttle_state() as state:
            if state.get("streak"):
                state["streak"] = 0


def _looks_like_challenge(text: str) -> bool:
    head = text[:20000]
    return any(marker in head for marker in _CHALLENGE_MARKERS)


def _default_headers() -> dict[str, str]:
    return {
        "User-Agent": _ua(),
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.6",
        "X-Requested-With": "XMLHttpRequest",
    }


def _client(base: str, transport: httpx.BaseTransport | None) -> tuple[httpx.Client, bool]:
    """返回 (client, shared)。shared=True 的 client 复用连接与 cookie，不要 close。

    共用 session 的意义不只是省握手：WAF 的 wzws_cid 是会话级的，每次新建
    Client 等于每次从零开始接受验证。
    """
    if transport is not None:
        return (
            httpx.Client(
                base_url=base,
                timeout=_TIMEOUT,
                transport=transport,
                headers=_default_headers(),
            ),
            False,
        )
    key = (base, _ua())
    with _SESSION_LOCK:
        client = _SESSIONS.get(key)
        if client is None:
            client = httpx.Client(
                base_url=base,
                timeout=_TIMEOUT,
                # public internet: keep trust_env ON (unlike loopback searxng.py)
                headers=_default_headers(),
                limits=httpx.Limits(max_keepalive_connections=8, max_connections=8),
            )
            raw_cookie = os.environ.get("LITDOWN_NCPSSD_COOKIE")
            if raw_cookie:
                for pair in raw_cookie.split(";"):
                    name, _, value = pair.partition("=")
                    if name.strip() and value.strip():
                        client.cookies.set(name.strip(), value.strip())
            _SESSIONS[key] = client
        return client, True


def _retry_after_seconds(response: httpx.Response) -> float | None:
    raw = response.headers.get("retry-after")
    if not raw:
        return None
    try:
        return max(1.0, min(float(raw), _COOLDOWN_CAP))
    except ValueError:
        return None


def _request_json(
    path: str,
    *,
    base: str,
    transport: httpx.BaseTransport | None,
    form: dict[str, str] | None = None,
    json_body: dict[str, object] | None = None,
) -> object:
    attempts = _max_attempts()
    last: Exception | None = None
    for attempt in range(1, attempts + 1):
        _wait_for_slot()
        client, shared = _client(base, transport)
        try:
            response = client.post(path, data=form, json=json_body, headers={"Referer": base + "/"})
            status, text = response.status_code, response.text
        except httpx.HTTPError as error:
            last = error
            if attempt < attempts:
                _enter_cooldown(reason=f"网络错误（{type(error).__name__}）")
            continue
        finally:
            if not shared:
                client.close()

        if status == 200:
            if _looks_like_challenge(text):
                last = NcpssdThrottledError("站点返回「访问验证」页而非 JSON")
                if attempt < attempts:
                    _enter_cooldown(reason="命中人机验证页")
                continue
            try:
                payload = response.json()
            except ValueError as error:
                last = error
                if attempt < attempts:
                    _enter_cooldown(reason="返回非 JSON（多半是验证页/网关页）")
                continue
            _clear_streak()
            return payload

        if status in (403, 429, 503) or status >= 500:
            last = NcpssdThrottledError(f"HTTP {status}")
            if attempt < attempts:
                _enter_cooldown(reason=f"HTTP {status}", retry_after=_retry_after_seconds(response))
            continue

        response.raise_for_status()  # 400/404 等：参数或路径问题，重试无意义

    hint = (
        f"{base} 连续 {attempts} 次没取到数据（最后一次：{last}）。"
        "这是站点的限流/人机验证，不是「查无此文」。"
        "现场处理：① 在浏览器打开 https://www.ncpssd.cn ，点一次「点击此区域继续访问」，"
        "把 Cookie 里的 wzws_cid 用 LITDOWN_NCPSSD_COOKIE='wzws_cid=…' 注入后重跑；"
        "② 或降速：LITDOWN_NCPSSD_MIN_INTERVAL=3 ；"
        "③ 冷却记录在 LITDOWN_NCPSSD_STATE_DIR（默认系统临时目录），"
        "确认是误判可用 LITDOWN_NCPSSD_STATE=off 关闭。"
    )
    raise NcpssdThrottledError(hint) from last


def _post_form(
    path: str,
    *,
    form: dict[str, str],
    base: str,
    transport: httpx.BaseTransport | None,
) -> object:
    return _request_json(path, base=base, transport=transport, form=form)


def _post_json(
    path: str,
    *,
    json_body: dict[str, object],
    base: str,
    transport: httpx.BaseTransport | None,
) -> object:
    return _request_json(path, base=base, transport=transport, json_body=json_body)


_TAG_RE = re.compile(r"<[^>]+>")
# "[1]" but also "[1;2]" / "[1, 2]" — one author, several institutions
_SUPERSCRIPT_RE = re.compile(r"\[\s*\d+(?:\s*[;；,，]\s*\d+)*\s*\]")


def _strip_markup(value: str | None) -> str | None:
    if value is None:
        return None
    return _clean(_TAG_RE.sub("", value)) or None


def _split_names(joined: str | None) -> tuple[str, ...]:
    if not joined:
        return ()
    parts = re.split(r"[;；,，]", _SUPERSCRIPT_RE.sub("", joined))
    return tuple(name for name in (part.strip() for part in parts) if name)


def _year_of(value: object) -> int | None:
    """从站点返回的年/日期字串取四位年份，剔除占位值。

    实测有些记录 date 字段是 ``1900-01-01`` 这类占位符（旧库导入遗留），
    直接播出会变成文献“1900 年”——下游按年份选渠道（mirror-first vs oa-first）
    时会整体算错，所以这里夹在合理区间内才收。
    """
    if not isinstance(value, str):
        return None
    head = value.strip()[:4]
    if not head.isdigit():
        return None
    year = int(head)
    return year if _MIN_YEAR <= year <= _MAX_YEAR else None


def _clean(text: str) -> str:
    return " ".join(text.split())


def _opt_str(value: object) -> str | None:
    return value if isinstance(value, str) and value.strip() else None


__all__ = [
    "TIER1_CN_JOURNALS",
    "NcpssdAPIError",
    "NcpssdHit",
    "NcpssdThrottledError",
    "detail_workers",
    "search_ncpssd",
    "validate_search",
]
