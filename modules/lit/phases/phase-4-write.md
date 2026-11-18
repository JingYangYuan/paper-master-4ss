# Phase 4：综述论证准备与正文交接

本阶段在模式 A / B / C / D 下加载。`lit` 负责构建可追溯的论证与证据材料，再交由 `write` 生成唯一综述正文净稿，不得将检索日志、文献地图与综述正文混为一体。

执行前须读取 `master/literature-review-protocol.md`（该协议优先于本文件细则）。

## 4a. 生成共享论证与证据材料

在 `paper-workspace/02-literature/` 下写入三份文件：

| 文件 | 用途 | 最低字段 / 内容要求 |
|---|---|---|
| `review-evidence.csv` | 正文论断与原文证据唯一映射表 | `claim_id`、`paper_id`、`evidence_level`、`source_location`、`source_excerpt`、`scope_conditions`、`permitted_paraphrase`、`not_supported`、`review_status`（完整 15 列见 `master/literature-review-protocol.md`） |
| `review-outline.md` | 综述论证蓝图 | 研究问题、各段中心主张、文献争论关系、段落顺序、引用 `claim_id` 与过渡任务 |
| `review-gaps.md` | 禁用内容隔离清单 | 未核验主张、缺失全文条目、待补反证、空白检索边界与下一步行动 |

`review-evidence.csv` 按「进入正文的论断」建行，不按论文逐篇建行；摘要仅可支撑概括性研究对象、设计与主要发现，机制分析、方法批评、效应量与强空白判断须提供全文或理论文本的定位出处。

## 4b. 组织论证结构

依据研究问题选择相称的叙事主线（理论争论、历史演进、实证版图、方法批判、跨学科桥梁或方法创新）。每个正文段落须完成以下论证动作：
1. 提出一个可讨论的学术判断；
2. 比较多项研究，说明彼此支持、冲突或不可直接比较的原因；
3. 界定该判断的适用边界与证据限制；
4. 推进研究问题、理论对话或有条件的研究不足。

允许多篇文献分组支撑同一判断，避免逐篇摘要罗列。任何研究不足须写明检索范围、最近似先例、已有覆盖范围及理论意义；核查后若不足不成立，须记入 `review-gaps.md` 并调整研究问题。理论、规范与阐释研究围绕概念区分、论证前提、竞争立场、反例与文本出处组织。

## 4c. 交接 `write` 生成综述净稿

需要输出可并入论文的综述正文时，`lit` 完成 4a 与 4b 后，将 `paper-registry.csv`、`review-evidence.csv`、`review-outline.md`、`review-gaps.md`、目标期刊及字数要求一并交由 `write` 模块执行常规写作、审查与文风定稿流程。

综述正文唯一输出路径为 `paper-workspace/05-writing/literature-review.md`（仅含标题层级、自然段与实际引用的参考文献）；检索日志、PRISMA 图、文献地图、空白表、Mermaid 图、证据表与待补缺口一律保留于 `02-literature/`。修改已有综述前须先同步更新 `review-evidence.csv` 的 `claim` 状态。

## 4d. 交付文件核对

1. `paper-workspace/02-literature/paper-registry.csv`
2. `paper-workspace/02-literature/review-evidence.csv`
3. `paper-workspace/02-literature/review-outline.md`
4. `paper-workspace/02-literature/review-gaps.md`
5. `paper-workspace/05-writing/literature-review.md`（仅在已交由 `write` 成稿时存在）

过程报告（PRISMA 图、检索日志、文献地图与假设推导）独立留存于 `02-literature/` 与 `_logs/`。
