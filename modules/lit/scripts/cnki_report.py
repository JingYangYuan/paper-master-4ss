# -*- coding: utf-8 -*-
"""知网下载结果核验 + 清单生成。

三件套（魔数/体积/页数）只回答"这是不是一个正常 PDF"，第四件套（内容比对）才回答
"这是不是我要的那一篇"。中文标题没有词边界，所以字符级通道是主力。

用法:
    python cnki_report.py --queue 工作目录/batch.json --pdf 工作目录/PDF
    python cnki_report.py --queue batch.json --pdf PDF --out 清单.csv --md 清单.md --books books.json
    python cnki_report.py --queue batch.json --pdf PDF --reject 工作目录/_存疑   # 把不匹配的挑走

退出码：期刊条目全部匹配 0，有缺失/存疑 1（专著不计，知网本来就不收）。
"""
import argparse
import csv
import hashlib
import io
import json
import os
import re
import shutil
import sys
from difflib import SequenceMatcher

try:
    import pypdf
    import logging
    logging.getLogger("pypdf").setLevel(logging.ERROR)   # 免掉 MediaBox 重复定义的噪音
except ImportError:  # 没装就退到 fitz
    pypdf = None
    try:
        import fitz
    except ImportError:
        fitz = None


def read_text(raw, pages=10):
    if pypdf is not None:
        rd = pypdf.PdfReader(io.BytesIO(raw))
        n = len(rd.pages)
        txt = ""
        for p in rd.pages[: min(pages, n)]:
            try:
                txt += p.extract_text() or ""
            except Exception:
                pass
        return txt, n
    if fitz is not None:
        doc = fitz.open(stream=raw, filetype="pdf")
        return "".join(doc[i].get_text() for i in range(min(pages, doc.page_count))), doc.page_count
    raise SystemExit("需要 pypdf 或 PyMuPDF")


def cjk_chars(s):
    return re.sub(r"[^\u4e00-\u9fffA-Za-z0-9]", "", s or "")


def match(pdf_text, title, doi=None):
    if doi and doi.lower().strip() and doi.lower().strip() in pdf_text.lower():
        return "doi", 1.0
    tw = re.findall(r"[a-z0-9]+", title.lower())
    pw = re.findall(r"[a-z0-9]+", pdf_text.lower())
    if tw and pw:
        L = SequenceMatcher(None, tw, pw, autojunk=False).find_longest_match(0, len(tw), 0, len(pw)).size
        if L >= max(2, int(len(tw) * 0.45)):
            return "word", L / len(tw)
    T = cjk_chars(title)
    P = cjk_chars(pdf_text)[:8000]
    if T and P:
        C = SequenceMatcher(None, T, P, autojunk=False).find_longest_match(0, len(T), 0, len(P)).size
        if C >= max(6, int(len(T) * 0.55)):
            return "char", C / len(T)
    return "", 0.0


