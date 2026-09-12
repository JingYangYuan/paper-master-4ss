#!/usr/bin/env python3
"""把本机已安装的 pi-chrome 打包成可离线安装的公开镜像仓。

背景（2026-09-12 实测）：npm 上的 `pi-chrome@0.15.51` tarball 与 OMP 本机安装的
0.15.51 **代码不同**——npm tarball 是同一版本号下的旧构建，缺 `offscreen.html` /
`offscreen.js` 与 manifest 的 `offscreen` 权限，MV3 service worker 没有保活文档，
在较新的 Chrome 里会休眠后不再轮询 `127.0.0.1:17318`，表现为"插件装了但连不上"。
因此镜像的源不是 npm，而是本机**已验证可用**的安装目录。

源：`~/.omp/plugins/node_modules/pi-chrome`（可用 --source 覆盖）
目标：`../pi-chrome-mirror/`（对外发布版，含 vendored 原件 + 校验和 + 安装说明）

用法：
    python3 scripts/export_pi_chrome_plugin.py                 # 导出
    python3 scripts/export_pi_chrome_plugin.py --check         # 只校验镜像与源是否一致
    python3 scripts/export_pi_chrome_plugin.py --zip-out DIR   # 另出伴生扩展 zip（Chrome 加载用）
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path

PKG_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PKG_ROOT.parent
TARGET = REPO_ROOT / "pi-chrome-mirror"
DEFAULT_SOURCE = Path.home() / ".omp" / "plugins" / "node_modules" / "pi-chrome"

UPSTREAM_REPO = "https://github.com/tianrendong/pi-chrome"
UPSTREAM_NPM = "https://www.npmjs.com/package/pi-chrome"
CNKI_DOC_REPO = "https://github.com/JingYangYuan/pi-chrome-cnki"
MIRROR_REPO = "https://github.com/JingYangYuan/pi-chrome-mirror"

COMPANION = "extensions/chrome-profile-bridge/browser-extension"
PLUGIN_ENTRY = "extensions/chrome-profile-bridge/index.ts"
SKIP_NAMES = {".DS_Store"}
SKIP_DIRS = {"node_modules", ".git", "__pycache__"}

README = """# pi-chrome 离线镜像（含完整伴生 Chrome 扩展）

[{upstream}]({upstream_repo}) 的 **0.15.51 本机可用构建**离线副本，供无法从 npm 安装 pi-chrome 的
机器使用。含 OMP 侧插件（`extensions/chrome-profile-bridge/index.ts`）**与**完整伴生 Chrome 扩展
（`{companion}/`，manifest v3，带 `offscreen` 保活）。

> 非官方镜像。代码版权归上游，MIT，见 [LICENSE](LICENSE)。
> 上游仓库：<{upstream_repo}> · npm：<{upstream_npm}>

## 为什么需要这个镜像

npm 上 `pi-chrome@0.15.51` 的 tarball 与本机安装的 0.15.51 **不是同一份代码**：

| 文件 | npm tarball | 本镜像（本机可用构建） |
|---|---|---|
| `{companion}/manifest.json` | 无 `offscreen` 权限 | 含 `offscreen` 权限 |
| `{companion}/offscreen.html` | **缺失** | 存在 |
| `{companion}/offscreen.js` | **缺失** | 存在 |
| `{companion}/service_worker.js` | 无保活逻辑 | `ensureOffscreen()` + 启动即 `pollLoop()` |
| `{plugin_entry}` | 旧构建 | 含 private-network CORS、GET `/result`、重载处理等修复 |

缺 `offscreen` 保活时，MV3 service worker 被 Chrome 回收后不再轮询 `127.0.0.1:17318`，
表现为"扩展已加载但 Agent 连不上"。**这是 Chrome 升级后最常见的失效原因**，装本镜像即可。

## 安装（不依赖 npm）

### 1. OMP 侧插件

```bash
git clone {mirror_repo}.git ~/pi-chrome-mirror
omp install ~/pi-chrome-mirror          # 本地路径安装，不需要 npm 下载
# 或先看计划：omp install ~/pi-chrome-mirror --dry-run
```

装完在 OMP 里 `/reload`，然后：

```text
/chrome authorize
/chrome doctor          # 应显示 ✓ Chrome is connected
```

也可完全手工：把本仓库目录放到 `~/.omp/plugins/node_modules/pi-chrome/`，
并让 `~/.omp/plugins/package.json` 的依赖指向它。

### 2. 伴生 Chrome 扩展（手动加载一次）

最省事：下载本仓库 Releases 里的 `pi-chrome-companion-{version}.zip`，解压得到含
`manifest.json` 的目录。然后 Chrome → `chrome://extensions` → 开启**开发者模式** →
**加载已解压的扩展程序** → 选择该目录（或本仓库的 `{companion}/`）。

扩展名 `Pi Chrome Connector`，加载后工具条应显示已启用；`/chrome doctor` 会报告连接状态。

## 校验

`checksums.sha256` 列出除本说明类文件外每个 vendored 文件的哈希：

```bash
shasum -a 256 -c checksums.sha256
```

