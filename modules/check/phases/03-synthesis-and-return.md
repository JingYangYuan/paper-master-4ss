# Phase 03：综合与回流

## 目标
去重顾问意见、处理分歧并裁决严重度；以矩阵支撑四级总体结论。写主报告、问题矩阵和按严重度排序的修订清单；输出 write→check→submission Mermaid。实质问题精确回流 design/lit/outline/analysis/write，格式与投稿包问题回流submission；只诊断，不覆盖稿件。

## 统一状态与字段
- 总体结论：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。
- 严重度：`阻断`、`重要`、`优化`。
- 问题字段：`check_id`、检查维度、原文位置/证据、依据、严重度、诊断、修改动作、回流模块、复核标准。

## 逐步动作

1. 去重顾问意见，保留分歧和未采纳理由；主流程裁决严重度。
2. 以问题矩阵支撑四级总体结论，仅可使用：`可进入投稿整备`、`小修后进入投稿整备`、`大修后复审`、`不建议当前投稿`。
3. 写入 `paper-workspace/05-writing/reviews/`：
   - `paper-check-report-[slug]-[YYYY-MM-DD].md`
   - `paper-check-matrix-[slug]-[YYYY-MM-DD].md`
   - `paper-check-revision-list-[slug]-[YYYY-MM-DD].md`
4. 综合文件写入 `_logs/agents/check-[YYYY-MM-DD]/agent-synthesis-check-[YYYY-MM-DD].md`。
5. 按共轭回流表精确回流：实质问题指向清单中的 design/lit/outline/analysis/write；格式与投稿包回流 submission。只诊断，不覆盖稿件。
6. 主报告必须含输入、限制、总体结论、关键阻断项、10 维结论和回流 Mermaid。

## 完成门槛

- 每个 `check_id` 可追溯到顾问原文或主流程裁决。
- 修订清单按「阻断 → 重要 → 优化」排序并写复核标准。
- 总体结论与阻断项一致：有阻断 → `大修后复审` 或 `不建议当前投稿`。
- 回流模块取值来自 10 维表，不得只写 write。

## 共轭回流表

| 问题类型 | 回流模块 | 下一模块不得做 |
|---|---|---|
| 选题/创新/理论锚点 | design/lit | 不进入投稿整备 |
| 结构/证据映射 | outline | 不以润色代替结构 |
| 数据/识别/结果声称 | analysis | 不扩大战果 |
| 实质改稿 | write | 不把全文审稿做成 scanner |
| 语言扫描残留 | write | 不交给 submission 修论证 |
| 引文体例/Word/投稿包 | submission | 不以模板修补论证断裂 |
| 原文缺失 | 用户补充 | 不推断违规 |

master 路由意图：通过质量门后才 `check -> submission`；`不建议当前投稿` 或 `大修后复审` 时默认不导出 Word。

## sequential-review 记录方式

若 Phase 02 已降级 sequential-review，本 phase 仍必须综合三份角色意见（含主流程代行的角色复核），不得省略未并行角色。synthesis 记录降级原因与完成门槛勾选结果。

## 产物
报告、矩阵和修订清单写入 `paper-workspace/05-writing/reviews/`；顾问意见与综合写入 `paper-workspace/_logs/agents/check-[YYYY-MM-DD]/`。
