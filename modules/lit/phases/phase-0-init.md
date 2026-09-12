# Phase 0：初始化与模式解析

由 `modules/lit/SKILL.md` 在每次执行时首先加载。处理目录创建、搜索日志初始化、论文清单初始化和模式参数解析。

---

## 0. 顾问派发闸门

进入 Phase 0/1 前，必须根据 `master/agent-orchestration.md` 创建 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/agent-brief.md`。正式检索前派发 `modules/lit/agents/search-strategy-consultant.md`，让其先给出检索词、来源组合和补洞策略；若为完整地图、定向综述或假设模式，同时预派发 `modules/lit/agents/theory-map-consultant.md` 做理论谱系预判。不能并行时按顺序复核并记录 `sequential-review`。

## 0a. 检索方向预确认（强制第一步）

在任何搜索、目录创建或日志初始化之前，必须先用 ask_user 让用户确认本次文献检索方向。若当前宿主只能顺序执行确认，也必须先完成本步骤再进入 0b。

结构化示例：

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

用户选择后，把每个选中方向映射为具体中英文检索词对；未选方向记录为 `用户暂不覆盖`。该映射必须写入搜索日志的 `检索方向映射` 表，作为后续每阶段检索式和顾问复核的输入。

## 0b. 创建输出目录

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace}"
mkdir -p "${OUTPUT_ROOT}/_logs"
python3 modules/lit/scripts/literature_registry.py init --workspace "${OUTPUT_ROOT}"
```

这会创建唯一文献根目录：02-literature/papers/ 保存项目内 PDF，02-literature/fulltext/ 保存按 paper_id 隔离的解析文本，02-literature/paper-registry.csv 是题录、文件路径和处理状态的唯一来源。用户已有 PDF 只以 source_pdf_path 登记，不自动搬移。

## 0c. 初始化搜索日志（防上下文压缩）

**关键防护：** 搜索结果仅存在于会话上下文中。一旦上下文压缩，所有命中数据将丢失。必须在搜索前创建磁盘日志，每次搜索后立即追加。

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace}"
mkdir -p ${OUTPUT_ROOT}/_logs
# 从主题构造 slug（前4-6个字，小写，连字符）
SLUG="[主题slug]"
DATE=$(date '+%Y-%m-%d')
RUN_ID=$(date '+%H%M%S')
SEARCH_LOG="${OUTPUT_ROOT}/_logs/paper-search-log-${SLUG}-${DATE}-${RUN_ID}.md"

cat > "$SEARCH_LOG" << HEADER
# 文献搜索日志：[主题]
*由 modules/lit 在 ${DATE} 生成*
*模式：[A/B/C/D/E]*

## 检索方向映射

| 方向 | 用户选择 | 中文检索词 | 英文检索词 | 覆盖状态 |
|------|----------|------------|------------|----------|
| X→Y 主效应 | 待填写 | 待填写 | 待填写 | 待填写 |
| X 概念族 | 待填写 | 待填写 | 待填写 | 待填写 |
| Y 概念族 | 待填写 | 待填写 | 待填写 | 待填写 |
| M 机制变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| W 调节变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| IV 工具变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| 竞品核查 | 待填写 | 待填写 | 待填写 | 待填写 |

## 检索阶段预确认

| 阶段/来源 | 用户选择 | 执行状态 | 说明 |
|-----------|----------|----------|------|
| WebSearch | 待确认 | 待执行 | 先行探路 |
| 本地文献库 | 待确认 | 待执行 | Zotero/Mendeley/BibTeX/EndNote/PDF；可由用户暂缓 |
| Zotero / Zotero MCP | 待确认 | 待执行 | 仅在保存题录/全文、本地库联动或读取附件全文时启用 |
| Annual Reviews | 待确认 | 待执行 | 综述检查点 |
| 引文链扩展 | 待确认 | 待执行 | 向前/向后追踪 |
| CNKI | 待确认 | 待检查 | 不得默认跳过 |
| Google Scholar | 待确认 | 待检查 | 不得默认跳过 |

## 搜索查询与结果

| # | 来源 | 检索词 | 命中数 | 保留数 | 关键论文 |
|---|------|--------|--------|--------|----------|
HEADER
echo "搜索日志已初始化：$SEARCH_LOG"
```

**规则：每次搜索操作后立即追加一行：**

```bash
cat >> "$SEARCH_LOG" << ROW
| [序号] | [来源] | [检索词] | [命中数] | [保留数] | [作者 年份; ...] |
ROW
```

**每个搜索阶段结束后追加论文清单快照：**

```bash
cat >> "$SEARCH_LOG" << 'SNAP'

