# Phase 01：输入定位与审稿路由

## 目标

登记待检稿件路径、目标期刊公开要求及引文核查材料；依据输入优先级选定稿件，确定完整审稿（单次派发 `paper-check-reviewer` 覆盖 A/B/C 三组清单）或单项检查，并记录未覆盖维度与理由。

## 统一判定口径

- **总体结论（四值）**：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。
- **严重度（三级）**：`阻断`、`重要`、`优化`。
- **问题矩阵字段（九项）**：`check_id`、检查维度、原文位置/证据、依据、严重度、诊断、修改动作、退回模块、复核标准。

## 执行步骤

1. 按 `MODULE.md`「输入定位优先级」选定稿件：用户显式指定路径 -> 最新 `revisions/styled-*.md` -> 顶层 `manuscript*.md` -> 均缺失时向用户索取。
2. 登记目标期刊公开要求与引文核验来源。期刊规则缺失时不阻断通用检查，须记录 `期刊特定核验: 未执行`；引文原文缺失时列入待核验清单，不得推断违规。
3. 确定派发范围：完整审稿派发 `paper-check-reviewer`（同一次意见内覆盖 A/B/C 三组清单并等待终态）；单项检查仅核对相关维度并写明未覆盖维度与原因。
4. 顾问派发失败时最多重试 1 次；仍失败则降级为 `sequential-review`，并在 `_logs/agents/check-[YYYY-MM-DD]/agent-brief.md` 中记录 `agent-gate-block: failed×1 + sequential-review`，不得虚构已派发记录。

## 完成门槛

- 稿件路径已登记且可读；
- 期刊核验状态已注明（已核验或 `期刊特定核验: 未执行`）；
- 派活清单记录完整：需求原文、标准名（`paper-check-reviewer`）、文件路径、顺序、并行/顺序复核及终态；
- 已声明四值总体结论、三级严重度与九字段问题矩阵口径。

## 十维审稿与退回对照表

| 维度 | 所属检查组 | 顾问标准名 | 退回模块 | 总控路由意图 |
|---|---|---|---|---|
| 选题 / 创新 | A 组 | `paper-check-reviewer` | `design` / `lit` | 全文审稿 / 拒稿风险 -> `check` |
| 标题 | A 组 | `paper-check-reviewer` | `write` | 全文审稿 / 编辑首筛 -> `check` |
| 摘要 | A 组 | `paper-check-reviewer` | `write` | 全文审稿 / 编辑首筛 -> `check` |
| 关键词 | A 组 | `paper-check-reviewer` | `write` | 全文审稿 / 编辑首筛 -> `check` |
| 引言 | A 组 | `paper-check-reviewer` | `outline` / `write` | 全文审稿 / 编辑首筛 -> `check` |
| 正文 | B 组 | `paper-check-reviewer` | `outline` / `analysis` / `write` | 全文审稿 / 论证闭环 -> `check` |
| 结尾 | B 组 | `paper-check-reviewer` | `write` | 全文审稿 -> `check` |
| 引文注释 | C 组 | `paper-check-reviewer` | `lit` / `submission` | 全文审稿 / 诚信规范 -> `check` |
| 技术规范 | C 组 | `paper-check-reviewer` | `submission` | 全文审稿 -> `check`；仅 Word/体例 -> `submission` |
| 投稿适配 | A 组 | `paper-check-reviewer` | `submission` | 全文审稿 / 期刊适配 -> `check`；仅投稿包 -> `submission` |

## 顺序复核记录规范

重试 1 次仍失败时，由主流程按「A 组（题摘关键词引言）-> B 组（正文结尾）-> C 组（引文技术规范）」顺序复核，按 `paper-check-reviewer--A|B|C.md` 写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/`，并在综合报告注明降级原因。

## 阶段产物

报告、矩阵与修订清单写入 `paper-workspace/05-writing/reviews/`；顾问意见与综合报告写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/`。
