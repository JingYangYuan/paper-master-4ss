# -*- coding: utf-8 -*-
"""lit-down 主流程：清单 → DOI → OA 直链 → 镜像兜底 → PDF。

用法:
    python litdown.py --queue refs.json --out 下载 --state state.json --log log.txt
    python litdown.py --queue dois.txt  --out 下载 --only-oa          # 只走合法 OA
    python litdown.py --queue refs.json --ids 3,7,9 --retry-failed     # 重跑指定条目

队列格式（任选其一）:
    [{"id":1,"title":"...","year":2019,"raw":"..."}, ...]
    [{"doi":"10.1093/qje/qjx032"}, ...]
    ["10.1093/qje/qjx032", "A title without doi", ...]

依赖: requests；可选 PyMuPDF 或 pypdf（页数校验）。
"""
import argparse
import json
import os
import random
import re
import sys
import time
from pathlib import Path

import requests

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
# Crossref / Unpaywall 要求留邮箱；`example.com` 这类保留域名会被 Unpaywall 判 422。
# 用环境变量覆盖：$env:LITDOWN_EMAIL="you@university.edu"
CONTACT = os.environ.get("LITDOWN_EMAIL", "litdown.tool@gmail.com")
SKIP_WHY = {"not-in-stash", "HTTP 404", "no-doi", "bad-pdf"}

