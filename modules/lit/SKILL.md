---
name: paper-lit-4ss
description: 中英文双语文献综述与假设推导一体化技能。支持五种模式：完整文献地图（A）、定向综述（B）、快速概览（C）、文献综述+假设推导（D）、知网专项搜索（E）。自动搜索本地文献库、CNKI 中文文献（浏览器控制 kns8s 专业检索，后端为 ZCode 内置 browser-use 或 OMP pi-chrome）、Google Scholar、WebSearch、Annual Reviews，生成结构化文献景观地图；收到理论、规范或阐释设计报告时在既有流程中组织支持立场、竞争立场和反例材料，不强制假设推导。当用户需要写文献综述、做系统回顾、找研究空白、提出研究假设、搜索中英文文献时使用。
argument-hint: "[研究主题] [可选: 完整|定向|快速|假设|知网] [可选: 目标期刊]"
user-invocable: true
---

# 文献综述与假设推导

一体化中英文文献综述技能。覆盖从搜索→文献地图→理论框架→假设推导的完整流水线。

## 路径约定

- 本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；若从本模块目录直接运行，也可将同模块路径改用 `agents/...`、`phases/...`、`references/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md` 与 `master/literature-review-protocol.md`。本模块的搜索日志、文献地图、证据表、综述蓝图、假设推导、顾问意见、综合文件和最终回复默认使用中文 Markdown；文献题名、作者、期刊、数据库名和检索式可保留原文。综述正文由 write 按共享协议生成，不能把过程材料拼进正文。机制链、假设推导链、PRISMA/检索流程、文献地图流程和 agent 派发/综合链路必须使用 Mermaid 图示，并在图后附 2-4 条中文解释。

## 多智能体并行触发

默认按 `master/agent-orchestration.md` 积极派发本模块顾问。遇到完整文献地图、双语文献检索、争议领域梳理、假设推导或较大规模文献综合时，必须并行派发本模块顾问；轻量快速概览若跳过，记录 `agent-skip`。派发前先读取对应 agent 定义，并把研究主题、检索阶段、范围约束、已有论文清单、摘要和用户确认事项作为输入包。实际派发以 `references/agent-registry.md` 中的 canonical agent name 为准；下表路径只作为角色协议路径。

| 触发场景 | 可派发 agent |
|---|---|
| 检索词、来源组合、阶段路线和补洞策略 | `modules/lit/agents/search-strategy-consultant.md` |
| 纳入、排除、待核验分类 | `modules/lit/agents/screening-consultant.md` |
| 理论谱系、概念关系、争议脉络和知识空白 | `modules/lit/agents/theory-map-consultant.md` |
| 证据等级、方法质量、适用边界 | `modules/lit/agents/evidence-quality-consultant.md` |
| 空白、理论、机制与假设桥接 | `modules/lit/agents/hypothesis-bridge-consultant.md` |

