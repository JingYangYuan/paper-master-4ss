#!/usr/bin/env python3
from __future__ import annotations
"""MinerU PDF → Markdown 批量转换脚本。

模式:
  - 精准解析 API v4 (Token): ≤200MB/≤200页, 批量≤50个, vlm 模型, 自动解压保存图片并写入 Markdown 相对路径
  - Agent 轻量 API v1 (免登录): ≤10MB/≤20页, 单文件, 自动下载 Markdown 中图片到本地
  - 长 PDF 切块模式: 按 ≤200 页切块 → MinerU 识别 → 自动管理分块图片与命名空间 → 按原页序合并 Markdown

用法:
  python3 pdf2md.py <目录路径>                       # Token 模式 (需 .env.kie)
  python3 pdf2md.py <目录路径> --agent               # 免登录轻量模式
  python3 pdf2md.py <目录路径> --token <jwt_token>   # 手动传入 Token
  python3 pdf2md.py <目录路径> --output <输出目录>
  python3 pdf2md.py <目录路径> --split-long          # 长 PDF 自动切块并合并
  python3 pdf2md.py <目录路径> --no-images           # 禁用图片提取 (仅保存纯文本)
"""

import os
# 强制清除代理环境变量，避免系统代理未运行时 requests 连接失败
for _var in ['HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy']:
    os.environ.pop(_var, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

import warnings
warnings.filterwarnings("ignore")

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import time
import urllib.parse
import zipfile
from pathlib import Path

import requests

V4_BASE = "https://mineru.net/api/v4"
AGENT_BASE = "https://mineru.net/api/v1/agent"
BATCH_SIZE = 40  # 减小批次避免限流 (50 文件/分钟限制)
MAX_V4_PAGES = 200
DEFAULT_CHUNK_PAGES = 180
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".gif", ".bmp", ".tiff", ".ico"}


def _safe_ascii_id(text: str, max_bytes: int = 96) -> str:
    """Return an ASCII identifier that stays below byte-count API limits."""
    digest = hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]
    base = re.sub(r"[^A-Za-z0-9._-]+", "_", text).strip("._-")
    if not base:
        base = "pdf"
    suffix = f"_{digest}"
    while len((base + suffix).encode("utf-8")) > max_bytes and base:
        base = base[:-1]
    return (base or "pdf") + suffix


def _clean_folder_name(name: str) -> str:
    """Sanitize folder name so it's safe for markdown relative paths and directory names."""
    cleaned = re.sub(r'[^\w\u4e00-\u9fff.-]+', '_', name).strip('._')
    return cleaned or "doc"


def _replace_markdown_and_html_images(md_text: str, link_replacer) -> str:
    """Replace image URLs in Markdown (![alt](url)) and HTML (<img src='url'>)."""
    # 1. Markdown images: ![alt](url "title") or ![alt](url) or ![alt](<url>)
    md_img_pattern = re.compile(
        r'(!\[(?P<alt>[^\]]*?)\]\(\s*(?:<(?P<url_bracket>[^>]+)>|(?P<url_raw>[^\s\)]+))(?P<title>\s+["\'][^"\']*?["\'])?\s*\))'
    )

    def _replace_md_img(match):
        full_match = match.group(0)
        alt = match.group('alt')
        url = match.group('url_bracket') or match.group('url_raw')
        title = match.group('title') or ""

        new_url = link_replacer(url)
        if new_url is None or new_url == url:
            return full_match

        return f"![{alt}]({new_url}{title})"

    md_text = md_img_pattern.sub(_replace_md_img, md_text)

    # 2. HTML <img> tags: <img ... src="..." ...>
    html_img_pattern = re.compile(
        r'(<img\b(?P<before>[^>]*?)\bsrc=["\'](?P<src>[^"\']+)["\'](?P<after>[^>]*?)>)',
        re.IGNORECASE,
    )

    def _replace_html_img(match):
        full_match = match.group(0)
        before = match.group('before')
        src = match.group('src')
        after = match.group('after')

        new_src = link_replacer(src)
        if new_src is None or new_src == src:
            return full_match

        return f'<img{before}src="{new_src}"{after}>'

    md_text = html_img_pattern.sub(_replace_html_img, md_text)
    return md_text


