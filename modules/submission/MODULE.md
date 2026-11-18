---
name: paper-submission-4ss
description: 中文社会科学论文投稿文件整备模块。用于将 Markdown 成稿导出为 Word，按用户模板或内置社会学研究范式模板检查格式，整理正文引用与文后参考文献，生成投稿清单、cover letter 与 response letter。
---

# Paper Submission 4SS：投稿文件整备

> 参数提示：[manuscript.md] [可选: --style sociological-research] [可选: --reference-doc template.docx]

本模块负责将定稿或接近定稿的 Markdown 文稿整备为可直接提交的投稿文件包，包括 Word 导出、版式检查、引文与参考文献整理、投稿清单、投稿信（cover letter）及审稿回复信（response letter）。

职责边界：本模块不执行正文实质重写或论证补救。论证与证据问题退回 `paper-check-report-*` 指向的模块（`design` / `lit` / `outline` / `analysis` / `write`）；语言扫描残留退回 `write`；本模块仅处理 Word 导出、引文体例、期刊模板与投稿附件整备。

## 路径约定

本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；在模块目录内直接运行时可使用 `references/...`、`scripts/...`、`templates/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md`。所有格式检查报告、引用整理报告、投稿清单、说明文件、顾问意见、综合文件与最终回复均使用中文 Markdown（引文条目、期刊名、模板名、命令与文件路径保留原文）；投稿整备流程、格式/引文并行核查链路、投稿包复核与退回路径须附 Mermaid 图及 2–4 句中文解释。`submission.docx` 按 Word 模板规范导出，不嵌入 Mermaid。

## 零、顾问派发规范

依据 `master/agent-orchestration.md` 确定派发档位。除单点依赖检查外，投稿整备任务应按需派发以下顾问（跳过轻量单文件检查时记录 `agent-skip`；执行身份以 `references/agent-registry.md` 标准名为准）：

| 审阅内容 | 对应顾问文件 |
|---|---|
| 版式规范、Word 导出、模板适配、标题层级与正文/文后引文一致性 | `modules/submission/agents/conformance-consultant.md` |
| 投稿包完整性、声明材料、cover/response letter 与退回裁决 | `modules/submission/agents/journal-package-consultant.md` |

默认顺序：先派发 `paper-submission-conformance-consultant` 统筹版式与引文核查，生成 `paper-workspace/_logs/agents/submission-[YYYY-MM-DD]/agent-synthesis-submission-[YYYY-MM-DD].md` 后，再派发 `paper-submission-journal-package-consultant` 进行投稿包终审。运行环境不支持并行时按序复核并记录 `sequential-review`。

## 0. 依赖前置验收

执行导出、格式核查或引文整理前，先读取并验证 `modules/submission/references/install-dependencies.md`。必需依赖未满足时不得生成 `submission.docx`，须在回复中报告缺失项与安装命令。

## 1. 输入优先级与导出拦截

按以下优先级定位稿件与题录来源：

1. 用户显式指定的 Markdown、Word 模板或题录文件；
2. `paper-workspace/05-writing/` 下的 `manuscript.md` 或最新正文净稿 `manuscript-[slug]-[YYYY-MM-DD].md`；
3. `paper-workspace/05-writing/revisions/` 下最新风格统一净稿 `styled-[slug]-[YYYY-MM-DD].md`；
3a. 最新 `paper-workspace/05-writing/reviews/paper-check-report-*`（及对应矩阵、修订清单）。若总体结论为 `不建议当前投稿` 或 `大修后复审`，默认禁止导出 Word，除非用户显式确认覆盖并在过程日志记录风险；
4. `paper-workspace/05-writing/drafts/` 与扫描报告（仅作追溯，不作为默认投稿输入）；
5. `paper-workspace/02-literature/` 下的 `paper-registry.csv`、`literature-map.md` 及检索日志 `paper-workspace/_logs/paper-search-log-*.md`；
6. 用户补充提供的 `.bib`、`.ris`、`.csv`、`.md` 题录文件。

**净稿与文献准入边界**：
- 文献补全以 `write` 阶段实际写入正文的文献为准，`lit` 阶段材料仅作题录字段补充库，严禁将未进入正文的文献自动插入文后参考文献；
- 导出 Word 前须核实输入稿非内部 `draft-[slug]-[date].md`，且不含任务包、source 注释、材料清单、Markdown 表格或 Mermaid 等过程痕迹；若检出过程痕迹，退回 `write` 重新输出净稿。

## 2. 输出目录

```bash
mkdir -p paper-workspace/06-submission paper-workspace/_logs
```

标准产出路径：

```text
paper-workspace/06-submission/
├── submission.docx
├── format-check-report.md
├── citation-normalized.md
├── citation-gap-report.md
├── submission-checklist.md
├── cover-letter.md
└── response-letter.md
```

过程日志写入 `paper-workspace/_logs/process-log-submission-[YYYY-MM-DD].md`。

## 3. 执行流程

### 3.1 依赖核查

依据 `references/install-dependencies.md` 核查：`pandoc`、`python3`、`python-docx`（`docx`）与 `lxml`。

### 3.2 模板与样式优先级

1. **用户自定义 Word 模板**：传入 `--reference-doc`，覆盖内置模板；
2. **内置社会学研究范式模板（`sociological-research`）**：使用 `templates/sociological-research-default.docx`。该模板仅保留样式、页边距、页脚页码与编号等版式资产，不含范文正文、表格、图片或参考文献。

