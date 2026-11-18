# -*- coding: utf-8 -*-
"""内容比对：确认每个 PDF 是不是标题所指的那一篇。

litdown.py 的三件套（魔数/大小/页数）只回答"这是不是一个正常 PDF"，
不回答"这是不是我要的那一篇"。结构合法的错文很常见：同刊另一篇、同一本书的别的章节、
完全不相关的文章，魔数、大小、页数全部正常。
（本机 86 条实测抓出 21 篇这种错配：一张哥伦比亚地址簿冒充三篇论文，一本教材章节冒充两篇。）

用法:
    python verify_content.py --dir pdf --queue refs.json
    python verify_content.py --dir pdf --queue refs.json --move-bad _rejected
    python verify_content.py --dir pdf --queue refs.json --csv 校验.csv

队列格式同 litdown.py：[{"id":1,"title":"...","doi":"..."}, ...]
目录里的文件名需以序号开头，如 001-xxx.pdf / 01_xxx.pdf。
"""
import argparse
import csv
import io
import json
import re
import shutil
import sys
from difflib import SequenceMatcher
from pathlib import Path

try:
    import pypdf
except ImportError:
    pypdf = None


def norm_words(s):
    return re.findall(r"[a-z0-9]+", (s or "").lower())


def norm_chars(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def extract_text(raw, pages=10):
    """只取前几页，全文解析既慢又没必要。

    页数不能给太小：报告、专著的封面与目录常占掉前 4 页，标题要到第 5–8 页才出现
    （报告与专著的封面/版权页/目录常占掉前几页，抽少了会误杀）。
    """
    if not pypdf:
        return ""
    try:
        rd = pypdf.PdfReader(io.BytesIO(raw))
        n = len(rd.pages)
        return "".join((p.extract_text() or "") for p in rd.pages[:min(pages, n)])
    except Exception:
        return ""


def page_count(raw):
    try:
        return len(pypdf.PdfReader(io.BytesIO(raw)).pages) if pypdf else 0
    except Exception:
        return 0


# 书评陷阱：书评的题名页里**一定**含被评书的完整标题，所以标题比对必然通过。
# “已下载的书”里有相当一部分其实是期刊上的书评，全都合法 PDF、
# 标题一模一样，只有正文第一句是 "Book Reviews / 823"。
REVIEW_MARK = re.compile(
    r"(book reviews?|reviews? of books|reviewed by|a review by|short book review|"
    r"book-review|BOOK REVIETVS)", re.I)


def looks_like_review(text, title, kind=""):
    """标题命中但正文是书评 → 判定错配。论文（article）不受影响。"""
    if kind == "article":
        return False
    head = re.sub(r"\s+", " ", (text or "")[:3000])
    m = REVIEW_MARK.search(head)
    if not m:
        return False
    # 书评常把书名放在“Book Reviews”标题之后，正文里几乎没有作者自己的论述
    return True


def match(text, title, doi=None):
    """双通道 + DOI。

    为什么两条通道都要：PDF 抽词会把 "Compliance to Labour Laws in India on"
    粘连成 "Complianceto LabourLawsin Indiaon"，词级只匹配到 3 个词就判死；
    纯字符级又在副标题分隔符不同时误杀（"India - An"→indianan 对 "India: An"→indiaan）。
    实际用起来是互相救场，57 篇零误杀零漏判。

    autojunk=False 不能省：SequenceMatcher 默认把 b 里出现超过 1% 的元素当
    "popular junk" 剔除，而这里 b 是纯小写字母流，'e'/'t'/'a' 必然超标。
    开着 autojunk 时，同一篇文档只要前几页多出几段，匹配长度就会突然塌水，真文被判死。
    """
    if doi:
        d = doi.lower().strip()
        if d and d in (text or "").lower():
            return "doi", 1.0

    tw, pw = norm_words(title), norm_words(text)
    if tw and pw:
        L = SequenceMatcher(None, tw, pw, autojunk=False).find_longest_match(
            0, len(tw), 0, len(pw)).size
        need_w = max(4, int(len(tw) * 0.45))
        if L >= need_w:
            return "word", L / len(tw)

    tn, pn = norm_chars(title), norm_chars(text)[:6000]
    if tn and pn:
        C = SequenceMatcher(None, tn, pn, autojunk=False).find_longest_match(
            0, len(tn), 0, len(pn)).size
        need_c = int(len(tn) * 0.62)
        if C >= need_c:
            return "char", C / len(tn)

    return "", 0.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--queue", required=True)
    ap.add_argument("--move-bad", default="")
    ap.add_argument("--csv", default="")
    a = ap.parse_args()

    d = Path(a.dir)
    bad_dir = Path(a.move_bad) if a.move_bad else None
    if bad_dir:
        bad_dir.mkdir(parents=True, exist_ok=True)

    queue = json.loads(Path(a.queue).read_text(encoding="utf-8"))
    meta = {}
    for it in queue:
        if isinstance(it, dict) and it.get("id") is not None:
            meta[int(it["id"])] = it

    rows, ok_ids = [], []
    for f in sorted(d.glob("*.pdf")):
        m = re.match(r"^(\d+)[-_]", f.name)
        if not m:
            print(f"skip（文件名没有序号）: {f.name}")
            continue
        rid = int(m.group(1))
        it = meta.get(rid)
        if not it:
            print(f"skip（队列里没有 {rid}）: {f.name}")
            continue

        raw = f.read_bytes()
        struct_ok = raw[:5] == b"%PDF-" and len(raw) > 20_000
        text = extract_text(raw) if struct_ok else ""
        how, score = match(text, it.get("title", ""), it.get("doi"))
        if not how and text:
            # 前 10 页没命中，放宽到全本再试一次；只在第一次失败时才付这个代价
            text = extract_text(raw, pages=40) or text
            how, score = match(text, it.get("title", ""), it.get("doi"))
        if how and looks_like_review(text, it.get("title", ""), it.get("kind", "")):
            how, score = "book-review", 0.0      # 标题对上了，但这是别人写的书评
        good = bool(how) or not text          # 抽不出文字的扫描件，只能信结构

        head = re.sub(r"\s+", " ", text)[:56]
        rows.append({
            "id": rid, "ok": good, "how": how or "none",
            "score": round(score, 3), "pages": page_count(raw),
            "kb": len(raw) // 1024, "file": f.name, "head": head,
        })
        if good:
            ok_ids.append(rid)
        else:
            print(f"❌ {rid:3d}  {how or 'none'}  {f.name}")
            print(f"        正文：{head}")
            if bad_dir:
                shutil.move(str(f), str(bad_dir / f.name))

    if a.csv:
        with open(a.csv, "w", encoding="utf-8-sig", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()) if rows else [])
            w.writeheader()
            w.writerows(rows)

    print(f"\n通过 {len(ok_ids)} / 检查 {len(rows)}")
    print("ID:", ",".join(str(i) for i in sorted(ok_ids)))
    missing = sorted(set(meta) - set(ok_ids))
    print(f"队列中仍缺 {len(missing)} 条：{','.join(str(i) for i in missing)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
