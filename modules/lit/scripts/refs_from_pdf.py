# -*- coding: utf-8 -*-
"""从论文 PDF 里切出参考文献条目（按悬挂缩进，不靠正则猜）。

NIHMS / PMC 作者稿、多数期刊排版都带悬挂缩进：条目首行 x0 小，续行 x0 大。
常见排版里首行左边界比续行小几个点（AH/XSL Formatter 出的稿子尤其明显）。
这比"按行首作者姓氏切"稳得多——后者遇到 "U.S. Bureau of Labor Statistics."、
"D'Unger AV, Land Kenneth C. ..." 这类条目就崩。

用法:
    python refs_from_pdf.py a.pdf b.pdf --out refs_raw.json
    python refs_from_pdf.py a.pdf --pages 21-25 --indent 155

输出: [{"source":"a.pdf","raw":"..."}, ...]
之后交给 enrich_crossref.py 定位 DOI。
"""
import argparse
import json
import re
import sys

import pymupdf

# 页脚/页眉：NIHMS 每页都刷这几行，不剔掉会污染条目
FOOTER = re.compile(
    r"^((?:[A-Z][\w'’-]+ et al\.)|Page \d+|.*Author manuscript.*|NIH-PA Author Manuscript.*|"
    r"References|Biographies|Figure \d+\..*|Diagram \d+\..*|Table \d+\..*)$"
)
STOP = re.compile(r"^(Biographies|Figure \d+\.|Diagram \d+\.|Tables? \d+\.)")


def page_lines(path, pages):
    d = pymupdf.open(path)
    for pi in pages:
        if pi >= d.page_count:
            break
        for b in d[pi].get_text("dict")["blocks"]:
            for ln in b.get("lines", []):
                txt = "".join(s["text"] for s in ln["spans"]).strip()
                if txt:
                    yield round(ln["bbox"][0], 1), txt


def extract(path, pages=None, indent=155):
    d = pymupdf.open(path)
    rng = range(d.page_count) if pages is None else range(pages[0], min(pages[1], d.page_count))
    out, cur, started = [], [], False
    for x0, txt in page_lines(path, rng):
        if re.fullmatch(r"References", txt, re.I):
            started = True
            continue
        if STOP.match(txt):
            break
        if not started or FOOTER.match(txt):
            continue
        if x0 < indent and cur:          # 首行 → 收上一条
            out.append(" ".join(cur))
            cur = []
        cur.append(txt)
    if cur:
        out.append(" ".join(cur))
    return [re.sub(r"\s+", " ", e).strip() for e in out if len(e) > 20]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdfs", nargs="+")
    ap.add_argument("--out", default="refs_raw.json")
    ap.add_argument("--pages", default="", help="1-based，如 21-25；不给则全文找 References")
    ap.add_argument("--indent", type=float, default=155.0,
                    help="首行左边界阈值；打印一页的 x0 分布再定")
    a = ap.parse_args()

    pages = None
    if a.pages:
        lo, hi = a.pages.split("-")
        pages = (int(lo) - 1, int(hi))

    rows = []
    for p in a.pdfs:
        es = extract(p, pages, a.indent)
        print(f"{p}: {len(es)} 条", file=sys.stderr)
        for e in es:
            rows.append({"source": p.rsplit("/", 1)[-1].replace(".pdf", ""), "raw": e})
    json.dump(rows, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"→ {a.out}（{len(rows)} 条）", file=sys.stderr)


if __name__ == "__main__":
    main()
