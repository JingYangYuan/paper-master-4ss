#!/usr/bin/env python3
"""把导出的独立包与公开文档副本推送到各自的 GitHub 公开仓。

对应 `export_standalone.py` 头部写的同步纪律：改任一模块后，无参数重新导出全部
独立包，再 push 全部 GitHub 仓——本脚本负责后半段。

每个仓库使用一个常驻缓存克隆（`~/.skills-manager/.publish-cache/<repo>`），
用 rsync `--delete` 使工作区与导出目录完全一致（保留 `.git`）。无差异则跳过，
不产生空提交。

用法：
    python3 scripts/publish_family.py                 # 同步并推送全部
    python3 scripts/publish_family.py lit pi-chrome-mirror  # 只推送指定仓库
    python3 scripts/publish_family.py --dry-run       # 只显示将发生的变化
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

PKG_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PKG_ROOT.parent
CACHE_ROOT = Path.home() / ".skills-manager" / ".publish-cache"
OWNER = "JingYangYuan"

# (键, 本地导出目录名, GitHub 仓库名)
TARGETS = [
    ("master", "paper-master-4ss", "paper-master-4ss"),
    ("design", "paper-design-4ss", "paper-design-4ss"),
    ("lit", "paper-lit-4ss", "paper-lit-4ss"),
    ("outline", "paper-outline-4ss", "paper-outline-4ss"),
    ("analysis", "paper-analysis-4ss", "paper-analysis-4ss"),
    ("write", "paper-write-4ss", "paper-write-4ss"),
    ("check", "paper-check-4ss", "paper-check-4ss"),
    ("submission", "paper-submission-4ss", "paper-submission-4ss"),
    ("update", "paper-update-4ss", "paper-update-4ss"),
    ("mechanigraph", "paper-mechanigraph-4ss", "paper-mechanigraph-4ss"),
    ("pi-chrome-mirror", "pi-chrome-mirror", "pi-chrome-mirror"),
]

COMMIT_MESSAGE = "sync: 重导独立包与 pi-chrome 离线发行仓（github.com/{owner}/pi-chrome-mirror）"


def run(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        raise SystemExit(f"命令失败 ({result.returncode}): {' '.join(cmd)}\n{result.stderr.strip()[:500]}")
    return result


def ensure_clone(repo: str, dry_run: bool) -> Path:
    CACHE_ROOT.mkdir(parents=True, exist_ok=True)
    clone = CACHE_ROOT / repo
    if clone.exists():
        return clone
    url = f"https://github.com/{OWNER}/{repo}.git"
    if dry_run:
        print(f"  [dry-run] 将克隆 {url} 到 {clone}")
        return clone
    run(["git", "clone", "--quiet", url, str(clone)])
    return clone


def sync_and_push(local: Path, repo: str, dry_run: bool, message: str) -> str:
    clone = ensure_clone(repo, dry_run)
    if dry_run:
        print(f"  [dry-run] rsync {local}/ → {clone}/（保留 .git）")
        return "dry-run"

    if not local.is_dir():
        return f"源目录缺失: {local}"

    run(["git", "-C", str(clone), "fetch", "--quiet", "origin"])
    run(["git", "-C", str(clone), "checkout", "--quiet", "--force", "main"])
    run(["git", "-C", str(clone), "reset", "--quiet", "--hard", "origin/main"])

    rsync = shutil.which("rsync")
    if rsync:
        run([
            rsync, "-a", "--delete",
            "--exclude", ".git/",
            "--exclude", ".zcode/",
            "--exclude", ".DS_Store",
            "--exclude", "__pycache__/",
            f"{local}/", f"{clone}/",
        ])
    else:
        raise SystemExit("缺少 rsync；请安装 rsync 后重试")

    run(["git", "-C", str(clone), "add", "-A"])
    staged = run(["git", "-C", str(clone), "diff", "--cached", "--quiet"], check=False)
    if staged.returncode == 0:
        return "已是最新，跳过"

    run(["git", "-C", str(clone), "commit", "--quiet", "-m", message])
    run(["git", "-C", str(clone), "push", "--quiet", "origin", "main"])
    head = run(["git", "-C", str(clone), "rev-parse", "--short", "HEAD"]).stdout.strip()
    return f"已推送 {head}"


def main() -> int:
    parser = argparse.ArgumentParser(description="推送独立包与公开文档到 GitHub")
    parser.add_argument("keys", nargs="*", help=f"要推送的键（默认全部）: {', '.join(k for k, _, _ in TARGETS)}")
    parser.add_argument("--dry-run", action="store_true", help="只报告将发生的变化")
    parser.add_argument("--message", default=None, help="覆盖提交信息")
    args = parser.parse_args()

    selected = TARGETS
    if args.keys:
        wanted = set(args.keys)
        unknown = wanted - {k for k, _, _ in TARGETS}
        if unknown:
            parser.error(f"未知键: {', '.join(sorted(unknown))}")
        selected = [t for t in TARGETS if t[0] in wanted]

    message = args.message or COMMIT_MESSAGE.format(owner=OWNER)
    changed = 0
    for key, local_name, repo in selected:
        local = REPO_ROOT / local_name
        print(f"[{key}] {local_name} → {OWNER}/{repo}")
        try:
            status = sync_and_push(local, repo, args.dry_run, message)
        except SystemExit as exc:
            print(f"  失败: {exc}")
            return 1
        print(f"  {status}")
        if status.startswith("已推送"):
            changed += 1

    print(f"\n推送 {changed} 个仓库，检查 {len(selected)} 个。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
