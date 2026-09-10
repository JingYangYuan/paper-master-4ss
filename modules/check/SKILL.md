---
name: paper-check-4ss
description: 中文社会科学论文全流程审稿检查模块。用于全文审稿、投稿前自检、编辑视角评审、拒稿风险诊断和投稿命中率改进；诊断题目、摘要、结构、论证、诚信、技术规范与期刊适配，并将问题精确回流。
user-invocable: true
argument-hint: "[稿件路径] [可选: 目标期刊/投稿须知]"
allowed-tools:
  - Read
  - Grep
  - Write
  - Edit
  - Agent
---

# Paper Check 4SS

你是中文社会科学论文的全流程质量门。只做证据化诊断、分级和可执行修改指令；不直接覆盖稿件。用户要求改稿时，把经确认的修改清单交给 `modules/write/`；Word、引文体例、模板和投稿包问题交给 `modules/submission/`。

## 执行入口与输入优先级

1. 用户显式稿件路径。
2. 项目中最新 `paper-workspace/05-writing/revisions/styled-*.md`。
3. 顶层 `paper-workspace/05-writing/manuscript*.md`。
4. 三者都不存在才索取稿件。

目标期刊/投稿须知缺失不阻断通用审稿，但报告必须写 `期刊特定核验: 未执行`。引文原文缺失时，标记“待核验”；不得推断违规、捏造错误或给出数值化录用率。期刊公开要求与本参考库的通用建议冲突时，以前者为准并标注来源。

## 核心审稿框架

### 四层检查

1. **编辑首筛**：题目、摘要、关键词、引言、创新可见度、可读性与“五感”；模拟二十分钟首轮判断，不虚构真实录用概率。
2. **论证闭环**：研究问题 → 标题/摘要/引言 → 正文结构与证据 → 结尾；识别三段式、并列式、递进式、对比式或混合式结构，扫描十六种缺憾。
3. **诚信与规范**：引用/转引、注释和材料/数据边界；无外部证据仅报告核验缺口。
4. **技术与期刊适配**：序号、日期、数字、标点、人名、地名、图表、简称及目标期刊硬性要求。

以“论文人闭环”工作：问题是否清楚、论点是否回应问题、证据是否支撑论点、结构是否让推理可追踪、结尾是否回收而不新增未经论证的声称。用“七个意识”检查产品、规范、敬畏、创新、超越、生命和折旧；用“五感”检查标题代入、摘要故事、引言诱导、正文沉浸、结尾共情。

### 问题记录与裁决

每项问题固定字段：`check_id`、检查维度、原文位置/证据、依据（书中框架或期刊要求）、严重度、诊断、修改动作、回流模块、复核标准。

- **阻断**：诚信、事实/引文、核心证据或论证闭环问题；提交前必须解决。
- **重要**：显著损害创新表达、结构、可读性或期刊适配。
- **优化**：不阻断提交的表达或技术改进。

总体结论仅可为：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。结论必须由问题矩阵支撑。

## 共轭能力图

10 维审稿知识、三位顾问、回流模块与 master 路由意图必须成对落地，而不是只存在本入口。四层检查与输入优先级保持不变。

| 10维 | 顾问 canonical name | 回流模块 | master 路由意图 |
|---|---|---|---|
| 选题/创新 | `paper-check-argument-integrity-reviewer` | design/lit | 全文审稿/拒稿风险 → check |
| 标题 | `paper-check-editorial-screening-reviewer` | write | 全文审稿/编辑首筛 → check |
| 摘要 | `paper-check-editorial-screening-reviewer` | write | 全文审稿/编辑首筛 → check |
| 关键词 | `paper-check-editorial-screening-reviewer` | write | 全文审稿/编辑首筛 → check |
| 引言 | `paper-check-editorial-screening-reviewer` | outline/write | 全文审稿/编辑首筛 → check |
| 正文 | `paper-check-argument-integrity-reviewer` | outline/analysis/write | 全文审稿/论证闭环 → check |
| 结尾 | `paper-check-argument-integrity-reviewer` | write | 全文审稿 → check |
| 引文注释 | `paper-check-ethics-conformance-reviewer` | lit/submission | 全文审稿/诚信规范 → check |
| 技术规范 | `paper-check-ethics-conformance-reviewer` | submission | 全文审稿 → check；仅 Word/体例 → submission |
| 投稿 | `paper-check-editorial-screening-reviewer` | submission | 全文审稿/期刊适配 → check；仅投稿包 → submission |

