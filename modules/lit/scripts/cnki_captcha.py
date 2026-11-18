# -*- coding: utf-8 -*-
"""腾讯点选验证码求解：橙色文字连通域 + 多字体模板匹配 + 全排列最优分配。

用法:
    python cnki_captcha.py 裁剪截图.png "舱把撤"
    python cnki_captcha.py cap.png "舱把撤" --save-crops 调试目录

输入：验证码区域的截图（务必按 CSS 像素裁剪、1:1，别用整页缩放后手工量坐标）
输出：{"chars": [...], "points": [[x,y],...], "conf": 置信度, ...}，坐标相对裁图左上角

字体：自动在系统里找能渲染汉字的字体；设环境变量 LITDOWN_CJK_FONTS 则只用它给的路径
（多个用 os.pathsep 分隔，可以是文件或目录），适合把字体随项目一起分发。
"""
import argparse
import itertools
import json
import os
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

S = 40           # 归一化边长
PROBE = "舱"      # 用来判断字体有没有汉字字形

PRIORITY = ("kai", "li", "song", "sun", "hei", "ming", "zhong", "xing", "fz", "st", "msy", "noto", "source")


def font_dirs():
    env = os.environ.get("LITDOWN_CJK_FONTS", "").strip()
    if env:                       # 设了就完全接管，不再扫系统目录
        return [p for p in env.split(os.pathsep) if p and os.path.exists(p)]
    dirs = []
    if sys.platform.startswith("win"):
        win = os.environ.get("WINDIR", r"C:\Windows")
        dirs += [os.path.join(win, "Fonts"), os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "Windows", "Fonts")]
    elif sys.platform == "darwin":
        dirs += ["/System/Library/Fonts", "/Library/Fonts", os.path.expanduser("~/Library/Fonts")]
    else:
        dirs += ["/usr/share/fonts", "/usr/local/share/fonts", "/usr/share/fonts/truetype",
                 os.path.expanduser("~/.fonts"), os.path.expanduser("~/.local/share/fonts")]
    return [d for d in dirs if d and os.path.isdir(d)]


def candidate_files(limit=4000):
    exts = (".ttf", ".ttc", ".otf", ".otc")
    files = []
    for d in font_dirs():
        if os.path.isfile(d):
            files.append(d)
            continue
        for root, _, names in os.walk(d):
            for n in names:
                if n.lower().endswith(exts):
                    files.append(os.path.join(root, n))
                    if len(files) >= limit:
                        return files
    return files


def renders_cjk(path, size=32):
    for idx in range(0, 4):
        try:
            f = ImageFont.truetype(path, size, index=idx) if path.lower().endswith((".ttc", ".otc")) else ImageFont.truetype(path, size)
        except Exception:
            continue
        img = Image.new("L", (size * 2, size * 2), 0)
        ImageDraw.Draw(img).text((4, 4), PROBE, fill=255, font=f)
        if img.getbbox() and np.asarray(img).sum() > 5000:
            return idx
    return None


_fonts = None


def load_fonts(max_fonts=26):
    """返回 [(path, index), ...]，只留真能渲染汉字的。"""
    global _fonts
    if _fonts is not None:
        return _fonts
    files = candidate_files()
    files.sort(key=lambda p: (0 if any(k in os.path.basename(p).lower() for k in PRIORITY) else 1, len(os.path.basename(p))))
    out = []
    for p in files:
        idx = renders_cjk(p)
        if idx is not None:
            out.append((p, idx))
            if len(out) >= max_fonts:
                break
    _fonts = out
    return out


def orange_mask(im):
    a = np.asarray(im.convert("RGB")).astype(np.int16)
    R, G, B = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    return (R > 165) & (G > 110) & (B < 140) & ((R - B) > 60) & ((R - G) > 15)


def blobs(mask, min_area=90):
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    out = []
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        stack = [(y0, x0)]
        seen[y0, x0] = True
        pts = []
        while stack:
            y, x = stack.pop()
            pts.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if len(pts) >= min_area:
            out.append(np.array(pts))
    return out


def merge_blobs(bl, gap=12):
    """艺术字笔画常被拆成多块，按外接框邻近合并。"""
    boxes = [(p[:, 1].min(), p[:, 0].min(), p[:, 1].max(), p[:, 0].max()) for p in bl]
    merged = True
    while merged and len(bl) > 1:
        merged = False
        for i in range(len(bl)):
            for j in range(i + 1, len(bl)):
                a, b = boxes[i], boxes[j]
                if a[0] - gap <= b[2] and b[0] - gap <= a[2] and a[1] - gap <= b[3] and b[1] - gap <= a[3]:
                    bl[i] = np.vstack([bl[i], bl[j]])
                    boxes[i] = (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))
                    del bl[j], boxes[j]
                    merged = True
                    break
            if merged:
                break
    return bl, boxes


