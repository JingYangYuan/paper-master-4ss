# -*- coding: utf-8 -*-
"""中文清单 → 知网任务单（batch.json + books.json）。

用法:
    python cnki_prepare.py --csv 文献表.csv --out 工作目录
    python cnki_prepare.py --csv 文献表.csv --out 工作目录 --map title=篇名,author=第一作者

产物:
    工作目录/batch.json  [{"seq","author","year","title","journal","issue","doi","type","grade","topic"}]
    工作目录/books.json  同上，但只装专著/图书（知网不收，留给读秀/超星/纸本）

列名自动识别中英文常见写法，识别不到用 --map 指定，形如 `字段=列名,字段=列名`。
字段: seq author title journal yearissue doi type grade topic
"""
import argparse
import csv
import json
import os
import re
import sys

CANDIDATES = {
    "seq": ["序号", "编号", "id", "no", "No", "index"],
    "author": ["作者", "著者", "authors", "author"],
    "title": ["题名", "标题", "篇名", "论文题名", "title"],
    "journal": ["期刊/出版社", "期刊", "刊名", "来源", "出版社", "journal", "venue"],
    "yearissue": ["年卷期", "年、卷、期", "年份", "年", "year", "issue"],
    "doi": ["DOI", "doi"],
    "type": ["文献类型", "类型", "type"],
    "grade": ["核验等级", "等级", "grade"],
    "topic": ["主题组", "分组", "主题", "章节", "章", "topic"],
}
BOOK_HINTS = ("专著", "图书", "著作", "book", "Book", "monograph")


def pick(header, key):
    for name in CANDIDATES[key]:
        if name in header:
            return name
    for name in CANDIDATES[key]:  # 退一步做宽松匹配
        for h in header:
            if name.lower() in h.lower():
                return h
    return None


def year_of(s):
    m = re.search(r"(19|20)\d{2}", s or "")
    return m.group(0) if m else ""


def clean_author(a):
    a = re.sub(r"\s+", "", a or "")
    return re.sub(r"[*※†‡＃#]", "", a).strip()


def clean_title(t):
    t = (t or "").replace("\ufeff", "")
    return re.sub(r"\s+", "", t)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="中文文献表（UTF-8，带表头）")
    ap.add_argument("--out", required=True, help="输出目录")
    ap.add_argument("--map", default="", help="字段=列名，逗号分隔，覆盖自动识别")
    ap.add_argument("--skip-books", action="store_true", help="不生成 books.json")
    a = ap.parse_args()

    with open(a.csv, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        sys.exit("CSV 为空或表头读不到")

    header = list(rows[0].keys())
    col = {k: pick(header, k) for k in CANDIDATES}
    for pair in filter(None, (x.strip() for x in a.map.split(","))):
        k, _, v = pair.partition("=")
        if k.strip() not in CANDIDATES:
            sys.exit(f"未知字段 {k}，可用：{' '.join(CANDIDATES)}")
        col[k.strip()] = v.strip()
    missing = [k for k in ("title",) if not col[k]]
    if missing:
        sys.exit(f"识别不到必需列 {missing}；表头是 {header}。用 --map title=列名 指定。")

    items, books = [], []
    for i, r in enumerate(rows, 1):
        seq_raw = (r.get(col["seq"]) or "").strip() if col["seq"] else str(i)
        try:
            seq = int(re.sub(r"\D", "", seq_raw) or i)
        except ValueError:
            seq = i
        typ = (r.get(col["type"]) or "期刊论文").strip() if col["type"] else "期刊论文"
        item = {
            "seq": seq,
            "author": clean_author(r.get(col["author"])) if col["author"] else "",
            "year": year_of(r.get(col["yearissue"])) if col["yearissue"] else "",
            "title": clean_title(r.get(col["title"])),
            "journal": (r.get(col["journal"]) or "").strip() if col["journal"] else "",
            "issue": (r.get(col["yearissue"]) or "").strip() if col["yearissue"] else "",
            "doi": (r.get(col["doi"]) or "").strip() if col["doi"] else "",
            "type": typ,
            "grade": (r.get(col["grade"]) or "").strip() if col["grade"] else "",
            "topic": (r.get(col["topic"]) or "").strip() if col["topic"] else "",
        }
        if not item["title"]:
            continue
        (books if any(h in typ for h in BOOK_HINTS) else items).append(item)

    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "batch.json"), "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=1)
    if not a.skip_books:
        with open(os.path.join(a.out, "books.json"), "w", encoding="utf-8") as f:
            json.dump(books, f, ensure_ascii=False, indent=1)

    print(f"期刊/论文 {len(items)} 条 → {os.path.join(a.out, 'batch.json')}")
    if books:
        dest = "（已按 --skip-books 跳过写入）" if a.skip_books else os.path.join(a.out, "books.json")
        print(f"专著 {len(books)} 条 → {dest}（知网不收，走读秀/超星/纸本）")
        for b in books:
            print(f"  #{b['seq']} {b['author']} 《{b['title']}》 {b['journal']} {b['year']}")
    for it in items:
        if len(it["title"]) > 60:
            print(f"  注意 #{it['seq']} 题名偏长（{len(it['title'])} 字），专业检索可能需要截断", file=sys.stderr)


if __name__ == "__main__":
    main()
