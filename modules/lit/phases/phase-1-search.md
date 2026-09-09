# Phase 1：文献搜索

由 `lit module/SKILL.md` 在所有模式下加载。

## 顾问派发闸门

搜索开始前必须读取 `search-strategy-consultant` 的意见并写入 `agent-synthesis-lit-[YYYY-MM-DD].md`。候选论文清单形成后，派发 `modules/lit/agents/screening-consultant.md` 复核纳入/排除/待核验分类；进入下一 phase 前，把筛选结论追加到 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/agent-synthesis-lit-[YYYY-MM-DD].md`。

## 搜索顺序（固定，不可调换）

```
Step 0a: 检索方向预确认             → ask_user 确认检索方向并映射中英文检索词
Step 0Q: 检索阶段预确认             → ask_user 确认各阶段执行/暂缓
Step 1: WebSearch 先行             → 识别关键词变体 + 核心文献 + 摘要总结
Step 1Q: ask_user            → 确认关键词、噪音、下一步方向
Step 2: 知识图谱（如有）            → 补充预提取的发现和关系
Step 2Q: ask_user            → 确认理论、机制或人群方向
Step 3: 本地文献库（如有）          → 匹配已收集文献，通读 PDF
Step 3Q: ask_user            → 确认已有文献缺口
Step 4: Annual Reviews              → 综述文章检查点
Step 4Q: ask_user            → 确认经典脉络和综述方向
Step 5: 引文链扩展                  → 向前/向后追踪
Step 5Q: ask_user            → 确认最终补洞方向
Step 6: CNKI/Scholar 可达性检查     → 两者都检查或记录用户明确暂缓
Step 7: 浏览器控制最终精准补充     → 可达且未暂缓的 CNKI/Scholar 精准补缺口
```

**核心逻辑**：先询问用户本次检索阶段是否全部启用；再用 WebSearch 摸清领域关键词和核心文献面貌；每完成一个搜索阶段，先让用户确认方向，避免无效堆积；再做本地匹配、综述检查和引文链；最后根据已确认的缺口，用 CNKI 和 Google Scholar 做精准补充。CNKI 和 Google Scholar 不再用于中段宽泛搜索，但不得被默认跳过。

## Step 0a：检索方向预确认（强制第一步）

任何检索、目录创建、日志初始化或顾问检索建议落地前，必须先 ask_user 确认本次检索方向。用户选择后，把每个方向映射为具体中英文检索词对，写入 `SEARCH_LOG` 的 `检索方向映射` 表。

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
  {label: "竞品核查", description: "专门搜索与本研究问题高度相近的已有研究"}
]
```

未选中的方向标记为 `用户暂不覆盖`。后续检索若偶然命中这些方向，可以记录在候选清单中，但不得主动扩展为新的检索轮次，除非用户在阶段确认中重新选择。

## Step 0Q：检索阶段预确认（强制）

任何检索开始前，必须先调用 ask_user，询问本次是否启用以下阶段：

1. WebSearch 先行探路
2. 本地文献库 / 已有 PDF
3. Zotero / Zotero MCP（保存题录、保存全文、读取附件全文时启用）
4. Annual Reviews 综述检查点
5. 引文链扩展
6. CNKI 中文文献
7. Google Scholar 英文文献

默认建议启用所有与模式相关的在线检索阶段。CNKI 与 Google Scholar 不得默认跳过；除非用户明确选择 `暂缓`，否则必须至少完成可达性检查，并在 `SEARCH_LOG` 记录为以下状态之一：

```
已执行 / CNKI 已执行 / 用户明确暂缓 / 网络不可达 / 浏览器控制正常 / 浏览器控制不可用 / 浏览器页面未完成 / CNKI 页面未完成
```

### 开场问询模板

结构化示例模块统一遵守 `references/ask-user-question-examples.md`。0Q 可使用以下 ask_user 示例：