本镜像构建指纹：`{fingerprint}`（源目录 {file_count} 个文件，逐字节复制，未做任何改写）。

## 注意

- 本机可用构建会在 `index.ts` 里把桥接请求元数据追加写入 `/tmp/pi-chrome-requests.log`（调试用）。
  镜像保持逐字节一致，未移除该行为；介意可自行删除 `index.ts` 中对应的 `appendFileSync` 调用。
- 伴生扩展权限较宽（`<all_urls>`、`debugger` 等），运行在你真实的 Chrome profile 中；只用于你自己授权的任务。
- 升级时重跑 `python3 scripts/export_pi_chrome_plugin.py` 并重新推送本仓库（见 `MIRROR.md`）。
"""

MIRROR_MD = """# 镜像维护说明

本仓库由 `paper-master-4ss` 的 `scripts/export_pi_chrome_plugin.py` 从**本机已安装且已验证可用**的
pi-chrome 目录导出，不是从 npm 拉取。

```bash
python3 scripts/export_pi_chrome_plugin.py                 # 导出/刷新 ../pi-chrome-mirror
python3 scripts/export_pi_chrome_plugin.py --check         # 校验镜像与源逐字节一致
python3 scripts/export_pi_chrome_plugin.py --zip-out /tmp  # 另出伴生扩展 zip
python3 scripts/publish_family.py pi-chrome-mirror         # 推送本仓库
```

## 为什么源是本机目录而不是 npm

2026-09-12 实测：`npm pack pi-chrome@0.15.51` 得到的 tarball 与 OMP 本机安装的 0.15.51
**同一版本号、不同代码**。npm 版缺 `offscreen.html` / `offscreen.js` 与 manifest 的
`offscreen` 权限，MV3 service worker 无保活；Chrome 回收 worker 后桥接轮询停止，
用户侧表现为"扩展加载了但连不上"。本机安装目录是当前实际工作、且已在本会话验证的构建，
故以它为源。

导出脚本内置完整性闸门，源若不满足以下条件会**直接失败**，避免再发出一个"看起来完整但连不上"的包：

- `{companion}/manifest.json` 含 `offscreen` 权限
- `{companion}/offscreen.html`、`offscreen.js` 存在
- `service_worker.js` 引用 `offscreen.html`
- `package.json` 的 `pi.extensions` 指向的入口文件存在

## 发布 release（zip 资产）

```bash
python3 scripts/export_pi_chrome_plugin.py --zip-out /tmp
gh release create pi-chrome-{version} /tmp/pi-chrome-companion-{version}.zip \\
  --repo JingYangYuan/pi-chrome-mirror \\
  --title "pi-chrome {version} (本机可用构建)" \\
  --notes "完整伴生 Chrome 扩展，含 offscreen 保活；用于 npm tarball 缺失 offscreen 文件的场景。"
```

## 上游归属

