# Phase 0：初始化与模式解析

本文件由 `modules/lit/MODULE.md` 在启动时加载，负责检索方向预确认、工作区目录初始化、检索日志创建、题录注册表初始化及模式参数解析。

## 0. 顾问派发门控

进入检索前，须依据 `master/agent-orchestration.md` 创建 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/agent-brief.md`：
- 正式检索前派发 `modules/lit/agents/search-strategy-consultant.md` 设计检索式、来源组合与补检策略；
- 属于完整地图（A）、定向综述（B）或假设推导（D）模式时，同步派发 `modules/lit/agents/theory-map-consultant.md` 预判理论谱系；
- 运行环境不支持并行时采用顺序复核并记录 `sequential-review`。

## 0a. 检索方向预确认（强制第一步）

发起任何检索、建置目录或创建日志前，须通过 `ask_user` 确认检索方向（支持多选）：

```text
question: "请确认本次文献检索的方向与范围（可多选）"
header: "检索方向"
options: [
  {label: "X→Y 主效应", description: "检索核心自变量对因变量的直接影响"},
  {label: "X 概念族", description: "检索核心自变量的测量、成因、趋势与相邻概念"},
  {label: "Y 概念族", description: "检索因变量的概念谱系、测量与相邻结果"},
  {label: "M 机制变量", description: "检索中介、过程与解释链条"},
  {label: "W 调节变量", description: "检索制度、区域、人群、行业与时期等边界条件"},
  {label: "IV 工具变量", description: "检索工具变量、自然实验、政策冲击与识别策略"},
  {label: "竞品核查", description: "专门检索与本研究问题高度相近的已有研究"}
]
```

确认后将选中方向映射为中英文检索词对，写入检索日志的「检索方向映射」表；未选方向记为 `用户暂不覆盖`。

## 0b. 初始化目录与注册表

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace}"
mkdir -p "${OUTPUT_ROOT}/_logs"
python3 modules/lit/scripts/literature_registry.py init --workspace "${OUTPUT_ROOT}"
```

该命令初始化文献工作区结构：
- `02-literature/papers/`：存放下载归档的 PDF 文件；
- `02-literature/fulltext/`：按 `paper_id` 隔离存放解析后的全文文本；
- `02-literature/paper-registry.csv`：题录、路径与处理状态的唯一登记源（用户已有 PDF 仅登记 `source_pdf_path`，不自动搬移）。

## 0c. 初始化落盘检索日志

为防止长会话上下文压缩导致检索记录丢失，发起检索前须在磁盘创建检索日志，并在每轮检索后即时追加：

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace}"
mkdir -p "${OUTPUT_ROOT}/_logs"
SLUG="[主题slug]"
DATE=$(date '+%Y-%m-%d')
RUN_ID=$(date '+%H%M%S')
SEARCH_LOG="${OUTPUT_ROOT}/_logs/paper-search-log-${SLUG}-${DATE}-${RUN_ID}.md"

cat > "$SEARCH_LOG" << HEADER
# 文献搜索日志：[主题]
*生成模块：modules/lit ｜ 日期：${DATE} ｜ 模式：[A/B/C/D/E]*

## 检索方向映射

| 方向 | 用户选择 | 中文检索词 | 英文检索词 | 覆盖状态 |
|---|---|---|---|---|
| X→Y 主效应 | 待填写 | 待填写 | 待填写 | 待填写 |
| X 概念族 | 待填写 | 待填写 | 待填写 | 待填写 |
| Y 概念族 | 待填写 | 待填写 | 待填写 | 待填写 |
| M 机制变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| W 调节变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| IV 工具变量 | 待填写 | 待填写 | 待填写 | 待填写 |
| 竞品核查 | 待填写 | 待填写 | 待填写 | 待填写 |

## 检索阶段预确认

