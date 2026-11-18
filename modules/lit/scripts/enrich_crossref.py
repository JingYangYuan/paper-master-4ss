# -*- coding: utf-8 -*-
"""raw 引文 → 结构化条目（title/year/venue/type）→ Crossref 定位 DOI → 审核。

三件事分开做，因为它们是三种不同的错误来源：

  ① 切词（parse）   —— 引文格式五花八门，切错标题后面全错
  ② 定位（crossref）—— 命中判据必须"返回标题出现在原引文里"，宽松相似度会把
                        AER 的文章匹到 JPE 去
  ③ 审核（audit）   —— 第二轮用 query.title 能捞回一批，但**捞回的一半是错的**
                        （书评、百科条目、同名综述）。不审就用，等于把错 DOI 喂给下载器。

用法:
    python enrich_crossref.py parse  --raw refs_raw.json --out refs.json
    python enrich_crossref.py doi    --refs refs.json --cache doi_cache.json
    python enrich_crossref.py doi    --refs refs.json --cache doi_cache.json --round2
    python enrich_crossref.py audit  --refs refs.json --cache doi_cache.json [--apply]
    python enrich_crossref.py merge  --refs refs.json --cache doi_cache.json \
                                     --overrides overrides.json --out refs_final.json

overrides.json 格式（人工判死后写进去，merge 时生效）:
    {"21": {"doi": "10.xxxx/yyyy"},            # 人工找到的正确 DOI
     "53": {"doi": null},                       # 判死：连同它带回来的错标题一起丢弃
     "65": {"doi": null, "title": "正确的书名"}}
"""
import argparse
import json
import os
import re
import time

import requests

MAIL = os.environ.get("LITDOWN_EMAIL", "litdown.tool@gmail.com")
QUOTES = "\u201c\u201d\"\u2018\u2019\u201e"
QCLS = "[" + QUOTES + "]"
NEG = "[^" + QUOTES + "]"
BAD = re.compile(r"\[PubMed:?[^\]]*\]|\[PMC[^\]]*\]|Retrieved\s*\([^)]*\)", re.I)
S = requests.Session()
S.headers.update({"User-Agent": "lit-down/1.1 (mailto:%s)" % MAIL})