中文社科稿件未指定样式时默认采用 `sociological-research`。导出前后不得破坏模板既有的字体、字号、行距、正文缩进与参考文献悬挂缩进；导出投稿稿默认移除标题自动分页，防止 `Heading 2` 等样式引发异常换页。格式检查结果中的阻断项须同步写入 `agent-synthesis-submission-[YYYY-MM-DD].md` 与 `format-check-report.md`。

### 3.3 Markdown 转 Word 与段落清洗

导出前由 `export_docx.py` 自动执行预处理：
- 移除文件开头 YAML frontmatter（`--- ... ---` 或 `--- ... ...`）；
- 移除正文独立成行的 Markdown 分割线（`---`、`***`、`___`），保留表格分隔行与代码块内部内容，防止分割线或元数据边界被导入 Word。

导出后由 `sanitize_reference_docx.py` 自动执行段落清洗：
- `Heading 1` / `Heading 2` / `Heading 3`（及中文对应样式 `标题 1` / `标题 2` / `标题 3`）首行缩进必须清零；若标题继承正文首行缩进（如两字符或约 `0.74 cm`），视为导出不合格并重新清洗；
- 主标题采用 `Heading 1` / `标题 1`（居中、无首行缩进、无左缩进、无字符缩进、无文本前导空格）；
- 主标题后的非三级标题统一采用 `Heading 2` / `标题 2`；`（一）...` 等中文三级标题保留 `Heading 3` / `标题 3`；`1. ...`、`1、...`、`（1）...` 等数字小标题统一采用正文 `Normal`；
- `Heading 1/2/3` 不得携带 `pageBreakBefore`、`keepNext` 或 `keepLines` 等分页控制属性；
- `摘要：`、`关键词：`、`Abstract`、`Keywords`、作者信息、基金项目、图题与表题等标签段落不得继承正文首行缩进，也不得保留文本前导空格或全角空格。

默认模板导出命令：

```bash
python3 modules/submission/scripts/export_docx.py \
  path/to/manuscript.md \
  --style sociological-research \
  --out paper-workspace/06-submission/submission.docx
```

自定义模板导出命令：

```bash
python3 modules/submission/scripts/export_docx.py \
  path/to/manuscript.md \
  --reference-doc path/to/template.docx \
  --out paper-workspace/06-submission/submission.docx
```

### 3.4 Word 格式校验

```bash
python3 modules/submission/scripts/check_docx_format.py \
  paper-workspace/06-submission/submission.docx \
  --source-md path/to/manuscript.md \
  --style sociological-research \
  --out paper-workspace/06-submission/format-check-report.md
```

核查要素涵盖标题、作者单位、中英文摘要、关键词、正文、注释、参考文献、作者简介、联系方式、页边距、标题层级、字号与行距，并检查 3.3 节全部导出清洗规则。任一项不通过须写入 `format-check-report.md` 并退回重新导出清洗。

### 3.5 引文与参考文献整理

依据 `references/citation-rules.md` 执行，支持识别 `张三（2020）`、`（张三，2020）`、`Smith (2020)`、`(Smith, 2020)`、`[@smith2020]` 及脚注式引用。按目标样式统一正文夹注并生成或校对文后参考文献列表；`write` 与 `lit` 材料中均无法确认的题名、期刊、年份、页码或 DOI 字段一律写入 `citation-gap-report.md`，严禁补造。顾问复核结论同步写入 `agent-synthesis-submission-[YYYY-MM-DD].md`。

```bash
python3 modules/submission/scripts/check_citations.py \
  path/to/manuscript.md \
  --write-root paper-workspace/05-writing \
  --lit-root paper-workspace/02-literature \
  --style sociological-research \
  --out-normalized paper-workspace/06-submission/citation-normalized.md \
  --out-gap paper-workspace/06-submission/citation-gap-report.md
```

## 4. 模块资源索引

| 文件 | 用途 |
|---|---|
| `references/install-dependencies.md` | 依赖检查、安装与验收 |
| `references/journal-style-sociological-research.md` | 《社会学研究》公开投稿要求与《社会》撰稿体例参照 |
| `references/citation-rules.md` | GB/T 7714、APA 及中文社会学夹注体例规范 |
| `templates/sociological-research-default.docx` | 内置社会学研究范式 Word 版式模板 |
| `scripts/sanitize_reference_docx.py` | 清理模板与导出稿中的标题分页、标题缩进及标签段落缩进 |
| `scripts/export_docx.py` | Markdown 预处理、Word 导出及后处理清洗 |
| `scripts/check_citations.py` | 按 `write` 优先、`lit` 补充顺序执行引文匹配与缺口报告 |

## 5. 执行约束与投稿包终审

**执行边界**：
- 用户模板优先于内置模板；
- 格式报告须标明每项要求属于「期刊公开官方要求」还是「体例参照来源」；
- 缺漏题录字段仅报告缺口，不得编造；
- 不替代 `write` 重写正文，不把未被正文引用的 `lit` 文献自动插入参考文献，不将内置模板冒称为某期刊官方模板。

**投稿包最终复核**：生成 `submission-checklist.md`、cover letter 或 response letter 后，须派发 `paper-submission-journal-package-consultant` 裁决投稿包完整性与缺失声明。论证或证据问题退回 `check` 清单指向模块；格式或题录问题退回 `write`、`lit` 或请用户补充；严禁用排版模板掩盖未解决的论证或诚信缺陷。

## 6. 交付汇报清单

1. 输入稿件路径与 `submission.docx` 输出路径；
2. Word 成稿、格式检查报告、引文规范化报告与缺口报告路径；
3. 已通过与未通过的投稿核查项；
4. 需退回 `check` 指向模块、`write`、`lit` 或待用户补充的具体事项及 `agent-synthesis` 中的投稿包状态。