主流程负责综合顾问意见，形成搜索日志、文献地图、综述草稿和假设推导。所有顾问意见写入 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/`，并生成 `agent-synthesis-lit-[YYYY-MM-DD].md`。若当前环境不能真实并行，则按上表顺序完成角色复核，并记录 `sequential-review`。

## 安装与依赖选择（发布版）

正式安装和运行前必须先阅读 **[install-dependencies.md](modules/lit/references/install-dependencies.md)** 并完成验收。浏览器控制是 CNKI 检索的强制依赖，后端按宿主二选一：ZCode 内置 browser-use（内置能力，无需安装）或 OMP pi-chrome（一次性加载伴生 Chrome 扩展，适配见 **[pi-chrome-browser.md](modules/lit/references/pi-chrome-browser.md)**，对外公开文档 <https://github.com/JingYangYuan/pi-chrome-cnki>）；Google Scholar 用 WebFetch/WebSearch 完成；Zotero、Zotero Connector、Zotero MCP 是可选增强，只在用户需要保存题录/全文、联动本地文献库或读取 Zotero 附件全文时启用。Zotero MCP 的推荐实现与操作协议见 **[zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md)**。

**执行铁律：**

- CNKI 检索页必须对用户可见可操作：CNKI 登录、验证码由用户手动完成。ZCode 后端浏览器面板常驻可见；OMP pi-chrome 默认后台运行，用户切到 `Pi Session:` 分组标签完成登录/验证码，需要前台跟随时再 `/chrome background off`。
- CNKI 检索、摘要抓取和全文下载必须通过浏览器控制 + Cookie/curl 完成，PDF 不得走浏览器下载管线。Cookie 只落盘给下载器使用（0600），用完即删；禁止把 `document.cookie` 内容回传对话或写入日志——OMP 后端用回环 sink（`modules/lit/scripts/cnki/cookie_sink.py`）。
- Phase 0/Step 0Q 必须询问用户是否启用 Zotero 和 Zotero MCP。
- 用户不想保存论文全文或不使用本地库时，不得强制安装 Zotero；本地文献库阶段记录为 `用户明确暂缓`，继续在线检索。
- 若用户选择 Zotero/Zotero MCP，则按 `modules/lit/references/install-dependencies.md` 完成 Zotero Desktop、Connector、MCP 工具验收后再执行本地库或全文保存阶段。
- 验收通过后，本地库检索、摘要即时入库、全文深读和集合登记按 `modules/lit/references/zotero-local-mcp.md` 执行；不得用 WebSearch 或顾问意见冒充 Zotero 完成状态。
- 所有安装验收和失败处理以 `modules/lit/references/install-dependencies.md` 为准。

## 参数

`$ARGUMENTS` — 从中提取：**研究主题**、**模式关键词**、**目标期刊**（可选）、**范围约束**（可选）。

## 路由分发

根据参数自动分发。若 design 的 `design-report` 或 `full-report` 标注概念/解释理论、规范理论或思想史/文本阐释且 `analysis_required: false`，在既有文献地图和写作流程中输出支持立场、竞争立场与反例材料，跳过假设推导；未检测到关键词且无 design 交接时默认模式 A。

| 关键词 | 模式 | 搜索 | 论文数 | 字数 | 推导假设 |
|--------|------|------|--------|------|----------|
| `完整` `地图` `全面` `landscape` | **A: 完整地图** | 6轮+ | 40-80 | 3-10k字 | 否 |
| `定向` `聚焦` `前言` `targeted` | **B: 定向综述** | 4轮 | 15-30 | 1-3k字 | 否 |
| `快速` `概览` `初步` `rapid` | **C: 快速概览** | 2轮 | 10-20 | 0.5-1.5k字 | 否 |
| `假设` `hypothesis` | **D: 综述+假设** | 5轮+ | 30-60 | 2-5k字 | 是 |
| `知网` `CNKI` `中文` | **E: 知网专项** | CNKI 网页操纵为主；WebSearch 仅可做关键词准备 | 10-30 | 无 | 否 |

> **模式E执行轨道（唯一）**：使用浏览器控制走 **kns8s 闭环轨道**（检索→分析摘要→选择下载全文一体化），完整协议见 [cnki-kns8s-closed-loop.md](modules/lit/references/cnki-kns8s-closed-loop.md)（经验来源 `~/.zcode/skills/cnki-skill` 与 2026-09-12 pi-chrome 实测；下载器 `modules/lit/scripts/cnki/kns8s-download.sh`）。后端二选一：ZCode 内置 browser-use，或 OMP pi-chrome（安装与适配见 [pi-chrome-browser.md](modules/lit/references/pi-chrome-browser.md)，公开文档 <https://github.com/JingYangYuan/pi-chrome-cnki>）。浏览器控制不可用时记录 `浏览器控制不可用` 并停止 CNKI 阶段。

### 理论意图检测

若含 `假设`/`hypothesis` 但未选模式D，提示用户确认是否启用一体化模式。仅出现“理论”不自动进入假设路径；若设计报告为理论路径，在既有文献地图中组织理论谱系、竞争立场、概念争议和可支撑/可反驳的论证根据。

---

## Phase 0：初始化（所有模式）

加载 **[phase-0-init.md](modules/lit/phases/phase-0-init.md)**，按以下固定顺序执行，不得跳过任何步骤：

### Step 0a：检索方向预确认（强制第一步）

**在任何搜索操作之前**，必须使用 ask_user 让用户逐项确认检索方向。这是 Phase 0 的**第一步**，未完成前不得创建目录、不得初始化日志、不得执行任何搜索。

```text
question: "请确认本次文献检索的方向与范围（可多选辅助确认）"
header: "检索方向"
options: [
  {label: "X→Y 主效应", description: "搜索核心自变量对因变量的直接影响"},
  {label: "X 概念族", description: "搜索核心自变量的测量、成因、趋势和相邻概念"},
  {label: "Y 概念族", description: "搜索因变量的概念谱系、测量和相邻结果"},
  {label: "M 机制变量", description: "搜索机制、中介、过程和解释链条"},
  {label: "W 调节变量", description: "搜索制度、区域、人群、行业、时期等调节条件"},
  {label: "IV 工具变量", description: "搜索工具变量、自然实验、政策冲击或识别策略先例"},
  {label: "竞品核查", description: "专门搜索与本研究问题高度相近的已有实证或理论研究"}
]
```

用户选择后，将每个选中方向映射为具体的**中英文检索词对**，写入搜索日志的 `检索方向映射` 表。未选中的方向标记为 `用户暂不覆盖`，后续检索中若偶然命中仍需记录但不主动扩展。

### Step 0b：检索阶段预确认（强制）

使用 ask_user 确认本次启用哪些检索阶段。CNKI 和 Google Scholar 不得默认跳过。

结构化示例见 `references/ask-user-question-examples.md`；本模块的 0Q、阶段确认、验证码和补检示例详见 `modules/lit/phases/phase-1-search.md`。

### Step 0c：基础设置

- 初始化 paper-workspace/02-literature/papers/、fulltext/、plans/ 与唯一题录注册表 paper-registry.csv；既有用户文件只登记原路径，不迁移
- 初始化搜索日志（**磁盘持久化**，防上下文压缩丢失），日志中必须包含 Step 0a 的 `检索方向映射` 表
- 初始化论文清单表
- 解析模式、目标期刊、范围约束
- 确定搜索路线图

---

## Phase 1：文献搜索（所有模式）

加载 **[phase-1-search.md](modules/lit/phases/phase-1-search.md)**。**固定搜索顺序：**

| 步骤 | 来源 | A | B | C | D | E | 说明 |
|------|------|---|---|---|---|---|------|
| 0Q | 检索阶段预确认 | ✓ | ✓ | ✓ | ✓ | ✓ | ask_user：确认各阶段是否执行；CNKI/Scholar 不得默认跳过 |
| 1 | WebSearch 先行 | ✓ | ✓ | ✓ | ✓ | 可选 | 识别关键词变体+核心文献+摘要总结 |
| 1Q | 用户方向确认 | ✓ | ✓ | ✓ | ✓ | ✓ | ask_user：确认保留/排除/扩展方向 |
| 2 | 知识图谱 | ✓ | ✓ | ✓ | ✓ | - | 补充预提取发现（如有） |
| 2Q | 用户方向确认 | ✓ | ✓ | ✓ | ✓ | - | ask_user：确认是否转向理论/机制/人群 |
| 3 | 本地文献库 | ✓ | ✓ | ✓ | ✓ | 可选 | 匹配已收集文献+PDF深度阅读（如有） |
| 3Q | 用户方向确认 | ✓ | ✓ | ✓ | ✓ | ✓ | ask_user：确认已有文献缺口 |
| 4 | Annual Reviews | ✓ | ✓ | - | ✓ | - | 综述检查点，提取经典脉络 |
| 4Q | 用户方向确认 | ✓ | ✓ | - | ✓ | - | ask_user：确认综述脉络和经典文献 |
| 5 | 引文链扩展 | ✓ | 可选 | - | ✓ | - | 向前/向后追踪 |
| 5Q | 用户方向确认 | ✓ | 可选 | - | ✓ | - | ask_user：确认最终补洞方向 |
| 6 | CNKI/Scholar 可达性检查 | ✓ | ✓ | ✓ | ✓ | ✓ | 两者都必须检查或由用户明确暂缓 |
| 7 | 浏览器控制精准补充 | ✓ | ✓ | ✓ | ✓ | ✓ | 可达且未暂缓的 CNKI/Scholar 精准补缺口 |

**核心逻辑**：先询问用户本次启用哪些检索阶段 → WebSearch 摸清领域关键词和核心文献 → 每阶段后让用户确认方向 → 本地库匹配已收集论文 → Annual Reviews 和引文链确定经典脉络 → 最后才用 CNKI/Google Scholar 做精准补充。

**关键规则：**
- 每次搜索后立即追加搜索日志（防上下文压缩数据丢失）
- **检索阶段预确认铁律**：Phase 1 开始前必须先 ask_user，让用户确认是否启用 WebSearch、本地文献库、Zotero/Zotero MCP、Annual Reviews、引文链扩展、CNKI、Google Scholar。CNKI 与 Google Scholar 不得默认跳过；必须记录为 `已执行` / `用户明确暂缓` / `网络不可达`。Zotero/Zotero MCP 可由用户明确暂缓，尤其适用于不保存论文全文的轻量检索。
- **阶段确认铁律**：每完成一个搜索阶段，必须使用 ask_user 汇报新增论文、疑似噪音、当前空白和下一步建议，等待用户确认后再进入下一阶段。
- **摘要铁律**：所有进入论文清单、文献地图、综述草稿或假设推导的论文都必须有摘要或等价的全文摘要信息；标题、作者、期刊、引用数只能用于候选排序，不能用于正式纳入。没有摘要的文献只能列入"待核验/排除候选"，不得作为证据使用。
- **CNKI/Scholar 后置但不跳过铁律**：CNKI 和 Google Scholar 仍放在后段精准补充，避免宽泛堆积；但不得默认跳过任一来源。两者必须在日志中有明确状态，并对可达且未暂缓的来源执行精准检索。
- **浏览器控制可用性铁律**：任何 CNKI 检索、关键词落地、结果解析、详情页摘要抓取或下载之前，必须先完成可用性检查：浏览器控制可列标签页/新建标签页/导航，能打开 `about:blank` 或 CNKI 首页并读取轻量页面状态。通过后才可记录 `浏览器控制正常` 并进入 CNKI 检索页。可用性检查与后端映射：ZCode 用内置 browser-use；OMP 用 pi-chrome，命令序列见 [pi-chrome-browser.md](modules/lit/references/pi-chrome-browser.md) §3。不可用时记录 `浏览器控制不可用` 并停止 CNKI 阶段，不得执行 CNKI 页面脚本、不得写 `CNKI 已执行`。
- **CNKI 检索入口铁律**：CNKI 正式检索默认且只默认专业检索页 `https://kns.cnki.net/starter/advanced`（跳转 `kns.cnki.net/kns8s/AdvSearch` 后切「专业检索」标签）。基础检索框只允许做单个自然短语、专名或站点可达性临时测试。不得把 WebSearch/Google Scholar 布尔串粘进基础检索框。多关键词先拆概念组转专业检索式：同义/近义词用 `+` 并入同一 `SU=(...)`，不同概念分轮宽检索，只有结果过大且用户确认跨概念收窄时才用 `*`。
- **CNKI 结果量控制铁律（不可跳过）**：专业检索触发后默认点「学术期刊N」筛选只保留期刊论文；结果仍过大时默认按被引排序（`li#CF`）取高影响文献。若宽检索命中为 0，立即回退上一轮宽松检索式，不继续叠加限制。**每轮 CNKI 检索返回后，必须在回复中显式报告命中总数和是否触发筛选收窄，作为阶段确认的一部分。**
- **CNKI 来源不可替代铁律**：CNKI 阶段只能由浏览器控制中的 CNKI（kns8s）网页操纵完成，包括专业检索页、结果页、详情页、期刊页或导出页。WebSearch、Google Scholar、普通搜索引擎、`cnki-researcher` 或 lit agents 只能做关键词准备、概念组设计和筛选建议；这些来源不得标记为 CNKI 完成状态，也不得填充 CNKI 论文清单字段。
- **Zotero 摘要存储铁律**：每篇进入正式论文清单（相关度 H 或 M）的论文，必须在抓取摘要后**立即**通过当前可用的 Zotero MCP 或 Zotero Connector 存入 Zotero，且包含 `abstractNote` 字段。不得等所有检索结束后批量补存。存入后记录 Zotero `item_key` 或连接器保存状态到搜索日志的论文清单中，并写入 `paper-registry.csv` 的 `source_id`（来源 `zotero-local-mcp`）。若 Zotero MCP/Connector 不可用，记录 `Zotero 不可用，摘要未保存` 并写入 `paper-workspace/02-literature/abstracts-pending-zotero.md` 待后续补存。操作步骤见 [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md)。
- **阶段判断更新规则**：每个检索阶段完成后，记录新文献改变或限制了哪些既有判断、需要补哪类证据；写入 stage-syntheses.md 仅作过程记录。不得按数据库来源直接拼接为综述正文。
- WebSearch 检索策略详见 **[search-strategies.md](modules/lit/references/search-strategies.md)**
- CNKI 闭环协议详见 **[cnki-kns8s-closed-loop.md](modules/lit/references/cnki-kns8s-closed-loop.md)**；免弹窗下载器为 `modules/lit/scripts/cnki/kns8s-download.sh`，按需读取协议对应章节，不得一次性加载全部代码。
- **面板可见铁律**：CNKI 登录、验证码由用户在可见浏览器中手动完成；自动化遇到人工闸门时停止并询问，不得后台绕过。ZCode 后端浏览器面板常驻可见；OMP pi-chrome 在默认后台模式下不抢焦点，用户切到 `Pi Session:` 分组标签操作即可。
- **CNKI 验证码铁律**：只有通过 [cnki-kns8s-closed-loop.md](modules/lit/references/cnki-kns8s-closed-loop.md) 的几何可见性判据（验证码容器在视口内且尺寸有效）确认真实可见时，才停止自动化并请用户在浏览器面板手动完成。隐藏预加载 DOM、0 结果、空结果表、页面未加载完或检索式过窄不得按验证码处理。

