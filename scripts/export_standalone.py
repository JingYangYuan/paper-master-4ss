#!/usr/bin/env python3
"""Export paper-master-4ss modules as standalone skills.

The monolith package (paper-master-4ss/) is the single source of truth; each
modules/<m>/ is exported to ../paper-<m>-4ss/ as a self-contained skill:

- module content lands at the package root;
- the master/ protocol files and the governance references are copied in so
  every bare `master/...` / `references/...` path resolves inside the package;
- analysis additionally gets scripts/ (guard + registrar), lit additionally
  gets design/frame/ (the discipline framework library it routes to);
- paths are rewritten: self-module paths become package-relative, other-module
  paths keep pointing at the sibling paper-master-4ss package;
- each SKILL.md gets a path-convention note and each package a README.

Usage:
  python3 scripts/export_standalone.py            # export all modules
  python3 scripts/export_standalone.py lit write  # export selected modules
  python3 scripts/export_standalone.py --check    # verify only, no writes
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

PKG_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PKG_ROOT.parent

MODULES = ["design", "lit", "outline", "analysis", "write", "submission", "update"]
MODULE_TITLES = {
    "design": "研究设计",
    "lit": "文献综述",
    "outline": "论文大纲",
    "analysis": "数据分析",
    "write": "论文写作",
    "submission": "投稿整备",
    "update": "知识更新",
}
MASTER_FILES = [
    "agent-orchestration.md",
    "handoff-checklists.md",
    "input-registry.md",
    "literature-review-protocol.md",
    "output-protocol.md",
    "routing-matrix.md",
    "user-journey.md",
    "workspace-contract.md",
]
GOVERNANCE_REFS = [
    "agent-registry.md",
    "agent-software-adapters.md",
    "ask-user-question-examples.md",
    "claude-team-config.md",
    "claude-md-writing-layer.md",
    "evaluation-rubric.md",
    "hooks-and-evaluation.md",
    "install-dependencies.md",
    "runtime-adapter.md",
    "team-routing.md",
]
SCRIPT_FILES = ["paper_master_guard.py", "register_zcode_hooks.py"]
TEXT_SUFFIXES = {".md", ".py", ".do", ".R", ".sh", ".js", ".json"}
SKIP_NAMES = {".env.kie", ".DS_Store"}

CHECK_PREFIXES = [
    "references/",
    "master/",
    "agents/",
    "phases/",
    "frame/",
    "design/frame/",
    "scripts/",
    "templates/",
    "chapters/",
    "resources/",
    "examples/",
]

NOTE_TEMPLATE = (
    "> **拆分版路径约定**：本包由 `paper-master-4ss/scripts/export_standalone.py` 从 "
    "`paper-master-4ss/modules/{module}/` 自动导出，是可独立安装的运行版。包内相对路径"
    "（`agents/`、`phases/`、`references/`、`master/` 等）相对本包根目录解析；跨模块路径 "
    "`paper-master-4ss/modules/<x>/...` 相对同级安装的 `paper-master-4ss/` 总控包解析。"
    "请勿直接编辑本包：修改总控模块后重新导出。\n"
)

README_TEMPLATE = """{banner}# Paper {title} 4SS

{description}

{family}
{extra}
## 安装

将本目录放到宿主的 skill 目录。入口见 `SKILL.md`。

```bash
git clone https://github.com/JingYangYuan/paper-{module}-4ss.git
```

