# -*- coding: utf-8 -*-
"""书轮：LibGen 图书库（不是论文库）。

**`index.php?req=` 默认几乎只出期刊文章（scimag）**，搜一本专著会看到满屏同主题论文，
看起来像"库里没有这本书"。加 `topics[]=l`（l = libgen 图书库）才会出书。
这是本书轮最容易踩的坑：不带它命中率极低，带上之后同样几本书立刻就有。

链路:
    index.php?req={q}&topics[]=l&res=50  → 表格里取 md5
    ads.php?md5={md5}                    → 正则 get.php?md5=..&key=..
    get.php?...                          → 校验 %PDF-

匹配: 归一化包含 / SequenceMatcher，阈值 0.60；标题列常带 ISBN、文件名、`" href=` 碎片，
先清洗再比。命中后仍要过内容比对——LibGen 里同名书评（类型 a）经常排在正书前面。

用法:
    python books_libgen.py --refs refs_final.json --state state_books.json --out ../下载
    python books_libgen.py --ids 26,65 --delay 3
"""
import argparse
import json
import random
import re
import sys
import time
from difflib import SequenceMatcher
from pathlib import Path

import requests

try:
    import pymupdf
except ImportError:
    pymupdf = None

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
HOST = "https://libgen.gl"
S = requests.Session()
S.headers.update({"User-Agent": UA})


def log(m):
    print(time.strftime("%H:%M:%S ") + m, flush=True)


def strip_tags(h):
    h = re.sub(r"<br\s*/?>", " | ", h)
    h = re.sub(r"<[^>]+>", " ", h)
    for a, b in (("&amp;", "&"), ("&quot;", '"'), ("&#039;", "'"), ("&nbsp;", " ")):
        h = h.replace(a, b)
    return re.sub(r"\s+", " ", h).strip()


def clean_title(t):
    t = t.split(" | ")[0]
    t = re.split(r'"\s*href=', t)[0]
    t = re.sub(r"\b\d{9,13}[Xx]?\b", " ", t)
    t = re.sub(r"\.(pdf|epub|djvu|chm|azw3|mobi)\b", " ", t, flags=re.I)
    return re.sub(r"\s+", " ", t).strip(' .;,-"')


def nz(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def sim(a, b):
    """包含关系不能直接给 1.0："Modern Epidemiology" 是 "Epidemiology Kept Simple:
    ... Modern Epidemiology" 的子串，直接判满分会把不相干的书排到第一。
    按长度比例折算，前缀关系才给高分。"""
    na, nb = nz(a), nz(b)
    if not na or not nb:
        return 0.0
    if na == nb:
        return 1.0
    if len(na) >= 8 and (nb.startswith(na) or na.startswith(nb)):
        return 0.90
    if len(na) >= 8 and (na in nb or nb in na):
        small, big = sorted((len(na), len(nb)))
        return 0.55 + 0.45 * small / big
    return SequenceMatcher(None, na, nb).ratio()


def search(q, tries=2):
    for k in range(tries):
        try:
            r = S.get(f"{HOST}/index.php", params={"req": q, "topics[]": "l", "res": 50},
                      timeout=(8, 30))
            if r.status_code != 200:
                time.sleep(5 + k * 5)
                continue
            out = []
            for row in re.findall(r"<tr[^>]*>(.*?)</tr>", r.text, re.S):
                if "md5=" not in row:
                    continue
                tds = re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)
                md5 = re.search(r"md5=([0-9a-f]{32})", row)
                if len(tds) < 8 or not md5:
                    continue
                out.append({
                    "md5": md5.group(1),
                    "title": clean_title(strip_tags(tds[0])),
                    "author": strip_tags(tds[1])[:80],
                    "year": strip_tags(tds[3])[:10],
                    "pages": strip_tags(tds[5])[:6],
                    "size": strip_tags(tds[6])[:10],
                    "ext": strip_tags(tds[7]).lower()[:6],
                })
            return out
        except Exception:
            time.sleep(4 + k * 6)
    return []


def download(md5, budget=600):
    try:
        r = S.get(f"{HOST}/ads.php", params={"md5": md5}, timeout=(8, 30))
        if r.status_code != 200:
            return None
        m = re.search(r"get\.php\?md5=[0-9a-f]{32}&key=[A-Z0-9]+", r.text)
        if not m:
            return None
        d = S.get(f"{HOST}/{m.group(0)}", timeout=(10, budget),
                  headers={"Referer": f"{HOST}/ads.php?md5={md5}"}, stream=True)
        buf = b"".join(d.iter_content(1 << 16))
        return buf if buf[:5] == b"%PDF-" else None
    except Exception as e:
        log(f"   dl {type(e).__name__}")
        return None