**搜索后评估**：论文数不足模式目标则追加检索。

**Step 8–12 强制链（2026-09-05 实测修订，2026-09-12 扩展，模式 A/B/D 终段必经）**：
- **Step 8 CNKI 精准闭环**：操作修正（`li[name="majorSearch"]` 切标签、`#ModuleSearch input.btn-search` 提交、结果渲染在 AdvSearch 主页面 body、facet 祖先点击）+ **>1000 命中先做学科边界讨论，边界清晰则用 CSSCI/北大核心/AMI 来源类别收窄** + **相关度与被引双排序、两种排序第一页逐条打开详情页抓摘要** + **高被引锚文献的引证文献（前沿）与共同参考文献（学科基础）**。详见 [phase-1-search.md](modules/lit/phases/phase-1-search.md) Step 8。
- **Step 9 Top-N 归档**：候选文献先写入 paper-registry.csv，下载计划由注册表生成。CNKI 走 modules/lit/scripts/cnki/kns8s-download.sh（Cookie + curl）；下载完成后才写入 papers/，并由注册表记录哈希、页数、状态和失败原因。
- **Step 10 全文化与证据映射**：用模块内置 modules/lit/scripts/mineru/pdf2md.py 加 --registry 解析至 fulltext/paper_id/document.md，逐篇回写解析状态。核读后把可用判断与原文定位写进 review-evidence.csv；关键主张必须逐条可回查，不使用“全文主张比例”替代溯源。不得引用外部 MinerU skill 路径。
- **Step 11 Zotero 集合归档与全文笔记**：目标集合（项目 slug）不存在则 `zotero_create_collection` 自动创建；H/M 条目 `zotero_add_item`（含 abstractNote）后 `zotero_attach_file` 挂 papers/ 本地 PDF、`zotero_set_item_collections` 归入项目集合；MinerU 全文 md 以纯文本骨架经 `zotero_manage_note` 写成条目子笔记（`zotero_get_notes` 同名查重、约 80k 字符截断）。协议见 [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md) §5b。
- **Step 12 参考文献交集滚雪球**：`python3 modules/lit/scripts/citation_intersection.py --workspace <paper-workspace>` 对已解析全文的参考文献取交集，产出 `02-literature/citation-intersection.md`；共引频次 ≥2 的高重复度条目逐条判读（已有/新增候选/待核验），未收录者登记注册表并补抓摘要，再以专业检索式回 CNKI 滚雪球检索下载（最多 2 轮或无新增共引即停）。
- **英文检索 exa 首选**：`web_search_exa`/`web_fetch_exa` 为英文文献主动首选通道（语义化 query + 批量摘要抓取），WebSearch 做中文与交叉验证；协议见 [search-strategies.md](modules/lit/references/search-strategies.md) exa 节。