### [阶段名称]后发现的论文 — [N]篇累计

| 作者 | 年份 | 标题 | 期刊 | 摘要状态 | 摘要要点 | 来源 | 相关度(H/M/L) |
|------|------|------|------|----------|----------|------|---------------|
SNAP
```

## 0d. 初始化论文清单

不得手工维护另一份与文件状态脱节的论文清单。每篇候选文献先登记到 paper-registry.csv；注册表按 DOI、来源标识或“规范化题名＋作者＋年份”去重并分配稳定 paper_id。PDF 默认使用原题名.pdf；只有同题异文献冲突时才置于 papers/paper_id/ 子目录，题名仍保留在文件名中。

```bash
python3 modules/lit/scripts/literature_registry.py register \
  --workspace "${OUTPUT_ROOT}" \
  --title "[原题名]" --authors "[作者]" --year "[年份]" --source "[来源]" \
  --doi "[DOI，可空]" --source-id "[CNKI/数据库标识，可空]" \
  --abstract "[已核摘要]" --language "[zh/en]" --citation-key "[作者年份]" \
  --selection-reason "[纳入理由]" --download-url "[PDF 直链，可空]"
```

注册表字段包含摘要与题录，也包含 download_status、pdf_path、parse_status、fulltext_path 与 reading_status。后续下载、解析和核读只能更新这份表；搜索日志可记录快照，但不是文件身份来源。

**摘要状态规则**：只有已抓取摘要或全文可替代摘要的论文可以进入正式清单；无摘要或仅题录只能放入待核验区，不能进入 Phase 2 证据综合。

**标题禁入规则**：标题、作者、期刊、引用数和数据库片段只能用于候选排序；不得仅凭标题或题录把文献写入正式论文清单、文献地图、综述草稿或假设推导。

## 0e. 模式参数解析

从 `$ARGUMENTS` 中检测模式关键词：

| 关键词 | 模式 | 搜索轮次 | 论文目标 | 字数预算 | 是否推导假设 |
|--------|------|---------|---------|---------|------------|
| `完整`、`地图`、`全面`、`landscape` | A | 6轮+ | 40-80篇 | 3,000-10,000字 | 否 |
| `定向`、`聚焦`、`论文前言`、`targeted` | B | 4轮 | 15-30篇 | 1,000-3,000字 | 否 |
| `快速`、`概览`、`初步`、`rapid` | C | 2轮 | 10-20篇 | 500-1,500字 | 否 |
| `假设`、`hypothesis`、`推导` | D | 5轮+ | 30-60篇 | 2,000-5,000字 | 是 |
| `知网`、`CNKI`、`中文` | E | CNKI 网页操纵为主；WebSearch 仅可做关键词准备 | 10-30篇 | 不写综述 | 否 |

**默认**：未检测到关键词时使用**模式A**。

### 理论/假设意图检测

如果参数含 `假设` / `hypothesis` 但未明确选择模式D，输出提示：

```
⚠️ 检测到假设意图。