代码与文档版权归 pi-chrome 上游作者，MIT 许可（本仓库保留上游 `LICENSE`）。
本仓库只做逐字节镜像与安装说明，未修改任何 vendored 文件。
"""


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_manifest(source: Path) -> dict:
    return json.loads(read_text(source / COMPANION / "manifest.json"))


def assert_completeness(source: Path) -> dict:
    """源必须含 offscreen 保活，否则拒绝导出（见 MIRROR.md）。"""
    problems: list[str] = []
    manifest_path = source / COMPANION / "manifest.json"
    if not manifest_path.is_file():
        raise SystemExit(f"源缺少 {COMPANION}/manifest.json: {source}")
    manifest = load_manifest(source)
    if "offscreen" not in manifest.get("permissions", []):
        problems.append("manifest.json 缺 offscreen 权限（npm tarball 版即此症状）")
    for name in ("offscreen.html", "offscreen.js"):
        if not (source / COMPANION / name).is_file():
            problems.append(f"{COMPANION}/{name} 不存在")
    worker = source / COMPANION / "service_worker.js"
    if not worker.is_file():
        problems.append(f"{COMPANION}/service_worker.js 不存在")
    elif "offscreen.html" not in read_text(worker):
        problems.append("service_worker.js 未引用 offscreen.html（无保活逻辑）")

    pkg = json.loads(read_text(source / "package.json"))
    entry = (pkg.get("pi") or {}).get("extensions") or []
    entry_rel = str(entry[0]).lstrip("./") if entry else ""
    if not entry_rel or not (source / entry_rel).is_file():
        problems.append(f"package.json 的 pi.extensions 入口不存在: {entry_rel or '(空)'}")

    if problems:
        raise SystemExit("源不完整，拒绝导出：\n  - " + "\n  - ".join(problems))
    return pkg


def vendored_files(source: Path) -> list[Path]:
    files: list[Path] = []
    for item in sorted(source.rglob("*")):
        if item.is_dir() or item.name in SKIP_NAMES:
            continue
        if any(part in SKIP_DIRS for part in item.relative_to(source).parts):
            continue
        files.append(item)
    return files


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def checksums_text(source: Path, files: list[Path]) -> str:
    """逐字节校验清单。

    `README.md` 在镜像中被替换为镜像说明（上游原文另存 `UPSTREAM-README.md`），
    因此清单里列的是 `UPSTREAM-README.md`——校验它等于校验上游 README 原样保留。
    """
    lines: list[str] = []
    for path in files:
        rel = path.relative_to(source).as_posix()
        if rel == "README.md":
            lines.append(f"{sha256(path)}  UPSTREAM-README.md")
            continue
        lines.append(f"{sha256(path)}  {rel}")
    return "\n".join(lines) + "\n"


def fingerprint(checksums: str) -> str:
    return hashlib.sha256(checksums.encode("utf-8")).hexdigest()[:12]


def build(source: Path) -> dict[str, str | bytes]:
    pkg = assert_completeness(source)
    files = vendored_files(source)
    checksums = checksums_text(source, files)
    version = str(pkg["version"])
    fp = fingerprint(checksums)

    out: dict[str, str | bytes] = {}
    for path in files:
        rel = path.relative_to(source).as_posix()
        data = path.read_bytes()
        if rel == "README.md":
            # 保留上游 README 原文，另存镜像说明为仓首页，避免"照着上游 README 去 npm 装"的老路。
            out["UPSTREAM-README.md"] = data
            continue
        out[rel] = data
    out["README.md"] = README.format(
        upstream=pkg.get("name", "pi-chrome"),
        upstream_repo=UPSTREAM_REPO,
        upstream_npm=UPSTREAM_NPM,
        companion=COMPANION,
        plugin_entry=PLUGIN_ENTRY,
        mirror_repo=MIRROR_REPO,
        version=version,
        fingerprint=fp,
        file_count=len(files),
    )
    out["MIRROR.md"] = MIRROR_MD.format(companion=COMPANION, version=version)
    out["checksums.sha256"] = checksums
    return out


def write_target(files: dict[str, str | bytes]) -> None:
    if TARGET.is_dir():
        for item in TARGET.iterdir():
            if item.name == ".git":
                continue
            if item.is_dir():
                shutil.rmtree(item)
            else:
                item.unlink()
    for rel, data in files.items():
        path = TARGET / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(data, bytes):
            path.write_bytes(data)
        else:
            path.write_text(data, encoding="utf-8")
    (TARGET / ".gitignore").write_text("dist/\n.DS_Store\n", encoding="utf-8")


def check_target(files: dict[str, str | bytes]) -> list[str]:
    drift: list[str] = []
    if not TARGET.is_dir():
        return [f"镜像目录不存在: {TARGET}"]
    for rel, data in files.items():
        path = TARGET / rel
        if not path.is_file():
            drift.append(f"缺失: {rel}")
            continue
        actual = path.read_bytes() if isinstance(data, bytes) else path.read_text(encoding="utf-8").encode("utf-8")
        expected = data if isinstance(data, bytes) else data.encode("utf-8")
        if actual != expected:
            drift.append(f"内容不同步: {rel}")
    for path in sorted(TARGET.rglob("*")):
        if not path.is_file() or ".git/" in path.as_posix():
            continue
        rel = path.relative_to(TARGET).as_posix()
        if rel not in files and rel not in {".gitignore"}:
            drift.append(f"镜像存在源中没有的文件: {rel}")
    return drift


def write_zip(source: Path, out_dir: Path) -> Path:
    version = str(json.loads(read_text(source / "package.json"))["version"])
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"pi-chrome-companion-{version}.zip"
    root = f"pi-chrome-companion-{version}"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted((source / COMPANION).rglob("*")):
            if path.is_file() and path.name not in SKIP_NAMES:
                zf.write(path, f"{root}/{path.relative_to(source / COMPANION).as_posix()}")
    return zip_path


def main() -> int:
    parser = argparse.ArgumentParser(description="导出 pi-chrome 离线镜像仓")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE), help="已安装的 pi-chrome 目录")
    parser.add_argument("--check", action="store_true", help="只校验镜像与源是否一致")
    parser.add_argument("--zip-out", default=None, help="另出伴生扩展 zip 的目录")
    args = parser.parse_args()

    source = Path(args.source).expanduser()
    if not source.is_dir():
        raise SystemExit(f"源目录不存在: {source}")

    files = build(source)
    if args.check:
        drift = check_target(files)
        if drift:
            print(f"[pi-chrome-mirror] 未同步（{len(drift)} 处）:")
            for item in drift:
                print(f"  - {item}")
            return 1
        print(f"[pi-chrome-mirror] 已同步: {TARGET}")
        return 0

    write_target(files)
    payload = len([k for k in files if k not in {"README.md", "MIRROR.md", "checksums.sha256"}])
    print(f"[pi-chrome-mirror] 导出完成: {TARGET}（vendored {payload} 文件 + 3 个说明文件）")
    print(f"[pi-chrome-mirror] 指纹: {fingerprint(str(files['checksums.sha256']))}")

    if args.zip_out:
        zip_path = write_zip(source, Path(args.zip_out).expanduser())
        print(f"[pi-chrome-mirror] 伴生扩展 zip: {zip_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
