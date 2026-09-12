#!/usr/bin/env python3
"""导出合并后的 pi-chrome 公开仓：可离线安装的完整插件 + CNKI 适配文档。

一个仓库承担两件事：
  1. 插件本体——逐字节复制本机**已验证可用**的 pi-chrome 安装
     （`extensions/`、`package.json`、`LICENSE`），供 `omp install <repo>` 离线安装；
  2. CNKI 适配文档与工具——`pi-chrome-browser.md` 与 `scripts/cnki/cookie_sink.py`。

不提供、也不提及上游官方安装通道：上游 npm 发布的 0.15.51 缺 MV3 `offscreen` 保活
（详见 NOTICE.md），照着官方通道装会得到"扩展已加载但连不上"的构建，因此本仓是
唯一受支持的分发点。

源：`~/.omp/plugins/node_modules/pi-chrome`（插件，可用 --source 覆盖）
    `modules/lit/references/pi-chrome-browser.md`、`modules/lit/scripts/cnki/cookie_sink.py`（文档与工具）
目标：`../pi-chrome-mirror/`

用法：
    python3 scripts/export_pi_chrome_repo.py                 # 导出
    python3 scripts/export_pi_chrome_repo.py --check         # 只校验目标是否与源一致
    python3 scripts/export_pi_chrome_repo.py --zip-out DIR   # 另出伴生扩展 zip（release 资产）
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
UPSTREAM_AUTHOR = "pi-chrome contributors"
MASTER_REPO = "https://github.com/JingYangYuan/paper-master-4ss"
LIT_REPO = "https://github.com/JingYangYuan/paper-lit-4ss"
MIRROR_REPO = "https://github.com/JingYangYuan/pi-chrome-mirror"

DOC_SRC = PKG_ROOT / "modules" / "lit" / "references" / "pi-chrome-browser.md"
SINK_SRC = PKG_ROOT / "modules" / "lit" / "scripts" / "cnki" / "cookie_sink.py"
DOC_NAME = "pi-chrome-browser.md"
SINK_NAME = "scripts/cnki/cookie_sink.py"

COMPANION = "extensions/chrome-profile-bridge/browser-extension"
PLUGIN_ENTRY = "extensions/chrome-profile-bridge/index.ts"

# 插件本体：仅运行时必需，逐字节复制
VENDOR_FILES = [
    "package.json",
    "LICENSE",
    PLUGIN_ENTRY,
    f"{COMPANION}/manifest.json",
    f"{COMPANION}/offscreen.html",
    f"{COMPANION}/offscreen.js",
    f"{COMPANION}/service_worker.js",
    f"{COMPANION}/snapshot_injected.js",
]

# 上游发布通道不得出现的痕迹；生成物与 vendored 文件都会扫描（见 assert_no_official_install）
FORBIDDEN = ["npm:pi-chrome", "npm install pi-chrome", "npmjs.com/package/pi-chrome", "npm i pi-chrome"]

GENERATED = ["README.md", "NOTICE.md", DOC_NAME, SINK_NAME, "checksums.sha256"]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


README = """# pi-chrome 离线发行版（完整插件 + CNKI 适配）

本仓库同时提供两样东西：

1. **可离线安装的 pi-chrome 插件本体** —— `extensions/`、`package.json`、`LICENSE`，逐字节复制自一份
   在 macOS + Chrome 上实测跑通的 0.15.51 安装，含 MV3 `offscreen` 保活的完整伴生 Chrome 扩展。
   `omp install <本仓库>` 即可，不需要任何外部下载通道。
2. **CNKI 知网适配文档与工具** —— [pi-chrome-browser.md]({doc})（安装授权、目标模型、能力映射、
   失败恢复、与 ZCode 后端差异）与 [scripts/cnki/cookie_sink.py]({sink})（Cookie 回环落盘）。

> 为什么自带插件而不是让用户去装上游发布的版本：上游发布通道的 0.15.51 与本机可用构建**同号不同构**，
> 缺 `offscreen.html` / `offscreen.js` 与 manifest 的 `offscreen` 权限，MV3 service worker 被 Chrome 回收后
> 不再轮询 `127.0.0.1:17318`，表现为"扩展已加载但连不上"。事实对照见 [NOTICE.md](NOTICE.md)。
> 本仓库是唯一受支持的分发点。

## 安装

```bash
git clone {mirror}.git
cd pi-chrome-mirror
omp install .                 # 本地路径安装；先加 --dry-run 看计划
```

装完在 OMP 里 `/reload`，然后：

```text
/chrome authorize             # 默认 15 分钟；长期用 /chrome authorize indefinite
/chrome doctor                # 应显示 ✓ Chrome is connected
/chrome revoke                # 用完撤销
```

