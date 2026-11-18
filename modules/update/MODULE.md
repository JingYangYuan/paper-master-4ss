---
name: paper-update-4ss
description: 社会科学论文技能包全包候选更新系统。用于从学术专著、教材、期刊论文、综述、课程材料、研究笔记、方法手册和本地经验中生成待人工审核的更新包，可指向 design、lit、outline、analysis、write、check、submission 与 update 自身。只输出到 paper-workspace/07-update/，不得直接修改任何核心模块文件。
---

# Paper Update 4SS：全包候选更新生成系统

> 参数提示：[discipline-knowledge|writing-paradigm|method-protocol|workflow-protocol|tooling-template|self-update|mixed] [输入路径或主题] [可选: 目标模块, 目标文件, 目标期刊]

本模块用于从研究者提供的学术专著、教材、论文、课程材料、笔记、方法手册或本地运行经验中提取结构化条目，生成**待人工审核的候选更新包**，供研究者评估是否纳入本包的学科知识、写作范式、方法协议、流程协议、工具模板或 `update` 自身规则。本模块只产出候选方案，不直接修改核心技能文件。

## 路径约定

本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；在模块目录内直接运行时可使用 `agents/...`、`phases/...`、`references/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md`。所有待审核更新包、审核清单、合并说明、顾问意见、综合文件与最终回复均使用中文 Markdown（文献题名、目标文件路径、命令与代码片段保留原文）；知识抽取、候选生成、目标路由、风险门控、人工审核及顾问综合链路须附 Mermaid 图及 2–4 句中文解释。

## 1. 强制约束

- 严禁直接修改 `paper-master-4ss` 目录下的任何核心模块、协议、脚本或模板文件；
- 严禁在未人工合并前声称候选更新已生效；
- 所有输出文件仅允许写入 `paper-workspace/07-update/`；
- 所有候选条目的状态字段必须保持为 `pending`；
- 涉及 `scripts/`、`templates/`、`agents/`、`phases/`、`MODULE.md` 与 `self-update` 的候选条目须写明具体的人工验证方式；
- `self-update` 候选条目须经 `target-routing-consultant` 与 `review-gate-consultant` 双重审核；
- 对外报告统一使用「候选知识」「候选协议」「候选模板」「证据」「审核风险」等审慎表述。

### 1.1 顾问派发规范

依据 `master/agent-orchestration.md` 决定派发档位。涉及全包跨模块路由、`self-update`、高风险脚本/模板变更、流程协议调整或人工审核包生成时，按阶段派发以下顾问（输入须包含来源材料、抽取结果、候选条目、目标路由、风险等级与验证要求；执行身份以 `references/agent-registry.md` 标准名为准）：

| 阶段 / 决策需求 | 对应顾问文件 |
|---|---|
| 判定更新目的（六类 + `mixed` + `self-update`）、抽取候选条目并给出风险初判 | `modules/update/agents/extraction-consultant.md` |
| 为学科知识、方法协议与文献策略类候选条目补充文献证据 | `modules/update/agents/literature-enrichment-consultant.md` |
| 检索 `target-registry`，归类目标模块、目标面、目标文件与建议插入位置 | `modules/update/agents/target-routing-consultant.md` |
| 复核来源、证据充分性、风险等级、`self-update` 合规性、验证命令与 `pending` 状态 | `modules/update/agents/review-gate-consultant.md` |

顾问意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/`，综合结论写入 `agent-synthesis-update-[YYYY-MM-DD].md`。运行环境不支持并行时按上表顺序复核并记录 `sequential-review`。

## 2. 更新目的分类

先读取 `modules/update/phases/01-purpose-routing.md` 确定更新目的：

| Purpose 取值 | 覆盖范围 | 典型候选目标目录 |
|---|---|---|
| `discipline-knowledge` | 理论、概念、机制、测量、实证证据与学科争议 | `design/frame/`、`design/references/` |
| `writing-paradigm` | 章节写法、论证动作、材料组织、反模式与范文结构 | `write/chapters/`、`write/resources/`、`outline/references/`、`check/chapters/`、`check/patterns.md` |
| `method-protocol` | 定量、质性、混合方法、文献检索、投稿引用与报告规范 | `analysis/references/`、`lit/references/`、`check/chapters/`、`submission/references/` |
| `workflow-protocol` | 模块入口、阶段流程、顾问职责与交付前检查 | `MODULE.md`、`phases/`、`agents/` |
| `tooling-template` | 脚本、代码模板、Word 模板、执行命令与工具协议 | `scripts/`、`templates/` |
| `self-update` | `update` 模块自身的 schema、目标注册表、阶段、顾问与审核规则 | `modules/update/**` |
| `mixed` | 同时涵盖多类更新目的 | 拆分为多个独立候选流处理 |

## 3. 执行流程与按需参考

按序执行六个阶段：
1. `modules/update/phases/01-purpose-routing.md`
2. `modules/update/phases/02-social-science-extraction.md`
3. `modules/update/phases/03-literature-enrichment.md`（按需）
4. `modules/update/phases/04-target-surface-routing.md`
5. `modules/update/phases/05-compatibility-and-risk-gates.md`
6. `modules/update/phases/06-review-package.md`

按需参考文档：
- 候选条目 Schema：`modules/update/references/update-schema.md`
- 来源类型规则：`modules/update/references/source-types.md`
- 目标文件注册表：`modules/update/references/target-registry.md`
- 各模块目标面细则：`modules/update/references/targets/*.md`
- 人工审核标准：`modules/update/references/review-rubric.md`

## 4. 输出目录结构

遵守 `master/output-protocol.md`（使用中文 Markdown，主要流程链路附 Mermaid 图）：

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

`proposed-diffs/` 仅存放建议插入片段、目标文件路径及建议位置，属于待审核文本草案，不得作为自动补丁直接应用。

## 5. 交付汇报清单

1. 待审核更新包输出目录路径；
2. 判定的更新目的（`purpose`）与目标模块；
3. 候选目标文件、目标面与风险等级；
4. 是否执行了文献补强或证据核验；
5. 是否涉及 `self-update` 及双重审核状态；
6. 审核状态（固定为 `pending`）。
