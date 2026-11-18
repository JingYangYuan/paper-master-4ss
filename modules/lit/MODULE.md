---
name: paper-lit-4ss
description: 中英文双语文献检索下载、文献综述与假设推导一体化技能。支持五种模式：完整文献地图（A）、定向综述（B）、快速概览（C）、文献综述+假设推导（D）、中文/书目批量落地（E）。集成 lit-down 检索下载管线：英文走 Crossref 定位 DOI、按年份分流 Sci-Hub 镜像与 OA 链（Unpaywall/OpenAlex/Europe PMC/arXiv/NBER）、web_search 机构库补位与 LibGen 专著书轮；中文走 NCPSSD 免登录定位（64 种 CSSCI 顶刊分级）与知网机构出口（专业检索+下载单+Referer 直取），配备四件套内容校验、断点续跑与 MinerU/Zotero/文献地图交接。
---

# Paper Lit 4SS：文献检索、下载、综述与假设推导

> 参数提示：[研究主题 / 参考文献清单 / DOI 列表 / PDF 路径] [可选: 完整|定向|快速|假设|知网] [可选: 目标期刊]

本模块负责中英文文献检索与全文批量落地，并将核验后的文献转化为可追溯的文献谱系、证据矩阵、研究空白与假设推导（或理论对话材料）。过程检索、题录、PDF 全文与证据表均保留在 `paper-workspace/02-literature/`；面向论文正文的文献综述净稿仅按 `master/literature-review-protocol.md` 交由 `write` 生成至 `05-writing/literature-review.md`。

核心约束：
1. 未取得摘要或等价全文信息的文献不得作为证据纳入正文或文献地图；
2. 英文文献按 `lit-down` 管线执行「探活 → Crossref 定位+审核 → mirror-first/oa-first 下载 → `web_search`/CDP 补位 → LibGen 书轮 → 四件套内容校验」，中文文献按「NCPSSD 免登录定位 → 知网专业检索+下载单直取 → 内容校验」两跳执行，严禁拿中文题名问 Crossref 或把 NCPSSD `pdfurl`（`nssd.org`）当 OA 全文；
3. 过程产物与正文净稿严格分离。

## 路径约定

本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；在模块目录内单独运行时可直接使用 `agents/...`、`phases/...`、`references/...`、`scripts/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md` 与 `master/literature-review-protocol.md`。

搜索日志、下载报告、文献地图、证据表、综述蓝图、假设推导、顾问意见、综合文件与最终回复均使用中文 Markdown；文献题名、作者、期刊、数据库名与检索式保留原文。机制链、假设推导链、PRISMA/检索流程、文献地图流程及顾问调度链须附 Mermaid 图及 2–4 句中文解释。综述正文不得直接拼接过程材料，须由 `write` 按共享协议成稿。

## 顾问派发规范

按 `master/agent-orchestration.md` 决定派发档位：完整文献地图、双语系统检索、争议领域梳理、假设推导与大规模文献综合建议派发对应顾问；快速概览或纯书目批量下载（模式 E）等轻量任务可跳过并记录 `agent-skip` 及原因。

派发前先读取对应顾问文件，输入须包含研究主题、当前检索阶段、范围约束、已有论文清单、摘要及用户确认项。执行身份以 `references/agent-registry.md` 标准名为准。

| 任务风险点 | 对应顾问文件 |
|---|---|
| 检索词构建、来源组合、分轮策略、补检方案 | 检索策略顾问 `modules/lit/agents/search-strategy-consultant.md` |
| 单篇纳入裁决、证据等级判定、证据构成相称性 | 证据筛选顾问 `modules/lit/agents/evidence-screening-consultant.md` |
| 理论脉络划分、概念关系、争议梳理与空白识别 | 理论地图顾问 `modules/lit/agents/theory-map-consultant.md` |
| 核查「空白—理论—机制—假设」逻辑桥接 | 假设桥接顾问 `modules/lit/agents/hypothesis-bridge-consultant.md` |