---

## Phase 2：文献景观地图（模式A/B/C/D）

加载 **[phase-2-landscape.md](modules/lit/phases/phase-2-landscape.md)**。构建 2a–2i 分析维度（2i 仅模式D）：

| 维度 | 内容 |
|------|------|
| 2a 领域演进 | 时代划分、范式转移、关键转折点 |
| 2b 理论版图 | 框架×核心主张×预测×实证支持×地位 |
| 2c 可支持的发现与判断 | 仅呈现当前证据足以支撑的发现、判断及其边界 |
| 2d 争议发现 | 证据分歧×权重评估×争议来源×解决路径 |
| 2e 非显著与缺少证据 | 区分非显著、接近零与检索范围内尚未发现直接研究 |
| 2f 机制清单 | 所有提出机制×类型×是否检验×状态 |
| 2g 方法版图 | 主导设计×数据源×优势×局限 |
| 2h 空白汇总 | 结构化空白表×排序（发表潜力×可行性） |
| 2i 理论交接 | **仅模式D**：空白→框架映射→机制就绪评估→交接陈述 |

---

## Phase 3：理论框架与假设推导（仅模式D）

加载 **[phase-3-hypothesis.md](modules/lit/phases/phase-3-hypothesis.md)**。从空白到假设的四步：