本技能支持"文献综述+理论假设一体化"模式（模式D）。
回复"模式D"启用一体化，或回复"继续"保持纯综述模式。
```

如果 design report 或 full report 已确认概念/解释理论、规范理论或思想史/文本阐释路径且 `analysis_required: false`，保持既有模式并在文献地图中比较支持、竞争与反例立场；不得改写为假设推导。

## 0f. 搜索路线图（固定顺序）

### 0f-0. 检索阶段预确认（强制）

确定搜索路线图前必须先 ask_user，询问本次是否启用以下阶段：

1. WebSearch 先行探路
2. 本地文献库 / 已有 PDF
3. Zotero / Zotero MCP（保存题录、保存全文、读取附件全文时启用）
4. Annual Reviews 综述检查点
5. 引文链扩展
6. CNKI 中文文献
7. Google Scholar 英文文献

结构化示例模块统一遵守 `references/ask-user-question-examples.md`。检索阶段预确认可使用以下示例：

```text
question: "本次文献检索是否启用各阶段？CNKI 和 Google Scholar 不得默认跳过，Zotero 可按是否保存全文决定。"
header: "检索阶段"
options: [
  {label: "在线全启用", description: "启用 WebSearch、Annual Reviews、引文链、CNKI 和 Google Scholar，Zotero 暂缓"},
  {label: "全部启用", description: "同时启用本地文献库和 Zotero/Zotero MCP，适合需要保存题录或全文的任务"},
  {label: "指定阶段", description: "用户逐项指定启用或暂缓的来源；CNKI/Scholar 只能由用户明确暂缓"}
]
```

**默认建议**：启用所有与模式相关的在线检索阶段；CNKI 和 Google Scholar 至少执行可达性检查，不得默认跳过。Zotero 与 Zotero MCP 不强制启用：若用户不想保存论文全文或不使用本地库，可明确选择暂缓。任何暂缓都必须写入 `SEARCH_LOG` 的"检索阶段预确认"表。

**状态记录规则**：

- `已执行`：完成检索，且每篇拟纳入论文都有摘要或等价全文摘要信息。
- `CNKI 已执行`：通过浏览器控制中的 CNKI（kns8s）网页完成专业检索/结果页/详情页摘要抓取；不得由 WebSearch、Google Scholar、普通搜索或代理结果替代。
- `CNKI 页面未完成`：CNKI 页面加载、检索、详情页或摘要抓取未完成；不得写成 `已执行`。
- `浏览器控制正常`：浏览器控制后端可列标签页/新建标签页/导航且检索页可达（ZCode 内置 browser-use；OMP pi-chrome 按 [pi-chrome-browser.md](modules/lit/references/pi-chrome-browser.md) §3 四项验收通过）；继续网页操纵。
- `浏览器控制不可用`：工具抛错、无法列页/新建页/导航。立即停止 CNKI 阶段；ZCode 提示重启宿主会话，OMP 先 `/chrome doctor` 并重载伴生扩展；不得用其他来源替代 CNKI。
- `浏览器页面未完成`：页面已打开但检索/详情/摘要未完成或选择器失配；重试一次后仍失败即停止并记录。
- `用户明确暂缓`：用户在 ask_user 中明确要求暂缓该来源。
- `网络不可达`：已做可达性检查但页面无法访问、验证码/登录阻断且用户选择放弃。
- `待核验`：仅发现标题/题录/片段，尚未取得摘要，不得纳入证据。
- `能力缺失`：用户选择启用 Zotero/Zotero MCP，但本机未安装、未配置或工具不可用；只影响本地库/全文保存，不影响在线检索。
- `Zotero MCP 正常`：已按 [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md) 完成能力检查，可检索；写入按同一协议即时入库。
- `Zotero MCP 只读`：能检索和读元数据，不能创建条目；新摘要写入 `abstracts-pending-zotero.md`。

### 0f-1. Zotero MCP 能力检查（仅启用时）

Step 0Q 选择启用 Zotero/Zotero MCP 后，在创建检索式或本地库搜索前按 [zotero-local-mcp.md](modules/lit/references/zotero-local-mcp.md) 第 2 节做能力检查，并把结果写入 `SEARCH_LOG` 的「检索阶段预确认」表。未启用则不得安装、不得写入 Zotero。

| 步骤 | 来源 | 模式A | 模式B | 模式C | 模式D | 模式E |
|------|------|-------|-------|-------|-------|-------|
| 0Q | ask_user：确认启用哪些检索阶段 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 1 | WebSearch 先行探路 | ✓ | ✓ | ✓ | ✓ | 可选 |
| 1Q | ask_user：确认关键词/噪音/下一方向 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | 知识图谱 | ✓ | ✓ | ✓ | ✓ | - |
| 2Q | ask_user：确认理论/机制方向 | ✓ | ✓ | ✓ | ✓ | - |
| 3 | 本地文献库 | ✓ | ✓ | ✓ | ✓ | 可选 |
| 3Q | ask_user：确认已有文献缺口 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 | Annual Reviews 检查点 | ✓ | ✓ | - | ✓ | - |
| 4Q | ask_user：确认经典脉络 | ✓ | ✓ | - | ✓ | - |
| 5 | 引文链扩展 | ✓ | 可选 | - | ✓ | - |
| 5Q | ask_user：确认最终补洞方向 | ✓ | 可选 | - | ✓ | - |
| 6 | CNKI / Google Scholar 可达性检查 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 7 | CNKI / Google Scholar 最终精准补充 | ✓ | ✓ | ✓ | ✓ | ✓ |