def norm_crop(mask, box, pad=3):
    x0, y0, x1, y1 = box
    sub = mask[max(0, y0 - pad):y1 + pad + 1, max(0, x0 - pad):x1 + pad + 1]
    im = Image.fromarray((sub * 255).astype(np.uint8))
    im.thumbnail((S, S), Image.BILINEAR)
    canvas = Image.new("L", (S, S), 0)
    canvas.paste(im, ((S - im.width) // 2, (S - im.height) // 2))
    return np.asarray(canvas).astype(np.float32) / 255.0


def render(ch, path, index, size=64):
    f = ImageFont.truetype(path, size, index=index) if index else ImageFont.truetype(path, size)
    canvas = Image.new("L", (size + 24, size + 24), 0)
    ImageDraw.Draw(canvas).text((12, 12), ch, fill=255, font=f)
    bb = canvas.getbbox()
    if bb:
        canvas = canvas.crop(bb)
    canvas.thumbnail((S, S), Image.BILINEAR)
    sq = Image.new("L", (S, S), 0)
    sq.paste(canvas, ((S - canvas.width) // 2, (S - canvas.height) // 2))
    return np.asarray(sq).astype(np.float32) / 255.0


def score(a, b):
    am, bm = a > 0.4, b > 0.4
    inter = np.logical_and(am, bm).sum()
    union = np.logical_or(am, bm).sum() or 1
    av, bv = a.ravel() - a.mean(), b.ravel() - b.mean()
    den = (np.linalg.norm(av) * np.linalg.norm(bv)) or 1
    return 0.6 * (inter / union) + 0.4 * max(0.0, float(np.dot(av, bv) / den))


def solve(png, chars, save_crops=None):
    fonts = load_fonts()
    if not fonts:
        return {"error": "系统里找不到可渲染汉字的字体，设 LITDOWN_CJK_FONTS 指一个 .ttf/.ttc"}
    im = Image.open(png)
    mask = orange_mask(im)
    bl, boxes = merge_blobs(blobs(mask))
    n = len(chars)
    if len(bl) < n:
        return {"error": f"blobs={len(bl)} < chars={n}", "blobs": [[int(b[:, 1].mean()), int(b[:, 0].mean())] for b in bl]}
    order = sorted(range(len(bl)), key=lambda i: -len(bl[i]))[:n]
    bl = [bl[i] for i in order]
    boxes = [boxes[i] for i in order]
    targets = [norm_crop(mask, b) for b in boxes]

    if save_crops:
        os.makedirs(save_crops, exist_ok=True)
        for k, b in enumerate(boxes):
            Image.fromarray((mask[b[1]:b[3] + 1, b[0]:b[2] + 1] * 255).astype(np.uint8)).save(
                os.path.join(save_crops, f"blob{k}.png"))

    best = {}
    for ch in chars:
        for path, idx in fonts:
            try:
                t = render(ch, path, idx)
            except Exception:
                continue
            for i, m in enumerate(targets):
                sc = score(t, m)
                if sc > best.get((ch, i), -1):
                    best[(ch, i)] = sc

    scored = []
    for perm in itertools.permutations(range(len(bl)), n):
        scored.append((sum(best.get((chars[k], perm[k]), 0) for k in range(n)), perm))
    scored.sort(key=lambda x: -x[0])
    top = scored[0][1]
    pts = [[int(round(bl[top[k]][:, 1].mean())), int(round(bl[top[k]][:, 0].mean()))] for k in range(n)]
    conf = round(scored[0][0] - scored[1][0], 3) if len(scored) > 1 else round(scored[0][0], 3)
    return {
        "chars": chars,
        "points": pts,
        "detail": [[chars[k], pts[k], round(best.get((chars[k], top[k]), 0), 3)] for k in range(n)],
        "conf": conf,
        "nfonts": len(fonts),
        "nblobs": len(bl),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", nargs="?", help="验证码区域截图")
    ap.add_argument("chars", nargs="?", help="提示里要依次点击的字，如 舱把撤")
    ap.add_argument("--save-crops", default=None, help="把切出的字块存到这个目录，便于核对")
    ap.add_argument("--list-fonts", action="store_true", help="只打印找到的字体就退出")
    a = ap.parse_args()

    if a.list_fonts:
        fonts = load_fonts()
        print(f"# {len(fonts)} 个可用汉字字体（LITDOWN_CJK_FONTS 可覆盖）")
        for p, idx in fonts:
            print(f"{p}#{idx}")
        return
    if not a.image or not a.chars:
        ap.error("需要 image 与 chars（或 --list-fonts）")

    chars = [c for c in a.chars if not c.isspace()]
    res = solve(a.image, chars, a.save_crops)
    print(json.dumps(res, ensure_ascii=False))
    if res.get("conf", 0) < 0.05:
        print("警告：最优与次优排列差距很小，识别可能不可靠", file=sys.stderr)


if __name__ == "__main__":
    main()