1. **3a 框架评估** — 多框架对比表（预测×适配度×原因）
2. **3b 框架选择** — 为什么该框架解决该空白，竞争框架为何不足
3. **3c 明确机制** — X→M→Y 因果链 + 范围条件 + 机制类型标注
4. **3d 推导假设** — 2-4条假设 + **推导链表**（每条H必须通过"空白→框架预测→机制链接→假设"四列验证）
5. **3e 替代解释** — 竞争预测 + 设计区分方式
6. **3f 呈现模式** — 按目标期刊确定融合式/分离式/整合-RQ

**详细框架目录**见 **[theory-frameworks.md](modules/lit/references/theory-frameworks.md)**（按研究领域按需加载章节）。
**空白→假设桥接**见 **[gap-to-hypothesis.md](modules/lit/references/gap-to-hypothesis.md)**。

### 理论、规范与阐释设计的文献承接

当设计报告标记理论、规范或阐释取向且 `analysis_required: false`，不进入假设推导。使用既有 Phase 2 与 Phase 4：将中心论题、概念区分、规范标准或阐释框架对应为“支持立场—竞争立场—反例/反诠释—可用材料”，写入文献地图与综述交接；不得另建独立模式或 phase。

---

## Phase 4：写作与输出（模式A/B/C/D）