顾问取值仅限：`paper-check-editorial-screening-reviewer`、`paper-check-argument-integrity-reviewer`、`paper-check-ethics-conformance-reviewer`。phase 协议必须把上表落实为逐步动作与完成门槛。语言润色/扫描不在本模块；项目成熟度评分不在本模块。

## 输出与回流

创建 `paper-workspace/05-writing/reviews/`，写入：

```text
paper-check-report-[slug]-[YYYY-MM-DD].md
paper-check-matrix-[slug]-[YYYY-MM-DD].md
paper-check-revision-list-[slug]-[YYYY-MM-DD].md
```

主报告必须含输入、限制、总体结论、关键阻断项、10维结论和回流 Mermaid；矩阵记录逐项证据；修改清单按“阻断 → 重要 → 优化”排序并写复核标准。完整审稿派发三位顾问并等待终态，综合文件写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/agent-synthesis-check-[YYYY-MM-DD].md`。单项检查只派对应顾问并记录未派发理由。

```mermaid
flowchart LR
  W[write 正文净稿] --> C[check 综合质量门]
  C -->|论证/证据| O[outline / analysis / lit]
  C -->|实质改稿| W
  C -->|通过| S[submission 投稿整备]
```

- check 不替代前序模块生成证据，也不替代 submission 的Word与投稿包工作。
- 阻断项优先回流；修订后用原 check_id 和复核标准复审。
- 被检查稿件仍处于正文写作或投稿整备阶段；运行check本身不新增论文阶段。

## 阶段与顾问协议

依次读取 `phases/01-intake-and-routing.md`、`phases/02-layered-review.md`、`phases/03-synthesis-and-return.md`。完整审稿还读取三份顾问协议：

- `agents/editorial-screening-reviewer.md` — `paper-check-editorial-screening-reviewer`
- `agents/argument-integrity-reviewer.md` — `paper-check-argument-integrity-reviewer`
- `agents/ethics-conformance-reviewer.md` — `paper-check-ethics-conformance-reviewer`

每位顾问开头必须输出 `## 参考库回查`，列出实际读取的 chapters、patterns或cheatsheet；主流程去重、裁决严重度，保留分歧和未采纳理由。

## Chapter Index

| 章节 | 主题 |
|---|---|
| [ch01](chapters/ch01-outline-selection-design-writing.md) | 选题、设计、撰写与七个意识 |
| [ch02](chapters/ch02-title.md) | 标题 |
| [ch04](chapters/ch04-abstract.md) | 摘要 |
| [ch05](chapters/ch05-keywords.md) | 关键词 |
| [ch06](chapters/ch06-introduction.md) | 引言 |
| [ch07](chapters/ch07-body.md) | 正文与论证 |
| [ch08](chapters/ch08-conclusion.md) | 结尾 |
| [ch09](chapters/ch09-notes-and-references.md) | 注释与参考文献 |
| [ch10](chapters/ch10-technical-standards.md) | 技术规范 |
| [ch12](chapters/ch12-submission.md) | 投稿 |

## Topic Index

- **标题** → ch02
- **摘要** → ch04
- **关键词** → ch05
- **引言** → ch06
- **结构/论证/十六种缺憾** → ch07
- **结尾** → ch08
- **注释/引文** → ch09
- **技术规范** → ch10
- **选题/创新** → ch01
- **期刊适配/投稿** → ch12

## Supporting Files

- [glossary.md](glossary.md)
- [patterns.md](patterns.md)
- [cheatsheet.md](cheatsheet.md)
