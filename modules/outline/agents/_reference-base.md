---
base-id: outline-2026.10.24
module: outline
---

# outline 模块参考库回查底座

本文件是 `outline` 模块 3 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=outline-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

大纲阶段须依次核查两项核心问题：结构选型是否成立、材料支撑是否充分。

整体结构由论文目的与材料条件共同决定，不单纯取决于期刊名称。学位论文与期刊论文的章节深度不同；实证、阐释、规范与综述四类研究对应不同的结构骨架（详见 `references/outline-patterns.md`）。常见结构失衡表现为理论章节过长、发现章节薄弱，或讨论章节重复承担了文献综述的对话功能。

每份材料须同时记录两项属性：功能位置（选题、文献综述、理论框架、方法、发现、讨论或结论）与证据强度。同一材料支撑多个章节时须分别登记；无关材料须写明暂缓理由。功能归类与证据充分性整合于同一张「材料 × 章节」矩阵中。

证据准入门槛：文献证据须达到 `02-literature/review-evidence.csv` 中的 `fulltext`、`abstract` 或 `theory_text` 级别；`unverified` 级条目严禁纳入正文写作计划。

章节逻辑核查涵盖标题顺序、层级深度与承接关系：标题须逐层递进，各章功能边界清晰，经验分析与理论对话衔接顺畅，避免标题空泛、重复或脱离已有材料。

缺口处理结论严格划分为三类：「补齐材料可解」「须退回上游（文献/设计/分析）」「须重构大纲」（须指明修改层级）。仅当缺口已准确分类且核心章节均具备达标证据时，方由 `gap-review-consultant` 放行进入写作阶段。

## B2 判据条目

C01 结构类型选择：学位论文 / 期刊论文与实证 / 阐释 / 规范 / 综述四类的组合判定准确（`references/outline-patterns.md` §一–§四、§七–§八）。

C02 范式微调匹配：社会学研究、管理世界案例、通用 IMRaD 等范式微调规则与目标期刊一致（§五）。

C03 篇幅与层级匹配：标题层级、展开深度与字数分配符合论文目的与篇幅上限（§六 字数分配指南）。

C04 结构平衡：理论、方法、发现、讨论四部分权重与论文类型相称，无明显比例失衡。

C05 材料功能位置归类：每份材料明确标注支撑的章节功能位置（选题/文献/理论/方法/发现/讨论/结论），跨章使用须逐处登记。

C06 材料类型识别：准确区分文献、设计、数据、访谈、案例与用户材料，弱相关材料写明暂缓理由。

C07 材料 × 章节矩阵完整性：矩阵覆盖全部核心章节且无空章；同一材料跨章引用时分别登记用途。

C08 证据强度达标：文献证据达到 `review-evidence.csv` 的 `fulltext`/`abstract`/`theory_text` 级；`unverified` 严禁进入正文计划。

C09 证据支撑论点：章节证据须支撑核心论点而非仅作背景铺陈；证据与论点错配须标出。

C10 章节顺序与递进：标题形成逻辑递进，无顺序错位、内容重复或论证断裂。

C11 章节职责边界：文献综述、理论框架、方法、发现与讨论不越位承担彼此功能；经验分析与理论对话衔接自然。

C12 标题质量：标题具体且可追溯至材料，不空泛、不重复、层级不超过四层。

C13 缺口三分类：准确区分为「补材料可解 / 需退回上游 / 需重构大纲」并指明退回目标模块。

C14 闭环检查：研究问题、文献、方法与发现形成闭环，结尾不新增未经论证的声称。

C15 写作风险预判：列明高风险章节及须由用户决策的前置事项。

C16 放行阻断权：仅 `paper-outline-gap-review-consultant` 拥有「可进入写作」裁决权；证据未达标或未分类缺口存在时不得放行。

C17 阶段前置门控：材料扫描未完成不构建大纲；大纲未完成不做质量检查；质量检查须输出三类缺口结论。

C18 证据可追溯要求：材料判断指向具体文件路径、`paper-registry.csv` 行或 `review-evidence.csv` 行；缺口标注「待核验」。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-outline-structure-consultant` | C01 C02 C03 C04 C17 | `references/outline-patterns.md` §一–§八、`references/output-formats.md`、`phases/02-build-outline.md` | T1 |
| `paper-outline-evidence-map-consultant` | C05 C06 C07 C08 C09 C18 | `references/outline-patterns.md`、`02-literature/review-evidence.csv`、`02-literature/paper-registry.csv`、`phases/01-scan-materials.md` 与 `02-build-outline.md` | T1 |
| `paper-outline-gap-review-consultant` | C10 C11 C12 C13 C14 C15 C16 C17 C18 | `phases/03-quality-check.md`、`references/output-formats.md`、证据映射表与素材清单 | T2（阻断「可进入写作」） |

L1 默认单点角色：`paper-outline-gap-review-consultant`（持有进入写作阶段的放行裁决权）。