伴生 Chrome 扩展（手动加载一次）：`chrome://extensions` → 开启**开发者模式** →
**加载已解压的扩展程序** → 选择本仓库的 `{companion}/`
（或下载 [Releases]({mirror}/releases) 里的 `pi-chrome-companion-{version}.zip` 解压后选择解压目录）。
扩展名 `Pi Chrome Connector`；`/chrome onboard` 也会显示安装后的扩展目录路径。

### 升级本仓库

```bash
cd pi-chrome-mirror && git pull
omp install .                 # 软链形态下 git pull 即时生效
```

`omp install` 在 macOS 上遇到**同名实目录**会报 `EPERM: operation not permitted, unlink ...`
（内部对目录调 `unlink`，已实测复现）。遇到时先删旧目录再装：

```bash
rm -rf ~/.omp/plugins/node_modules/pi-chrome && omp install .
```

## 每次 CNKI 阶段前的四项验收

| 步骤 | 命令 | 通过标准 |
|---|---|---|
| 1 | `chrome_tab action=list` | 返回标签页列表，不报错 |
| 2 | `chrome_tab action=version` | 返回 `extensionVersion` / `bridgeUrl` / `capabilities` |
| 3 | `chrome_navigate`（**不带 target**）到 `about:blank` | 返回 `Navigated to about:blank` |
| 4 | `chrome_evaluate`（**不带 targetId**）读 `location.href` | 返回 `about:blank` |

任一项失败即记录 `浏览器控制不可用` 并停止 CNKI 阶段；先 `/chrome doctor`，再确认伴生扩展已加载。

## 三条硬约束（2026-09-12 实测，本仓 0.15.51）

1. **不要传 `targetId`**：`chrome_evaluate` / `chrome_snapshot` / `chrome_click` 传 `targetId` 会返回
   `Runtime.evaluate: Detached while handling command`。全流程只走 `chrome_navigate` 建立的单一自动化目标。
2. **页内异步不得 `awaitPromise`**：await 慢 fetch 会中断调用。写成立即返回的 fire-and-forget 挂到
   `window.__x`，再用 `chrome_wait_for {{ kind: "expression", value: "window.__x !== null" }}` 轮询。
3. **点击与读取一律用 `chrome_evaluate`**：kns8s 这类重页面上 `chrome_snapshot` 会
   `inject snapshot script ... timed out after 8000ms`，`chrome_click` 会 `DOM click fallback ... timed out`。
   默认 `hardBackground: true` 下 `chrome_tab activate` 被拒属预期，由用户切到 `Pi Session:` 分组标签
   完成登录/验证码。

完整失败模式表与恢复步骤见 [pi-chrome-browser.md]({doc}) §7。

## Cookie：走回环 sink，不进对话

页面不能写文件，而把 `document.cookie` 打印进对话等于把会话凭证写进日志与模型上下文。

```bash
python3 {sink} --out /tmp/cnki_cookie.txt --port 17399 --timeout 240
```

```js
// 页面侧（chrome_evaluate）：立即返回，不 await
fetch('http://127.0.0.1:17399/c', {{ method: 'POST', body: document.cookie }})
  .then(r => r.status)
```

```bash
rm -f /tmp/cnki_cookie.txt     # 下载器用完立即删除
```

## 文件

| 路径 | 内容 |
|---|---|
| `extensions/chrome-profile-bridge/` | OMP 侧插件（桥接服务，监听 `127.0.0.1:17318`） |
| `{companion}/` | 伴生 Chrome 扩展（manifest v3，5 文件，含 `offscreen` 保活） |
| `package.json` | 插件元数据（`pi.extensions` 入口、版本） |
| [pi-chrome-browser.md]({doc}) | CNKI 适配协议：安装授权、目标模型、能力映射、失败模式表、Cookie 导出、与 ZCode 后端差异、实测记录 |
| [scripts/cnki/cookie_sink.py]({sink}) | Cookie 回环 sink（超时 rc=2，非法载荷 rc=3，0600 落盘） |
| [checksums.sha256](checksums.sha256) | 上述插件的逐字节校验清单 |
| [NOTICE.md](NOTICE.md) | 来源、许可、构建对照与维护说明 |

## 校验

```bash
shasum -a 256 -c checksums.sha256
```

## 来源与许可

- 插件代码来自 [{upstream_author}]({upstream_repo})，MIT 许可（`LICENSE` 原样保留）。
  本仓库**未修改**任何插件文件；只做分发与文档。
- CNKI 适配文档与 `cookie_sink.py` 属于 [{master}]({master}) / [{lit}]({lit}) 的文献模块，
  由 `scripts/export_pi_chrome_repo.py` 同步导出，请勿直接编辑本仓库。