```text
question: "本次文献检索阶段如何安排？CNKI 和 Google Scholar 不得默认跳过，Zotero 可按是否保存全文决定。"
header: "检索阶段"
options: [
  {label: "在线全启用", description: "启用 WebSearch、Annual Reviews、引文链、CNKI 和 Google Scholar，Zotero 暂缓"},
  {label: "全部启用", description: "同时启用本地文献库和 Zotero/Zotero MCP，适合保存题录、全文或读取附件"},
  {label: "指定阶段", description: "用户逐项指定启用或暂缓的来源；CNKI/Scholar 只能由用户明确暂缓"}
]
```

```
本次文献检索将分阶段进行，避免无效堆积。请确认启用哪些阶段：
- WebSearch：先摸清关键词、核心文献和摘要
- 本地文献库：检查已有文献/PDF；不使用本地库时可暂缓
- Zotero/Zotero MCP：保存题录/全文、读取 Zotero 附件全文；不保存全文时可暂缓
- Annual Reviews：检查经典综述脉络
- 引文链扩展：追踪经典和近年前沿
- CNKI：后段精准补充中文文献，不默认跳过
- Google Scholar：后段精准补充英文文献，不默认跳过

问题：本次检索阶段如何安排？
选项A：在线检索全启用，Zotero 暂缓（推荐给不保存全文的用户）
选项B：全部启用，包括 Zotero/Zotero MCP
选项C：按用户指定阶段执行
```

用户若选择 C，必须追问或从用户文本中提取每个阶段的状态。CNKI 和 Google Scholar 只能被标记为 `用户明确暂缓`，不能因为模式、环境猜测或时间节省而静默跳过。Zotero/Zotero MCP 可以由用户明确暂缓；暂缓只影响本地库、全文保存和附件全文读取，不影响在线检索与摘要核验。

## 阶段确认闸门（强制）

每个搜索阶段结束后，必须先写入搜索日志和阶段综述段落，然后调用 ask_user。不得在未获得用户确认时继续下一阶段。

### 问询内容模板

各阶段确认可复用以下 ask_user 示例：

```text
question: "本阶段已完成。下一阶段按哪个方向继续？"
header: "方向确认"
options: [
  {label: "按推荐继续", description: "采用当前搜索日志中证据最充分的关键词、理论或机制方向"},
  {label: "收窄方向", description: "收窄到用户指定的理论、机制、人群、时期或中文/英文文献缺口"},
  {label: "改查方向", description: "放弃当前推荐方向，改用用户指定的新检索方向"}
]
```

```
本阶段新增：
- 有摘要且可纳入：N篇（列3-5篇代表论文）
- 无摘要/仅题录：N篇（暂不纳入）
- 疑似噪音：N篇（说明原因）

当前判断：
- 已清晰的关键词/理论/机制：
- 仍缺的方向：
- 建议下一阶段检索式：

问题：下一阶段按哪个方向继续？
选项A：按推荐方向继续
选项B：收窄到[某理论/机制/人群/时期]
选项C：改查[用户指定方向]
```

### 用户确认后的处理

- 用户选 A：按推荐检索式进入下一阶段。
- 用户选 B：立即改写下一阶段检索式，并把收窄理由写入日志。
- 用户选 C：使用用户指定方向，旧方向只保留为备选。
- 用户要求停止：保存当前日志和论文清单，终止后续搜索。

### 阶段综述沉淀

每个检索阶段完成后，必须输出并写入一段 200-400 字中文综述段落，综合该阶段新增论文的核心发现、方法特征、证据强弱和与本研究问题的关系。所有阶段段落追加到：

```text
paper-workspace/02-literature/stage-syntheses.md
```

阶段综述是 Phase 4 文献综述草稿的素材，不得只用论文罗列表替代。若某阶段无可纳入论文，也要写明无新增证据的原因、待核验缺口和下一阶段补洞方向。

## 摘要准入规则（强制）

所有进入正式论文清单、Phase 2 文献地图、Phase 3 假设推导或 Phase 4 草稿的论文，必须具备以下之一：

- 数据库/期刊页面可抓取摘要；
- PDF/全文中可提取摘要、引言摘要段或等价的研究概述；
- 综述/书籍章节无标准摘要时，必须提取至少150字的核心论点摘要。

标题、作者、期刊、引用数、下载数和搜索结果片段只能用于候选排序，不能用于正式纳入。无摘要、仅题录、只有标题作者的文献，一律放入"待核验/排除候选"，不得作为证据引用。每篇正式纳入论文在清单中必须填写：