所有输出遵守 `master/output-protocol.md` 与 `master/literature-review-protocol.md`：文献景观地图、证据矩阵和假设推导保留在 lit 阶段；可进入论文的综述正文只由 write 输出到 `05-writing/literature-review.md`。机制图、假设推导链和 PRISMA/检索流程图必须使用 Mermaid，普通证据矩阵和文献清单继续使用 Markdown 表格。

加载 **[phase-4-write.md](modules/lit/phases/phase-4-write.md)**。执行：

1. **4a 证据表与综述蓝图** — 将每个可写判断关联到文献、原文位置、边界和段落任务
2. **4b 论证组织** — 围绕研究问题比较支持、竞争或不可直接比较的研究
3. **4c 写作交接** — 将证据表和蓝图交给 write 的统一正文流程
4. **4d 分离交付** — 过程材料留在 02-literature/，正文净稿只放在 05-writing/literature-review.md

**叙事模板与过渡短语**见 **[synthesis-guide.md](modules/lit/references/synthesis-guide.md)**。

---

## 质量检查清单

**搜索覆盖：** [ ]Step 0a 检索方向预确认已完成 [ ]Step 0b 检索阶段已确认 [ ]每阶段后用户确认 [ ]CNKI total>200 已执行 CSSCI/hx 收窄 [ ]>1000 命中已做学科边界讨论或来源类别收窄（Step 8.2） [ ]相关度+被引双排序已执行（Step 8.3） [ ]两序首页文献已逐条详情页抓摘要（Step 8.3） [ ]高被引锚文献引证/共引已执行（Step 8.4） [ ]本地文献库 [ ]Zotero MCP 已按 zotero-local-mcp.md 验收或记录暂缓/能力缺失 [ ]CNKI状态已记录 [ ]Google Scholar状态已记录 [ ]英文 exa MCP 已主动使用或记录回退（search-strategies exa 节） [ ]多轮搜索按模式 [ ]Annual Reviews [ ]论文数达标 [ ]H/M论文摘要已存入 Zotero 或待补存清单 [ ]阶段综述段落已输出

