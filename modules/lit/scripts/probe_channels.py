# -*- coding: utf-8 -*-
"""lit-down 渠道探活。开工前先跑这个，别用上个月的结论。

用法:
    python probe_channels.py            # 全部
    python probe_channels.py --quick    # 只探关键渠道
"""
import argparse
import concurrent.futures as cf
import os
import sys
import requests

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
# Unpaywall 会拒绝 example.com 这类保留域名（422），必须用真邮箱；可用 $env:LITDOWN_EMAIL 覆盖
MAIL = os.environ.get("LITDOWN_EMAIL", "litdown.tool@gmail.com")

# 探活样本：尽量挑确定存在的对象
SAMPLE_DOI = "10.1093/qje/qjx032"
SAMPLE_DOI_JEP = "10.1257/jep.31.2.87"
SAMPLE_PMCID = "PMC13713197"
SAMPLE_ARXIV = "1901.05331"

CHECKS = [
    # (组, 名称, URL, 期望)
    ("元数据", "crossref", f"https://api.crossref.org/works/{SAMPLE_DOI}", "json"),
    ("元数据", "openalex", f"https://api.openalex.org/works/doi:{SAMPLE_DOI}", "json"),
    ("元数据", "unpaywall", f"https://api.unpaywall.org/v2/{SAMPLE_DOI}?email={MAIL}", "json"),
    ("元数据", "semanticscholar", f"https://api.semanticscholar.org/graph/v1/paper/DOI:{SAMPLE_DOI}?fields=title", "json"),
    ("元数据", "datacite", "https://api.datacite.org/dois?page%5Bsize%5D=1", "json"),
    ("OA", "europepmc-search", "https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:%2210.1093/qje/qjx032%22&format=json", "json"),
    ("OA", "europepmc-fulltext", f"https://www.ebi.ac.uk/europepmc/webservices/rest/{SAMPLE_PMCID}/fullTextXML", "text"),
    ("OA", "europepmc-pdf", f"https://europepmc.org/articles/{SAMPLE_PMCID}?pdf=render", "pdf"),
    ("OA", "arxiv-pdf", f"https://arxiv.org/pdf/{SAMPLE_ARXIV}", "pdf"),
    ("OA", "nber-pdf", "https://www.nber.org/system/files/working_papers/w24963/w24963.pdf", "pdf"),
    ("OA", "openalex-content", "https://content.openalex.org/works/W2163605009.pdf", "pdf"),
    ("出版社", "springer", "https://link.springer.com/content/pdf/10.1007/s00181-019-01722-4.pdf", "pdf"),
    ("出版社", "sciencedirect", "https://www.sciencedirect.com/", "html"),
    ("出版社", "wiley", "https://onlinelibrary.wiley.com/doi/pdfdirect/10.1111/j.1467-6419.2007.00522.x", "pdf"),
    ("出版社", "aeaweb", f"https://www.aeaweb.org/articles/pdf/doi/{SAMPLE_DOI_JEP}", "pdf"),
    ("镜像", "sci-hub.ren", f"https://sci-hub.ren/{SAMPLE_DOI}", "html"),
    ("镜像", "sci-hub.ee", f"https://sci-hub.ee/{SAMPLE_DOI}", "html"),
    ("镜像", "sci-hub.usualwant", f"https://sci-hub.usualwant.com/{SAMPLE_DOI}", "html"),
    ("镜像", "sci-hub.se", f"https://sci-hub.se/{SAMPLE_DOI}", "html"),
    ("镜像", "bban-cdn", "https://sci.bban.top/pdf/10.1093/qje%252Fqjx032.pdf", "pdf"),
    ("书", "libgen.gl", "https://libgen.gl/index.php?req=econometrics", "html"),
    ("书", "libgen.li", "https://libgen.li/index.php?req=econometrics", "html"),
    ("书", "annas-archive.gs", "https://annas-archive.gs/", "html"),
    ("书", "z-lib.gd", "https://z-lib.gd/", "html"),
    ("书", "gutenberg", "https://www.gutenberg.org/ebooks/9662", "html"),
    ("搜索", "scholar.google", "https://scholar.google.com/scholar?q=machine+learning", "html"),
    ("搜索", "scholar.archive", "https://scholar.archive.org/search?q=machine+learning", "html"),
    ("搜索", "bing", "https://www.bing.com/search?q=machine+learning", "html"),
    ("搜索", "duckduckgo", "https://html.duckduckgo.com/html/?q=machine+learning", "html"),
]

QUICK = {"crossref", "openalex", "unpaywall", "sci-hub.ren", "bban-cdn", "libgen.gl", "arxiv-pdf"}


def probe(item):
    group, name, url, expect = item
    s = requests.Session()
    s.headers.update({"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})
    try:
        r = s.get(url, timeout=(6, 20), allow_redirects=True)
        body = r.content
        if expect == "pdf":
            ok = body[:5] == b"%PDF-"
            verdict = "PDF" if ok else ("假PDF" if r.status_code == 200 else "no")
        elif expect == "json":
            ok = r.status_code == 200 and body[:1] in (b"{", b"[")
            verdict = "ok" if ok else "no"
        else:
            ok = r.status_code == 200 and len(body) > 500
            verdict = "ok" if ok else "no"
        return group, name, r.status_code, len(body), verdict
    except Exception as e:
        return group, name, "ERR", 0, type(e).__name__[:18]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true")
    a = ap.parse_args()
    items = [c for c in CHECKS if (not a.quick or c[1] in QUICK)]

    print(f"探活 {len(items)} 个渠道…\n")
    rows = []
    with cf.ThreadPoolExecutor(max_workers=8) as ex:
        for row in ex.map(probe, items):
            rows.append(row)

    last = None
    for group, name, code, size, verdict in rows:
        if group != last:
            print(f"\n[{group}]")
            last = group
        flag = "✓" if verdict in ("ok", "PDF") else "✗"
        print(f"  {flag} {name:<22s} {str(code):>4s} {size:>9d}  {verdict}")

    good = [r for r in rows if r[4] in ("ok", "PDF")]
    pdf = [r for r in rows if r[4] == "PDF"]
    sizes = [r[3] for r in rows if r[3] > 0]
    repeated = sorted({s for s in sizes if sizes.count(s) > 1})
    print(f"\n可用 {len(good)}/{len(rows)}，其中直给 PDF 的 {len(pdf)} 个："
          + "、".join(r[1] for r in pdf))
    if repeated:
        print(f"⚠ 多个站点返回完全相同的字节数 {repeated}：大概率是本地代理/劫持页或统一错误页，"
              f"不是真内容，必须验证正文再采信。")
    print("\n注意：`no` 也可能是样本本身不存在；SSLError / ReadTimeout 多为链路报错，"
          "**再跑一遍**再判定为死。判 PDF 渠道只看魔数，不看 Content-Type。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
