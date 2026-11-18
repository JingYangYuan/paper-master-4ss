---
base-id: submission-2026.10.24
module: submission
---

# submission 模块参考库回查底座

本文件是 `submission` 模块 2 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=submission-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

投稿整备阶段将已定稿的正文转化为符合目标期刊技术要求、结构完整且引文一致的投稿材料包。本模块不修改核心论证或补充证据，仅在版式、引文对应关系与投稿附件完整性上把关。

版式核查、引文一致性与投稿包组装须协同处理。版式核查关注标题、作者单位、摘要、关键词、正文、注释、参考文献、附录与作者信息等要素是否齐全，以及 Word 导出后的页边距、字体字号、行距、标题层级、分页、标题缩进清零与独立 Markdown 分割线清除。引文核查关注正文夹注与文后参考文献的一一对应、题录字段完整性（作者、年份、题名、期刊、卷期、页码、DOI）及体例统一性（GB/T 7714、APA 或中文社会学夹注）。

关键禁止事项：严禁将未在正文中实际引用的文献自动补入文后参考文献；题录字段缺失时仅可标注缺口并退回 `lit` 或请用户补充，不得依据相似标题自行补全。

投稿包终审以「是否满足编辑部技术初筛」为准绳：文件齐全度、命名一致性、cover letter 与 response letter 是否匹配当前稿件状态，以及伦理、署名、基金、利益冲突、数据可用性声明是否完备。须准确分流「本模块内可修复的格式问题」与「须退回 `write`/`lit`/用户的内容或证据问题」，不得用排版掩盖实质缺陷。

## B2 判据条目

C01 版式要素齐全：标题、作者单位、摘要、关键词、正文、注释、参考文献、附录与作者信息完备（`references/journal-style-sociological-research.md` §必检要素）。

C02 Word 导出与排版合规：核查模板、页边距、字号、行距、标题层级与分页；标题不得继承正文首行缩进，正文不得残留独立 Markdown 分割线（`---`/`***`/`___`）。

C03 引用体例统一：按目标期刊选定 GB/T 7714、APA 或中文社会学夹注体例并保持全篇一致（`references/citation-rules.md`）。

C04 引文—文献一一对应：正文引用均可匹配文后条目，文后无未被正文引用的多余条目。

C05 题录字段缺口标注：作者、年份、题名、期刊、卷期、页码、DOI 缺失时逐条标注「待核验/缺口」，不得推测补全。

C06 禁止自动补录未引用文献：严禁将未进入正文的文献加入参考文献列表。

C07 投稿包文件齐全：`submission.docx`、格式检查报告、引文缺口报告、投稿清单、cover/response letter、声明材料与作者信息按期刊要求齐备且命名一致。

C08 学术声明完整：伦理、署名、基金、利益冲突与数据可用性声明逐项核对，缺项记为阻断或重要。

C09 信件状态一致：cover letter 与 response letter 的版本、审稿轮次与贡献陈述与稿件当前状态相符。

C10 退回分流准确：明确区分模块内可修格式项与须退回 `write`/`lit`/用户处理的内容或题录项。

C11 技术初筛风险预判：从编辑部初筛视角标出会导致技术退回的缺项及提交前必做清单。

C12 职责边界遵守：不修改论证、不补做证据、不虚构期刊要求、不声称已完成未执行的期刊特定核验。

C13 可追溯要求：判断指向具体体例条款、模板位置、脚本输出或期刊公开要求；缺失标「待核验」。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-submission-conformance-consultant` | C01 C02 C03 C04 C05 C06 C13 | `references/citation-rules.md`、`references/journal-style-sociological-research.md`、`references/install-dependencies.md`、`scripts/` 说明 | T2（引用诚信风险） |
| `paper-submission-journal-package-consultant` | C07 C08 C09 C10 C11 C12 C13 | `references/journal-style-sociological-research.md` §报告写法、投稿清单、cover/response letter、声明材料 | T1 |

L1 默认单点角色：`paper-submission-conformance-consultant`（统筹版式规范与引文一致性）。
