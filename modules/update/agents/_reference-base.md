---
base-id: update-2026.10.24
module: update
---

# update 模块参考库回查底座

本文件是 `update` 模块 4 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=update-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

`update` 模块仅输出**待人工审核的候选更新包**，不直接修改核心技能文件；在研究者明确批准合并前，所有候选条目状态必须保持 `pending`。

更新流程按「判定目的 -> 抽取候选 -> 文献补强（按需）-> 目标路由 -> 兼容与风险门控」推进。更新目的限定为六类及混合：`discipline-knowledge`、`writing-paradigm`、`method-protocol`、`workflow-protocol`、`tooling-template`、`self-update`（及 `mixed`）。目的判定与候选抽取基于同一批输入材料，应在一次任务内连续完成。

候选条目须完整记录来源（材料路径、页码或行号）、证据等级、适用边界与争议状态；不得将局部经验直接泛化为通用理论或强制规则。

风险分级决定验证要求：`medium`/`high` 候选须说明兼容性影响；`high` 候选须附人工验证命令、样例或检查清单。`self-update` 候选须同时经过 `target-routing` 与 `review-gate` 双重审核，且不得绕过 `pending` 状态。

文献补强默认强制适用于 `discipline-knowledge`、方法规范型 `method-protocol` 与文献策略类候选；`workflow-protocol`、`tooling-template` 与 `self-update` 仅在声称依托外部文献或规范时启用。补强仅服务审核，不改变 `pending` 状态。

目标面限定四类：`knowledge-reference`、`workflow-protocol`、`tooling-template`、`self-update`。目标文件须落在 `target-registry` 允许范围内，越界即判为错误归类。

## B2 判据条目

C01 目的分类准确：归入六类目的之一或明确标为 `mixed` 并给出拆分路线（`references/source-types.md`）。

C02 `mixed` 拆分合理：多类混合材料拆分为可独立审核的候选流并说明依据。

C03 `self-update` 标注：指向 `update` 自身规则时标注 `self-update: true` 并说明变更必要性。

C04 候选字段完整：每条候选具备来源、证据等级、适用边界、争议状态与风险等级（`references/update-schema.md`）。

C05 来源可追溯：注明材料路径与页码/行号，无出处条目不得纳入候选。

C06 边界与争议说明：标注领域适用边界、执行边界与学术争议，避免将个别经验泛化为通则。

C07 风险定级合规：按 `references/review-rubric.md` §风险等级定级，`medium`/`high` 须评估兼容影响。

C08 `high` 风险验证要求：`high` 级候选须附人工验证命令、样例或核查清单，否则不得进入审核包。

C09 文献补强作用域：默认覆盖 `discipline-knowledge`、方法规范型 `method-protocol` 与文献策略类候选；其余类型按需启用。

C10 补强交叉验证：结合经典文献、综述定位、实证证据、方法规范与争议来源进行交叉印证，标注过时或不适用风险。

C11 目标路由精确：目标模块、目标面、目标文件与建议插入位置四要素齐全，且目标文件处于 `target-registry.md` 允许清单内。

C12 目标面四分类准确：`knowledge-reference` / `workflow-protocol` / `tooling-template` / `self-update` 分类与风险等级相称。

C13 `self-update` 双重审核：`self-update` 候选同时具备 `target-routing` 与 `review-gate` 审核记录。

C14 `pending` 状态锁定：审核包内全部候选保持 `pending`，禁止自行合并落盘。

C15 阻断处置清晰：`blocked` 候选须写明阻断原因与解除条件（`references/review-rubric.md` §决策状态、§阻断规则）。

C16 跨模块影响评估：评估候选对目标模块入口、阶段、顾问、门控与交接规则的影响。

C17 职责边界遵守：不修改目标文件、不代作采纳决定、不声称已合并、不虚构文献或验证输出。

C18 可追溯要求：判断指向具体参考条款、`targets` 文件行或材料位置；缺口标注「待核验」。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-update-extraction-consultant` | C01 C02 C03 C04 C05 C06 C07 C18 | `references/source-types.md`、`references/update-schema.md`、`phases/01-purpose-routing.md`、`phases/02-social-science-extraction.md` | T1 |
| `paper-update-literature-enrichment-consultant` | C09 C10 C05 C18 | `phases/03-literature-enrichment.md`、`modules/lit/references/search-strategies.md` / `synthesis-guide.md` 相关段落 | T1 |
| `paper-update-target-routing-consultant` | C11 C12 C13 C16 C18 | `references/target-registry.md`、`references/targets/<module>-targets.md`、`phases/04-target-surface-routing.md` | T1 |
| `paper-update-review-gate-consultant` | C07 C08 C13 C14 C15 C16 C17 C18 | `references/review-rubric.md`、`phases/05-compatibility-and-risk-gates.md`、`phases/06-review-package.md` | T2（`pending` 守门） |

L1 默认单点角色：`paper-update-review-gate-consultant`（`pending` 状态守门人）。