| 阶段/来源 | 用户选择 | 执行状态 | 说明 |
|---|---|---|---|
| web_search | 待确认 | 待执行 | 关键词探路、种子文献与机构库副本补位 |
| NCPSSD（国家哲社文献中心） | 待确认 | 待执行 | 中文社科文献免登录定位、ISSN 与 64 种 CSSCI 顶刊分级 |
| Crossref / OA / 镜像 / LibGen | 待确认 | 待执行 | 英文 DOI 定位、mirror-first/oa-first 批量下载与无 DOI 专著书轮 |
| 本地文献库 | 待确认 | 待执行 | 本地 PDF / BibTeX / 文献库（可由用户暂缓） |
| Zotero / Zotero MCP | 待确认 | 待执行 | 需保存题录、全文或读取附件时启用 |
| Annual Reviews / 引文链 | 待确认 | 待执行 | 综述脉络核查与向前/向后引文追踪 |
| CNKI（知网机构出口） | 待确认 | 待检查 | 依赖机构 IP 与可见浏览器控制，须核查权限与可达性，不得默认跳过 |

## 搜索查询与结果

| # | 来源 | 检索词 | 命中数 | 保留数 | 关键论文 |
|---|---|---|---|---|---|
HEADER
echo "搜索日志已初始化：$SEARCH_LOG"
```

每次查询后追加记录行，每个阶段结束后追加清单快照（包含作者、年份、标题、期刊、摘要状态、摘要要点、来源、相关度 H/M/L）。

## 0d. 注册表登记规范

不得手工另建与文件状态脱节的私有清单。每篇候选文献均须通过脚本登记至 `paper-registry.csv`（按 DOI、来源标识或「规范化题名+作者+年份」去重并分配稳定 `paper_id`；PDF 默认使用 `原题名.pdf`，仅同名冲突时归入 `papers/<paper_id>/`）：

```bash
python3 modules/lit/scripts/literature_registry.py register \
  --workspace "${OUTPUT_ROOT}" \
  --title "[原题名]" --authors "[作者]" --year "[年份]" --source "[来源]" \
  --doi "[DOI，可空]" --source-id "[CNKI/数据库标识，可空]" \
  --abstract "[已核摘要]" --language "[zh/en]" --citation-key "[作者年份]" \
  --selection-reason "[纳入理由]" --download-url "[PDF 直链，可空]"