def content_ok(raw, title):
    if not pymupdf:
        return "no-check", 0.0
    try:
        d = pymupdf.open(stream=raw, filetype="pdf")
        text = "".join(d[i].get_text() for i in range(min(20, d.page_count)))
    except Exception:
        return "", 0.0
    if not text.strip():
        return "scanned", 0.0            # 扫描件无文本层，只能靠元数据 + 来源
    tw = re.findall(r"[a-z0-9]+", title.lower())
    pw = re.findall(r"[a-z0-9]+", text.lower())
    if not tw or not pw:
        return "", 0.0
    L = SequenceMatcher(None, tw, pw, autojunk=False).find_longest_match(0, len(tw), 0, len(pw)).size
    if L >= max(4, int(len(tw) * 0.45)):
        return "word", L / len(tw)
    tn, pn = nz(title), nz(text)[:8000]
    C = SequenceMatcher(None, tn, pn, autojunk=False).find_longest_match(0, len(tn), 0, len(pn)).size
    if C >= int(len(tn) * 0.62):
        return "char", C / len(tn)
    return "", 0.0


def clean_name(s, n=80):
    s = re.sub(r'[\\/:*?"<>|\r\n\t]', " ", s or "")
    return re.sub(r"\s+", " ", s).strip()[:n]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--refs", default="refs_final.json")
    ap.add_argument("--out", default="../下载")
    ap.add_argument("--state", default="state_books.json")
    ap.add_argument("--also", default="state.json", help="这些 id 已下过就跳过")
    ap.add_argument("--ids", default="")
    ap.add_argument("--delay", type=float, default=3.0)
    a = ap.parse_args()

    refs = json.load(open(a.refs, encoding="utf-8"))
    sp = Path(a.state)
    state = json.loads(sp.read_text(encoding="utf-8")) if sp.exists() else {}
    done = {}
    if Path(a.also).exists():
        done = json.loads(Path(a.also).read_text(encoding="utf-8"))
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    want = {int(x) for x in a.ids.split(",") if x.strip()} if a.ids else None

    todo = [r for r in refs
            if not state.get(str(r["id"]), {}).get("ok")
            and not done.get(str(r["id"]), {}).get("ok")
            and (want is None or r["id"] in want)]
    log(f"=== 书轮队列 {len(todo)} ===")

    for r in todo:
        i, title, year = r["id"], r["title"], r.get("year")
        author = r.get("first_author", "")
        rec = {"id": i, "title": title, "year": year, "ok": False}

        base = re.sub(r"[:—–].*$", "", title).strip() or title
        queries = [f"{base} {author}".strip()]
        if base != title:
            queries.append(title)
        if r.get("kind") == "chapter" and r.get("venue"):
            queries.append(re.sub(r"[:—–].*$", "", r["venue"]).strip())
        queries.append(base)

        cands, seen = [], set()
        for q in queries[:3]:
            for c in search(q):
                if c["md5"] in seen or c["ext"] not in ("pdf", "epub", "djvu", "azw3", "chm"):
                    continue
                seen.add(c["md5"])
                cands.append(c)
            if len(cands) >= 20:
                break
            time.sleep(1.5 + random.random())

        best, bs = None, 0
        for c in cands:
            sc = sim(title, c["title"])
            if c["ext"] == "pdf":
                sc += 0.03
            if year and re.search(r"\d{4}", c["year"] or "") and \
                    abs(int(re.search(r"\d{4}", c["year"]).group(0)) - int(year)) <= 3:
                sc += 0.05
            if author and author.split()[0].lower() in (c["author"] or "").lower():
                sc += 0.04
            if sc > bs:
                best, bs = c, sc

        if not best or bs < 0.60:
            rec["why"] = "no-hit"
            rec["cands"] = [c["title"][:60] for c in cands[:3]]
            log(f"--  {i:3d} no-hit({bs:.2f}) {title[:50]}")
        else:
            raw = download(best["md5"])
            if not raw:
                rec.update({"why": "dl-fail", "md5": best["md5"]})
                log(f"--  {i:3d} dl-fail  {title[:50]}")
            else:
                how, sc = content_ok(raw, title)
                d = pymupdf.open(stream=raw, filetype="pdf") if pymupdf else None
                pages = d.page_count if d else 0
                # 页数 sanity：书库里混着期刊文章（同名评论、同主题论文），
                # 一本专著不可能 38 页。短文件必须词级强匹配才收。
                short = r.get("kind") == "book" and pages < 60 and not (how == "word" and sc >= 0.75)
                if short:
                    rec["why"] = f"short-pdf({pages}p)"
                    log(f"--  {i:3d} short-pdf({pages}p) {title[:45]}")
                elif not how and bs < 0.85:
                    rec["why"] = f"content-miss({sc:.2f})"
                    log(f"--  {i:3d} content-miss({sc:.2f}) {title[:45]}")
                else:
                    f = out / f"{i:03d}-{clean_name(title)}.pdf"
                    f.write_bytes(raw)
                    rec.update({"ok": True, "file": f.name, "pages": pages, "size": len(raw),
                                "src": "libgen", "md5": best["md5"], "match": how or "meta",
                                "libgen_title": best["title"][:120], "sim": round(bs, 2)})
                    log(f"OK  {i:3d} {pages:4d}p [{how or 'meta'}] {title[:45]}")
        state[str(i)] = rec
        sp.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")
        time.sleep(a.delay + random.random() * 2)

    log(f"=== 书轮累计 {sum(1 for v in state.values() if v.get('ok'))}/{len(state)} ===")


if __name__ == "__main__":
    sys.exit(main())
