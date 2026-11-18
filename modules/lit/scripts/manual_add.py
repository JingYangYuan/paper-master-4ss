# -*- coding: utf-8 -*-
"""手工补录：从任意 URL 或本地文件补进下载目录，同样过四件套。

用在三个地方：
  ① web_search 找到的机构库/作者主页 PDF
  ② 需要 curl 才能下来的站（requests 卡住、TLS 慢）——先 curl 到本地再喂进来
  ③ 扫描件（无文本层）：页数 ≥ 20 且文本为 0 时判 scanned，靠来源可信度接受

用法:
    python manual_add.py pairs.json            # [{"id":3,"url":"https://..."} , ...]
    python manual_add.py pairs.json --state state.json --out ../下载
"""
import argparse
import json
import re
import subprocess
import tempfile
from difflib import SequenceMatcher
from pathlib import Path

import pymupdf

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
REVIEW = re.compile(r"(book reviews?|reviews? of books|reviewed by|short book review)", re.I)


def nz(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def match(text, title, doi=None):
    if doi and doi.lower() in (text or "").lower():
        return "doi", 1.0
    tw = re.findall(r"[a-z0-9]+", (title or "").lower())
    pw = re.findall(r"[a-z0-9]+", (text or "").lower())
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


def get(url, budget=600):
    """本地文件直接读；URL 一律交给 curl —— 慢速国际链路下 requests 会卡住不返回。"""
    if Path(url).exists():
        return Path(url).read_bytes()
    tmp = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False).name
    rc = subprocess.run(["curl", "-sL", "-m", str(budget), "-A", UA, "-o", tmp, url]).returncode
    return Path(tmp).read_bytes() if rc == 0 and Path(tmp).stat().st_size else b""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pairs")
    ap.add_argument("--refs", default="refs_final.json")
    ap.add_argument("--state", default="state.json")
    ap.add_argument("--out", default="../下载")
    a = ap.parse_args()

    pairs = json.load(open(a.pairs, encoding="utf-8"))
    refs = {r["id"]: r for r in json.load(open(a.refs, encoding="utf-8"))}
    st = json.loads(Path(a.state).read_text(encoding="utf-8")) if Path(a.state).exists() else {}
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)

    for p in pairs:
        i, url = int(p["id"]), p["url"]
        r = refs[i]
        raw = get(url)
        if raw[:5] != b"%PDF-":
            print(f"NO  {i} {len(raw)}B {url[:70]}")
            continue
        d = pymupdf.open(stream=raw, filetype="pdf")
        text = "".join(d[k].get_text() for k in range(min(12, d.page_count)))
        how, sc = match(text, r["title"], r.get("doi"))
        if not how:
            text = "".join(d[k].get_text() for k in range(min(40, d.page_count)))
            how, sc = match(text, r["title"], r.get("doi"))
        if how and r.get("kind") != "article" and REVIEW.search(re.sub(r"\s+", " ", text[:3000])):
            print(f"REV {i} 这是书评，不是原书：{r['title'][:45]}")
            continue
        if not how:
            if d.page_count >= 20 and len(text.strip()) < 50:      # 扫描件
                how, sc = "scanned", 0.0
            else:
                print(f"MIS {i} {d.page_count}p {len(raw)}B content-miss {r['title'][:45]}")
                continue
        f = out / f"{i:03d}-{clean_name(r['title'])}.pdf"
        f.write_bytes(raw)
        st[str(i)] = {"id": i, "title": r["title"], "year": r.get("year"), "doi": r.get("doi"),
                      "kind": r.get("kind"), "ok": True, "file": f.name, "pages": d.page_count,
                      "size": len(raw), "src": p.get("src", "manual"), "url": url,
                      "match": how, "score": round(sc, 3)}
        Path(a.state).write_text(json.dumps(st, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"OK  {i} {d.page_count}p [{how}] {r['title'][:50]}")


if __name__ == "__main__":
    main()