顾问意见写入 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/`，综合结果写入 `agent-synthesis-lit-[YYYY-MM-DD].md`。运行环境不支持并行时按上表顺序复核并记录 `sequential-review`。

## 依赖安装与运行规则

执行前先读取 **[install-dependencies.md](modules/lit/references/install-dependencies.md)** 完成环境验收。

工具后端说明：
- **英文与中文定位检索/下载（`lit-down`）**：`probe_channels.py`、`refs_from_pdf.py`、`enrich_crossref.py`、`download.py`、`books_libgen.py`、`manual_add.py`、`verify_content.py`、`make_report.py`、`ncpssd_search.py`（依赖 `requests`、`httpx`、`pymupdf`/`pypdf`）。
- **CNKI 全文取回与浏览器兜底**：使用 `ego-browser` 驱动可见浏览器运行 `cnki_fetch_batch.mjs`（见 [cnki.md](modules/lit/references/cnki.md)）或处理 Turnstile/CDP `Page.getResourceContent`/`Page.printToPDF`（见 [browser.md](modules/lit/references/browser.md)）。缺失 `browser_control` 时 CNKI 全文取回与浏览器兜底阶段无法执行，仅可开展 NCPSSD 定位、英文 HTTP 渠道与本地库检索。
- **Zotero 本地库（可选增强）**：需保存题录/全文或进行本地库检索/深读时启用，安装与操作协议见 **[zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md)**。

七项执行纪律：
1. **CNKI 权限与验证码边界**：知网取全文依赖机构 IP（页面顶栏须有机构名）；撞到验证码闸门按「记 `verify` → 跳过 → 冷却后下轮重跑」处理（可选 `cnki_captcha.py` 辅助点选）；需要人工登录或手动过验证时通过 `task.handOff()` 移交可见窗口，交人后严禁脚本跑 `goto` 冲掉验证页。
2. **CNKI 下载单直取规范**：在 `ego-browser` 中脚本点击 `target=_blank` 会被弹窗拦截，必须从详情页取 `li.btn-dlpdf a` 的 `href`，由 Node 带 `Network.getCookies`（含 httpOnly）+ `Referer: 详情页` 请求直取字节，严禁将 Cookie 内容输出至对话或日志。
3. **Zotero 启用询问**：在 Phase 0 / Step 0Q 须先确认是否启用 Zotero / Zotero MCP。用户明确暂缓时记为 `用户明确暂缓`，不强制安装，继续在线检索与 `lit-down` 归档。
4. **Zotero 启用前置验收**：仅在按 `modules/lit/references/install-dependencies.md` 完成 Zotero Desktop、Connector 与 MCP 验收后，方可执行本地库检索与全文入库。
5. **Zotero 操作记录真实性**：入库与深读须严格按 `modules/lit/references/zotero-local-mcp.md` 执行，不得以联网检索或顾问意见替代本地库执行状态。
6. **安装排障口径**：依赖安装与排障统一以 `modules/lit/references/install-dependencies.md` 为准；CrossRef/Unpaywall 邮箱通过 `LITDOWN_EMAIL` 环境变量传入（勿用 `example.com`）。
7. **可选组件容错**：Zotero 不可用时仅停用该渠道并记录缺失，不影响其余检索下载流程。

## 参数与模式路由

从 `$ARGUMENTS` 提取：**研究主题或输入清单/PDF**、**模式关键词**、**目标期刊（可选）**、**范围约束（可选）**。

若上游 `design-report` / `full-report` 已标注概念/解释理论、规范理论或思想史/文本阐释取向且 `analysis_required: false`，则在既有文献地图与综述流程中整理「支持立场、竞争立场与反例材料」，跳过假设推导。未检测到模式关键词且无上游交接时，默认采用**模式 A**。

| 关键词 | 模式 | 检索轮次 / 轨道 | 目标文献数 | 预期篇幅 | 是否推导假设 |
|---|---|---|---|---|---|
| `完整` `地图` `全面` `landscape` | **A：完整地图** | ≥ 6 轮 + 双语全链落地 | 40–80 | 3–10k 字 | 否 |
| `定向` `聚焦` `前言` `targeted` | **B：定向综述** | 4 轮 + 核心全文落地 | 15–30 | 1–3k 字 | 否 |
| `快速` `概览` `初步` `rapid` | **C：快速概览** | 2 轮 + 关键摘要/OA | 10–20 | 0.5–1.5k 字 | 否 |
| `假设` `hypothesis` | **D：综述＋假设** | ≥ 5 轮 + 双语全链落地 | 30–60 | 2–5k 字 | 是 |
| `知网` `CNKI` `中文` `下载` `文献落地` `补齐参考文献` | **E：检索与下载专项** | 按输入语种走 `lit-down` 双轨批量落地（不写综述） | 10–200 | 无 | 否 |

**模式 E 双轨说明（集成 `lit-down`）**：
- **中文主题/清单落地**：`ncpssd_search.py`（免登录定位 + 64 种 CSSCI 顶刊分级）→ `cnki_prepare.py` → `ego-browser` 运行 `cnki_fetch_batch.mjs` → `cnki_report.py`。
- **英文/书目/PDF 参考文献落地**：`probe_channels.py` → `refs_from_pdf.py`（如输入 PDF）→ `enrich_crossref.py`（parse/doi/audit/merge）→ `download.py`（`mirror-first` / `oa-first`）+ `web_search` / `manual_add.py` / `browser.md` CDP → `books_libgen.py`（无 DOI 专著）→ `verify_content.py` + `make_report.py`。
- 缺少 `browser_control` 时仅可运行 NCPSSD 定位与英文 HTTP 下载，记录 `浏览器控制不可用` 并停止 CNKI 取全文阶段。

**假设意图确认**：仅出现「假设」/`hypothesis` 但未明确选择模式 D 时，须先询问确认是否进入模式 D。仅出现「理论」时不自动触发假设推导。

---

## Phase 0：初始化（所有模式）

加载 **[phase-0-init.md](modules/lit/phases/phase-0-init.md)**，按顺序执行以下三步：

### Step 0a：确认检索方向（首步强制）

在建立目录或发起任何检索前，通过 `ask_user` 确认检索方向（支持多选；若用户直接提供现成参考文献清单或待下 PDF，可快速确认“竞品核查/既有书目落地”后直接进入 Phase 1）：

```text
question: "请确认本次文献检索的方向与范围（可多选）"
header: "检索方向"
options: [
  {label: "X→Y 主效应", description: "检索核心自变量对因变量的直接影响"},
  {label: "X 概念族", description: "检索自变量的测量、成因、趋势与相邻概念"},
  {label: "Y 概念族", description: "检索因变量的概念谱系、测量与相邻结果"},
  {label: "M 机制变量", description: "检索中介、过程与解释链条"},
  {label: "W 调节变量", description: "检索制度、区域、人群、行业与时期等边界条件"},
  {label: "IV 工具变量", description: "检索工具变量、自然实验、政策冲击与识别策略"},
  {label: "竞品核查", description: "专门检索与本研究问题高度重合的已有实证或理论研究"}
]
```

确认后将所选方向映射为中英文检索词对，写入检索日志的「检索方向映射」表；未选方向标注 `用户暂不覆盖`。

### Step 0b：确认启用检索来源

通过 `ask_user` 确认本轮启用的检索来源（`web_search`、NCPSSD、Crossref/OA/镜像/LibGen、本地库/Zotero、Annual Reviews、引文链、CNKI）。

### Step 0c：初始化工作区与索引

- 运行 `literature_registry.py init` 创建 `paper-workspace/02-literature/papers/`、`fulltext/`、`plans/` 及唯一题录注册表 `paper-registry.csv`（用户已有文件仅登记原路径）；
- 创建落盘检索日志（包含 Step 0a 的检索方向映射表与来源确认表）；
- 初始化论文清单表，解析模式、目标期刊与范围约束，确定检索路线图。

---

## Phase 1：文献检索与全文下载（所有模式，集成 `lit-down`）

加载 **[phase-1-search.md](modules/lit/phases/phase-1-search.md)**，按 `lit-down` 管线与标准工作区闭环推进：

| 步骤 | 阶段内容 | A | B | C | D | E | 说明 |
|---|---|---|---|---|---|---|---|
| 0Q | 检索来源预确认 | ✓ | ✓ | ✓ | ✓ | ✓ | 通过 `ask_user` 确认启用来源与 Zotero 状态 |
| ⓪ | 探活与出口 IP 判断 | ✓ | ✓ | ✓ | ✓ | 英文/混合 | `probe_channels.py` 跑两遍 + 决定 `mirror-first` / `oa-first` |
| ① | 候选发现与清单解析 | ✓ | ✓ | ✓ | ✓ | ✓ | `web_search`、本地库、Annual Reviews、引文链或 `refs_from_pdf.py` |
| ② | 定位分流（中文/英文） | ✓ | ✓ | ✓ | ✓ | ✓ | 中文走 `ncpssd_search.py`；英文走 `enrich_crossref.py`（parse/doi/audit/merge） |
| ③④ | 批量取全文与补位 | ✓ | ✓ | 可选 | ✓ | ✓ | 英文 `download.py` + `web_search`/`manual_add.py`/`browser.md` CDP + 书轮 `books_libgen.py`；中文 `cnki_prepare.py` → `cnki_fetch_batch.mjs` |
| ⑤ | 四件套校验与清单 | ✓ | ✓ | 可选 | ✓ | ✓ | `verify_content.py` / `make_report.py` / `cnki_report.py`（魔数+大小+页数+`autojunk=False` 内容比对+书评拦截） |
| 9 | 注册表归档 | ✓ | ✓ | ✓ | ✓ | ✓ | `literature_registry.py register` + `mark-download` 写入 `paper-registry.csv` |
| 10 | 全文化解析（MinerU） | ✓ | ✓ | - | ✓ | 可选 | `modules/lit/scripts/mineru/pdf2md.py --registry` 解析至 `fulltext/` |
| 11 | Zotero 归档与笔记 | 可选 | 可选 | - | 可选 | 可选 | 仅启用 Zotero 时执行 `zotero-local-mcp.md` §5b |
| 12 | 参考文献交集滚雪球 | ✓ | ✓ | - | ✓ | - | `citation_intersection.py` 对共引 ≥ 2 条目回流检索下载（最多 2 轮） |

### Phase 1 核心执行规则（摘要）

1. **即时写日志与阶段确认**：每阶段完成后更新 `SEARCH_LOG` 与 `02-literature/stage-syntheses.md`，经 `ask_user` 确认方向后再推进。
2. **摘要准入门槛**：进入正式清单、文献地图、综述或假设推导的文献必须具备摘要或等价全文信息；仅含标题、作者、期刊或被引数者只可列为「待核验/排除候选」。
3. **英文定位与下载纪律**：中文条目严禁进 Crossref；Crossref 第二轮必须 `audit --apply` 过滤错配；根据年份分布选择 `--order mirror-first`（默认）或 `--order oa-first` + `--probe-oa`；无 DOI 专著进 `books_libgen.py`（必带 `topics[]=l`）；四件套内容比对必须带 `autojunk=False` 并拦截书评。
4. **中文两跳纪律**：NCPSSD（`ncpssd_search.py`）只管定位、元数据与 64 种 CSSCI 顶刊置顶，其 `pdfurl` 多为停用的 `nssd.org` 不可作 OA；批量扫库用 `--no-detail`，`exit 1` 为限流/故障而非空库；知网取全文用 `cnki_fetch_batch.mjs`（专业检索 → 下载单 `href` → Node 带 Cookie + Referer 直取），撞验证码记 `verify` 跳过并在冷却后重跑。
5. **注册表唯一事实源**：所有下载校验通过的 PDF 存于 `02-literature/papers/`，并通过 `literature_registry.py register` / `mark-download` 写入 `paper-registry.csv`，供 Step 10–12 与 Phase 2–4 消费。
6. **遵守 20 条工程铁律**：长任务后台跑、分段超时 + 墙钟 deadline、`RLock` 并发写盘、判出口 IP、机构代理自检等完整细则见 **[phase-1-search.md](modules/lit/phases/phase-1-search.md)**。

---

## Phase 2：文献景观地图（模式 A / B / C / D）

加载 **[phase-2-landscape.md](modules/lit/phases/phase-2-landscape.md)**，构建 2a–2i 九个维度（2i 仅模式 D 启用）：

| 维度 | 核心内容 |
|---|---|
| 2a 领域演进 | 时期划分、范式转移与关键转折点 |
| 2b 理论版图 | 框架、核心主张、预测、实证支持度与当前地位 |
| 2c 已证实发现与边界 | 仅汇总现有证据可支撑的发现、判断及适用边界 |
| 2d 争议发现 | 证据分歧、权重评估、分歧成因与解决路径 |
| 2e 非显著与证据缺口 | 严格区分统计不显著、效应接近零与检索范围内尚无直接研究 |
| 2f 机制清单 | 已有研究提出的机制、类型、是否经过检验及当前状态 |
| 2g 方法版图 | 主导研究设计、数据源、优势与局限 |
| 2h 空白汇总 | 结构化空白表，按发表潜力与可行性排序 |
| 2i 理论交接 | **仅模式 D**：空白 -> 框架映射 -> 机制就绪评估 -> 交接说明 |

---

## Phase 3：理论框架与假设推导（仅模式 D）

加载 **[phase-3-hypothesis.md](modules/lit/phases/phase-3-hypothesis.md)**，按六步推进：
1. **3a 框架评估**：构建多框架对比表（预测、适配度、理由）；
2. **3b 框架选择**：论证选定框架为何能解释该空白及竞争框架的不足；
3. **3c 机制阐释**：构建 `X -> M -> Y` 因果链、范围条件与机制类型标注；
4. **3d 假设推导**：提出 2–4 条假设及「空白 -> 框架预测 -> 机制链接 -> 假设」推导链表；
5. **3e 替代解释**：列明竞争预测及通过研究设计区分的方法；
6. **3f 呈现结构**：依据目标期刊选定融合式、分离式或整合 RQ 模式。

学科框架索引见 **[theory-frameworks.md](modules/lit/references/theory-frameworks.md)**；空白到假设桥接指南见 **[gap-to-hypothesis.md](modules/lit/references/gap-to-hypothesis.md)**。

### 非假设取向设计的承接

当上游设计报告为概念/解释理论、规范理论或思想史/文本阐释取向且 `analysis_required: false` 时，不进入 Phase 3 假设推导，直接沿 Phase 2 与 Phase 4 将核心论题、概念区分、规范原则或阐释框架整理为「支持立场—竞争立场—反例/反诠释—可用材料」，写入文献地图与综述交接材料。

---

## Phase 4：写作规划与交接（模式 A / B / C / D）

遵守 `master/output-protocol.md` 与 `master/literature-review-protocol.md`。过程性文献地图、证据矩阵与假设推导保留在 `02-literature/`；综述正文净稿仅由 `write` 输出至 `05-writing/literature-review.md`。

加载 **[phase-4-write.md](modules/lit/phases/phase-4-write.md)** 执行四步：
1. **4a 证据表与综述蓝图**：将每项可写判断映射至文献、原文位置、适用边界与段落任务；
2. **4b 论证组织**：围绕研究问题比较支持、竞争或不可直接比较的研究；
3. **4c 交接 `write`**：将 `paper-registry.csv`、`review-evidence.csv`、`review-outline.md` 与 `review-gaps.md` 移交 `write` 统一成稿；
4. **4d 产物分离**：确保过程材料与正文净稿完全分离。

叙事框架与过渡参考见 **[synthesis-guide.md](modules/lit/references/synthesis-guide.md)**。

---

## 质量检查清单

- **检索与定位覆盖**：[ ] Step 0a 方向确认与 Step 0Q 来源确认完成 [ ] 英文任务已执行 `probe_channels.py` 两遍并判断出口 IP [ ] `LITDOWN_EMAIL` 已设置（非 `example.com`） [ ] 中文条目未误入 Crossref，已走 `ncpssd_search.py` 定位与顶刊分级 [ ] Crossref 第二轮已执行 `audit --apply` [ ] 已按年份分布决定 `mirror-first` 或 `oa-first` + `--probe-oa` [ ] 本地库与 Zotero MCP 已验收、暂缓或记录缺失 [ ] CNKI 与 `web_search` 状态已明确记录 [ ] H/M 摘要已入库或写入待补清单
- **下载、四件套校验与归档**：[ ] 英文已执行 `verify_content.py` / `make_report.py`（合并 state 成功优先），无 DOI 专著已单开 `books_libgen.py` 并拦截书评 [ ] 中文已执行 `cnki_prepare.py` → `cnki_fetch_batch.mjs` → `cnki_report.py` [ ] 唯一 `paper-registry.csv` 已建立，PDF 存于 `papers/` 并完成 `mark-download` 哈希与页数回写 [ ] 失败项保留原因与断点状态 [ ] Step 10 MinerU 解析落于 `fulltext/paper_id/document.md` 并回写 `parse_status`
- **Zotero 归档与滚雪球**：[ ] 启用 Zotero 时已完成集合归档、挂接 PDF 与全文子笔记 [ ] `citation-intersection.md` 已生成，共引 ≥ 2 条目逐条判读并完成滚雪球
- **文献地图与交接**：[ ] 纳入文献均有摘要（无纯标题纳入） [ ] 区分无效应、接近零与缺证据 [ ] `review-evidence.csv` 关键 claim 均有原文定位 [ ] `review-outline.md`、`review-gaps.md` 就绪且过程报告与正文净稿分离
- **假设推导（模式 D）**：[ ] 推导链完整 [ ] 每条 H 可追溯至理论与机制 [ ] 无常识直推假设 [ ] 替代解释明确

---

## 参考文件按需索引

仅在推进到对应阶段时读取相应文件，避免一次性全量加载：

| 当前阶段 | 文件路径 | 说明 |
|---|---|---|
| Phase 0 | [phase-0-init.md](modules/lit/phases/phase-0-init.md) | 初始化、目录建置与模式解析 |
| Phase 1 | [phase-1-search.md](modules/lit/phases/phase-1-search.md) | `lit-down` 检索下载全流程、20 条铁律、四件套校验与 Step 9–12 闭环 |
| Phase 1 | [channels.md](modules/lit/references/channels.md) | 英文元数据、OA、Sci-Hub 镜像、搜索源与假信号诊断总表 |
| Phase 1 | [publishers.md](modules/lit/references/publishers.md) | 出版社直链模板、Elsevier PII 与 `oa_status` 分流 |
| Phase 1 | [books.md](modules/lit/references/books.md) | 专著与章节赛道：合法路线、LibGen `topics[]=l` 与书评陷阱 |
| Phase 1 | [browser.md](modules/lit/references/browser.md) | `ego-browser` 浏览器兜底、Turnstile cookie、CDP `Page.getResourceContent` 与 `Page.printToPDF` |
| Phase 1 | [ncpssd.md](modules/lit/references/ncpssd.md) | 中文定位入口 NCPSSD、64 种顶刊分级、限流与 iCloudWAF 处置 |
| Phase 1 | [cnki.md](modules/lit/references/cnki.md) | 知网机构出口：专业检索、下载单+Referer 直取、验证码冷却与 `cnki_*` 脚本族 |
| Phase 1 | [search-strategies.md](modules/lit/references/search-strategies.md) | PRISMA 流程、学科核心期刊谱系、检索式构造与文献矩阵模板 |
| Phase 0/1 | [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md) | Zotero 本地库检索、入库、附件与笔记协议 |
| Phase 1 | [mineru-pdf2md.md](modules/lit/references/mineru-pdf2md.md) | 内置 MinerU PDF 转 Markdown 协议 |
| Phase 2 | [phase-2-landscape.md](modules/lit/phases/phase-2-landscape.md) | 2a–2i 文献景观地图构建 |
| Phase 3 | [phase-3-hypothesis.md](modules/lit/phases/phase-3-hypothesis.md) | 框架—机制—假设推导流程 |
| Phase 3 | [theory-frameworks.md](modules/lit/references/theory-frameworks.md) | 学科框架索引（按需路由至 `modules/design/frame/theory-frameworks-*.md`） |
| Phase 3 | [gap-to-hypothesis.md](modules/lit/references/gap-to-hypothesis.md) | 空白到假设的逻辑桥接规范 |
| Phase 4 | [phase-4-write.md](modules/lit/phases/phase-4-write.md) | 综述证据表、蓝图与写作交接流程 |
| Phase 4 | [synthesis-guide.md](modules/lit/references/synthesis-guide.md) | 文献综合结构与论证过渡写法 |
