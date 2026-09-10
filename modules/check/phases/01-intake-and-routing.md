# Phase 01：输入与路由

## 目标
登记稿件路径、目标期刊/投稿须知和引文材料。依输入优先级选择稿件；无期刊规则不阻断通用检查，但登记`期刊特定核验: 未执行`。缺少原文引文时建立待核验清单。确定完整审稿（3顾问并行）或单项审稿（最少对应顾问），并写明未派发理由。

## 统一状态与字段
- 总体结论：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。
- 严重度：`阻断`、`重要`、`优化`。
- 问题字段：`check_id`、检查维度、原文位置/证据、依据、严重度、诊断、修改动作、回流模块、复核标准。

## 逐步动作

1. 按 SKILL「执行入口与输入优先级」选择稿件：用户显式路径 → 最新 `revisions/styled-*.md` → 顶层 `manuscript*.md` → 否则索取稿件。
2. 登记目标期刊/投稿须知和引文原文。缺期刊规则不阻断，登记 `期刊特定核验: 未执行`。缺少原文引文时建立待核验清单，不得推断违规。
3. 判定派发强度：完整审稿（三位顾问并行，等待终态）或单项审稿（最少对应角色）。未派发角色必须写明理由。
4. 若 `spawn_agent` 失败，最多重试 2 次；仍失败则 `sequential-review`，并在 `_logs/agents/check-[YYYY-MM-DD]/agent-brief.md` 记录 `agent-gate-block: failed×2 + sequential-review`。不得伪造已派发。

## 完成门槛

- 稿件路径已登记且可读取。
- 期刊核验状态已写明（已执行或 `期刊特定核验: 未执行`）。
- 派发清单含：模块选择原文、canonical name、路径、顺序、并行或 sequential-review、终态。
- 统一字段已声明：总体结论四档、严重度三档、问题九字段。

## 共轭回流表

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

顾问取值仅限上表三个 canonical name。总体结论仅可为：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。严重度仅可为：`阻断`、`重要`、`优化`。问题字段固定为：`check_id`、检查维度、原文位置/证据、依据、严重度、诊断、修改动作、回流模块、复核标准。

## sequential-review 记录方式

失败×2 后，主流程按 editorial → argument-integrity → ethics 顺序复核，意见仍写入 `_logs/agents/check-[YYYY-MM-DD]/` 对应 canonical 文件名，synthesis 标明降级原因。禁止把 sequential-review 写成已并行派发。

## 产物
报告、矩阵和修订清单写入 `paper-workspace/05-writing/reviews/`；顾问意见与综合写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/`。