S = requests.Session()
# 关键：不要传 proxies。Clash TUN 已在系统层接管，显式传会 ProxyError。
S.headers.update({"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})


# ---------- 基础工具 ----------

class Log:
    def __init__(self, path):
        self.f = open(path, "a", encoding="utf-8") if path else None

    def __call__(self, msg):
        print(msg, flush=True)
        if self.f:
            self.f.write(msg + "\n")
            self.f.flush()


def clean_name(s, n=90):
    s = re.sub(r'[\\/:*?"<>|\r\n\t]', " ", s or "")
    return re.sub(r"\s+", " ", s).strip()[:n]


def page_count(raw):
    try:
        import fitz
        return fitz.open(stream=raw, filetype="pdf").page_count
    except Exception:
        pass
    try:
        import pypdf, io
        return len(pypdf.PdfReader(io.BytesIO(raw)).pages)
    except Exception:
        pass
    return len(re.findall(rb"/Type\s*/Page[^s]", raw))     # 压缩流会返回 0，仅作最后兜底


def verify(raw):
    """返回 (页数, 失败原因)。只信魔数。"""
    if not raw or raw[:5] != b"%PDF-":
        return 0, "not-pdf"
    if len(raw) < 20_000:
        return 0, "bad-pdf"
    n = page_count(raw)
    if n < 1:
        return 0, "bad-pdf"
    return n, ""


def fetch(url, referer=None, cookie=None, timeout=(8, 30)):
    h = {}
    if referer:
        h["Referer"] = referer
    if cookie:
        h["Cookie"] = cookie
    try:
        r = S.get(url, headers=h, timeout=timeout, allow_redirects=True)
        if r.status_code == 429:
            time.sleep(12)
            r = S.get(url, headers=h, timeout=timeout, allow_redirects=True)
        if r.status_code != 200:
            return None, f"HTTP {r.status_code}"
        return r.content, ""
    except Exception as e:
        return None, type(e).__name__


# ---------- ② 定位 DOI ----------

def crossref_doi(item):
    title = (item.get("title") or item.get("raw") or "").strip()
    if len(title) < 8:
        return None
    try:
        r = S.get("https://api.crossref.org/works",
                  params={"query.bibliographic": title, "rows": 3,
                          "select": "DOI,title,alternative-id,type,publisher",
                          "mailto": CONTACT}, timeout=(8, 40))
        if r.status_code != 200:
            return None
        key = re.sub(r"[^a-z0-9]", "", title.lower())[:40]
        for it in r.json()["message"]["items"]:
            t = (it.get("title") or [""])[0]
            if re.sub(r"[^a-z0-9]", "", t.lower())[:40] == key and key:
                return it
    except Exception:
        return None
    return None


# ---------- ③ 开放获取链 ----------

def oa_candidates(item, doi):
    """按精度排序，yield (url, src, referer)。"""
    if not doi:
        return
    # 1 Unpaywall
    try:
        r = S.get(f"https://api.unpaywall.org/v2/{doi}", params={"email": CONTACT}, timeout=(8, 30))
        if r.status_code == 200:
            j = r.json()
            best = j.get("best_oa_location") or {}
            for u in [best.get("url_for_pdf"), best.get("url")]:
                if u:
                    yield u, "unpaywall", None
    except Exception:
        pass
    # 2 OpenAlex
    try:
        r = S.get(f"https://api.openalex.org/works/doi:{doi}",
                  params={"select": "best_oa_location,locations,open_access"}, timeout=(8, 30))
        if r.status_code == 200:
            j = r.json()
            best = j.get("best_oa_location") or {}
            if best.get("pdf_url"):
                yield best["pdf_url"], "openalex", None
            for L in (j.get("locations") or []):
                if L.get("pdf_url"):
                    yield L["pdf_url"], "openalex", None
    except Exception:
        pass
    # 3 出版社模板（仅 OA 时有效，失败就当没试过）
    suffix = doi.split("/", 1)[-1]
    if doi.startswith("10.1038/"):
        yield f"https://www.nature.com/articles/{suffix}.pdf", "nature", None
    if doi.startswith("10.1007/"):
        yield f"https://link.springer.com/content/pdf/{doi}.pdf", "springer", None
    if doi.startswith("10.48550/arXiv."):
        yield f"https://arxiv.org/pdf/{suffix}", "arxiv", None
    if doi.startswith("10.3386/w"):
        w = re.sub(r"\D", "", suffix)
        yield f"https://www.nber.org/system/files/working_papers/w{w}/w{w}.pdf", "nber", None
    # 4 Europe PMC（只覆盖生物医学；PDF render 常 403，失败很正常）
    try:
        r = S.get("https://www.ebi.ac.uk/europepmc/webservices/rest/search",
                  params={"query": f'DOI:"{doi}"', "format": "json", "pageSize": 1}, timeout=(8, 30))
        if r.status_code == 200:
            res = (r.json().get("resultList") or {}).get("result") or []
            pmcid = res[0].get("pmcid") if res else None
            if pmcid:
                yield f"https://europepmc.org/articles/{pmcid}?pdf=render", "europepmc", None
    except Exception:
        pass
    # 5 Semantic Scholar
    try:
        r = S.get(f"https://api.semanticscholar.org/graph/v1/paper/DOI:{doi}",
                  params={"fields": "title,openAccessPdf"}, timeout=(8, 30))
        if r.status_code == 200:
            u = (r.json().get("openAccessPdf") or {}).get("url")
            if u:
                yield u, "semanticscholar", None
    except Exception:
        pass


def arxiv_by_title(title):
    toks = [w for w in re.findall(r"[a-z]{4,}", title.lower())
            if w not in {"with", "from", "that", "this", "using", "their", "when"}][:8]
    if len(toks) < 3:
        return []
    try:
        q = " AND ".join(f"ti:{w}" for w in toks)
        r = S.get("http://export.arxiv.org/api/query",
                  params={"search_query": q, "max_results": 8}, timeout=(8, 40))
        if r.status_code != 200:
            return []
    except Exception:
        return []
    out = []
    base = set(toks)
    for m in re.finditer(r"<entry>.*?</entry>", r.text, re.S):
        e = m.group(0)
        t = re.search(r"<title>(.*?)</title>", e, re.S)
        et = re.sub(r"\s+", " ", t.group(1)).strip() if t else ""
        cand = set(w for w in re.findall(r"[a-z]{4,}", et.lower()))
        if not cand:
            continue
        jac = len(base & cand) / len(base | cand)
        pid = re.search(r"<id>http://arxiv.org/abs/([^<]+)</id>", e)
        if jac >= 0.45 and pid:
            out.append((f"https://arxiv.org/pdf/{pid.group(1)}", "arxiv-title", jac))
    out.sort(key=lambda x: -x[2])
    return [(u, s, None) for u, s, _ in out]


def landing_pdf(url, cookie=None):
    """从落地页抓 citation_pdf_url / embed[src$=.pdf]。"""
    raw, why = fetch(url, cookie=cookie, timeout=(8, 40))
    if not raw:
        return None
    html = raw.decode("utf-8", "ignore")
    m = re.search(r'<meta[^>]+name=["\']citation_pdf_url["\'][^>]+content=["\']([^"\']+)', html, re.I)
    if not m:
        m = re.search(r'<embed[^>]+src=["\']([^"\']+\.pdf[^"\']*)', html, re.I)
    if not m:
        return None
    return m.group(1).split("#")[0]


# ---------- ④ 镜像兜底 ----------

MIRRORS = ["sci-hub.ren", "sci-hub.ee", "sci-hub.usualwant.com"]


def scihub(doi, cookie, log):
    for host in MIRRORS:
        raw, why = fetch(f"https://{host}/{doi}", cookie=cookie, timeout=(8, 35))
        if not raw:
            log(f"      {host}: {why}")
            continue
        html = raw.decode("utf-8", "ignore")
        if "mutual aid" in html or "request this article" in html:
            return None, "not-in-stash"
        if "Verification" in html and "scihub_verified" not in html:
            log(f"      {host}: 未过 Turnstile，用浏览器过一遍再带 cookie 回来")
            continue
        m = re.search(r'<embed[^>]+src=["\']([^"\']+\.pdf[^"\']*)', html, re.I)
        if not m:
            log(f"      {host}: 页面里没有 embed 地址")
            continue
        pdf_url = m.group(1).split("#")[0]      # 必须去 #view=FitH
        body, why = fetch(pdf_url, referer=f"https://{host}/", cookie=cookie, timeout=(10, 60))
        if body:
            return body, ""
        log(f"      {host} → cdn: {why}")
    return None, "scihub-fail"


# ---------- 主循环 ----------

def load_queue(path):
    p = Path(path)
    txt = p.read_text(encoding="utf-8")
    if txt.lstrip().startswith("["):
        data = json.loads(txt)
    else:
        data = [ln.strip() for ln in txt.splitlines() if ln.strip() and not ln.startswith("#")]
    out = []
    for i, it in enumerate(data, 1):
        if isinstance(it, str):
            it = {"doi": it} if it.lower().startswith("10.") else {"title": it}
        it.setdefault("id", i)
        out.append(it)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queue", required=True)
    ap.add_argument("--out", default="下载")
    ap.add_argument("--state", default="state.json")
    ap.add_argument("--log", default="log_litdown.txt")
    ap.add_argument("--ids", default="")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--only-oa", action="store_true", help="不下镜像，只走合法 OA")
    ap.add_argument("--scihub-cookie", default="scihub_verified=1")
    ap.add_argument("--retry-failed", action="store_true")
    ap.add_argument("--delay", type=float, default=0.8)
    a = ap.parse_args()

    log = Log(a.log)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    sp = Path(a.state)
    state = json.loads(sp.read_text(encoding="utf-8")) if sp.exists() else {}

    queue = load_queue(a.queue)
    if a.ids:
        want = {int(x) for x in a.ids.split(",") if x.strip()}
        queue = [q for q in queue if int(q["id"]) in want]
    todo = []
    for q in queue:
        s = state.get(str(q["id"]), {})
        if s.get("ok"):
            continue
        if not a.retry_failed and s.get("why") in SKIP_WHY:
            continue
        todo.append(q)
    if a.limit:
        todo = todo[:a.limit]
    log(f"=== lit-down: 队列 {len(queue)}，待抓 {len(todo)} ===")

    for n, item in enumerate(todo, 1):
        i = int(item["id"])
        title = item.get("title") or item.get("raw") or ""
        rec = {"title": title[:200], "year": item.get("year")}
        doi = item.get("doi")

        if not doi and title:
            cr = crossref_doi(item)
            if cr:
                doi = cr["DOI"]
                rec["pii"] = (cr.get("alternative-id") or [None])[0]
                if not title:
                    title = (cr.get("title") or [""])[0]
                    rec["title"] = title[:200]
        rec["doi"] = doi

        if not title and doi:
            try:
                cr = S.get(f"https://api.crossref.org/works/{doi}",
                           params={"mailto": CONTACT}, timeout=(8, 25)).json()["message"]
                title = (cr.get("title") or [""])[0]
                rec["title"] = title[:200]
                rec["year"] = rec.get("year") or ((cr.get("issued", {}).get("date-parts") or [[None]])[0][0])
            except Exception:
                pass

        hit = None
        if doi:
            for url, src, ref in oa_candidates(item, doi):
                body, why = fetch(url, referer=ref)
                if body and verify(body)[0]:
                    hit = (body, src, url)
                    break
                if body and not verify(body)[0]:
                    pdf2 = landing_pdf(url)
                    if pdf2:
                        body, _ = fetch(pdf2, referer=url)
                        if body and verify(body)[0]:
                            hit = (body, src + "+meta", pdf2)
                            break
        elif title:
            for url, src, ref in arxiv_by_title(title):
                body, _ = fetch(url)
                if body and verify(body)[0]:
                    hit = (body, src, url)
                    break

        if not hit and not a.only_oa and doi:
            body, why = scihub(doi, a.scihub_cookie, log)
            if body and verify(body)[0]:
                hit = (body, "scihub", doi)
            elif why == "not-in-stash":
                rec["why"] = "not-in-stash"

        if hit:
            body, src, url = hit
            pages, why = verify(body)
            f = out / f"{i:03d}-{clean_name(title or doi)}.pdf"
            f.write_bytes(body)
            rec.update({"ok": True, "file": str(f), "pages": pages, "size": len(body),
                        "src": src, "url": str(url)})
            log(f"OK {i:3d} {pages:4d}p [{src}] {title[:55]}")
        else:
            if not rec.get("why"):
                rec["why"] = "no-doi" if not doi else "oa-miss"
            rec.update({"ok": False})
            log(f"-- {i:3d} {rec['why']:<12s} {title[:55]}")

        state[str(i)] = rec
        sp.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")
        time.sleep(a.delay + random.random() * 0.7)

    ok = sum(1 for v in state.values() if v.get("ok"))
    by = {}
    for v in state.values():
        if v.get("ok"):
            by[v.get("src", "?")] = by.get(v.get("src", "?"), 0) + 1
    log(f"=== 结束：本次 +{len([1 for v in todo if state[str(v['id'])].get('ok')])}，"
        f"累计 {ok}/{len(state)}；渠道 {by} ===")


if __name__ == "__main__":
    sys.exit(main())