与 [`paper-master-4ss`](https://github.com/JingYangYuan/paper-master-4ss) 同级安装时，跨模块路径才能解析。只做本模块任务也可以单独使用。

## 与总控的关系

本包由总控 [`paper-master-4ss`](https://github.com/JingYangYuan/paper-master-4ss) 导出；对应源目录是总控包内的 `modules/{module}/`：

- 包内相对路径相对本包根目录解析
- `master/` 与部分 `references/` 是导出时的协议快照
- 更新方式：修改总控对应模块后重新导出，不要直接改本仓库

## License

[MIT](LICENSE)
"""

FAMILY_ROWS = [
    ("master", "paper-master-4ss", "总控：登记输入、选择模块、维护工作区"),
    ("design", "paper-design-4ss", "选题、框架路由、研究设计蓝图"),
    ("lit", "paper-lit-4ss", "中英文检索、文献地图、空白与假设"),
    ("outline", "paper-outline-4ss", "素材转大纲、证据映射、缺口报告"),
    ("analysis", "paper-analysis-4ss", "定量 / 质性 / 混合，Stata · R · Python"),
    ("write", "paper-write-4ss", "章节写作、润色、语言扫描、正文净稿"),
    ("submission", "paper-submission-4ss", "Word 导出、体例、投稿清单与信函"),
    ("update", "paper-update-4ss", "待审核更新包，不直接改核心文件"),
]


def family_table(module: str) -> str:
    lines = ["## 4SS 家族", "", "| 包 | 职责 |", "|---|---|"]
    for key, name, role in FAMILY_ROWS:
        url = f"https://github.com/JingYangYuan/{name}"
        if key == module:
            lines.append(f"| **[{name}]({url})**（本仓库） | {role} |")
        else:
            lines.append(f"| [{name}]({url}) | {role} |")
    return "\n".join(lines)


MODULE_README_EXTRA = {
    "design": """
## 它做什么

把研究主题路由到 14 个学科框架库，并在 FRAME / STORM / DESIGN / FULL 中选一条执行。模式确认后必须再确认研究取向（实证、概念/解释理论、规范理论、思想史/文本阐释、混合），不预设理论或实证。

## 四种模式

| 模式 | 用途 |
|---|---|
| FRAME | 框架锚定与学科定位 |
| STORM | 跨学科头脑风暴 |
| DESIGN | 研究设计蓝图 |
| FULL | 从框架走到完整设计 |

先读 `references/researcher-agency-overlay.md`。不自动连续推进阶段。
""",
    "lit": """
## 它做什么

按固定检索顺序做中英文文献综述：方向确认 → WebSearch → 本地库 / Zotero MCP（可选）→ Annual Reviews → 引文链 → CNKI / Google Scholar 精准补充 → 文献地图。模式 D 才推导假设。

Zotero 是可选增强。启用后按 `references/zotero-local-mcp.md` 做能力检查、本地库检索、摘要即时入库和全文深读；未启用不得强制安装。

## 五种模式

| 模式 | 用途 |
|---|---|
| A 完整地图 | 6 轮以上检索，40–80 篇 |
| B 定向综述 | 4 轮，15–30 篇 |
| C 快速概览 | 2 轮，10–20 篇 |
| D 综述+假设 | 5 轮以上，含假设推导 |
| E 知网专项 | CNKI kns8s 闭环为主 |

CNKI 依赖可见浏览器控制；Google Scholar 用 WebFetch/WebSearch。
""",
    "outline": """
## 它做什么

把已有文献素材转成可直接用于写作的结构化大纲：材料扫描 → 结构构建 → 段落级证据映射 → 缺口报告。

## 双轨与协议

| 项 | 选项 |
|---|---|
| 输出轨道 | 毕业论文（五章） / 期刊论文（五要素） |
| 方法协议 | 规范、实证、阐释、混合 |
| 发表风格 | 社会学研究范式 / 管理世界案例研究范式 |
""",
    "analysis": """
## 它做什么

把结构化数据、面板、访谈/田野/开放题文本和政策档案转成可复现的清洗脚本、估计结果、质性编码和论文结果素材。内置 Stata、R、Python 三语言模板。

不替代 design 的识别策略裁决；结果声称边界交给 write。Stata MCP / 本地 Stata 按 `references/install-dependencies.md` 验收。
""",
    "write": """
## 它做什么

先经研究方法协议与发表范式双层路由，再按章节标准和范文提示词写作、润色和检查。产出正文净稿（标题层级 + 自然段），过程材料不得拼进正文。

配备 `writing_scanner.py` 与 `complexity_analyzer.py`，用于语言反模式扫描和文本复杂度诊断。

## 路由

| 层 | 选项 |
|---|---|
| 方法协议 | 规范、实证、阐释、混合 |
| 发表风格 | 社会学研究范式 / 管理世界案例研究范式 |
""",
    "submission": """
## 它做什么

把接近完成的 Markdown 成稿转成投稿包：Word 导出、格式对照、正文引用与文后参考文献整理、投稿清单、cover letter 与 response letter。

不负责大规模重写正文；论证或语言问题写入检查报告并回流 write。Word 导出依赖 pandoc。
""",
    "update": """
## 它做什么

从专著、教材、论文、课程材料、笔记和方法手册生成**待人工审核**的更新包，可指向 design、lit、outline、analysis、write、submission 与 update 自身。

只写到 `paper-workspace/07-update/`，不得直接修改任何核心模块文件。合并进总控必须经人工确认。
""",
}



def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def rewrite_paths(text: str, module: str) -> str:
    others = [m for m in MODULES if m != module]

    if module == "lit":
        text = text.replace("paper-master-4ss/modules/design/frame/", "design/frame/")
        text = text.replace("modules/design/frame/", "design/frame/")

    for other in others:
        text = re.sub(
            r"(?<!paper-master-4ss/)modules/" + re.escape(other) + r"/",
            f"paper-master-4ss/modules/{other}/",
            text,
        )

    text = text.replace(f"paper-master-4ss/modules/{module}/", "")
    text = text.replace(f"modules/{module}/", "")
    text = text.replace("paper-master-4ss/master/", "master/")
    text = text.replace("paper-master-4ss/references/", "references/")
    text = text.replace("paper-master-4ss/scripts/", "scripts/")
    return text


def insert_note(text: str, module: str) -> str:
    if "拆分版路径约定" in text:
        return text
    lines = text.splitlines(keepends=True)
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                lines.insert(i + 1, "\n" + NOTE_TEMPLATE.format(module=module))
                return "".join(lines)
    return NOTE_TEMPLATE.format(module=module) + text


def copy_tree(src: Path, dst: Path) -> None:
    for item in src.rglob("*"):
        if item.name in SKIP_NAMES or item.is_dir():
            continue
        if item.name == ".env.kie":
            continue
        rel = item.relative_to(src)
        target = dst / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)


def rewrite_text_files(target: Path, module: str) -> int:
    count = 0
    for item in sorted(target.rglob("*")):
        if not item.is_file() or item.suffix not in TEXT_SUFFIXES:
            continue
        text = read_text(item)
        new = rewrite_paths(text, module)
        if item.name == "SKILL.md" and item.parent == target:
            new = insert_note(new, module)
        if new != text:
            item.write_text(new, encoding="utf-8")
            count += 1
    return count


def check_package(target: Path) -> list[str]:
    broken: list[str] = []
    for item in sorted(target.rglob("*")):
        if not item.is_file() or item.suffix not in TEXT_SUFFIXES:
            continue
        rel = item.relative_to(target)
        # master/ 协议与治理 references 是导出快照，保留总控包上下文，不做严格检查；
        # update 的 targets/ 是外部模块命名空间映射，按设计指向其他包
        if rel.parts[0] == "master" or item.name in GOVERNANCE_REFS or "targets/" in str(rel):
            continue
        text = read_text(item)
        for raw in re.findall(r"[A-Za-z0-9_*][A-Za-z0-9_./*-]*", text):
            token = raw.rstrip("./-")
            if not token or token.endswith(".") or token.endswith("/"):
                continue  # 行文省略号或目录名提及，非具体路径
            if not any(token.startswith(p) for p in CHECK_PREFIXES):
                continue
            if token.endswith(".env.kie"):
                continue  # 记载用户级 token 文件，按设计不随包分发
            stem = token.split("*")[0].rstrip("/")
            if not stem:
                continue
            candidates = [target / stem, item.parent / stem]
            if any(c.exists() for c in candidates):
                continue
            first = stem.split("/")[0]
            first_ok = any(c.exists() for c in [target / first, item.parent / first])
            if first_ok and ("*" in token or stem.endswith(("-", "_"))):
                continue  # 通配/占位路径（含 [学科] 类中文占位），只要求所在目录存在
            if "." not in stem.rsplit("/", 1)[-1]:
                parent = stem.rsplit("/", 1)[0] if "/" in stem else "."
                if any(c.exists() for c in [target / parent, item.parent / parent]):
                    continue  # 家族/前缀式提及（无扩展名），只要求所在目录存在
            if re.search(r"-[A-Za-z]\.md$", stem):
                continue  # 行文示例文件名（如 theory-frameworks-X.md）
            broken.append(f"{rel}: {token}")
    return broken


def make_readme(target: Path, module: str) -> None:
    skill_md = target / "SKILL.md"
    description = ""
    if skill_md.exists():
        match = re.search(r"^description:\s*(.+)$", read_text(skill_md), re.MULTILINE)
        if match:
            description = match.group(1).strip().strip('"').strip("'")
    banner = ""
    if (target / "docs" / "banner.svg").is_file():
        banner = (
            '<p align="center">\n'
            f'  <img src="docs/banner.svg" alt="paper-{module}-4ss" width="100%">\n'
            "</p>\n\n"
        )
    (target / "README.md").write_text(
        README_TEMPLATE.format(
            title=MODULE_TITLES[module],
            module=module,
            description=description,
            banner=banner,
            extra=MODULE_README_EXTRA.get(module, ""),
            family=family_table(module),
        ),
        encoding="utf-8",
    )


def export(module: str) -> tuple[list[str], int, int]:
    src = PKG_ROOT / "modules" / module
    target = REPO_ROOT / f"paper-{module}-4ss"
    if not src.is_dir():
        raise SystemExit(f"模块不存在: {src}")
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)

    copy_tree(src, target)

    master_dst = target / "master"
    master_dst.mkdir(exist_ok=True)
    for name in MASTER_FILES:
        shutil.copy2(PKG_ROOT / "master" / name, master_dst / name)

    refs_dst = target / "references"
    refs_dst.mkdir(exist_ok=True)
    for name in GOVERNANCE_REFS:
        dst = refs_dst / name
        if not dst.exists():
            shutil.copy2(PKG_ROOT / "references" / name, dst)

    scripts_dst = target / "scripts"
    scripts_dst.mkdir(exist_ok=True)
    for name in SCRIPT_FILES:
        shutil.copy2(PKG_ROOT / "scripts" / name, scripts_dst / name)

    if module == "lit":
        frame_dst = target / "design" / "frame"
        frame_dst.mkdir(parents=True, exist_ok=True)
        for frame in sorted((PKG_ROOT / "modules" / "design" / "frame").glob("*.md")):
            shutil.copy2(frame, frame_dst / frame.name)

    rewritten = rewrite_text_files(target, module)
    make_readme(target, module)
    broken = check_package(target)
    return broken, rewritten, sum(1 for _ in target.rglob("*") if _.is_file())


def main() -> int:
    parser = argparse.ArgumentParser(description="导出 modules/<m> 为独立 skill")
    parser.add_argument("modules", nargs="*", help="要导出的模块名（默认全部）")
    parser.add_argument("--check", action="store_true", help="只验证已导出包，不写入")
    args = parser.parse_args()

    selected = args.modules or MODULES
    for m in selected:
        if m not in MODULES:
            parser.error(f"未知模块: {m}（可选: {', '.join(MODULES)}）")

    if not args.check:
        for m in selected:
            broken, rewritten, total = export(m)
            target = REPO_ROOT / f"paper-{m}-4ss"
            print(f"[{m}] 导出完成: {target}（{total} 文件，改写 {rewritten} 个文本文件）")
            if broken:
                print(f"[{m}] 路径自检发现 {len(broken)} 处可疑引用:")
                for b in broken[:10]:
                    print(f"  - {b}")
            else:
                print(f"[{m}] 路径自检通过")
        return 0

    failed = False
    for m in selected:
        target = REPO_ROOT / f"paper-{m}-4ss"
        if not target.is_dir():
            print(f"[{m}] 未导出: {target}")
            failed = True
            continue
        broken = check_package(target)
        if broken:
            failed = True
            print(f"[{m}] 路径自检发现 {len(broken)} 处可疑引用:")
            for b in broken[:10]:
                print(f"  - {b}")
        else:
            print(f"[{m}] 路径自检通过: {target}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