```
摘要状态：已抓取摘要 / 全文可替代摘要
摘要要点：研究问题 + 方法/材料 + 核心发现
```

**执行约束**：每篇候选至少抓取摘要、数据库详情页摘要、PDF/全文摘要段或等价全文概述后，才允许判断为保留。不得只看标题决定纳入，不得用"看起来相关"替代摘要核验。

**Zotero 摘要存储约束**：每篇进入正式论文清单且相关度为 H 或 M 的论文，必须在抓取摘要后立即尝试存入 Zotero，保存内容必须包含 `abstractNote` 或等价摘要字段。当前宿主若暴露 Zotero MCP，则优先使用 Zotero MCP；若只有 Zotero Connector 或本地导出能力，则记录连接器保存状态；若 Zotero 不可用，写入 `paper-workspace/02-literature/abstracts-pending-zotero.md`，并在搜索日志中记录 `Zotero 不可用，摘要未保存`。不得等检索结束后再批量补存摘要。

**浏览器控制可用性硬约束**：进入任何 CNKI 检索动作前，必须先完成 Step 6.0 的浏览器控制可用性检查：ZCode 内置浏览器控制（browser-use）可列标签页/新建标签页/导航，能打开 `about:blank` 或 CNKI 首页并读取轻量页面状态。检查未通过时，不得进入 CNKI 检索页、不得执行任何 CNKI 页面脚本、不得写 `CNKI 已执行`。browser-use 不可用时记录 `浏览器控制不可用`，停止 CNKI 阶段并提示用户重启宿主会话；不得 kill 进程、不得用 WebSearch、Google Scholar、普通搜索、`cnki-researcher` 或 lit agents 替代 CNKI 检索结果。CNKI 需要登录、验证码或人工确认时，在用户可见的浏览器面板中完成。

---

## Step 1：WebSearch 先行探路（所有模式）

**目的**：快速识别领域核心关键词（含同义词/中英对照）、找到 5-10 篇核心文献、对摘要进行初步总结。为后续搜索提供方向校准。

### 1a. 关键词勘探

运行 2-3 个宽泛检索式，摸清领域术语面貌：

```
"[主要概念]" "[结果变量]" sociology OR demography
"[主要概念]" review OR meta-analysis OR 综述
"[主要概念]" "[中文对应词]"
```

**产出**：关键词变体清单（含中英文对照、同义词、上位词/下位词）。

### 1b. 核心文献定位

用精炼后的关键词运行 3-5 个检索式，定位核心文献：

```
"[精炼概念]" "[精炼结果]" "[学科]"
"[精炼概念]" "[机制词]" "[人群]"
"[精炼概念]" "[理论名称]"
"[主要概念]" 2022 OR 2023 OR 2024 OR 2025 OR 2026
"[主要概念]" debate OR critique OR challenge
```

详细检索策略见 [search-strategies.md](modules/lit/references/search-strategies.md)。

### 1c. 摘要总结

对前 5-10 篇高相关度论文，使用 WebFetch 获取摘要或全文信息。凡无法获得摘要的论文，只能列入待核验，不得进入种子论文。产出：

- **领域共识**：2-3 句话总结该领域已确立的发现
- **核心争论**：1-2 个主要争议点
- **关键词清单**：中英文对照的关键词变体表（用于后续 CNKI/Google Scholar 搜索）
- **种子论文**：5-10 篇核心论文的作者/年份/标题/关键发现
- **摘要清单**：每篇种子论文的摘要状态和2-3句摘要要点

**每次搜索后立即追加日志：**
```bash
cat >> "$SEARCH_LOG" << ROW
| [序号] | WebSearch | [精确检索式] | [返回数] | [有摘要保留数/待核验数] | [作者 年份; 摘要要点; 核心发现] |
ROW
```

### 1Q. 用户方向确认

完成 WebSearch 后必须 ask_user。重点让用户确认：

- 哪些关键词是有效方向；
- 哪些论文/子领域明显偏题；
- 下一步应优先查理论、机制、人群、方法还是中文文献缺口。

---

## Step 2：知识图谱（如有）

