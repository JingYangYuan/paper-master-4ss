# Phase 03: 文献补充与证据核验

## 顾问派发闸门

当候选目的为 `discipline-knowledge`、涉及方法规范的 `method-protocol`，或涉及文献检索/综述/假设推导的候选时，必须派发 `modules/update/agents/literature-enrichment-consultant.md`。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/literature-enrichment-consultant.md`。

`writing-paradigm` 若来源仅为课程材料或研究笔记，建议派发该顾问做可迁移依据补强。`workflow-protocol`、`tooling-template`、`self-update` 默认不强制文献补强，除非候选内容本身声称来自文献或方法规范。

## 目标

为需要外部证据的候选项补充文献证据、争议状态、适用边界和过时风险。文献补强只服务于候选审核，不代表候选已经合并。

## 补充标准

| Purpose | 补充重点 |
|---|---|
| `discipline-knowledge` | 经典来源、综述来源、实证来源、争议来源、适用边界 |
| `method-protocol` | 方法手册、统计/质性规范、报告标准、软件或工具文档 |
| `writing-paradigm` | 可迁移写作依据、目标期刊范式、范文或写作手册 |
| 文献策略类候选 | 数据库规则、检索协议、PRISMA/综述规范、CNKI/Scholar 操作证据 |

## 调用 lit 模块

若候选需要系统文献补强，可调用或参考 `modules/lit/` 的检索策略，但本 phase 不替代 lit 模块完整文献综述。只需为候选更新提供足够审核依据。

## 输出

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

## 停止条件

若证据不足，候选仍可进入 Phase 04，但必须在 `Risk tier` 和 `review-checklist` 中标记“证据不足，需补核验”。
