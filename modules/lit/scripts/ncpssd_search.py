#!/usr/bin/env python3
"""ncpssd_search.py — 国家哲学社会科学文献中心（NCPSSD）检索命令行。

连接器逻辑来自 Co.Metrics 内置的 metrics_ai.data.ncpssd 模块（scripts/ncpssd.py），
本脚本在其上加了：两轮分级检索（默认，64 种公认中文顶刊优先）、JSON 输出、
lit-down 衔接（--csv 直接出 cnki_prepare.py 认的清单、--download-oa 直取开放 PDF）、
命令行参数解析。

依赖：httpx（pip install httpx）。检索匿名可用，无需登录；只下载开放（OA）PDF。

用法：
    python ncpssd_search.py "数字普惠金融 城乡收入差距"
    python ncpssd_search.py "共同富裕" --order recency --limit 20
    python ncpssd_search.py "最低工资" --issns 0577-9154          # 定向《经济研究》
    python ncpssd_search.py "乡村振兴" --tier1-only               # 只跑内置 64 种顶刊
    python ncpssd_search.py "..." --json out.json
    python ncpssd_search.py "城市治理 数字化" --csv 中文清单.csv  # 喂 cnki_prepare.py
    python ncpssd_search.py "基层治理" --download-oa ../下载      # 免登录直取 OA 全文
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
from urllib.parse import urljoin

try:
    import httpx
except ImportError:
    print(
        "缺少依赖 httpx：请先 `pip install httpx`（或用 pipx/venv 隔离安装）。",
        file=sys.stderr,
    )
    raise SystemExit(3)

from ncpssd import (
    NcpssdAPIError,
    NcpssdHit,
    NcpssdThrottledError,
    ORDER_RECENCY,
    ORDER_RELEVANCE,
    TIER1_CN_JOURNALS,
    search_ncpssd,
    validate_search,
)

TIER1_CN_TOP = "tier1_cn_top"


def _tier_of(hit: NcpssdHit) -> str | None:
    """ISSN 优先、刊名精确匹配兜底的顶刊标注（TIER1_CN_JOURNALS，64 种）。"""
    if hit.issn in TIER1_CN_JOURNALS:
        return TIER1_CN_TOP
    return TIER1_CN_TOP if (hit.venue or "").strip() in set(TIER1_CN_JOURNALS.values()) else None


def run(
    query: str,
    *,
    limit: int = 10,
    issns: tuple[str, ...] = (),
    order: str = ORDER_RELEVANCE,
    tier1_only: bool = False,
    enrich: bool = True,
) -> tuple[list[dict], str | None]:
    """返回 (匹配列表, backend_error)。backend_error 非 None 表示后端故障而非空库。"""

    passes: tuple[tuple[str, ...], ...]
    if issns or tier1_only:
        passes = (tuple(issns) if issns else tuple(TIER1_CN_JOURNALS),)
    else:
        # 默认两轮：先 64 种顶刊定向，再全库；顶刊命中排最前。
        passes = (tuple(TIER1_CN_JOURNALS), ())

    hits: list[NcpssdHit] = []
    seen: set[str] = set()
    # 先校验参数：参数错要原样抛（exit 2），不能被下面那个 except 归入 backend_error。
    validate_search(query, issns=issns, order=order)
    try:
        for pass_issns in passes:
            if len(hits) >= limit:
                break
            for hit in search_ncpssd(
                query, limit=limit, issns=pass_issns, order=order, enrich=enrich
            ):
                if hit.url in seen or len(hits) >= limit:
                    continue
                seen.add(hit.url)
                hits.append(hit)
    except NcpssdThrottledError as error:
        # 限流/人机验证：既不是空结果，也不是「站点挂了」，单独报，别混成空库。
        return [], f"ncpssd_throttled: {error}"
    except NcpssdAPIError as error:
        return [], f"ncpssd_unavailable: {error}"

    matches = []
    for h in hits:
        d = asdict(h)
        d["authors"] = list(h.authors)
        d["tier"] = _tier_of(h)
        d["landing_url"] = h.url
        # NCPSSD 的 pdfurl 不能当开放证据（多数指向已停用的 nssd.org），
        # 只当“元数据里标了全文链接”统计。
        d["is_open_access"] = None
        d["has_pdf_url"] = bool(h.pdf_url)
        matches.append(d)
    # 顶刊在前，组内保持原序（稳定排序）。
    matches.sort(key=lambda m: 0 if m["tier"] else 1)
    return matches, None


NCPSSD_HOME = "https://www.ncpssd.cn/"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
BAD_CHARS = set('\\/:*?"<>|')


def _safe_name(title: str, limit: int = 60) -> str:
    """文件名清洗：与 lit-down 的统一命名 {序号:03d}-{标题}.pdf 保持一致。"""
    t = re.sub(r"[\r\n\t]+", " ", title or "").strip()
    t = "".join("_" if ch in BAD_CHARS else ch for ch in t)
    t = re.sub(r"\s+", " ", t).strip(" .")
    return t[:limit].rstrip(" .") or "untitled"


def write_csv(matches: list[dict], path: str) -> None:
    """出 cnki_prepare.py 能自动识别的列名（序号/题名/第一作者/期刊/年份/文献类型/等级）。

    多出来的 链接/PDF链接/ISSN 三列 cnki_prepare 会忽略，留着是给人核对用的。
    """
    cols = ["序号", "题名", "第一作者", "期刊", "年份", "文献类型", "等级", "ISSN", "链接", "PDF链接"]
    with open(path, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(cols)
        for i, m in enumerate(matches, 1):
            w.writerow([
                i,
                m["title"],
                (m.get("authors") or [""])[0],
                m.get("venue") or "",
                m.get("year") or "",
                "期刊论文",
                "CSSCI 顶刊" if m.get("tier") else "",
                m.get("issn") or "",
                m.get("url") or "",
                m.get("pdf_url") or "",
            ])
    print(f"已写入 {path}（{len(matches)} 条，可直接 `cnki_prepare.py --csv` 吃进知网链）")


def _fetch_pdf(url: str, *, budget: float = 90.0) -> tuple[bytes | None, str]:
    """取一个 PDF 字节串，校验只看魔数 + 体积（与 lit-down 第四件套同规矩）。"""
    buf = bytearray()
    ctype = ""
    try:
        with httpx.Client(
            follow_redirects=True,
            timeout=httpx.Timeout(30.0, connect=10.0),
            headers={"User-Agent": UA, "Referer": NCPSSD_HOME},
            trust_env=True,
        ) as client:
            with client.stream("GET", url) as resp:
                ctype = resp.headers.get("content-type", "")
                if resp.status_code != 200:
                    return None, f"HTTP {resp.status_code}"
                deadline = time.time() + budget
                for chunk in resp.iter_bytes(65536):
                    buf.extend(chunk)
                    if time.time() > deadline:      # socket timeout 管不住慢速吐字节
                        return None, "slow"
                    if len(buf) > 60 * 1024 * 1024:
                        return None, "too-big"
    except httpx.HTTPError as error:
        return None, f"error {type(error).__name__}"
    raw = bytes(buf)
    if not raw[:5].startswith(b"%PDF"):
        return None, f"not-pdf（{len(raw)}B {ctype or '?'}）"
    if len(raw) < 20000:
        return None, f"not-pdf（仅 {len(raw)}B）"
    return raw, "ok"


def _pages_of(raw: bytes) -> int | None:
    try:
        import io

        import pypdf

        return len(pypdf.PdfReader(io.BytesIO(raw)).pages)
    except Exception:
        return None


def download_oa(matches: list[dict], out_dir: str, *, workers: int = 3) -> None:
    """把命中里带开放 PDF 的条目直接落到本地，免登录。"""
    import os

    os.makedirs(out_dir, exist_ok=True)
    jobs = []
    for i, m in enumerate(matches, 1):
        url = m.get("pdf_url")
        if not url:
            continue
        jobs.append((i, m, urljoin(NCPSSD_HOME, url)))
    if not jobs:
        print("本次命中没有标记为开放的 PDF（NCPSSD 多数全文要登录后从落地页取）。")
        return

    def one(job: tuple[int, dict, str]) -> tuple[int, dict, str, str, int | None, int]:
        i, m, url = job
        raw, status = _fetch_pdf(url)
        pages = _pages_of(raw) if raw else None
        if raw:
            name = f"{i:03d}-{_safe_name(m['title'])}.pdf"
            with open(os.path.join(out_dir, name), "wb") as fh:
                fh.write(raw)
            return i, m, name, status, pages, len(raw)
        return i, m, "", status, None, 0

    rows = []
    with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        for i, m, name, status, pages, size in pool.map(one, jobs):
            rows.append((i, m["title"], status, name, pages or "", size))
            flag = "✓" if name else "×"
            print(f"{flag} {i:3d} {m['title'][:48]} — {status}" + (f" | {pages}p" if pages else ""))

    manifest = os.path.join(out_dir, "ncpssd_oa.csv")
    with open(manifest, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["序号", "题名", "状态", "文件名", "页数", "字节"])
        w.writerows(rows)
    ok = sum(1 for r in rows if r[2] == "ok")
    print(f"\nOA 直取 {ok}/{len(jobs)} 条 → {out_dir}；清单 {manifest}")


def _fmt(match: dict) -> str:
    tier = " [顶刊]" if match["tier"] else ""
    year = match.get("year") or "n.d."
    venue = match.get("venue") or "?"
    authors = "、".join(match.get("authors") or []) or "?"
    oa = " [标称OA]" if match.get("pdf_url") else ""
    lines = [
        f"{match['title']}{tier}{oa}",
        f"    {authors} | {venue} | {year}" + (f" | ISSN {match['issn']}" if match.get("issn") else ""),
        f"    {match['url']}",
    ]
    if match.get("snippet"):
        snippet = match["snippet"]
        lines.append("    " + (snippet[:160] + "…" if len(snippet) > 160 else snippet))
    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="检索国家哲学社会科学文献中心（NCPSSD），中文社科期刊文献结构化结果。"
    )
    ap.add_argument("query", help="检索词；空格分隔多词按 AND 组合")
    ap.add_argument("--limit", type=int, default=10, help="返回条数上限（1–50，默认 10）")
    ap.add_argument(
        "--issns",
        nargs="*",
        default=[],
        help="定向期刊 ISSN（如 0577-9154），可多个；格式不符会直接报错",
    )
    ap.add_argument(
        "--order",
        choices=[ORDER_RELEVANCE, ORDER_RECENCY],
        default=ORDER_RELEVANCE,
        help="排序：relevance（相关度，默认）或 recency（按时间）",
    )
    ap.add_argument(
        "--tier1-only",
        action="store_true",
        help="只检索内置 64 种顶刊（综合社科/经济学金融/社会学青年人口/政治学国关/民族民俗/公管行管/管理学/心理教育/社科总论马列/名校学报）",
    )
    ap.add_argument("--json", dest="json_out", metavar="PATH", help="结果写入 JSON 文件")
    ap.add_argument(
        "--csv",
        dest="csv_out",
        metavar="PATH",
        help="写成中文清单 CSV（列名已对齐 cnki_prepare.py，可直接接着跑知网链）",
    )
    ap.add_argument(
        "--download-oa",
        dest="oa_dir",
        metavar="DIR",
        help="把命中里带开放 PDF 的条目直接下到 DIR（免登录，只看 PDF 魔数；实测多半已死链）",
    )
    ap.add_argument("--oa-workers", type=int, default=3, help="--download-oa 的并发数（默认 3）")
    ap.add_argument(
        "--no-detail",
        action="store_true",
        help="不逐条补全摘要/ISSN（请求数从 1+N 降到 1，大批量扫库时用；会偶见缺 ISSN）",
    )
    ap.add_argument(
        "--min-interval",
        type=float,
        default=None,
        help="两次请求的最小间隔秒数（默认 1.2；站点在挡时可调到 3）",
    )
    ap.add_argument(
        "--detail-workers",
        type=int,
        default=None,
        help="详情补全并发（默认 3，上限即 3；调大只会更容易撞验证页）",
    )
    ap.add_argument(
        "--no-wait",
        action="store_true",
        help="忽略上次留下的冷却记录（确认换了出口 IP 或已在浏览器验过时用）",
    )
    args = ap.parse_args()

    if args.limit < 1 or args.limit > 50:
        print("参数错误：--limit 取值范围 1–50", file=sys.stderr)
        raise SystemExit(2)

    # 命令行参数直接落到连接器的环境变量上：连接器是 import 复用的库，
    # 只在 CLI 层做参数解析，不把 CLI 概念带进库。
    if args.min_interval is not None:
        os.environ["LITDOWN_NCPSSD_MIN_INTERVAL"] = str(max(0.0, args.min_interval))
    if args.detail_workers is not None:
        os.environ["LITDOWN_NCPSSD_WORKERS"] = str(max(1, args.detail_workers))
    if args.no_wait:
        os.environ["LITDOWN_NCPSSD_STATE"] = "off"

    try:
        matches, backend_error = run(
            args.query,
            limit=args.limit,
            issns=tuple(args.issns),
            order=args.order,
            tier1_only=args.tier1_only,
            enrich=not args.no_detail,
        )
    except NcpssdAPIError as error:
        # 参数级错误（空查询、ISSN 格式坏、未知排序）——这是用户输入问题，退出码 2。
        print(f"参数错误：{error}", file=sys.stderr)
        raise SystemExit(2)

    if backend_error:
        if str(backend_error).startswith("ncpssd_throttled"):
            print(f"被站点限流：{backend_error}", file=sys.stderr)
        else:
            print(f"后端不可用：{backend_error}", file=sys.stderr)
        # 检索没跑成不等于没文献：明确报错，退出码 1。
        raise SystemExit(1)

    if args.json_out:
        payload = {
            "query": args.query,
            "order": args.order,
            "issns": args.issns,
            "tier1_only": args.tier1_only,
            "match_count": len(matches),
            "backend_error": None,
            "matches": matches,
        }
        with open(args.json_out, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, ensure_ascii=False, indent=1)
        print(f"已写入 {args.json_out}（{len(matches)} 条）")

    if args.csv_out:
        write_csv(matches, args.csv_out)

    if args.oa_dir:
        download_oa(matches, args.oa_dir, workers=args.oa_workers)

    if not matches:
        print("（无命中——检索成功返回空，如需放宽可减少关键词或去掉 --issns）")
        return

    t1 = sum(1 for m in matches if m["tier"])
    head = f"共 {len(matches)} 条"
    if t1:
        head += f"，其中顶刊 {t1} 条（已置顶）"
    print(head)
    if any(m.get("pdf_url") for m in matches):
        print("注：pdfurl 多为历史 nssd.org 链接（该域名已停用，实测返回 4.6KB HTML）。")
        print("    只当“该记录标称有全文”看，别当直链；真要验用 --download-oa。")
    print()
    for m in matches:
        print(_fmt(m))
        print()


if __name__ == "__main__":
    main()