def _download_and_save_remote_image(
    url: str,
    target_img_dir: Path,
    rel_prefix: str,
    part_prefix: str = "",
    remote_cache: dict[str, str] | None = None,
) -> str:
    """Download remote image from URL, save to target_img_dir, return relative URL."""
    if remote_cache is not None and url in remote_cache:
        return remote_cache[url]

    try:
        parsed = urllib.parse.urlsplit(url)
        url_path = parsed.path
        raw_name = Path(url_path).name
        ext = Path(raw_name).suffix.lower()
        if not ext or ext not in IMAGE_EXTS:
            ext = ".png"

        url_hash = hashlib.sha1(url.encode("utf-8")).hexdigest()[:8]
        stem_part = Path(raw_name).stem
        cleaned_stem = re.sub(r'[^\w\u4e00-\u9fff.-]+', '_', stem_part).strip('._')
        if cleaned_stem and len(cleaned_stem) <= 32:
            dest_filename = f"{part_prefix}{cleaned_stem}_{url_hash}{ext}"
        else:
            dest_filename = f"{part_prefix}img_{url_hash}{ext}"

        dest_path = target_img_dir / dest_filename
        if not dest_path.exists():
            resp = requests.get(url, timeout=30)
            if resp.status_code == 200 and len(resp.content) > 0:
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                dest_path.write_bytes(resp.content)
            else:
                return url

        rel_path = f"{rel_prefix}{dest_filename}"
        if remote_cache is not None:
            remote_cache[url] = rel_path
        return rel_path
    except Exception:
        return url


def _process_markdown_images_for_agent(
    md_text: str,
    output_dir: Path,
    stem: str,
    extract_images: bool = True,
) -> tuple[str, int]:
    """Process markdown from Agent mode, download any remote images and rewrite links."""
    if not extract_images:
        return md_text, 0

    doc_folder = _clean_folder_name(stem)
    target_img_dir = output_dir / "images" / doc_folder
    rel_prefix = f"images/{doc_folder}/"
    remote_cache: dict[str, str] = {}
    saved_count = [0]

    def link_replacer(raw_url: str) -> str:
        clean = raw_url.strip().strip("<>")
        if clean.startswith(("http://", "https://")):
            target_img_dir.mkdir(parents=True, exist_ok=True)
            res = _download_and_save_remote_image(clean, target_img_dir, rel_prefix, remote_cache=remote_cache)
            if res != raw_url and res.startswith(rel_prefix):
                saved_count[0] += 1
            return res
        return raw_url

    rewritten_md = _replace_markdown_and_html_images(md_text, link_replacer)
    if saved_count[0] == 0 and target_img_dir.exists():
        try:
            target_img_dir.rmdir()
        except OSError:
            pass
    return rewritten_md, saved_count[0]


