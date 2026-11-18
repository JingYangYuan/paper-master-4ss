# -*- coding: utf-8 -*-
"""并发下载：镜像 / OA 链按指定顺序打，每条都过"校验四件套"。

相对 litdown.py 的四点改动，都是踩过的坑：

1. **fetch 用 stream + 墙钟 deadline**。requests 的 `timeout=(6, 30)` 只保证单次 socket
   读写不超时；服务器慢速吐字节时每次 read 都在 30s 内成功，整个请求可以挂到无限长
   （慢速服务器会让整批任务像"卡死"，一条日志都不出）。
2. **state 写入用 RLock**。给并发加 `threading.Lock` 之后又在锁内调自己的 `log()`
   （它也要这把锁），`Lock` 不可重入 → 主线程死锁，worker 全部空转，日志一条不出。
3. **每条最多试 4 个候选、单条墙钟上限**。OA 候选可能十几个，一个 30s 超时就是十分钟。
4. **sci-hub 页面先找 `<embed>` 再判"没有"**。`mutual aid` 这个字符串在**有** PDF 的
   正常页面上也会出现，先判它会把能下的条目误杀成 not-in-stash。

顺序：默认 mirror-first（老文献最快）。老文献里镜像命中率远高于 OA 链，先跑 OA 等于为镜像本来
能直接命中的条目每条都白跑一遍多候选的 OA 链。

用法:
    python download.py --stage all --order mirror-first --workers 4 --out ../下载 --state state.json
    python download.py --stage all --order oa-first --probe oa_probe.json ...   # 新文为主时
    python download.py --refs refs_final.json --probe-oa oa_probe.json        # 只预探 OA，不下载
    python download.py --stage mirror --workers 2 --ids 56,147 ...             # 单独重试

队列格式: refs_final.json（enrich_crossref.py merge 的产物），字段 id/title/year/doi/kind
"""
import argparse
import io
import json
import random
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from difflib import SequenceMatcher
from pathlib import Path

import requests

try:
    import pymupdf
except ImportError:                       # 没装也能跑，只是页数校验退化到 pypdf
    pymupdf = None

MAIL = "litdown.tool@gmail.com"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
MIRRORS = ["sci-hub.ru", "sci-hub.ren", "sci-hub.ee", "sci-hub.usualwant.com"]
CDN = "https://sci.bban.top/pdf/{}.pdf"

_tl = threading.local()
LOCK = threading.RLock()                  # 必须 RLock：log() 也在锁内被调用
LOG_F = None
PROBE = {}
MAX_CANDS = 4
ITEM_BUDGET = 150                          # 单条墙钟上限（秒）