def nz(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def toks(s):
    return set(w for w in re.findall(r"[a-z0-9]+", (s or "").lower()) if len(w) > 1)


# ---------- ① 切词 ----------

def parse_one(raw):
    r = re.sub(r"\s+", " ", BAD.sub(" ", raw)).strip()
    typ = None
    if re.search(r"\bIn:\s", r) and re.search(r"\beditors?\b", r):
        typ = "chapter"
    elif re.search(r"Doctoral Dissertation|Lecture at", r):
        typ = "thesis"
    elif re.search(r"Stata module|ssc install", r, re.I):
        typ = "software"

    title = venue = ""
    m = re.search(rf"{QCLS}\s*({NEG}{{6,260}}?)\s*{QCLS}", r)
    if m:                                   # 引号版（APA/NIH 系）
        title = m.group(1)
        rest = re.sub(r"^[.,;]\s*", "", r[m.end():].strip())
        typ = typ or "article"
        if typ == "article":
            vm = re.match(r"^(.{2,120}?)[.,;]?\s*(?:19|20)\d{2}\b", rest)
            if vm:
                venue = vm.group(1).strip(" .")
    else:                                   # 无引号版（ASR/JASA 系）
        am = re.match(r"^(.{3,260}?)\.\s+(?=[A-Z0-9])", r)
        body = r[am.end():] if am else r
        ym = re.search(r"\b(1[89]\d{2}|20[0-2]\d)\b", body)
        head = body[: ym.start()] if ym else body
        segs = re.split(r"(?<=[.?!”])\s+", head.strip())
        if len(segs) >= 2:
            title, venue = segs[0], " ".join(segs[1:]).strip(" .;")
        else:
            title = head.strip(" .;")
        typ = typ or "book"
        venue = re.sub(r"^[A-Z][^:]{2,30}:\s*", "", venue).strip(" .;")

    m2 = re.search(r"\b(1[89]\d{2}|20[0-2]\d)\b\s*[;:(]", r) or re.search(r"\b(1[89]\d{2}|20[0-2]\d)\b", r)
    year = int(m2.group(1)) if m2 else None
    if typ == "book":
        ys = re.findall(r"\b(1[89]\d{2}|20[0-2]\d)\b", r)
        if ys:
            year = int(ys[-1])

    return {
        "raw": r,
        "title": re.sub(r"\s+", " ", title).strip(" .;:"),
        "year": year,
        "venue": venue[:120],
        "type": typ or "other",
        "first_author": re.split(r"[,.]", r)[0].strip(),
    }


def cmd_parse(a):
    rows = json.load(open(a.raw, encoding="utf-8"))
    parsed = []
    for r in rows:
        p = parse_one(r["raw"])
        p["sources"] = [r["source"]]
        parsed.append(p)
    merged, order = {}, []
    for p in parsed:                                  # 按标题去重（同一篇被两章引用很常见）
        k = nz(p["title"])[:80]
        if not k:
            continue
        if k in merged:
            for s in p["sources"]:
                if s not in merged[k]["sources"]:
                    merged[k]["sources"].append(s)
            continue
        p["key"] = k
        merged[k] = p
        order.append(k)
    out = []
    for i, k in enumerate(order, 1):
        merged[k]["id"] = i
        out.append(merged[k])
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    from collections import Counter
    print(f"{len(rows)} → {len(out)} 条", Counter(p["type"] for p in out))


# ---------- ② 定位 ----------

def crossref(params, rows=5):
    for attempt in range(3):
        try:
            r = S.get("https://api.crossref.org/works",
                      params={**params, "rows": rows, "mailto": MAIL,
                              "select": "DOI,title,container-title,issued,type,score,publisher,alternative-id"},
                      timeout=(8, 40))
            if r.status_code == 429:
                time.sleep(10 + attempt * 10)
                continue
            return r.json()["message"]["items"] if r.status_code == 200 else None
        except Exception:
            time.sleep(2)
    return None


def pick(items, raw, title=None):
    """命中判据：返回标题的前 40 字符（归一化）必须出现在原引文里。"""
    nr = nz(raw)
    best = None
    for it in items or []:
        t = (it.get("title") or [""])[0]
        nt = nz(t)
        if len(nt) < 8:
            continue
        head = nt[:40]
        ok = head in nr or (len(nr) >= 40 and nr[:40] in nt) or (title and nt[:35] in nz(title))
        if not ok:
            continue
        score = it.get("score", 0) + (30 if head in nr else 0)
        if best is None or score > best[0]:
            best = (score, it)
    return best[1] if best else None


def rec_of(it):
    return {
        "doi": it["DOI"],
        "cr_title": (it.get("title") or [""])[0],
        "cr_year": ((it.get("issued", {}).get("date-parts") or [[None]])[0][0]),
        "cr_venue": (it.get("container-title") or [""])[0],
        "cr_type": it.get("type"),
        "publisher": it.get("publisher"),
        "pii": (it.get("alternative-id") or [None])[0],
    }


def cmd_doi(a):
    refs = json.load(open(a.refs, encoding="utf-8"))
    cache = json.load(open(a.cache, encoding="utf-8")) if os.path.exists(a.cache) else {}
    for n, ref in enumerate(refs, 1):
        k = str(ref["id"])
        if cache.get(k, {}).get("doi") and not a.round2:
            continue
        if a.round2 and (cache.get(k, {}).get("doi") or cache.get(k, {}).get("round2")):
            continue
        q = {"query.title": ref["title"]} if a.round2 else {"query.bibliographic": ref["raw"][:380]}
        hit = pick(crossref(q), ref["raw"], ref["title"])
        cache[k] = rec_of(hit) if hit else {"doi": None}
        if a.round2:
            cache[k]["round2"] = True
        json.dump(cache, open(a.cache, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        flag = "OK " if hit else "-- "
        print(f"{n:3d}/{len(refs)} {flag}{ref['title'][:60]}", flush=True)
        time.sleep(0.35)
    print(f"=== DOI {sum(1 for v in cache.values() if v.get('doi'))}/{len(refs)} ===")


# ---------- ③ 审核 ----------

def judge(our, cr):
    a, b = toks(our), toks(cr)
    if not a or not b:
        return 0.0
    if nz(cr)[:35] in nz(our) or nz(our)[:35] in nz(cr):
        return 1.0
    cov_a, cov_b = len(a & b) / len(a), len(b & a) / len(b)
    return min(cov_a, cov_b) if cov_a > 0.5 else 0.0


def cmd_audit(a):
    refs = {r["id"]: r for r in json.load(open(a.refs, encoding="utf-8"))}
    cache = json.load(open(a.cache, encoding="utf-8"))
    bad = []
    for k, v in cache.items():
        if not v.get("doi"):
            continue
        sc = judge(refs[int(k)]["title"], v.get("cr_title", ""))
        if sc < 0.8:
            bad.append((int(k), round(sc, 2), v["doi"], v.get("cr_title", "")[:60], refs[int(k)]["title"][:60]))
    print(f"通过 {sum(1 for v in cache.values() if v.get('doi')) - len(bad)} / 可疑 {len(bad)}")
    for b in sorted(bad):
        print(f"  {b[0]:3d} {b[1]:.2f} {b[2]:<34s} CR: {b[3]} || ref: {b[4]}")
    if a.apply:
        for b in bad:
            cache[str(b[0])]["rejected"] = cache[str(b[0])]["doi"]
            cache[str(b[0])]["doi"] = None
        json.dump(cache, open(a.cache, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("已把可疑项 doi 置空（保留 rejected 字段供追溯）")


# ---------- 合并 ----------

BOOKT = ("book", "monograph", "edited-book", "reference-book", "report", "thesis",
         "dissertation", "posted-content", "dataset", "component", "standard")


def cmd_merge(a):
    refs = json.load(open(a.refs, encoding="utf-8"))
    cache = json.load(open(a.cache, encoding="utf-8"))
    ovr = json.load(open(a.overrides, encoding="utf-8")) if a.overrides and os.path.exists(a.overrides) else {}
    out = []
    for r in refs:
        k = str(r["id"])
        c, o = dict(cache.get(k, {})), ovr.get(k, {})
        doi = o["doi"] if "doi" in o else c.get("doi")
        if "doi" in o and o["doi"] is None:
            # 判死的 DOI：连同它带回来的错标题一起丢，回到 PDF 里解析出的原引文标题
            title, year, venue, typ = o.get("title") or r["title"], r.get("year"), r.get("venue"), r["type"]
        else:
            title = o.get("title") or c.get("cr_title") or r["title"]
            year = c.get("cr_year") or r.get("year")
            venue = c.get("cr_venue") or r.get("venue")
            typ = c.get("cr_type") or r["type"]
        if typ in BOOKT or r["type"] in ("book", "thesis"):
            kind = "book"
        elif typ in ("journal-article", "article", "proceedings-article"):
            kind = "article"
        elif typ == "book-chapter":
            kind = "chapter"
        else:
            kind = r["type"]
        out.append({"id": r["id"], "title": re.sub(r"^\d+\.\s*", "", title or "").strip(),
                    "year": year, "venue": venue, "doi": doi, "kind": kind,
                    "sources": r["sources"], "raw": r["raw"], "note": o.get("note", "")})
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    from collections import Counter
    print(f"{len(out)} 条", Counter(x["kind"] for x in out),
          f"有 DOI {sum(1 for x in out if x['doi'])}")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("parse"); p.add_argument("--raw", required=True); p.add_argument("--out", default="refs.json")
    p.set_defaults(fn=cmd_parse)

    p = sub.add_parser("doi"); p.add_argument("--refs", default="refs.json"); p.add_argument("--cache", default="doi_cache.json")
    p.add_argument("--round2", action="store_true"); p.set_defaults(fn=cmd_doi)

    p = sub.add_parser("audit"); p.add_argument("--refs", default="refs.json"); p.add_argument("--cache", default="doi_cache.json")
    p.add_argument("--apply", action="store_true"); p.set_defaults(fn=cmd_audit)

    p = sub.add_parser("merge"); p.add_argument("--refs", default="refs.json"); p.add_argument("--cache", default="doi_cache.json")
    p.add_argument("--overrides", default="overrides.json"); p.add_argument("--out", default="refs_final.json")
    p.set_defaults(fn=cmd_merge)

    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