def _extract_and_rewrite_zip_archive(
    zip_bytes: bytes,
    output_dir: Path,
    stem: str,
    source_stem: str | None = None,
    part_no: int | None = None,
    final_output_dir: Path | None = None,
    extract_images: bool = True,
) -> tuple[str | None, int]:
    """
    Extract full.md and all images from MinerU zip.
    Saves images to (final_output_dir or output_dir) / "images" / <doc_folder> / ...
    Rewrites markdown image references to relative paths.
    Returns (rewritten_md_text, saved_images_count).
    """
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        md_name = next((n for n in zf.namelist() if n.endswith("/full.md") or n == "full.md"), None)
        if not md_name:
            md_files = [n for n in zf.namelist() if n.lower().endswith(".md") and not n.startswith("__MACOSX")]
            md_name = md_files[0] if md_files else None
        if not md_name:
            return None, 0

        md_text = zf.read(md_name).decode("utf-8", errors="replace")
        md_base_dir = os.path.dirname(md_name)

        if not extract_images:
            return md_text, 0

        # Folder structure for images
        base_target_dir = final_output_dir or output_dir
        if source_stem is not None and part_no is not None:
            # Long PDF chunk mode
            doc_folder = _clean_folder_name(source_stem)
            part_prefix = f"part{part_no:02d}_"
        else:
            # Normal PDF mode
            doc_folder = _clean_folder_name(stem)
            part_prefix = ""

        target_img_dir = base_target_dir / "images" / doc_folder
        rel_prefix = f"images/{doc_folder}/"

        # Find all images in zip
        img_entries = [
            n for n in zf.namelist()
            if not n.endswith("/") and not n.startswith("__MACOSX") and Path(n).suffix.lower() in IMAGE_EXTS
        ]

        mapping: dict[str, str] = {}
        basename_mapping: dict[str, str] = {}
        saved_count = 0

        if img_entries:
            target_img_dir.mkdir(parents=True, exist_ok=True)

        for entry in img_entries:
            if md_base_dir and entry.startswith(md_base_dir + "/"):
                rel_entry = entry[len(md_base_dir) + 1:]
            else:
                rel_entry = entry

            # Strip leading images/ or ./images/ to avoid duplicate nested folders
            if rel_entry.startswith("images/"):
                clean_name = rel_entry[len("images/"):]
            elif rel_entry.startswith("./images/"):
                clean_name = rel_entry[len("./images/"):]
            else:
                clean_name = rel_entry

            clean_name = os.path.normpath(clean_name).lstrip("/\\")
            # Flatten any sub-path into clean filename with part prefix
            flat_name = clean_name.replace("/", "_").replace("\\", "_")
            dest_filename = f"{part_prefix}{flat_name}"
            dest_path = target_img_dir / dest_filename
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            dest_path.write_bytes(zf.read(entry))
            saved_count += 1

            rel_target_url = f"{rel_prefix}{dest_filename}"

            # Register various ways this image could be referenced in markdown
            candidates = [
                entry,
                rel_entry,
                f"./{rel_entry}",
                f"/{rel_entry}",
                clean_name,
                f"images/{clean_name}",
                f"./images/{clean_name}",
                f"/{clean_name}",
                Path(entry).name,
                Path(clean_name).name,
                urllib.parse.quote(entry),
                urllib.parse.quote(rel_entry),
                urllib.parse.quote(f"images/{clean_name}"),
            ]
            for c in candidates:
                if c:
                    mapping[c] = rel_target_url
                    mapping[os.path.normpath(c).replace("\\", "/")] = rel_target_url

            basename_mapping[Path(entry).name] = rel_target_url

        remote_cache: dict[str, str] = {}

        def link_replacer(raw_url: str) -> str:
            clean = raw_url.strip().strip("<>")
            unquoted = urllib.parse.unquote(clean)
            norm = os.path.normpath(unquoted).replace("\\", "/")

            for cand in [raw_url, clean, unquoted, norm, norm.lstrip("./"), norm.lstrip("/")]:
                if cand in mapping:
                    return mapping[cand]

            base = Path(norm).name
            if base in basename_mapping:
                return basename_mapping[base]

            if clean.startswith(("http://", "https://")):
                nonlocal saved_count
                res = _download_and_save_remote_image(
                    clean, target_img_dir, rel_prefix, part_prefix, remote_cache
                )
                if res != raw_url and res.startswith(rel_prefix):
                    saved_count += 1
                return res

            return raw_url

        rewritten_md = _replace_markdown_and_html_images(md_text, link_replacer)
        if saved_count == 0 and target_img_dir.exists():
            try:
                target_img_dir.rmdir()
            except OSError:
                pass
        return rewritten_md, saved_count


# ---- Agent 轻量模式 (免登录) ----

def agent_parse_file(pdf_path: Path, output_dir: Path, extract_images: bool = True) -> str | None:
    """Agent API: 签名上传 → 轮询 → 下载 Markdown CDN 并本地化图片。"""
    name = pdf_path.name
    print(f"  [{name}] 获取上传链接...")
    resp = requests.post(
        f"{AGENT_BASE}/parse/file",
        json={"file_name": name, "language": "ch"},
        timeout=30,
    )
    data = resp.json()
    if data.get("code") != 0:
        print(f"    失败: {data.get('msg')}")
        return None

    task_id = data["data"]["task_id"]
    file_url = data["data"]["file_url"]

    with open(pdf_path, "rb") as f:
        put_resp = requests.put(file_url, data=f, timeout=120)
    if put_resp.status_code not in (200, 201):
        print(f"    上传失败 HTTP {put_resp.status_code}")
        return None

    start = time.time()
    while time.time() - start < 300:
        resp = requests.get(f"{AGENT_BASE}/parse/{task_id}", timeout=30)
        r = resp.json()
        state = r["data"]["state"]
        elapsed = int(time.time() - start)

        if state == "done":
            md_resp = requests.get(r["data"]["markdown_url"], timeout=60)
            md_text, img_count = _process_markdown_images_for_agent(
                md_resp.text, output_dir, pdf_path.stem, extract_images=extract_images
            )
            md_path = output_dir / f"{pdf_path.stem}.md"
            md_path.write_text(md_text, encoding="utf-8")
            img_msg = f", {img_count} 张图片" if img_count > 0 else ""
            print(f"    完成 [{elapsed}s] {md_path} ({len(md_text)} 字符{img_msg})")
            return md_text

        if state == "failed":
            print(f"    失败 [{elapsed}s]: {r['data'].get('err_msg', '')}")
            return None

        label = {"waiting-file": "等待上传", "pending": "排队", "running": "解析中"}
        print(f"    [{elapsed}s] {label.get(state, state)}...")
        time.sleep(3)

    print("    超时 (300s)")
    return None