def sess():
    if not hasattr(_tl, "s"):
        s = requests.Session()
        s.headers.update({"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})
        _tl.s = s
    return _tl.s


def log(msg):
    line = time.strftime("%H:%M:%S ") + msg
    with LOCK:
        print(line, flush=True)
        if LOG_F:
            LOG_F.write(line + "\n")
            LOG_F.flush()


# ---------- 校验四件套 ----------

def page_count(raw):
    if pymupdf:
        try:
            return pymupdf.open(stream=raw, filetype="pdf").page_count
        except Exception:
            pass
    try:
        import pypdf
        return len(pypdf.PdfReader(io.BytesIO(raw)).pages)
    except Exception:
        return 0


def verify(raw):
    if not raw or raw[:5] != b"%PDF-":
        return 0, "not-pdf"
    if len(raw) < 20_000:
        return 0, "bad-pdf"
    n = page_count(raw)
    return (n, "") if n >= 1 else (0, "bad-pdf")


def extract_text(raw, pages=10):
    if not pymupdf:
        return ""
    try:
        d = pymupdf.open(stream=raw, filetype="pdf")
        return "".join(d[i].get_text() for i in range(min(pages, d.page_count)))
    except Exception:
        return ""


def match(text, title, doi=None):
    """双通道 + DOI；autojunk=False 不能省。"""
    if doi and doi.lower().strip() in (text or "").lower():
        return "doi", 1.0
    if not title:
        return "", 0.0
    tw = re.findall(r"[a-z0-9]+", title.lower())
    pw = re.findall(r"[a-z0-9]+", (text or "").lower())
    if not tw or not pw:
        return "", 0.0
    L = SequenceMatcher(None, tw, pw, autojunk=False).find_longest_match(0, len(tw), 0, len(pw)).size
    if L >= max(4, int(len(tw) * 0.45)):
        return "word", L / len(tw)
    tn, pn = re.sub(r"[^a-z0-9]", "", title.lower()), re.sub(r"[^a-z0-9]", "", text.lower())[:6000]
    C = SequenceMatcher(None, tn, pn, autojunk=False).find_longest_match(0, len(tn), 0, len(pn)).size
    if C >= int(len(tn) * 0.62):
        return "char", C / len(tn)
    return "", 0.0


REVIEW = re.compile(r"(book reviews?|reviews? of books|reviewed by|short book review)", re.I)


def content_ok(raw, title, doi=None, kind=""):
    """标题命中还不够：书评的题名页含被评书全名，必须排除。"""
    text = extract_text(raw)
    how, sc = match(text, title, doi)
    if not how:
        text = extract_text(raw, pages=40) or text
        how, sc = match(text, title, doi)
    if how and kind != "article" and REVIEW.search(re.sub(r"\s+", " ", text[:3000])):
        return "", 0.0            # 书评：必须返回空串，否则外层 `if how:` 会把它当成功
    return how, sc


# ---------- 抓取 ----------

def fetch(url, referer=None, timeout=(6, 20), budget=45, cap=60 << 20):
    """stream 读取 + 墙钟预算。服务器慢速吐字节时只有这个办法能掐断。"""
    h = {"Referer": referer} if referer else {}
    deadline = time.time() + budget
    try:
        r = sess().get(url, headers=h, timeout=timeout, allow_redirects=True, stream=True)
        if r.status_code != 200:
            r.close()
            return None, f"HTTP {r.status_code}"
        buf, total = [], 0
        for chunk in r.iter_content(65536):
            buf.append(chunk)
            total += len(chunk)
            if total > cap or time.time() > deadline:
                r.close()
                return (b"".join(buf), "") if total > cap else (None, "slow")
        return b"".join(buf), ""
    except Exception as e:
        return None, type(e).__name__


def probe_oa(refs, out_path, workers=8):
    """先批量问 Unpaywall：只有 is_oa 的才值得进下载流程。
    先问一遍能省掉大部分注定拿不到的抓取。"""
    def one(r):
        doi = r.get("doi")
        if not doi:
            return r["id"], {"urls": []}
        o = {"urls": []}
        try:
            j = sess().get(f"https://api.unpaywall.org/v2/{doi}", params={"email": MAIL},
                           timeout=(6, 15)).json()
            o["is_oa"] = j.get("is_oa")
            for loc in ([j.get("best_oa_location") or {}] + (j.get("oa_locations") or []))[:4]:
                for u in (loc.get("url_for_pdf"), loc.get("url")):
                    if u and u not in o["urls"]:
                        o["urls"].append(u)
        except Exception as e:
            o["err"] = type(e).__name__
        return r["id"], o

    res, t0 = {}, time.time()
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(one, r) for r in refs]
        for n, f in enumerate(as_completed(futs), 1):
            i, o = f.result()
            res[str(i)] = o
            if n % 20 == 0:
                log(f"  probe {n}/{len(refs)} {time.time()-t0:.0f}s")
    json.dump(res, open(out_path, "w"), indent=1)
    log(f"=== probe 完成：{sum(1 for v in res.values() if v['urls'])}/{len(res)} 条有 OA 直链，"
        f"{time.time()-t0:.0f}s → {out_path}")


def oa_candidates(doi, rid):
    seen, out = set(), []
    if PROBE and str(rid) not in PROBE:
        return []                         # probe 模式下没直链的条目：连 API 都不问，直接走镜像
    if str(rid) in PROBE:                 # probe 模式：不再实时问 API
        for u in PROBE[str(rid)].get("urls", [])[:3]:
            out.append((u, "unpaywall", None))
            seen.add(u)
        if doi.startswith("10.3386/w"):
            w = re.sub(r"\D", "", doi.split("/", 1)[-1])
            out.append((f"https://www.nber.org/system/files/working_papers/w{w}/{w}.pdf", "nber", None))
        return out

    def add(u, src):
        if u and u not in seen:
            seen.add(u)
            out.append((u, src, None))

    try:
        j = sess().get(f"https://api.unpaywall.org/v2/{doi}", params={"email": MAIL},
                       timeout=(6, 20)).json()
        best = j.get("best_oa_location") or {}
        add(best.get("url_for_pdf"), "unpaywall")
        add(best.get("url"), "unpaywall")
        for loc in (j.get("oa_locations") or [])[:2]:
            add(loc.get("url_for_pdf"), "unpaywall")
    except Exception:
        pass
    try:
        j = sess().get(f"https://api.openalex.org/works/doi:{doi}",
                       params={"select": "best_oa_location,locations"}, timeout=(6, 20)).json()
        best = j.get("best_oa_location") or {}
        add(best.get("pdf_url"), "openalex")
        add(best.get("landing_page_url"), "openalex")
        for L in (j.get("locations") or [])[:3]:
            add(L.get("pdf_url"), "openalex")
    except Exception:
        pass
    suffix = doi.split("/", 1)[-1]
    if doi.startswith("10.48550/arXiv."):
        add(f"https://arxiv.org/pdf/{suffix}", "arxiv")
    if doi.startswith("10.3386/w"):
        w = re.sub(r"\D", "", suffix)
        add(f"https://www.nber.org/system/files/working_papers/w{w}/{w}.pdf", "nber")
    if doi.startswith("10.1007/"):
        add(f"https://link.springer.com/content/pdf/{doi}.pdf", "springer")
    if doi.startswith("10.1038/"):
        add(f"https://www.nature.com/articles/{suffix}.pdf", "nature")
    return out


def landing_pdf(url):
    raw, _ = fetch(url, timeout=(6, 25))
    if not raw:
        return None
    html = raw.decode("utf-8", "ignore")
    m = (re.search(r'<meta[^>]+name=["\']citation_pdf_url["\'][^>]+content=["\']([^"\']+)', html, re.I)
         or re.search(r'<embed[^>]+src=["\']([^"\']+\.pdf[^"\']*)', html, re.I))
    return m.group(1).split("#")[0] if m else None


def scihub(doi):
    for host in MIRRORS:
        raw, why = fetch(f"https://{host}/{doi}", timeout=(6, 25))
        if not raw:
            continue
        html = raw.decode("utf-8", "ignore")
        # sci-hub.ru 新布局不再给 <embed>，PDF 落在 /storage/... 路径上（页面里明文可见）
        m = re.search(r'(["\'])(/storage/[^"\']+\.pdf)\1', html)
        if not m:
            m = re.search(r'<embed[^>]+src=["\']([^"\']+\.pdf[^"\']*)', html, re.I)
            if m and not m.group(1).startswith("/storage/"):
                body, _ = fetch(m.group(1).split("#")[0], referer=f"https://{host}/",
                                timeout=(8, 50), budget=90)
                if body:
                    return body, ""
                continue
        if m:                                        # 先看 PDF 直链，再谈别的
            url = m.group(2) if m.lastindex and m.lastindex >= 2 else m.group(1)
            if url.startswith("/"):
                url = f"https://{host}{url}"
            body, _ = fetch(url.split("#")[0], referer=f"https://{host}/",
                            timeout=(8, 50), budget=90)
            if body:
                return body, ""
            continue
        if re.search(r"request this article|article not found", html, re.I):
            return None, "not-in-stash"
    # CDN 兜底：两种编码都试（页面给哪种就说明库里存的哪种，自己拼时不知道）
    for enc in (doi, doi.replace("/", "%252F")):
        body, _ = fetch(CDN.format(enc), referer="https://sci-hub.ren/", timeout=(8, 50), budget=90)
        if body:
            return body, ""
    return None, "scihub-fail"


def clean_name(s, n=80):
    s = re.sub(r'[\\/:*?"<>|\r\n\t]', " ", s or "")
    return re.sub(r"\s+", " ", s).strip()[:n]


# ---------- 单条 ----------

def try_oa(ref, rec, tried, t0, out_dir):
    """OA 链：Unpaywall → OpenAlex → 出版社模板 → 落地页。慢，但合法且不需要镜像。"""
    i, doi, title = ref["id"], ref.get("doi"), ref.get("title") or ""
    for url, src, refr in oa_candidates(doi, i)[:MAX_CANDS]:
        if time.time() - t0 > ITEM_BUDGET:
            tried.append("budget")
            break
        body, why = fetch(url, referer=refr, timeout=(6, 25))
        if body and verify(body)[0]:
            how, sc = content_ok(body, title, doi, ref.get("kind", ""))
            if how:
                return finish(rec, body, src, url, how, sc, out_dir)
            tried.append(f"{src}:content({sc:.2f})")
            continue
        if body:                                       # 落地页 → 抓 citation_pdf_url
            p2 = landing_pdf(url)
            if p2:
                b2, _ = fetch(p2, referer=url, timeout=(8, 45))
                if b2 and verify(b2)[0]:
                    how, sc = content_ok(b2, title, doi, ref.get("kind", ""))
                    if how:
                        return finish(rec, b2, src + "+meta", p2, how, sc, out_dir)
        tried.append(f"{src}:{why or 'not-pdf'}")
    return None


def try_mirror(ref, rec, tried, out_dir):
    """镜像：一条 DOI 一次，命中率随年份塌，但 2021 年前的老文献极快。"""
    doi, title = ref.get("doi"), ref.get("title") or ""
    body, why = scihub(doi)
    if body and verify(body)[0]:
        how, sc = content_ok(body, title, doi, ref.get("kind", ""))
        if how:
            return finish(rec, body, "scihub", doi, how, sc, out_dir)
        tried.append(f"scihub:content({sc:.2f})")
        rec["why"] = "wrong-content"
    else:
        rec["why"] = why
        tried.append(f"scihub:{why}")
    return None


def process(ref, out_dir, stage, order="mirror-first"):
    t0 = time.time()
    i, doi, title = ref["id"], ref.get("doi"), ref.get("title") or ""
    rec = {"id": i, "title": title, "year": ref.get("year"), "doi": doi, "kind": ref.get("kind"), "ok": False}
    tried = []

    if stage == "mirror":
        seq = ["mirror"]
    elif stage == "oa":
        seq = ["oa"]
    else:                                              # all：按 order 决定先后
        seq = ["mirror", "oa"] if order == "mirror-first" else ["oa", "mirror"]

    for step in seq:
        if not doi:
            break
        hit = try_mirror(ref, rec, tried, out_dir) if step == "mirror" \
            else try_oa(ref, rec, tried, t0, out_dir)
        if hit:
            return hit

    rec.setdefault("why", "no-doi" if not doi else "not-found")
    rec["tried"] = tried[:8]
    return rec


def finish(rec, body, src, url, how, sc, out_dir):
    pages = verify(body)[0]
    f = Path(out_dir) / f"{rec['id']:03d}-{clean_name(rec['title'])}.pdf"
    f.write_bytes(body)
    rec.update({"ok": True, "file": f.name, "pages": pages, "size": len(body),
                "src": src, "url": str(url), "match": how, "score": round(sc, 3)})
    return rec


def main():
    global LOG_F, PROBE
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", default="all", choices=["oa", "mirror", "all"])
    ap.add_argument("--out", default="../下载")
    ap.add_argument("--refs", default="refs_final.json")
    ap.add_argument("--state", default="state.json")
    ap.add_argument("--log", default="download.log")
    ap.add_argument("--ids", default="")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--probe", default="", help="oa_probe.json：用预探的直链，不实时问 API")
    ap.add_argument("--probe-oa", default="", help="只做 OA 预探，输出到这个文件，不下载")
    # 注：--probe-oa 接的是「输出文件」，refs 走 --refs
    ap.add_argument("--order", default="mirror-first", choices=["mirror-first", "oa-first"],
                    help="stage=all 时的尝试顺序。老文献（≤2021）用 mirror-first 最快")
    a = ap.parse_args()

    LOG_F = open(a.log, "a", encoding="utf-8")
    refs = json.load(open(a.refs, encoding="utf-8"))
    if a.probe_oa:
        probe_oa(refs, a.probe_oa)
        return
    if a.probe:
        PROBE = json.load(open(a.probe, encoding="utf-8"))
        log(f"probe 模式：{sum(1 for v in PROBE.values() if v.get('urls'))} 条带直链")

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    sp = Path(a.state)
    state = json.loads(sp.read_text(encoding="utf-8")) if sp.exists() else {}
    want = {int(x) for x in a.ids.split(",") if x.strip()} if a.ids else None
    todo = [r for r in refs
            if (want is None or r["id"] in want) and not state.get(str(r["id"]), {}).get("ok")]
    if a.stage == "oa":
        todo = [r for r in todo if r.get("doi")]
    log(f"=== stage={a.stage} workers={a.workers} 待抓 {len(todo)}/{len(refs)} ===")

    done = 0
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        futs = {ex.submit(process, r, str(out), a.stage, a.order): r for r in todo}
        for fut in as_completed(futs):
            ref = futs[fut]
            try:
                rec = fut.result()
            except Exception as e:
                rec = {"id": ref["id"], "title": ref.get("title"), "ok": False,
                       "why": f"error:{type(e).__name__}"}
            with LOCK:
                state[str(ref["id"])] = rec
                sp.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")
                done += 1
                if rec.get("ok"):
                    log(f"{done:3d}/{len(todo)} OK  {rec['id']:3d} {rec['pages']:4d}p "
                        f"[{rec['src']}/{rec['match']}] {rec['title'][:45]}")
                else:
                    log(f"{done:3d}/{len(todo)} --  {rec['id']:3d} {rec.get('why',''):<14s} {rec['title'][:45]}")

    ok = sum(1 for v in state.values() if v.get("ok"))
    by = {}
    for v in state.values():
        if v.get("ok"):
            by[v.get("src")] = by.get(v.get("src"), 0) + 1
    log(f"=== 累计 {ok}/{len(state)}（仅本 state；书轮另有 state_books.json）；渠道 {by} ===")


if __name__ == "__main__":
    sys.exit(main())
