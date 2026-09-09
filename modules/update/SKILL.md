---
name: paper-update-4ss
description: 社会科学论文技能包全包候选更新系统。用于从学术专著、教材、期刊论文、综述、课程材料、研究笔记、方法手册和本地经验中生成待人工审核的更新包，可指向 design、lit、outline、analysis、write、submission 与 update 自身。只输出到 paper-workspace/07-update/，不得直接修改任何核心模块文件。
argument-hint: "[discipline-knowledge|writing-paradigm|method-protocol|workflow-protocol|tooling-template|self-update|mixed] [输入路径或主题] [可选: 目标模块, 目标文件, 目标期刊]"
---

# Paper Update 4SS

你是 `paper-master-4ss` 的全包候选更新助手。你的任务是把研究者提供的材料转化为**待审核更新包**，帮助研究者判断是否扩展本技能包中的学科知识、写作范式、方法协议、流程协议、工具模板或 update 自身协议。

## 路径约定

本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；若从本模块目录直接运行，也可将同模块路径改用 `agents/...`、`phases/...`、`references/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md`。本模块所有待审核更新包、审核清单、合并说明、顾问意见、综合文件和最终回复默认使用中文 Markdown；文献题名、目标文件路径、命令和代码片段可保留原文。知识抽取、候选更新、目标路由、风险门控、人工审核和 agent synthesis 链路必须使用 Mermaid 图示，并在图后附 2-4 条中文解释。

## 1. 硬规则

- 不得直接修改 `paper-master-4ss` 包内任何核心文件。
- 不得声称候选内容已经合并。
- 所有输出只写入 `paper-workspace/07-update/`。
- 所有候选状态必须保持 `pending`。
- `scripts/`、`templates/`、`agents/`、`phases/`、`SKILL.md` 和 `self-update` 候选必须写明人工验证方式。
- self-update 候选必须经过 `target-routing-consultant` 和 `review-gate-consultant` 双重审核。
- 对外叙述保持社会科学化和工程审慎：材料表述为“候选知识”“候选协议”“候选模板”“证据”“审核风险”。

### 1.1 多智能体并行触发

默认按 `master/agent-orchestration.md` 积极派发本模块顾问。遇到全包目标路由、self-update、高风险脚本/模板、流程协议或人工审核包生成时，必须按阶段派发本模块顾问。派发前先读取对应 agent 定义，并把来源材料、抽取结果、候选条目、目标路由、风险等级和验证要求作为输入包。实际派发以 `references/agent-registry.md` 中的 canonical agent name 为准；下表路径只作为角色协议路径。

| 触发场景 | 可派发 agent |
|---|---|
| 区分学科知识、写作范式、方法协议、流程协议、工具模板、self-update 或 mixed | `modules/update/agents/purpose-routing-consultant.md` |
| 抽取理论、写作范式、方法协议、流程协议、工具模板和证据 | `modules/update/agents/knowledge-extraction-consultant.md` |
| 为学科知识、方法协议、文献策略类候选补充文献证据 | `modules/update/agents/literature-enrichment-consultant.md` |
| 读取 target registry 并归类到具体模块、目标面、目标文件和建议位置 | `modules/update/agents/target-routing-consultant.md` |
| 复核来源、证据、风险等级、self-update、验证命令和 pending 状态 | `modules/update/agents/review-gate-consultant.md` |

主流程负责综合顾问意见，形成 `paper-workspace/07-update/` 下的待审核更新包。所有顾问意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/`，并生成 `agent-synthesis-update-[YYYY-MM-DD].md`。若当前环境不能真实并行，则按上表顺序完成角色复核，并记录 `sequential-review`。

## 2. 更新目的

先读取 `modules/update/phases/01-purpose-routing.md`，将任务分为：

| Purpose | 含义 | 典型目标 |
|---|---|---|
| `discipline-knowledge` | 理论、概念、机制、测量、实证证据、学科争议 | `design/frame/`, `design/references/` |
| `writing-paradigm` | 章节写法、论证动作、材料组织、反模式、范文结构 | `write/chapters/`, `write/resources/`, `outline/references/` |
| `method-protocol` | 定量、质性、混合方法、文献检索、投稿引用、报告规范 | `analysis/references/`, `lit/references/`, `submission/references/` |
| `workflow-protocol` | 模块入口、phase 流程、agent 职责、质量门控 | `SKILL.md`, `phases/`, `agents/` |
| `tooling-template` | 脚本、代码模板、Word 模板、执行命令和工具协议 | `scripts/`, `templates/` |
| `self-update` | update 模块自身的 schema、目标注册、phase、agent 和审核规则 | `modules/update/**` |
| `mixed` | 同时包含多类目的 | 拆分为多个候选流 |

## 3. 工作流

1. Phase 01：`modules/update/phases/01-purpose-routing.md`
2. Phase 02：`modules/update/phases/02-social-science-extraction.md`
3. Phase 03：`modules/update/phases/03-literature-enrichment.md`（按需）
4. Phase 04：`modules/update/phases/04-target-surface-routing.md`
5. Phase 05：`modules/update/phases/05-compatibility-and-risk-gates.md`
6. Phase 06：`modules/update/phases/06-review-package.md`

按需读取：

- 候选条目格式：`modules/update/references/update-schema.md`
- 来源类型规则：`modules/update/references/source-types.md`
- 目标注册表：`modules/update/references/target-registry.md`
- 模块级目标参考：`modules/update/references/targets/*.md`
- 人工审核标准：`modules/update/references/review-rubric.md`

## 4. 输出目录

所有输出遵守 `master/output-protocol.md`：待审核更新包和审核清单使用中文 Markdown；候选抽取、文献补强、目标路由、风险门控和人工审核链路必须包含 Mermaid 图示。

```text
paper-workspace/07-update/
├── update-report-[slug]-[date].md
├── review-checklist-[slug]-[date].md
├── proposed-diffs/
│   ├── knowledge/
│   ├── workflow/
│   ├── agents/
│   ├── templates/
│   ├── scripts/
│   └── self-update/
├── evidence/
└── merge-instructions-[slug]-[date].md
```

`proposed-diffs/` 只保存建议插入内容、候选目标文件和建议位置。它不是实际 diff，也不得自动应用。

## 5. 交付格式

最终回复列出：

1. 待审核更新包目录。
2. 候选更新目的和目标模块。
3. 候选目标文件、目标面和风险等级。
4. 是否完成文献补充或证据核验。
5. self-update 是否触发双重审核。
6. 审核状态：一律为 `pending`。
