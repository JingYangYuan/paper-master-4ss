# Phase 4：综述论证准备与正文交接

由 lit 模块在模式 A、B、C、D 下加载。lit 不再把搜索日志、地图和正文混在一个报告内；它准备能被核查的论证材料，再交由 write 模块生成唯一的综述正文。

先读取 master/literature-review-protocol.md。该协议优先于本文件中的任何泛化写作建议。

## 4a. 建立论证与证据材料

在 02-literature/ 写入三个独立文件：

| 文件 | 作用 | 最低内容 |
|---|---|---|
| review-evidence.csv | 主张与来源的唯一关联 | claim_id、paper_id、原文位置、原文摘录、适用边界、可转述内容、不可声称内容、复核状态 |
| review-outline.md | 章节论证蓝图 | 研究问题、各段主张、争论关系、段落顺序、claim_id、过渡任务 |
| review-gaps.md | 不能安全进入正文的内容 | 未核验主张、缺失全文、待补反证、空白核查范围和下一步 |

证据表应按“一个进入正文的判断”建行，而不是按“每篇论文”建行。摘要只能支撑摘要明确表述的概括；机制、方法批评、效应数值、争议判断和强空白判断必须给出全文或理论文本中的位置。

## 4b. 组织论证

选择与研究问题相称的叙事路线：理论争论、历史发展、实证版图、方法批判、跨学科桥梁或计算方法创新。它们是选择项，不是固定章节模板。

每个正文段落应完成一个论证动作：

1. 提出一个可争论的判断。
2. 结合多项研究说明支持、冲突或不可直接比较的原因。
3. 交代判断的适用边界和证据限制。
4. 推进研究问题、理论对话或有条件的研究不足。

允许多篇文献共同支持一个判断。不得为了“每引一篇都分析”而写成逐篇摘要，也不得预设所有主题必有空白或贡献。

对研究不足，必须写清检索范围、最近先例、已被覆盖的内容、尚未解释的具体问题及理论意义。若核查后不足不成立，应在 review-gaps.md 记录并调整研究问题。

理论、规范和阐释路径围绕概念区分、论证前提、竞争立场、反例和文本出处组织；不要求填充变量关系、效应量或重复验证发现。

## 4c. 交给 write 生成正文

用户要求可进入论文的文献综述时，lit 完成 4a 和 4b 后，调用 write 的常规写作、审查和文风流程。输入包必须含 paper-registry.csv、review-evidence.csv、review-outline.md、review-gaps.md、目标期刊与用户的字数要求。

正文唯一保存为 paper-workspace/05-writing/literature-review.md。它只含标题层级、自然段和实际引用的参考文献；搜索日志、PRISMA、地图、空白表、Mermaid、证据表和待补材料保留在 02-literature/。

快速概览允许形成有边界的初稿，但未核验内容不得写成成熟结论。后续改写须更新 review-evidence.csv 的 claim 状态，保留有效来源关系。

## 4d. 输出确认

lit 完成后确认以下路径：

1. 02-literature/paper-registry.csv
2. 02-literature/review-evidence.csv
3. 02-literature/review-outline.md
4. 02-literature/review-gaps.md
5. 05-writing/literature-review.md（仅在已调用 write 并完成正文时）

模式 A 的 PRISMA 图、搜索日志和文献地图仍是过程报告，单独保存于 02-literature/。