# ---- 精准解析 API v4 (Token) ----

def _poll_batch(
    batch_id: str,
    output_dir: Path,
    headers: dict,
    manifest_map: dict | None = None,
    final_output_dir: Path | None = None,
    extract_images: bool = True,
    timeout: int = 1800,
) -> dict:
    """轮询批量结果，下载并保存 full.md 和图片。"""
    start = time.time()
    while time.time() - start < timeout:
        resp = requests.get(
            f"{V4_BASE}/extract-results/batch/{batch_id}",
            headers=headers, timeout=30,
        )
        r = resp.json()
        if r.get("code") != 0:
            time.sleep(5)
            continue

        results = r["data"]["extract_result"]
        elapsed = int(time.time() - start)

        # 统计状态
        states = {}
        for item in results:
            states[item["state"]] = states.get(item["state"], 0) + 1

        if "running" not in states and "pending" not in states and "waiting-file" not in states:
            print(f"  [{elapsed}s] 全部完成，下载中...")
            return _download_results(
                results, output_dir, manifest_map=manifest_map,
                final_output_dir=final_output_dir, extract_images=extract_images
            )

        progress = ", ".join(f"{k}:{v}" for k, v in states.items())
        print(f"  [{elapsed}s] {progress}")
        time.sleep(5)

    print("  超时")
    return {}


def _download_results(
    results: list,
    output_dir: Path,
    manifest_map: dict | None = None,
    final_output_dir: Path | None = None,
    extract_images: bool = True,
) -> dict:
    """下载 zip 并提取 full.md 与图片。"""
    output = {}
    for item in results:
        fname = item["file_name"]
        if item["state"] != "done":
            print(f"  跳过 {fname} (state={item['state']})")
            continue

        zip_url = item.get("full_zip_url")
        if not zip_url:
            continue

        try:
            content = _download_with_retries(zip_url, fname)
            stem = Path(fname).stem
            manifest_info = (manifest_map or {}).get(stem)
            source_stem = manifest_info["source_stem"] if manifest_info else None
            part_no = manifest_info["part"] if manifest_info else None

            md_text, img_count = _extract_and_rewrite_zip_archive(
                content,
                output_dir,
                stem,
                source_stem=source_stem,
                part_no=part_no,
                final_output_dir=final_output_dir,
                extract_images=extract_images,
            )

            if md_text is None:
                print(f"  {fname} 未找到 Markdown 文件")
                continue

            md_path = output_dir / f"{stem}.md"
            md_path.write_text(md_text, encoding="utf-8")
            output[fname] = md_text
            img_msg = f", {img_count} 张图片" if img_count > 0 else ""
            print(f"  {md_path} ({len(md_text)} 字符{img_msg})")
        except Exception as e:
            print(f"  {fname} 异常: {e}")

    return output


def _download_with_retries(url: str, fname: str, attempts: int = 5) -> bytes:
    """Download a MinerU zip with retries for transient incomplete reads."""
    last_error = None
    for attempt in range(1, attempts + 1):
        try:
            with requests.get(url, timeout=(20, 240), stream=True) as resp:
                resp.raise_for_status()
                chunks = []
                for chunk in resp.iter_content(chunk_size=1024 * 256):
                    if chunk:
                        chunks.append(chunk)
                return b"".join(chunks)
        except Exception as e:
            last_error = e
            print(f"  {fname} 下载失败，重试 {attempt}/{attempts}: {e}")
            time.sleep(min(2 * attempt, 10))
    raise last_error