def find_file(pdf_dir, seq):
    """文件名规则：序号开头，如 01-作者年 题名.pdf / 1_x.pdf / 010 x.pdf"""
    if not os.path.isdir(pdf_dir) or seq is None:
        return None
    hits = []
    for f in os.listdir(pdf_dir):
        if not f.lower().endswith((".pdf", ".caj")):
            continue
        m = re.match(r"^(\d+)\D", f)
        if m and int(m.group(1)) == int(seq):
            hits.append(f)
    return sorted(hits)[0] if hits else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queue", required=True, help="batch.json（cnki_prepare.py 产出）")
    ap.add_argument("--pdf", required=True, help="PDF 目录，文件名以序号开头")
    ap.add_argument("--books", default=None, help="books.json，专著条目会被列为未获取")
    ap.add_argument("--out", default=None, help="CSV 路径，默认 <pdf 同级>/下载清单.csv")
    ap.add_argument("--md", default=None, help="Markdown 路径，默认与 CSV 同名 .md")
    ap.add_argument("--reject", default=None, help="把不匹配的文件挪进这个目录")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    base = os.path.dirname(os.path.abspath(a.pdf))
    out_csv = a.out or os.path.join(base, "下载清单.csv")
    out_md = a.md or os.path.splitext(out_csv)[0] + ".md"

    queue = json.load(open(a.queue, encoding="utf-8"))
    books = json.load(open(a.books, encoding="utf-8")) if a.books and os.path.exists(a.books) else []

    rows, seen_hash = [], {}
    tasks = [(it, False) for it in queue] + [(b, True) for b in books]
    for it, is_book in tasks:
        rec = {
            "序号": it.get("seq"),
            "主题组": it.get("topic", ""),
            "作者": it.get("author", ""),
            "题名": it.get("title", ""),
            "文献类型": it.get("type", "专著" if is_book else "期刊论文"),
            "期刊": it.get("journal", ""),
            "年卷期": it.get("issue", ""),
            "核验等级": it.get("grade", ""),
        }
        if is_book:
            rec.update(状态="未获取", 页数="", 大小KB="", 内容比对="", 相似度="", 文件名="",
                       来源渠道="", 备注="专著，知网不收；走读秀/超星/图书馆纸本")
            rows.append(rec)
            continue
        f = find_file(a.pdf, it.get("seq"))
        if not f:
            rec.update(状态="缺失", 页数="", 大小KB="", 内容比对="", 相似度="", 文件名="", 来源渠道="", 备注="")
            rows.append(rec)
            continue
        p = os.path.join(a.pdf, f)
        raw = open(p, "rb").read()
        rec.update(文件名=f, 大小KB=int(len(raw) / 1024), 来源渠道="知网 CNKI", 备注="")
        if not raw.startswith(b"%PDF-"):
            rec.update(状态="非PDF", 页数="", 内容比对="", 相似度="")
            rows.append(rec)
            continue
        rec["sha1"] = hashlib.sha1(raw).hexdigest()[:10]
        seen_hash.setdefault(rec["sha1"], []).append(it.get("seq"))
        txt, pages = read_text(raw)
        rec["页数"] = pages
        via, sc = match(txt, it.get("title", ""), it.get("doi"))
        if not via:                                  # 首次全失败才放宽到 40 页（报告封面/目录很长）
            txt2, _ = read_text(raw, pages=40)
            via, sc = match(txt2 or txt, it.get("title", ""), it.get("doi"))
        rec["内容比对"] = via
        rec["相似度"] = round(sc, 2)
        rec["状态"] = "已下载" if via else "存疑"
        rows.append(rec)

    dup = {h: v for h, v in seen_hash.items() if len(v) > 1}
    for h, seqs in dup.items():
        for r in rows:
            if r.get("sha1") == h:
                r["备注"] = (r["备注"] + "；重复内容，与本表 #" + "/".join(str(x) for x in seqs if x != r["序号"]) + " 相同").strip("；")

    cols = ["序号", "主题组", "作者", "题名", "文献类型", "期刊", "年卷期", "核验等级",
            "状态", "页数", "大小KB", "内容比对", "相似度", "文件名", "来源渠道", "备注"]
    with open(out_csv, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        w.writerows(sorted(rows, key=lambda r: int(r["序号"])))

    ok = [r for r in rows if r["状态"] == "已下载"]
    total_kb = sum(r["大小KB"] for r in ok)
    total_pages = sum(int(r["页数"]) for r in ok if r["页数"])
    md = ["# 下载清单\n",
          f"- 已下载 **{len(ok)} 篇**，{total_pages} 页，{total_kb / 1024:.1f} MB",
          f"- 未获取 {len(rows) - len(ok)} 条\n",
          "| 序号 | 作者 | 题名 | 期刊 | 页 | KB | 内容比对 |", "|---:|---|---|---|---:|---:|---|"]
    for r in sorted(ok, key=lambda r: int(r["序号"])):
        md.append(f"| {r['序号']} | {r['作者']} | {r['题名']} | {r['期刊']} | {r['页数']} | {r['大小KB']} | {r['内容比对']} {r['相似度']} |")
    bad = [r for r in rows if r["状态"] != "已下载"]
    if bad:
        md += ["\n## 未获取 / 存疑\n", "| 序号 | 作者 | 题名 | 状态 | 备注 |", "|---:|---|---|---|---|"]
        for r in bad:
            md.append(f"| {r['序号']} | {r['作者']} | {r['题名']} | {r['状态']} | {r['备注']} |")
    open(out_md, "w", encoding="utf-8").write("\n".join(md) + "\n")

    if a.reject and bad:
        os.makedirs(a.reject, exist_ok=True)
        for r in bad:
            if r.get("文件名"):
                shutil.move(os.path.join(a.pdf, r["文件名"]), os.path.join(a.reject, r["文件名"]))

    if not a.quiet:
        for r in sorted(rows, key=lambda r: int(r["序号"])):
            flag = "" if r["状态"] == "已下载" else f"  <-- {r['状态']}"
            print(f"{r['序号']:>3} {r.get('页数', ''):>3}页 {r.get('大小KB', ''):>5}KB {r.get('内容比对', ''):<4}{r.get('相似度', ''):>4}  {r['题名'][:36]}{flag}")
        if dup:
            print(f"\n警告：{len(dup)} 组文件内容完全重复，见清单备注")
    print(f"\n已下载 {len(ok)}/{len(rows)}，{total_pages} 页，{total_kb / 1024:.1f} MB → {out_csv}")
    broken = [r for r in rows if r["状态"] in ("缺失", "存疑", "非PDF")]   # 专著不计，知网本来就不收
    sys.exit(0 if not broken else 1)


if __name__ == "__main__":
    main()