```bash
SHARED_REF_DIR="${PAPER_SHARED_REF_DIR:-${SCHOLAR_SKILL_DIR:-.}/shared-references}"
KG_REF="$SHARED_REF_DIR/knowledge-graph-search.md"
if [ -f "$KG_REF" ]; then
  eval "$(cat "$KG_REF" | sed -n '/^```bash/,/^```/p' | sed '1d;$d')" 2>/dev/null
  if kg_available; then
    echo "=== 知识图谱：主题搜索 ==="
    kg_search_papers "[主题]" 20 | kg_format_papers
    echo "=== 知识图谱：理论搜索 ==="
    kg_search_concepts "[主题]" 10 theory
  fi
fi
```

**目的**：补充 Step 1 可能遗漏的预提取发现和论文间关系。来源标签 `knowledge-graph`。

### 2Q. 用户方向确认

完成知识图谱阶段后必须 ask_user。重点让用户确认：

- 知识图谱补出的理论/概念关系是否符合研究意图；
- 哪些关系只是概念邻近但不应纳入；
- 下一阶段本地文献库应优先检索哪些作者、理论或机制词。

---

## Step 3：本地文献库（如有）

**目的**：用 Step 1 精炼后的关键词搜索本地已收集的文献，避免重复发现已知工作，并利用已存储 PDF 进行深度阅读。

**Zotero 选择规则**：如果用户在 Step 0Q 明确暂缓 Zotero/Zotero MCP，跳过本步骤并在日志中记录 `本地文献库=用户明确暂缓`。不得要求用户为了不保存全文的轻量检索安装 Zotero。若用户选择启用 Zotero/Zotero MCP 但工具不可用，记录为 `能力缺失`，提示按 `modules/lit/references/install-dependencies.md` 安装配置，但继续后续在线检索。

**Zotero MCP 使用规则**：仅当用户选择启用 Zotero MCP，且当前宿主已按安装说明配置好可用的 Zotero MCP 实现时，才检索和深读本地条目。推荐实现与逐步操作见 [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md)。本 skill 不假设固定工具前缀；按宿主实际工具列表匹配 `zotero_search_items` 等规范名。MCP 不可用时再尝试 `zotero-cli`、Zotero Connector、本地导出、BibTeX/EndNote。

**本地库检索顺序（启用且能力检查通过）：**

1. 对每个 Step 0a 已确认方向，先 `zotero_semantic_search`（limit 10–20）；该工具不可用则记 `semantic_search=能力缺失` 并改 `zotero_search_items`。
2. 对作者、年份、专名、种子题名用短查询跑 `zotero_search_items`（`titleCreatorYear`）。
3. 有项目集合时，用 `zotero_get_collection_items` 扫描，避免全库噪音。
4. 命中条目用 `zotero_get_item_metadata`（含摘要）核验；无摘要且无法从附件提取等价摘要的，只进待核验。
5. 与 `paper-registry.csv` 按 DOI / 题名作者年 / Zotero `item_key` 去重后登记；`source=zotero-local-mcp`，`source_id=<item_key>`。
6. 种子文献或 H 档需要深读时：`zotero_get_pdf_outline` → `zotero_read_pdf_pages`；不要默认 `zotero_get_item_fulltext`。

**如果未检测到任何文献管理工具**（Zotero MCP / CLI / Connector / Mendeley / BibTeX / EndNote），跳过此步，继续 Step 4。若用户原本选择启用 Zotero/Zotero MCP，状态记为 `能力缺失`；若用户选择轻量检索，状态记为 `用户明确暂缓`。

**通读 PDF 回退**：MCP 全文工具不可用时，才对已登记的本地 PDF 使用 `pdftotext` 或 MinerU：

```bash
if [ -n "$PDF_PATH" ] && [ -f "$PDF_PATH" ]; then
  pdftotext "$PDF_PATH" - | head -300
fi
```

**每次本地查询后追加日志：**
```bash
cat >> "$SEARCH_LOG" << ROW
| [序号] | 本地文献库 | [检索词] | [命中数] | [有摘要保留数/待核验数] | [作者 年份; 摘要要点; ...] |
ROW
```


[Showing lines 1-300 of 689. Use :301 to continue]