def _env_token(target_dir: Path) -> str | None:
    """从目录级、用户级、skill 级 .env.kie 读取 Token。"""
    candidates = []
    for parent in [target_dir, *target_dir.parents]:
        candidates.append(parent / ".env.kie")
        if parent == Path.home():
            break
    candidates.extend([
        Path.home() / ".config/mineru/.env.kie",
        Path.home() / ".mineru/.env.kie",
        Path.home() / ".env.kie",
        Path(__file__).resolve().parent / ".env.kie",
    ])

    seen = set()
    for env_file in candidates:
        if env_file in seen or not env_file.exists():
            continue
        seen.add(env_file)
        for line in env_file.read_text(encoding="utf-8").splitlines():
            if line.startswith("MINERU_PIPELINE_ID="):
                val = line.split("=", 1)[1].strip()
                if val and val != "your_pipeline_id_here":
                    return val
    return None


def _batch_convert(
    pdf_paths: list[Path],
    output_dir: Path,
    token: str,
    manifest_map: dict | None = None,
    final_output_dir: Path | None = None,
    extract_images: bool = True,
) -> dict:
    """v4 批量上传 → 解析 → 下载，带限流重试。"""
    files_payload = [{"name": p.name, "data_id": _safe_ascii_id(p.stem, 120)} for p in pdf_paths]
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {token}"}

    for attempt in range(5):
        resp = requests.post(
            f"{V4_BASE}/file-urls/batch",
            headers=headers,
            json={"files": files_payload, "model_version": "vlm", "language": "ch",
                  "enable_table": True, "enable_formula": True},
            timeout=30,
        )
        if resp.status_code == 429:
            wait = min(30 * (attempt + 1), 120)
            print(f"触达限流，{wait}s 后重试 ({attempt + 1}/5)...")
            time.sleep(wait)
            continue

        r = resp.json()
        if isinstance(r, str):
            print(f"获取上传链接失败: {r}")
            if "limit" in r.lower():
                wait = min(30 * (attempt + 1), 120)
                print(f"触达限流，{wait}s 后重试 ({attempt + 1}/5)...")
                time.sleep(wait)
                continue
            return {}
        if r.get("code") != 0:
            print(f"获取上传链接失败: {r.get('msg')}")
            return {}

        batch_id = r["data"]["batch_id"]
        file_urls = r["data"]["file_urls"]
        print(f"batch_id: {batch_id}, {len(file_urls)} 个上传链接")

        for i, (pdf_path, url) in enumerate(zip(pdf_paths, file_urls)):
            print(f"  上传 [{i+1}/{len(pdf_paths)}] {pdf_path.name} "
                  f"({pdf_path.stat().st_size / 1024:.0f} KB)...", end=" ")
            with open(pdf_path, "rb") as f:
                pr = requests.put(url, data=f, timeout=120)
            print("OK" if pr.status_code in (200, 201) else f"FAIL HTTP {pr.status_code}")

        print("上传完成，等待解析...")
        return _poll_batch(
            batch_id, output_dir, headers,
            manifest_map=manifest_map, final_output_dir=final_output_dir,
            extract_images=extract_images,
        )

    print("重试耗尽，放弃此批次")
    return {}