- 本仓不含上游的 `docs/`、`test-suite/` 与上游 README：它们不影响插件的安装与运行。
"""

NOTICE = """# 来源、许可与构建对照

## 来源

| 项 | 值 |
|---|---|
| 上游项目 | pi-chrome（[{upstream_author}]({upstream_repo})） |
| 上游许可 | MIT，见 `LICENSE`（原样保留，未修改） |
| 本仓版本 | {version} |
| 构建指纹 | `{fingerprint}`（`checksums.sha256` 的 sha256 前 12 位） |
| 复制方式 | 逐字节复制，未做任何改写；只纳入运行所需的 `extensions/`、`package.json`、`LICENSE` |

## 为什么本仓自带插件

本仓的 {version} 与上游 npm 发布通道上的 {version} **同号不同构**。上游发布版的伴生扩展没有
MV3 `offscreen` 保活，Chrome 回收空闲 service worker 后桥接轮询即停止；Chrome 升级会加快 worker
回收，因此升级后集中表现为"扩展已加载但 `/chrome doctor` 连不上"。

| 文件 | 上游发布通道 | 本仓（本机实测可用） |
|---|---|---|
| `{companion}/manifest.json` | 无 `offscreen` 权限 | 含 `offscreen` 权限 |
| `{companion}/offscreen.html` | 不存在 | 存在 |
| `{companion}/offscreen.js` | 不存在 | 存在 |
| `{companion}/service_worker.js` | 无保活逻辑 | `ensureOffscreen()` + 启动即 `pollLoop()` |
| `{plugin_entry}` | 旧构建 | 含 private-network CORS、GET `/result`、重载处理等修复 |

因此本仓不使用、也不建议任何上游官方安装通道；升级路径见下。

## 维护

本仓由 `paper-master-4ss` 的 `scripts/export_pi_chrome_repo.py` 生成，**请勿直接编辑**：

```bash
python3 scripts/export_pi_chrome_repo.py                 # 从本机 pi-chrome 安装重导
python3 scripts/export_pi_chrome_repo.py --check         # 校验本仓与源逐字节一致
python3 scripts/export_pi_chrome_repo.py --zip-out /tmp  # 出伴生扩展 zip
python3 scripts/publish_family.py pi-chrome-mirror       # 推送
```

导出脚本内置两道闸门，任一不过即拒绝导出：

1. **完整性**：`manifest.json` 必须含 `offscreen` 权限；`offscreen.html`、`offscreen.js` 必须存在；
   `service_worker.js` 必须引用 `offscreen.html`；`package.json` 的 `pi.extensions` 入口必须存在。
2. **无官方安装通道**：生成物与 vendored 文本文件中不得出现上游官方安装指令（包管理器形式的 pi-chrome 引用，见脚本 `FORBIDDEN`）。

