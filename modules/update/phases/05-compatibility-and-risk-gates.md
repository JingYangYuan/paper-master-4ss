# Phase 05: 兼容性与风险门控

## 顾问派发闸门

兼容性与风险门控前，必须派发 `modules/update/agents/review-gate-consultant.md`。若候选项为 `self-update: true`，必须复用或再次派发 `modules/update/agents/target-routing-consultant.md`，形成“双重审核”记录：目标路由复核 + 审核门控复核。

顾问意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/review-gate-consultant.md`，并同步进入 `agent-synthesis-update-[YYYY-MM-DD].md`。

## 目标

在生成待审核更新包前，检查候选更新是否会影响模块边界、执行逻辑、脚本运行、模板兼容性、agent 调度、自更新安全和跨模块一致性。所有候选仍保持 `pending`，不得自动合并。

## 风险等级

| Risk tier | 目标面 | 要求 |
|---|---|---|
| `low` | `frame/`, `chapters/`, `references/`, `resources/` 中的知识条目 | 来源清楚、证据充分、目标正确、边界明确 |
| `medium` | `SKILL.md`, `phases/`, `agents/` 的流程或角色协议 | 说明兼容影响、相邻模块影响、需要同步更新的索引 |
| `high` | `scripts/`, `templates/`, 自更新、执行命令、二进制模板 | 提供人工验证命令、失败风险、回滚提示和双重审核 |

## 必查项

| 检查项 | 通过标准 |
|---|---|
| 输出边界 | 所有内容只写入 `paper-workspace/07-update/` |
| 审核状态 | 所有候选均为 `pending` |
| 来源 | 有路径、题名、作者、URL 或材料说明 |
| 目标 | 有目标模块、目标面、目标文件和建议位置 |
| 风险 | 有 `Risk tier` 与风险解释 |
| 兼容性 | 说明是否影响入口、phase、agent、脚本、模板或跨模块交接 |
| 验证 | medium/high 候选包含人工验证方式 |
| 自更新 | `self-update: true` 候选包含目标路由复核和审核门控复核 |

## 执行步骤

1. 读取 Phase 04 的目标路由表。
2. 按 `Risk tier` 分组检查候选项。
3. 对 `medium` 候选补写兼容性影响：
   - 影响哪个入口文件或 phase。
   - 是否需要同步修改 agent 描述或注册表。
   - 是否影响已有输出协议。
4. 对 `high` 候选补写验证方式：
   - 脚本候选：给出人工运行命令、输入样例、预期输出。
   - 模板候选：给出渲染、导出或格式检查方式。
   - agent/phase/SKILL 候选：给出静态一致性检查项。
5. 对 `self-update` 候选执行双重审核：
   - `target-routing-consultant` 确认目标面和目标文件。
   - `review-gate-consultant` 确认不会绕过 pending 审核。
6. 输出风险门控表：

| Candidate ID | Risk tier | Compatibility impact | Required validation | Self-update review | Gate status | Required fix |
|---|---|---|---|---|---|---|

## 门控状态

- `pass-to-review-package`：可进入 Phase 06。
- `revise-before-package`：候选内容可保留，但必须补来源、目标、风险或验证方式。
- `blocked`：目标越界、状态不是 pending、试图直接修改核心文件，或 self-update 试图跳过双重审核。

## 输出要求

将门控结果写入：

```text
paper-workspace/07-update/review-checklist-[slug]-[date].md
paper-workspace/_logs/agents/update-[YYYY-MM-DD]/agent-synthesis-update-[YYYY-MM-DD].md
```

若存在 `blocked`，最终回复只能说明“已生成待修正候选包”，不得建议合并。
