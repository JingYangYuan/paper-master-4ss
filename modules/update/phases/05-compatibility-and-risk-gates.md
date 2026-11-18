# Phase 05：兼容性与风险门控

## 顾问派发门控

生成审核包前须派发 `modules/update/agents/review-gate-consultant.md`。若候选条目包含 `self-update: true`，须同时复用或增派 `modules/update/agents/target-routing-consultant.md`，形成「目标路由复核 + 审核门控复核」双重审核记录。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/review-gate-consultant.md` 并更新 `agent-synthesis-update-[YYYY-MM-DD].md`。

## 目标

核查候选更新对模块边界、执行流程、脚本运行、模板兼容、顾问调度与自更新安全的潜在影响。所有候选状态维持 `pending`，不得自动合并。

## 风险分级与验证要求

| 风险等级 | 典型目标面 | 准入要求 |
|---|---|---|
| `low` | `frame/`、`chapters/`、`references/`、`resources/` 知识条目 | 来源清楚、证据充分、目标准确、适用边界明确 |
| `medium` | `MODULE.md`、`phases/`、`agents/` 流程或角色协议 | 说明兼容性影响、相邻模块影响及须同步更新的索引 |
| `high` | `scripts/`、`templates/`、`self-update`、执行命令与二进制模板 | 提供人工验证命令、失败风险、回滚提示及双重审核（`self-update`） |

## 强制核查清单

- **输出边界**：全部产物仅写入 `paper-workspace/07-update/`；
- **状态锁定**：所有候选保持 `pending`；
- **来源与目标**：路径/出处、目标模块、目标面、目标文件与建议位置齐全；
- **风险与兼容性**：标明 `Risk tier` 与影响面（入口、阶段、顾问、脚本、模板或跨模块交接）；
- **人工验证**：`medium`/`high` 候选须含可执行的人工验证方式（脚本候选须含命令、样例与预期输出；模板候选须含导出/格式检查方式；协议与角色候选须含静态一致性核查项）；
- **自更新双重审核**：`self-update: true` 候选须具备两份独立复核记录。

## 执行步骤

1. 读取 Phase 04 目标路由表并按 `Risk tier` 分组核查；
2. 为 `medium` 候选补齐兼容性影响说明（影响入口/阶段、是否需同步调整 `agent-registry.md` 或输出协议）；
3. 为 `high` 候选补齐可执行验证方式与回滚提示；
4. 对 `self-update` 候选执行 `target-routing-consultant` + `review-gate-consultant` 双重审核；
5. 输出风险门控表（字段：`Candidate ID`、`Risk tier`、`Compatibility impact`、`Required validation`、`Self-update review`、`Gate status`、`Required fix`）。

## 门控结论取值

- `pass-to-review-package`：可进入 Phase 06 生成审核包；
- `revise-before-package`：候选内容保留，但须补充来源、目标、风险或验证方式；
- `blocked`：目标越界、状态非 `pending`、试图直接修改核心文件或 `self-update` 跳过双重审核。

门控结果写入 `paper-workspace/07-update/review-checklist-[slug]-[date].md` 与 `agent-synthesis-update-[YYYY-MM-DD].md`。存在 `blocked` 条目时，最终回复须注明「已生成待修正候选包」，不得建议合并。