升级到新构建时：在本机装好并验证可用后，重跑导出（版本号与校验和随之更新），重建 release zip 并推送。
"""


def load_manifest(source: Path) -> dict:
    return json.loads(read_text(source / COMPANION / "manifest.json"))


def assert_completeness(source: Path) -> dict:
    """源必须含 offscreen 保活，否则拒绝导出（避免再发出一个连不上的包）。"""
    problems: list[str] = []
    manifest_path = source / COMPANION / "manifest.json"
    if not manifest_path.is_file():
        raise SystemExit(f"源缺少 {COMPANION}/manifest.json: {source}")
    if "offscreen" not in load_manifest(source).get("permissions", []):
        problems.append("manifest.json 缺 offscreen 权限（上游发布版即此症状）")
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


def assert_no_official_install(files: dict[str, bytes | str]) -> None:
    """生成物与 vendored 文件中不得残留上游官方安装通道。"""
    hits: list[str] = []
    for rel, data in files.items():
        text = data if isinstance(data, str) else data.decode("utf-8", "ignore")
        for needle in FORBIDDEN:
            if needle in text:
                hits.append(f"{rel}: {needle}")
    if hits:
        raise SystemExit("生成物中仍有上游安装通道痕迹，拒绝导出：\n  - " + "\n  - ".join(hits))


def rewrite_doc(text: str) -> str:
    """把包内相对引用改写为公开仓库/GitHub 绝对引用。"""
    # 源文件顶部的"公开文档指向本仓库"自指行在公开副本中剥除（NOTICE/README 已给出来源）。
    lines = text.splitlines(keepends=True)
    if lines and lines[0].startswith("# "):
        stripped = [line for line in lines[:4] if not line.startswith("> **公开文档**")]
        lines = stripped + lines[4:]
        text = "".join(lines)

    replacements = [
        ("[cnki-kns8s-closed-loop.md](cnki-kns8s-closed-loop.md)",
         f"[CNKI kns8s 闭环协议]({MASTER_REPO}/blob/main/modules/lit/references/cnki-kns8s-closed-loop.md)"),
        ("`references/runtime-adapter.md`", f"[`runtime-adapter.md`]({MASTER_REPO}/blob/main/references/runtime-adapter.md)"),
        ("`references/agent-software-adapters.md`",
         f"[`agent-software-adapters.md`]({MASTER_REPO}/blob/main/references/agent-software-adapters.md)"),
        (f"python3 modules/lit/scripts/cnki/cookie_sink.py", f"python3 {SINK_NAME}"),
        (f"`modules/lit/scripts/cnki/cookie_sink.py`", f"`{SINK_NAME}`"),
        (f"`modules/lit/scripts/cnki/kns8s-download.sh`", "`kns8s-download.sh`（见 paper-master-4ss）"),
    ]
    for old, new in replacements:
        text = text.replace(old, new)
    return text


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build(source: Path) -> dict[str, bytes | str]:
    pkg = assert_completeness(source)
    version = str(pkg["version"])

    vendored: dict[str, bytes] = {}
    for rel in VENDOR_FILES:
        path = source / rel
        if not path.is_file():
            raise SystemExit(f"源缺少运行所需文件: {rel}")
        vendored[rel] = path.read_bytes()

    checksums = "".join(f"{sha256_bytes(data)}  {rel}\n" for rel, data in sorted(vendored.items()))
    fingerprint = sha256_bytes(checksums.encode("utf-8"))[:12]

    files: dict[str, bytes | str] = dict(vendored)
    files[DOC_NAME] = rewrite_doc(read_text(DOC_SRC))
    files[SINK_NAME] = read_text(SINK_SRC)
    files["checksums.sha256"] = checksums
    files["NOTICE.md"] = NOTICE.format(
        upstream_author=UPSTREAM_AUTHOR,
        upstream_repo=UPSTREAM_REPO,
        version=version,
        fingerprint=fingerprint,
        companion=COMPANION,
        plugin_entry=PLUGIN_ENTRY,
    )
    files["README.md"] = README.format(
        doc=DOC_NAME,
        sink=SINK_NAME,
        companion=COMPANION,
        mirror=MIRROR_REPO,
        master=MASTER_REPO,
        lit=LIT_REPO,
        upstream_author=UPSTREAM_AUTHOR,
        upstream_repo=UPSTREAM_REPO,
        version=version,
    )
    files[".gitignore"] = ".DS_Store\n__pycache__/\n*.py[cod]\n*.log\n.env\n.env.*\n"

    assert_no_official_install(files)
    return files


def write_target(files: dict[str, bytes | str]) -> None:
    """清空受管文件后重写；保留 `.git`（推送从这里发出）。"""
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
    (TARGET / SINK_NAME).chmod(0o755)


def check_target(files: dict[str, bytes | str]) -> list[str]:
    drift: list[str] = []
    if not TARGET.is_dir():
        return [f"目标目录不存在: {TARGET}"]
    for rel, data in files.items():
        path = TARGET / rel
        if not path.is_file():
            drift.append(f"缺失: {rel}")
            continue
        expected = data if isinstance(data, bytes) else data.encode("utf-8")
        if path.read_bytes() != expected:
            drift.append(f"内容不同步: {rel}")
    for path in sorted(TARGET.rglob("*")):
        if not path.is_file() or ".git/" in path.as_posix():
            continue
        rel = path.relative_to(TARGET).as_posix()
        if rel not in files:
            drift.append(f"目标存在源中没有的文件: {rel}")
    return drift


def write_zip(source: Path, out_dir: Path) -> Path:
    version = str(json.loads(read_text(source / "package.json"))["version"])
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"pi-chrome-companion-{version}.zip"
    root = f"pi-chrome-companion-{version}"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted((source / COMPANION).rglob("*")):
            if path.is_file() and path.name != ".DS_Store":
                zf.write(path, f"{root}/{path.relative_to(source / COMPANION).as_posix()}")
    return zip_path


def main() -> int:
    parser = argparse.ArgumentParser(description="导出合并后的 pi-chrome 公开仓（插件 + CNKI 文档）")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE), help="本机已安装的 pi-chrome 目录")
    parser.add_argument("--check", action="store_true", help="只校验目标仓库与源是否一致")
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
    vendored = len([k for k in files if k in VENDOR_FILES])
    print(f"[pi-chrome-mirror] 导出完成: {TARGET}（vendored {vendored} + 生成 {len(files) - vendored} 文件）")
    print(f"[pi-chrome-mirror] 指纹: {sha256_bytes(str(files['checksums.sha256']).encode('utf-8'))[:12]}")

    if args.zip_out:
        print(f"[pi-chrome-mirror] 伴生扩展 zip: {write_zip(source, Path(args.zip_out).expanduser())}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
