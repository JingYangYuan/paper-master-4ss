# Phase 03：文献补充与证据核验

## 顾问派发门控

当候选目的为 `discipline-knowledge`、方法规范型 `method-protocol` 或文献检索/综述/假设推导类候选时，须派发 `modules/update/agents/literature-enrichment-consultant.md`（意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/literature-enrichment-consultant.md`）。

`writing-paradigm` 若仅源于课程讲义或研究笔记，建议派发补强可迁移依据；`workflow-protocol`、`tooling-template` 与 `self-update` 仅在候选声称基于特定文献或外部规范时启用。

## 目标

为须外部证据支撑的候选条目补充文献依据、学术争议、适用边界与过时风险；补强结论仅用于辅助人工审核，不代表候选已被采纳或合并。

## 分类补充重点

| 更新目的 | 补充重点 |
|---|---|
| `discipline-knowledge` | 经典来源、综述定位、实证证据、争议来源与适用边界 |
| `method-protocol` | 方法手册、统计/质性规范、报告标准与工具官方文档 |
| `writing-paradigm` | 可迁移写作依据、目标期刊体例、范文或写作专著 |
| 文献策略类候选 | 数据库规则、检索协议、综述规范与平台操作实测证据 |

若需系统补证，可参考 `modules/lit/` 检索策略，但本阶段不替代完整文献综述流程。

## 输出格式

```markdown
# Literature Enrichment

## Search Scope
- Candidate ID:
- Purpose:
- Search scope:
- Sources checked:

## Evidence Table

| Source | Type | Supports | Boundary | Risk |
|---|---|---|---|---|

## Integration Notes
- Evidence status:
- Remaining gap:
- Whether candidate may enter target routing:
```

## 缺证处理

外部证据不足时，候选可继续进入 Phase 04，但须在 `Risk tier` 与 `review-checklist` 中明确标注「证据不足，需补核验」。
