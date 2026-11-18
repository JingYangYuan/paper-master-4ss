# -*- coding: utf-8 -*-
"""从 state + 队列生成下载清单（csv + md）与渠道统计。

论文轮和书轮各写各的 state（论文轮 state.json、书轮 state_books.json），
报告必须能合并读——只读一个会把另一轮的成果整段漏掉。

用法:
    python make_report.py --queue refs_final.json --state state.json --state state_books.json --out 清单
    python make_report.py ... --dir ../下载 --notes notes.json

notes.json: {"86": "与 #2 同一篇", "62": "扫描件，无文本层"}
"""
import argparse
import csv
import json
from pathlib import Path

SRC_CN = {
    "scihub": "Sci-Hub",
    "unpaywall": "Unpaywall",
    "openalex": "OpenAlex",
    "semanticscholar": "Semantic Scholar",
    "europepmc": "Europe PMC",
    "arxiv": "arXiv",
    "arxiv-title": "arXiv（标题检索）",
    "arxiv-title+meta": "arXiv（落地页）",
    "nber": "NBER",
    "nature": "Nature",
    "springer": "Springer",
    "libgen": "Library Genesis",
    "websearch": "web_search 补位",
    "nber-book": "NBER 书籍章节",
    "manual": "人工补录",
}
WHY_CN = {
    "not-in-stash": "镜像未收录",
    "oa-miss": "无开放获取，且镜像未收录",
    "HTTP 403": "出版商拦截（403）",
    "HTTP 404": "地址失效",
    "not-pdf": "拿到落地页而非 PDF",
    "bad-pdf": "文件损坏或只有封面",
    "no-doi": "无法定位 DOI",
    "scihub-fail": "镜像全部失败",
    "title-miss": "标题检索无匹配",
    "wrong-content": "抓到的 PDF 不是这一篇",
    "book-review": "抓到的是书评，不是原书",
    "scanned": "扫描件（无文本层）",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queue", required=True)
    ap.add_argument("--state", action="append", required=True, help="可给多次，合并读")
    ap.add_argument("--out", default="清单")
    ap.add_argument("--dir", default="", help="PDF 目录，用来确认文件真的在")
    ap.add_argument("--notes", default="", help='{"id": "人工备注"}')
    a = ap.parse_args()

    q = json.loads(Path(a.queue).read_text(encoding="utf-8"))
    if isinstance(q, list) and q and isinstance(q[0], str):
        q = [{"id": i, "title": s, "doi": s if s.lower().startswith("10.") else ""}
             for i, s in enumerate(q, 1)]
    # 合并多个 state：**成功记录优先**。书轮会为论文条目也写一条 failed，
    # 直接 update() 会让后者覆盖前者的成功记录，报告里的成功率就对不上文件数。
    st = {}
    for sp in a.state:
        if not Path(sp).exists():
            continue
        for k, v in json.loads(Path(sp).read_text(encoding="utf-8")).items():
            if k not in st or v.get("ok") or not st[k].get("ok"):
                st[k] = v
    notes = json.loads(Path(a.notes).read_text(encoding="utf-8")) if a.notes and Path(a.notes).exists() else {}

    rows, miss = [], []
    for item in q:
        i = str(item.get("id"))
        s = st.get(i, {})
        if s.get("file"):
            f = Path(a.dir) / s["file"] if a.dir else Path(s["file"])
            ok = bool(s.get("ok") and f.exists())
        else:
            f, ok = None, False
        rows.append({
            "序号": item.get("id"),
            "章": item.get("chapter", ""),
            "年份": s.get("year") or item.get("year", ""),
            "标题": (s.get("title") or item.get("title") or "")[:120],
            "状态": "已下载" if ok else "未获取",
            "来源": SRC_CN.get(s.get("src", ""), s.get("src", "")),
            "页数": s.get("pages", ""),
            "大小MB": round((s.get("size") or 0) / 1048576, 2) if ok else "",
            "文件名": f.name if ok else "",
            "DOI": s.get("doi") or item.get("doi", ""),
            "未获原因": "" if ok else WHY_CN.get(s.get("why", ""), s.get("why", "未尝试")),
            "备注": notes.get(i, ""),
        })
        if not ok:
            miss.append(rows[-1])

    base = Path(a.out)
    with open(str(base) + ".csv", "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()) if rows else [])
        w.writeheader()
        w.writerows(rows)

    by = {}
    for r in rows:
        if r["状态"] == "已下载":
            by[r["来源"]] = by.get(r["来源"], 0) + 1
    total = len(rows)
    got = total - len(miss)

    md = [f"# 文献下载清单", "",
          f"- 条目总数：**{total}**",
          f"- 已下载 PDF：**{got}**（{got / total:.1%}）" if total else "- 0",
          f"- 未获取：**{len(miss)}**",
          "- 渠道构成：" + "、".join(f"{k} {v}" for k, v in sorted(by.items(), key=lambda x: -x[1])),
          "", "## 已下载", "",
          "| 序号 | 年份 | 标题 | 来源 | 页数 | 文件 |", "|---|---|---|---|---|---|"]
    for r in rows:
        if r["状态"] == "已下载":
            md.append(f"| {r['序号']} | {r['年份']} | {r['标题'][:80]} | {r['来源']} | {r['页数']} | {r['文件名'][:60]} |")
    md += ["", "## 未获取", "", "| 序号 | 年份 | 标题 | 原因 |", "|---|---|---|---|"]
    for r in miss:
        md.append(f"| {r['序号']} | {r['年份']} | {r['标题'][:80]} | {r['未获原因']} |")
    Path(str(base) + ".md").write_text("\n".join(md) + "\n", encoding="utf-8")

    print(f"总 {total}  已下载 {got}  未获取 {len(miss)}")
    print("渠道:", by)
    print(f"→ {base}.csv / {base}.md")


if __name__ == "__main__":
    main()
