# Phase 02：分层审阅

## 目标
执行编辑首筛、论证闭环、诚信与规范、技术与期刊适配四层检查。完整审稿必须同步派发三位顾问、等待终态、保存原始意见；失败最多重试两次后才可顺序复核并记录。统一使用问题字段和三档严重度，避免把材料缺失推断为违规。

## 统一状态与字段
- 总体结论：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。
- 严重度：`阻断`、`重要`、`优化`。
- 问题字段：`check_id`、检查维度、原文位置/证据、依据、严重度、诊断、修改动作、回流模块、复核标准。

## 逐步动作

1. 完整审稿同步派发三位顾问并等待终态：
   - `paper-check-editorial-screening-reviewer`：编辑首筛、创新可见度、题摘关键词/引言、期刊适配。
   - `paper-check-argument-integrity-reviewer`：问题—论点—证据—结构—结尾闭环与十六缺憾。
   - `paper-check-ethics-conformance-reviewer`：引文注释和技术规范。
2. 每位顾问必须先输出 `## 参考库回查`。editorial 必读含 `chapters/ch12-submission.md`；无用户提供或可抓取的公开规则时写 `期刊特定核验: 未执行`。
3. 单项检查只派最少对应角色，并记录未派发理由。
4. 统一使用问题九字段和三档严重度。材料缺失只标「待核验」，不得升级为违规。
5. 派发失败最多重试 2 次，再 `sequential-review`，记录方式与 Phase 01 相同。

## 完成门槛

- 完整审稿：三份顾问原文均到达终态，或已记录 sequential-review 与原因。
- 每个问题含九字段；严重度只用 `阻断`、`重要`、`优化`。
- 诚信、事实/引文、核心证据或论证闭环以外的问题不得标阻断。
- 四层检查均有结论或明确跳过理由：编辑首筛、论证闭环、诚信与规范、技术与期刊适配。

## 共轭回流表

沿用 Phase 01 的 10 维 × 顾问 canonical name × 回流模块 × master 路由意图表。本 phase 只填写问题，不改稿、不导出 Word。

四层与顾问对应：

| 四层 | 主顾问 | 10 维 |
|---|---|---|
| 编辑首筛 | `paper-check-editorial-screening-reviewer` | 标题、摘要、关键词、引言、投稿 |
| 论证闭环 | `paper-check-argument-integrity-reviewer` | 选题/创新、正文、结尾 |
| 诚信与规范 | `paper-check-ethics-conformance-reviewer` | 引文注释 |
| 技术与期刊适配 | `paper-check-ethics-conformance-reviewer`（技术）+ `paper-check-editorial-screening-reviewer`（期刊） | 技术规范、投稿 |

## sequential-review 记录方式

顾问原文仍按 canonical 文件名落盘。synthesis 必须列出未并行原因、复核顺序和每个角色是否完成参考库回查。空返回或无参考回查视为失败。

## 产物
报告、矩阵和修订清单写入 `paper-workspace/05-writing/reviews/`；顾问意见与综合写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/`。