```

**摘要准入门槛**：仅已抓取摘要或全文可替代摘要的文献可进入正式纳入状态；无摘要、仅题录或仅含标题作者的文献一律归入「待核验」，禁止写入文献地图、综述或假设推导。

## 0e. 模式参数解析

从 `$ARGUMENTS` 解析模式关键词（未匹配且无上游交接时默认采用**模式 A**）：

| 关键词 | 模式 | 检索轮次 / 轨道 | 论文目标 | 预期篇幅 | 是否推导假设 |
|---|---|---|---|---|---|
| `完整` `地图` `全面` `landscape` | A | ≥ 6 轮 + 双语全链落地 | 40–80 篇 | 3,000–10,000 字 | 否 |
| `定向` `聚焦` `前言` `targeted` | B | 4 轮 + 核心全文落地 | 15–30 篇 | 1,000–3,000 字 | 否 |
| `快速` `概览` `初步` `rapid` | C | 2 轮 + 关键摘要/OA | 10–20 篇 | 500–1,500 字 | 否 |
| `假设` `hypothesis` `推导` | D | ≥ 5 轮 + 双语全链落地 | 30–60 篇 | 2,000–5,000 字 | 是 |
| `知网` `CNKI` `中文` `下载` `文献落地` `补齐参考文献` | E | 按语种走 `lit-down` 双轨批量落地（不写综述） | 10–200 篇 | 不写综述 | 否 |

**假设意图确认**：若输入含「假设」/`hypothesis` 但未选定模式 D，须先询问用户确认是否启用一体化假设推导模式。若上游设计报告已锁定概念/解释理论、规范理论或思想史/文本阐释取向且 `analysis_required: false`，保持既有模式，在文献地图中整理支持立场、竞争立场与反例材料，不强制假设推导。

## 0f. 检索阶段预确认与 Zotero 检查

### 0f-0. 检索阶段预确认（使用 `ask_user`）

遵循 `references/user-question-examples.md` 确认以下来源启用状态（CNKI 仅可在无机构 IP / 无浏览器或用户确认时暂缓；Zotero 依用户是否保存全文或使用本地库决定）：

```text
question: "本次文献检索与下载来源如何安排？英文可走 Crossref+OA/镜像+web_search+LibGen，中文可走 NCPSSD+CNKI；Zotero 可按是否保存全文决定。"
header: "检索来源"
options: [
  {label: "双语全链启用", description: "启用 web_search、NCPSSD、Crossref/OA/镜像/LibGen、CNKI（需机构 IP 与 ego-browser），Zotero 暂缓"},
  {label: "含 Zotero 全启用", description: "在双语全链基础上启用本地库与 Zotero/Zotero MCP，适合保存题录、全文或读取附件"},
  {label: "仅免登录/英文链", description: "仅运行 NCPSSD 中文定位与英文 Crossref/OA/镜像/LibGen/web_search，暂缓 CNKI 取全文"}
]
```

**标准状态词表**：
- `已执行`：完成检索/下载且拟纳入条目均具备摘要或等价全文信息；
- `CNKI 已执行`：经由 `ego-browser` 运行 `cnki_fetch_batch.mjs` 完成专业检索、下载单直取与 `cnki_report.py` 校验；
- `浏览器控制正常` / `浏览器控制不可用`：依 `modules/lit/references/browser.md` 与 `ego-browser skill` 判定（不可用时停止 CNKI 取全文与 CDP 兜底阶段）；
- `用户明确暂缓`：用户经 `ask_user` 明确要求暂缓该来源；
- `网络不可达`：经 `probe_channels.py` 或机构权限检查无法访问，或遇登录/验证码阻断后用户放弃；
- `待核验`：仅取得题录或片段，尚未获取摘要；
- `能力缺失`：用户启用 Zotero 但环境未安装或工具不可用；
- `Zotero MCP 正常` / `Zotero MCP 只读`：依 `modules/lit/references/zotero-local-mcp.md` §2 能力检查判定。

### 0f-1. Zotero MCP 能力检查（仅启用时）

用户在 Step 0Q 选择启用 Zotero / Zotero MCP 后，须先按 `modules/lit/references/zotero-local-mcp.md` §2 执行能力检查并记录至 `SEARCH_LOG`。未启用时不得强制安装或写入 Zotero。

| 步骤 | 来源 / 阶段 | 模式 A | 模式 B | 模式 C | 模式 D | 模式 E |
|---|---|---|---|---|---|---|
| 0Q | `ask_user`：检索来源预确认 | ✓ | ✓ | ✓ | ✓ | ✓ |
| ⓪ | 探活与出口 IP（`probe_channels.py`） | ✓ | ✓ | ✓ | ✓ | 英文/混合 |
| ① | 候选发现与清单解析（`web_search` / 本地库 / Annual Reviews / 引文链 / `refs_from_pdf.py`） | ✓ | ✓ | ✓ | ✓ | ✓ |
| ② | 定位分流（中文 `ncpssd_search.py` / 英文 `enrich_crossref.py`） | ✓ | ✓ | ✓ | ✓ | ✓ |
| ③④ | 批量取全文与补位（`download.py` / `books_libgen.py` / `cnki_prepare.py` → `cnki_fetch_batch.mjs`） | ✓ | ✓ | 可选 | ✓ | ✓ |
| ⑤ | 四件套校验与清单（`verify_content.py` / `make_report.py` / `cnki_report.py`） | ✓ | ✓ | 可选 | ✓ | ✓ |
