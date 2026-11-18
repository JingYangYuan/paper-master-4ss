---
base-id: lit-2026.10.24
module: lit
---

# lit 模块参考库回查底座

本文件是 `lit` 模块 4 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=lit-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

文献综述阶段的目标是产出可被下游直接复用的知识状态地图，并据此完成可检验假设的逻辑推导。

检索式属于阶段核心产物：须覆盖中英文同义词，区分理论、机制、人群、情境与方法五类检索面，明确来源优先级与补检方向；中文文献先走 NCPSSD 免登录定位与顶刊分级，英文文献走 Crossref 定位 DOI（严禁中文条目进 Crossref）。CNKI 存在严格操作边界：顾问仅可设计面向专业检索的 `TI='...' AND AU='...'` / `LY='...'` 查询方案与补检方向，并提醒主流程在取全文前核验机构 IP 与 `browser_control`（`ego-browser`）可用性；严禁声称已完成 CNKI 取全文，也不得以 `web_search` 或 NCPSSD `pdfurl`（已停用的 `nssd.org`）充当 CNKI 全文结果。

筛选与质量评估在同一张裁决表中完成：单篇文献须一次性裁决纳入状态（纳入 / 排除 / 待核验）、证据等级（`fulltext` / `abstract` / `theory_text` / `unverified`）、可复核的排除理由及待核验字段。文献构成不设机械比例，经典、综述与实证文献的比例应与研究问题相称；仅凭标题纳入、摘要缺失或范围偏移须显式标出。

文献地图（描述性）与假设推导（规范性推论）须保持边界分离：文献地图负责整理理论谱系、概念关系、争议脉络与空白，并严格区分「已有研究做过但未发现效应」与「尚未有人研究」；假设桥接负责核查「空白 -> 理论 -> 机制 -> 假设」的逐环追溯性，排除常识化命题、漂浮机制与跳步推导。

唯一登记与证据源：纳入文献以 `02-literature/paper-registry.csv` 为唯一登记源（含核读状态与全文路径），证据等级以 `02-literature/review-evidence.csv` 的 `evidence_level` 为准；`unverified` 级条目不得进入正文写作计划。

## B2 判据条目

C01 检索词覆盖：中英文关键词与同义词覆盖核心概念，区分理论、机制、人群、情境、方法五类检索面（`references/search-strategies.md` §布尔搜索策略）。

C02 检索路线与来源组合：明确英文（Crossref 定位+审核 → `mirror-first`/`oa-first` → `web_search`/CDP 补位 → LibGen 书轮）与中文（NCPSSD 定位+64 种顶刊分级 → CNKI 专业检索+下载单直取）分阶段路线与补检方向；显式列明遗漏方向。

C03 CNKI 操作边界：仅设计专业检索（`TI='完整题名' AND AU='作者'` / `LY='刊名'`）与补检策略；不得声称已完成 CNKI 取全文或以 `web_search`/NCPSSD 链接代替 CNKI 全文。

C04 定位与检索式规范：中文条目走 `ncpssd_search.py`（多词自动拆 OR 组再 AND，严禁进 Crossref）；英文条目走 `enrich_crossref.py`（含二轮 `audit --apply`）；按年份分布决策 `mirror-first` 或 `oa-first`，不凭空把 Web 布尔串填进中文期刊库基础框。

C05 筛选裁决完整性：单篇裁决纳入状态（纳入/排除/待核验）、排除理由与待核验字段；禁止仅凭标题纳入，排除理由须可复核。

C06 证据等级门槛：采用 `fulltext` / `abstract` / `theory_text` / `unverified` 分级；`unverified` 不得进入正文计划与假设证据链（`references/synthesis-guide.md`）。

C07 证据构成相称性：不设固定比例配额，须论证经典、综述、实证、方法文献构成与研究问题的匹配度；摘要缺失与范围偏移列为风险。

C08 理论谱系与概念关系：清晰区分理论流派与核心概念，记录核心问题、基本前提、概念工具与竞争框架；争议须呈现双方证据。

C09 空白类型区分：区分「已有研究无效应」与「尚未研究」，并归类至人群/情境、机制、识别或理论争论四类之一（`references/gap-to-hypothesis.md` §1）。

C10 假设桥接可追溯：每条假设可追溯至「空白 -> 理论预测 -> 机制 -> 变量方向」四步，替代解释明确，无常识化或跳步推导。

C11 方向一致性：理论预期、机制陈述、变量方向与假设措辞保持一致，不出现前后方向矛盾。

C12 证据边界与外推限制：标出过时、地域不适配或样本外推过度的文献并注明降级理由。

C13 唯一事实源：纳入清单以 `paper-registry.csv` 为准，证据等级以 `review-evidence.csv` 为准，不得另建私有清单。

C14 空白与假设分工边界：`theory-map` 止步于识别空白，不产假设；假设由 `hypothesis-bridge` 基于该空白独立推导。

C15 综述成稿交接：综述正文须按 `master/literature-review-protocol.md` 交由 `write` 成稿，输出至 `paper-workspace/05-writing/literature-review.md`。

C16 阶段前置门控：检索未完成不进入文献地图；文献地图未区分空白类型不进入假设推导；假设未通过桥接检查不交接写作。

C17 证据可追溯要求：判断须指向已读文件路径、`paper-registry.csv` 行或检索日志；信息缺失时标「待核验」，不得凭印象补全。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-lit-search-strategy-consultant` | C01 C02 C03 C04 C16 C17 | `references/search-strategies.md`、`references/ncpssd.md`、`references/cnki.md`、`references/channels.md`、`references/books.md`、`references/browser.md`、`phases/phase-1-search.md` | T1 |
| `paper-lit-theory-map-consultant` | C08 C09 C13 C14 C16 C17 | `references/theory-frameworks.md`、`references/synthesis-guide.md`（景观地图叙事模板）、`phases/phase-2-landscape.md` 2a–2i 维度 | T1 |
| `paper-lit-evidence-screening-consultant` | C05 C06 C07 C12 C13 C17 | `references/synthesis-guide.md`、`references/search-strategies.md`、`phases/phase-1-search.md` 纳入规则、`02-literature/paper-registry.csv` | T1 |
| `paper-lit-hypothesis-bridge-consultant` | C09 C10 C11 C14 C15 C17 | `references/gap-to-hypothesis.md`（空白类型、机制规格模板、假设写作规则、失败模式）、`phases/phase-3-hypothesis.md` | T2（结论进正文） |

L1 默认单点角色：`paper-lit-hypothesis-bridge-consultant`（确保空白到假设的逻辑桥接成立，防止下游整体偏离）。