def _split_long_pdfs(pdf_files: list[Path], chunks_dir: Path, chunk_pages: int) -> list[dict]:
    """Split PDFs into chunks accepted by MinerU v4 and return a merge manifest."""
    if chunk_pages <= 0:
        raise ValueError("--chunk-pages 必须大于 0")
    if chunk_pages > MAX_V4_PAGES:
        raise ValueError(f"--chunk-pages 不能超过 {MAX_V4_PAGES}")
    try:
        import fitz
    except ImportError as exc:
        raise SystemExit("错误: --split-long 需要 PyMuPDF/fitz。请先安装 pymupdf。") from exc

    chunks_dir.mkdir(parents=True, exist_ok=True)
    for old in chunks_dir.glob("*.pdf"):
        old.unlink()

    manifest = []
    for pdf_path in pdf_files:
        doc = fitz.open(pdf_path)
        total_pages = doc.page_count
        for start in range(0, total_pages, chunk_pages):
            end = min(start + chunk_pages, total_pages)
            part_no = start // chunk_pages + 1
            short_stem = _safe_ascii_id(pdf_path.stem, 72)
            chunk_name = f"{short_stem}__part{part_no:02d}_p{start + 1:03d}-{end:03d}.pdf"
            chunk_path = chunks_dir / chunk_name
            chunk_doc = fitz.open()
            chunk_doc.insert_pdf(doc, from_page=start, to_page=end - 1)
            chunk_doc.save(chunk_path)
            chunk_doc.close()
            manifest.append({
                "source": str(pdf_path),
                "source_name": pdf_path.name,
                "source_stem": pdf_path.stem,
                "part": part_no,
                "pages": [start + 1, end],
                "chunk": str(chunk_path),
                "chunk_name": chunk_name,
                "page_count": end - start,
            })
        doc.close()
    (chunks_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return manifest


def _merge_split_markdown(manifest: list[dict], chunk_md_dir: Path, output_dir: Path) -> int:
    """Merge chunk Markdown files back to one Markdown per source PDF."""
    grouped = {}
    for item in manifest:
        grouped.setdefault(item["source_stem"], []).append(item)

    merged = 0
    for source_stem, items in sorted(grouped.items()):
        items.sort(key=lambda item: item["part"])
        source_name = items[0]["source_name"]
        sections = [
            f"# {source_name}\n",
            "\n> MinerU OCR Markdown. Long PDF was split by page range and merged in original order.\n",
        ]
        complete = True
        for item in items:
            md_path = chunk_md_dir / f"{Path(item['chunk_name']).stem}.md"
            if not md_path.exists():
                print(f"缺少分块 Markdown，无法合并: {md_path}")
                complete = False
                continue
            start, end = item["pages"]
            sections.append(f"\n\n---\n\n## Part {item['part']}: PDF pages {start}-{end}\n\n")
            sections.append(md_path.read_text(encoding="utf-8").strip())
            sections.append("\n")
        if not complete:
            continue
        merged_path = output_dir / f"{source_stem}.md"
        merged_path.write_text("".join(sections), encoding="utf-8")

        img_folder = output_dir / "images" / _clean_folder_name(source_stem)
        img_info = ""
        if img_folder.exists():
            imgs = [p for p in img_folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTS]
            if imgs:
                img_info = f", 含 {len(imgs)} 张图片"

        print(f"合并: {merged_path} ({merged_path.stat().st_size} bytes{img_info})")
        merged += 1
    return merged


def _registry_documents(registry_file: Path, pdf_files: list[Path]) -> dict[Path, dict]:
    """Return registry rows keyed by resolved PDF path; reject untracked inputs."""
    if not registry_file.is_file():
        raise SystemExit(f"错误: 未找到文献注册表: {registry_file}")
    with registry_file.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
    root = registry_file.parent
    by_pdf = {
        (root / row["pdf_path"]).resolve(): row
        for row in rows
        if row.get("paper_id") and row.get("pdf_path")
    }
    missing = [str(pdf) for pdf in pdf_files if pdf.resolve() not in by_pdf]
    if missing:
        raise SystemExit("错误: --registry 只接受已登记的项目 PDF: " + ", ".join(missing[:3]))
    return {pdf.resolve(): by_pdf[pdf.resolve()] for pdf in pdf_files}


def _write_registry_parse_status(
    registry_file: Path, paper_id: str, status: str, fulltext_path: Path | None, note: str = ""
) -> None:
    with registry_file.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = list(reader.fieldnames or [])
        rows = list(reader)
    for field in ("parse_status", "fulltext_path", "notes"):
        if field not in headers:
            headers.append(field)
    root = registry_file.parent.resolve()
    for row in rows:
        if row.get("paper_id") != paper_id:
            continue
        row["parse_status"] = status
        if fulltext_path is not None:
            row["fulltext_path"] = str(fulltext_path.resolve().relative_to(root))
        if note:
            row["notes"] = note
        break
    with registry_file.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def _convert_one_pdf(
    pdf_path: Path, output_dir: Path, args, token: str | None, extract_images: bool
) -> bool:
    """Run one document into its own output directory to preserve paper identity."""
    output_dir.mkdir(parents=True, exist_ok=True)
    if args.agent:
        return bool(agent_parse_file(pdf_path, output_dir, extract_images=extract_images))
    if not token:
        return False
    if args.split_long:
        chunks_dir = output_dir / "_chunks"
        chunk_md_dir = output_dir / "_chunk_md"
        chunk_md_dir.mkdir(parents=True, exist_ok=True)
        manifest = _split_long_pdfs([pdf_path], chunks_dir, args.chunk_pages)
        manifest_map = {Path(item["chunk_name"]).stem: item for item in manifest}
        results = _batch_convert(
            [Path(item["chunk"]) for item in manifest],
            chunk_md_dir,
            token,
            manifest_map=manifest_map,
            final_output_dir=output_dir,
            extract_images=extract_images,
        )
        return bool(results) and _merge_split_markdown(manifest, chunk_md_dir, output_dir) == 1
    return bool(_batch_convert([pdf_path], output_dir, token, extract_images=extract_images))


def _convert_registered_pdfs(
    registry_file: Path, pdf_files: list[Path], output_dir: Path, args, token: str | None, extract_images: bool
) -> int:
    documents = _registry_documents(registry_file, pdf_files)
    success = 0
    for index, pdf_path in enumerate(pdf_files, 1):
        row = documents[pdf_path.resolve()]
        paper_id = row["paper_id"]
        document_dir = output_dir / paper_id
        print(f"[{index}/{len(pdf_files)}] {paper_id}: {pdf_path.name}")
        try:
            parsed = _convert_one_pdf(pdf_path, document_dir, args, token, extract_images)
            generated = document_dir / f"{pdf_path.stem}.md"
            document = document_dir / "document.md"
            if parsed and generated.is_file():
                if generated != document:
                    generated.replace(document)
                _write_registry_parse_status(registry_file, paper_id, "parsed", document)
                success += 1
                print(f"  已登记: {document}")
            else:
                _write_registry_parse_status(registry_file, paper_id, "failed", None, "MinerU 未生成可用 Markdown")
                print(f"  解析失败: {paper_id}", file=sys.stderr)
        except Exception as exc:
            _write_registry_parse_status(registry_file, paper_id, "failed", None, f"MinerU 异常: {exc}")
            print(f"  解析异常: {paper_id}: {exc}", file=sys.stderr)
    print(f"\n注册表解析完成: {success}/{len(pdf_files)}")
    return 0 if success == len(pdf_files) else 1


# ---- 主入口 ----

def main():
    parser = argparse.ArgumentParser(description="MinerU PDF → Markdown 批量转换")
    parser.add_argument("paths", type=str, nargs="*", default=["."],
                        help="PDF 所在目录或文件路径 (默认当前目录)")
    parser.add_argument("--pattern", type=str, default=None,
                        help="文件名匹配模式，例如 '*定量*'")
    parser.add_argument("--agent", action="store_true",
                        help="使用免登录 Agent 轻量 API (≤10MB/≤20页)")
    parser.add_argument("--token", type=str, default=None,
                        help="JWT/API Token (用于精准解析 API v4)")
    parser.add_argument("--output", type=str, default=None,
                        help="输出目录 (默认 <目标目录>/pdf2md_output)")
    parser.add_argument("--registry", type=str, default=None,
                        help="paper-registry.csv；启用后每篇写入 <output>/<paper_id>/document.md 并回写解析状态")
    parser.add_argument("--split-long", action="store_true",
                        help="Token 模式下将长 PDF 切成 ≤200 页分块，识别后按原顺序合并")
    parser.add_argument("--chunk-pages", type=int, default=DEFAULT_CHUNK_PAGES,
                        help=f"--split-long 每块页数 (默认 {DEFAULT_CHUNK_PAGES}, 最大 {MAX_V4_PAGES})")
    parser.add_argument("--no-images", action="store_true",
                        help="禁用图片提取与本地化 (默认开启图片本地保存与相对链接转换)")
    args = parser.parse_args()

    extract_images = not args.no_images
    raw_paths = [Path(p).resolve() for p in args.paths]
    pdf_files = []
    for p in raw_paths:
        if p.is_file() and p.suffix.lower() == ".pdf":
            pdf_files.append(p)
        elif p.is_dir():
            pattern = args.pattern or "*.pdf"
            pdf_files.extend(sorted(p.glob(pattern)))
        else:
            matches = sorted(p.parent.glob(p.name))
            pdf_files.extend([m for m in matches if m.is_file() and m.suffix.lower() == ".pdf"])

    # Deduplicate preserving order
    seen = set()
    unique_pdf_files = []
    for f in pdf_files:
        if f not in seen:
            seen.add(f)
            unique_pdf_files.append(f)
    pdf_files = unique_pdf_files

    if not pdf_files:
        print(f"未找到匹配的 PDF 文件 (输入: {args.paths}, pattern: {args.pattern})")
        return

    first_target = raw_paths[0]
    base_dir = first_target if first_target.is_dir() else first_target.parent
    output_dir = Path(args.output).resolve() if args.output else base_dir / "pdf2md_output"
    output_dir.mkdir(parents=True, exist_ok=True)

    token = args.token or _env_token(base_dir)

    if args.agent and args.split_long:
        print("错误: --split-long 仅支持 Token 精准解析模式，不能与 --agent 同用")
        sys.exit(1)

    if args.registry:
        if not args.output:
            print("错误: --registry 必须显式指定 --output 为项目的 fulltext 目录")
            sys.exit(1)
        sys.exit(_convert_registered_pdfs(
            Path(args.registry).resolve(), pdf_files, output_dir, args, token, extract_images
        ))

    if args.agent:
        print(f"Agent 轻量模式 (免登录): {len(pdf_files)} 个 PDF → {output_dir}")
        print("限制: ≤10MB/≤20页, 逐文件上传\n")
        success = 0
        for i, p in enumerate(pdf_files, 1):
            print(f"[{i}/{len(pdf_files)}]", end=" ")
            if agent_parse_file(p, output_dir, extract_images=extract_images):
                success += 1
            if i < len(pdf_files):
                time.sleep(2)
        print(f"\n完成: {success}/{len(pdf_files)}")
    elif token:
        if args.split_long:
            chunks_dir = output_dir / "_chunks"
            chunk_md_dir = output_dir / "_chunk_md"
            chunk_md_dir.mkdir(parents=True, exist_ok=True)
            print(f"长 PDF 切块模式: {len(pdf_files)} 个 PDF → {output_dir}")
            print(f"切块页数: {args.chunk_pages} 页；中间 PDF: {chunks_dir}；中间 Markdown: {chunk_md_dir}\n")
            manifest = _split_long_pdfs(pdf_files, chunks_dir, args.chunk_pages)
            chunk_files = [Path(item["chunk"]) for item in manifest]
            manifest_map = {Path(item["chunk_name"]).stem: item for item in manifest}
            print(f"生成分块: {len(chunk_files)} 个")
            all_results = {}
            for i in range(0, len(chunk_files), BATCH_SIZE):
                batch = chunk_files[i:i + BATCH_SIZE]
                print(f"批次 [{i // BATCH_SIZE + 1}] {len(batch)} 个分块")
                all_results.update(_batch_convert(
                    batch, chunk_md_dir, token,
                    manifest_map=manifest_map, final_output_dir=output_dir,
                    extract_images=extract_images
                ))
                if i + BATCH_SIZE < len(chunk_files):
                    time.sleep(3)
            merged = _merge_split_markdown(manifest, chunk_md_dir, output_dir)
            print(f"\n分块完成: {len(all_results)}/{len(chunk_files)}；合并完成: {merged}/{len(pdf_files)}")
        else:
            print(f"精准解析 API v4 (Token): {len(pdf_files)} 个 PDF → {output_dir}")
            print(f"限制: ≤200MB/≤200页, 每批≤50个, vlm 模型\n")
            all_results = {}
            for i in range(0, len(pdf_files), BATCH_SIZE):
                batch = pdf_files[i:i + BATCH_SIZE]
                print(f"批次 [{i // BATCH_SIZE + 1}] {len(batch)} 个文件")
                all_results.update(_batch_convert(
                    batch, output_dir, token,
                    extract_images=extract_images
                ))
                if i + BATCH_SIZE < len(pdf_files):
                    wait = 65  # 确保每分钟不超过 50 个文件
                    print(f"等待 {wait}s 避免限流...")
                    time.sleep(wait)
            print(f"\n完成: {len(all_results)}/{len(pdf_files)}")
    else:
        print("错误: 未找到 Token。请:")
        print("  1. 在目标目录创建 .env.kie，写入 MINERU_PIPELINE_ID=<token>")
        print("  2. 使用 --token <token> 手动传入")
        print("  3. 使用 --agent 切换到免登录轻量模式")
        sys.exit(1)


if __name__ == "__main__":
    main()