**下载与全文化：** [ ]Top-N 判选理由已写入注册表 [ ]唯一 paper-registry.csv 已初始化 [ ]PDF 均在 papers/ 或被登记为外部输入 [ ]下载器完成 .part→解析校验→归档 [ ]解析结果位于 fulltext/paper_id/document.md [ ]下载、解析、核读状态均已回写 [ ]失败项保留原因与续跑状态

**Zotero 归档与滚雪球：** [ ]项目集合已查重并创建/复用 [ ]H/M 条目含 abstractNote [ ]papers/ PDF 已挂附件 [ ]MinerU 全文 md 已存为 Zotero 子笔记或记录待办 [ ]citation-intersection.md 已产出 [ ]共引≥2 条目已逐条判读（已有/新增/待核验） [ ]二轮滚雪球已执行或记录停止理由

**文献地图：** [ ]所有纳入论文有摘要 [ ]无标题-only纳入 [ ]框架和发现数量与研究问题相称 [ ]争议有双方证据或不可比较说明 [ ]无效、接近零与证据不足已区分 [ ]机制和方法判断有证据边界 [ ]空白具体且命名最近先例 [ ]理论路径已整理支持、竞争与反例材料（如适用）

**综述交接：** [ ]review-evidence.csv 已建立 [ ]关键 claim 有原文定位 [ ]review-outline.md 映射所有正文段落 [ ]review-gaps.md 列出未核验内容 [ ]正文与过程报告分离 [ ]字数和结构匹配用户/期刊要求

**假设推导（模式D）：** [ ]推导链完整 [ ]每条H追溯理论+机制 [ ]无常识可推导假设 [ ]替代解释明确

---

## 参考文件加载

**按需加载，禁止一次性加载全部：**

| 加载时机 | 文件 | 内容 |
|---------|------|------|
| Phase 0 | [phase-0-init.md](modules/lit/phases/phase-0-init.md) | 初始化+模式解析 |
| Phase 1 | [phase-1-search.md](modules/lit/phases/phase-1-search.md) | 七步搜索流程 |
| Phase 1 | [cnki-kns8s-closed-loop.md](modules/lit/references/cnki-kns8s-closed-loop.md) | CNKI kns8s 检索→分析→下载闭环协议（后端中立）+ `modules/lit/scripts/cnki/kns8s-download.sh` |
| Phase 1 | [pi-chrome-browser.md](modules/lit/references/pi-chrome-browser.md) | OMP pi-chrome 后端的安装、授权、能力映射与失败恢复；ZCode 宿主用 §2.1 |
| Phase 1 | [phase-1-search.md](modules/lit/phases/phase-1-search.md) Step 8–12 | 实测修正协议：操作修正、>1000 来源类别收窄、双排序首页摘要、引证/共引、Top-N 下载与 CSV、MinerU 全文化、Zotero 集合与全文笔记、参考文献交集滚雪球 |
| Phase 0/1 | [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md) | 本地库检索、摘要即时入库、全文深读、集合登记 |
| Phase 1 | [search-strategies.md](modules/lit/references/search-strategies.md) exa 节 | 英文文献 exa MCP 首选协议 |
| Phase 1 | [mineru-pdf2md.md](modules/lit/references/mineru-pdf2md.md) | 模块内置 MinerU PDF→MD 协议（自包含） |
| Phase 1 | [search-strategies.md](modules/lit/references/search-strategies.md) | 学科搜索策略+布尔构建 |
| Phase 2 | [phase-2-landscape.md](modules/lit/phases/phase-2-landscape.md) | 2a–2i 景观地图 |
| Phase 3 | [phase-3-hypothesis.md](modules/lit/phases/phase-3-hypothesis.md) | 框架→机制→假设+推导链 |
| Phase 3 | [theory-frameworks.md](modules/lit/references/theory-frameworks.md) | 学科路由索引（加载后按关键词路由到 modules/design/frame/ 十四大学科/领域框架） |
| Phase 3 | modules/design/frame/theory-frameworks-*.md | 十四大学科/领域框架库（按路由结果按需加载 1-3 个文件） |
| Phase 3 | [gap-to-hypothesis.md](modules/lit/references/gap-to-hypothesis.md) | 空白→假设桥接指南 |
| Phase 4 | [phase-4-write.md](modules/lit/phases/phase-4-write.md) | 写作结构+文件输出 |
| Phase 4 | [synthesis-guide.md](modules/lit/references/synthesis-guide.md) | 综合框架+过渡短语 |
