# Phase 1：文献检索与全文下载（集成 lit-down 检索下载管线）

本文件由 `modules/lit/MODULE.md` 在所有模式下加载，定义顾问门控、方向与来源确认、以及基于 `lit-down` 的中英文文献定位、批量下载、四件套校验、注册表归档、全文化与滚雪球闭环。

## 顾问派发门控

检索启动前须读取 `search-strategy-consultant` 意见并写入 `agent-synthesis-lit-[YYYY-MM-DD].md`。候选文献清单形成后，派发 `modules/lit/agents/evidence-screening-consultant.md` 复核纳入/排除/待核验裁决，并将结论追加至 `paper-workspace/_logs/agents/lit-[YYYY-MM-DD]/agent-synthesis-lit-[YYYY-MM-DD].md` 后方可进入 Phase 2。

## 核心检索与下载原则（结论先行）

1. **能下到的比例由“渠道链”决定，不由“搜索能力”决定**：纯 OA 链对社科/人文/经济类清单覆盖率很低，必须按「先定位（英文 Crossref 拿 DOI / 中文 NCPSSD 拿刊与作者）→ 按年份决定先镜像还是先 OA → `web_search` 补位」执行。
2. **顺序比渠道重要**：老文献（入库截止年前为主）`--order mirror-first`（默认），先打镜像省掉大量无效 OA 请求；新文为主或医学/生物 `--order oa-first` 配合 `--probe-oa` 预探 Unpaywall。
3. **书不是论文，分轨判据是“有没有 DOI”**：有 DOI 的（工作论文、报告、有 DOI 的章节）先走论文链；**没 DOI 的专著**才单开 LibGen 书轮（`topics[]=l`）。
4. **中文清单整条链换轨**：中文期刊基本不发 DOI，汉字条目**不要进 Crossref**；第一跳走 **NCPSSD（`www.ncpssd.cn`，免登录）**定准题名/刊名/ISSN/年份/第一作者并获 64 种 CSSCI 顶刊分级，第二跳走 **知网（CNKI）机构出口**取全文（专业检索 `TI='...' AND AU='...'` → 详情页取下载单 `href` → Node 带 `Network.getCookies` + `Referer` 直取字节）。
5. **NCPSSD 的 `pdfurl` 不是全文**：多指向已停用的 `nssd.org`（实测 18/18 返回 4,660 字节停放页），严禁当中文 OA 链使用。
6. **搜索能补漏，但补不了权限**：`web_search` 擅长挖出机构库副本、作者主页与课程阅读页，但对付费墙无能为力。

## 固定检索与下载总流程

```text
Step 0a（方向预确认） -> Step 0Q（来源与 Zotero 预确认）
  -> ⓪ 探活与出口 IP 判断（probe_channels.py）
  -> ① 候选发现与清单解析（web_search / 本地库 / Annual Reviews / 引文链 / refs_from_pdf.py）
  -> ② 定位分流：
       ├─ 中文条目 -> NCPSSD 定位与顶刊分级（ncpssd_search.py）-> cnki_prepare.py
       └─ 英文/国际 -> Crossref 定位与审核（enrich_crossref.py parse/doi/audit/merge）
  -> ③④ 批量取全文：
       ├─ 英文论文 -> download.py（mirror-first / oa-first）-> web_search + manual_add.py / browser.md CDP 补位
       ├─ 无 DOI 专著 -> 书轮 books_libgen.py（topics[]=l）
       └─ 中文知网 -> ego-browser 运行 cnki_fetch_batch.mjs -> cnki_report.py
  -> ⑤ 四件套校验与清单（verify_content.py + make_report.py）
  -> Step 9：写入唯一注册表 paper-registry.csv（literature_registry.py）
  -> Step 10：PDF 全文化解析（MinerU pdf2md.py）
  -> Step 11：Zotero 集合归档与全文笔记（可选）
  -> Step 12：参考文献交集滚雪球（citation_intersection.py，最多 2 轮）
```

## 阶段确认门控、摘要准入与浏览器边界

1. **摘要准入**：进入正式清单、文献地图、综述或假设推导的文献必须具备可抓取摘要、PDF/全文摘要段或 ≥ 150 字的核心论点摘要；仅凭标题、作者、期刊或被引数不得纳入。
2. **阶段综述沉淀**：每完成一个关键阶段（探词/定位/下载核验/滚雪球），更新 `SEARCH_LOG` 与 `paper-workspace/02-literature/stage-syntheses.md`（200–400 字中文综述段落），并通过 `ask_user` 确认下一步方向：
   - `按推荐继续`：沿当前证据最充分的关键词、理论或机制方向继续；
   - `收窄方向`：收窄至用户指定的理论、机制、人群、时期或语种缺口；
   - `改查方向`：按用户指定的新检索方向执行。
3. **Zotero 即时入库（启用时）**：对相关度 H/M 条目抓完摘要后按 `modules/lit/references/zotero-local-mcp.md` 入库（含 `abstractNote`）；Zotero 不可用或暂缓时写入 `paper-workspace/02-literature/abstracts-pending-zotero.md` 并记入日志。
4. **浏览器控制边界**：CNKI 取全文与 Turnstile/CDP 兜底依赖 `ego-browser`（详见 `modules/lit/references/browser.md` 与 `modules/lit/references/cnki.md`）；缺少 `browser_control` 或无机构 IP 权限时记 `浏览器控制不可用` / `网络不可达` 并停止 CNKI 取全文阶段，严禁用 `web_search` 替代 CNKI 下载状态。

---

## ⓪ 探活、出口 IP 与顺序决策

**纯中文清单跳过英文探活**（镜像与 OA 链均不适用）；中英混合或纯英文清单先测出口 IP 与渠道连通性：

```bash
curl -s "http://ip-api.com/json/?fields=isp,country,query"
python3 modules/lit/scripts/probe_channels.py          # 跑两遍，取第二次结论
python3 modules/lit/scripts/probe_channels.py --quick  # 只探关键渠道
```

- 出口 IP 若为机房段（`Alibaba` / `Tencent` / `Colo` / `Cloud`），Cloudflare 会统一拦出版社与 OA 站，需换节点再跑 OA，而镜像站往往反而畅通；"换节点"与"换渠道"分开判断。
- 设定联系邮箱（Crossref / Unpaywall 必填，`example.com` 会 422）：

```bash
export LITDOWN_EMAIL="you@university.edu"
```

- 根据清单年份分布决定下载顺序：

| 清单特征 | 顺序参数 | 理由 |
|---|---|---|
| 绝大多数在镜像入库截止年之前（社科、经济学、教育学经典） | `--order mirror-first`（默认） | 镜像覆盖好，一次 DOI 查询即结束 |
| 有相当比例晚于截止年，或医学/生物类 | `--order oa-first` + `--probe-oa` | 镜像对新文命中率接近零；PMC/OA 覆盖更好 |

`oa-first` 时先跑 Unpaywall 预探（`--probe-oa oa_probe.json`），后续加 `--probe oa_probe.json` 让无直链条目直接落入镜像，省去无效 API 往返。

---

## ① 候选发现与清单解析

根据任务形态选择上游发现与输入解析入口：

### 1A. 从研究主题发现候选文献（模式 A / B / C / D / E 主题检索）

1. **联网检索探路（`web_search` / `web_fetch`）**：运行 2–3 条宽泛检索与 3–5 条精炼检索（`"[核心概念]" "[结果变量]"`、`"[核心概念]" review OR 综述`），整理同义词、种子文献与摘要。若宿主内置 `google_search` 报 `include_server_side_tool_invocations`，直接改用 `web_search`。
2. **本地库 / Zotero（可选）**：仅当 Step 0Q 启用 Zotero 时，按 `zotero-local-mcp.md` §4 执行 `zotero_semantic_search` 与 `zotero_search_items` 并去重登记。
3. **Annual Reviews 与引文链（模式 A / B / D）**：检索 Annual Reviews 或领域权威综述锁定学科脉络，并基于种子文献做向前/向后引文追踪（可辅以 Semantic Scholar / Crossref API）。
4. **中文主题发现（NCPSSD 免登录定位）**：用 `ncpssd_search.py` 直接发现中文核心文献并自动置顶 64 种 CSSCI 顶刊（详见 ②B）。

### 1B. 从现有参考文献表或论文 PDF 解析（已知书目批量落地）

接受三种输入：结构化 JSON（最优）、纯 DOI 文本、参考文献原始字符串（Excel/CSV 中文清单直接进 ②B / 知网链）。若输入是论文 PDF，**按悬挂缩进切分**（剔除页眉页脚，遇 `Biographies` / `Figure 1.` 停止，双栏先分栏）：

```bash
python3 modules/lit/scripts/refs_from_pdf.py a.pdf b.pdf --out refs_raw.json
```

---

## ② 定位分流（英文 Crossref / 中文 NCPSSD）

**先分流：含汉字题名/刊名/作者的条目不进 Crossref**，直接走 ②B（NCPSSD）；英文/国际条目走 ②A（Crossref）。

### ②A. 英文文献：Crossref 定位与审核

```bash
python3 modules/lit/scripts/enrich_crossref.py parse --raw refs_raw.json --out refs.json
python3 modules/lit/scripts/enrich_crossref.py doi   --refs refs.json --cache doi_cache.json
python3 modules/lit/scripts/enrich_crossref.py doi   --refs refs.json --cache doi_cache.json --round2
python3 modules/lit/scripts/enrich_crossref.py audit --refs refs.json --cache doi_cache.json --apply
python3 modules/lit/scripts/enrich_crossref.py merge --refs refs.json --cache doi_cache.json --out refs_final.json
```

- 命中判据：返回标题前 40 字符归一化后与输入相等；第二轮 `query.title` 会捞回书评/百科/同名综述，**必须执行 `audit --apply`** 将可疑项写入 `overrides.json` 并在 `merge` 时连同错标题一并丢弃。
- 保留 Crossref 副产物 `alternative-id` 中的 Elsevier PII（`S` 开头、≥16 位）。
- 无 DOI 的条目分流：专著走 `books_libgen.py`（见「书籍：单开一轮」），其余走 `web_search` + `manual_add.py`。

### ②B. 中文文献第一跳：NCPSSD 定位与顶刊分级（免登录）

详情、64 种顶刊清单与限流处置见 `modules/lit/references/ncpssd.md`。常用命令：

```bash
python3 modules/lit/scripts/ncpssd_search.py "数字普惠金融 城乡收入差距" --limit 30 --csv 中文清单.csv
python3 modules/lit/scripts/ncpssd_search.py "共同富裕" --order recency --limit 20
python3 modules/lit/scripts/ncpssd_search.py "最低工资" --issns 0577-9154      # 定向《经济研究》
python3 modules/lit/scripts/ncpssd_search.py "乡村振兴" --tier1-only           # 只跑内置 64 种顶刊
```

关键约束：
1. `--csv` 列名已对齐 `cnki_prepare.py`（序号/题名/第一作者/期刊/年份/文献类型/等级），第一作者只取第一人（因知网 `AU=` 只认单人）。
2. **不能按题名去重**：中文同名文章多，去重看落地页 `id`，进知网必须带 `AU`。
3. **`pdfurl` 不可当全文**：指向已停用的 `nssd.org`，`is_open_access` 恒为 `null`。
4. **限流与故障区分**：`exit 1`（`ncpssd_unavailable` / `ncpssd_throttled`）不是“没有文献”；大批量扫库务必加 `--no-detail`（请求数 1+N→1），被 iCloudWAF 拦截时连接器按 30→60→120→240→480s 自动退避，或浏览器点击验证后注入 `LITDOWN_NCPSSD_COOKIE`。

---

## ③ ④ 英文与国际文献批量下载

### 主下载流（`download.py`）

```bash
# 老文献为主：默认 mirror-first
python3 modules/lit/scripts/download.py --stage all --order mirror-first --workers 4 \
  --refs refs_final.json --out paper-workspace/02-literature/papers --state state.json

# 新文为主 / 生物医学：先预探 OA，再 oa-first
python3 modules/lit/scripts/download.py --refs refs_final.json --probe-oa oa_probe.json
python3 modules/lit/scripts/download.py --stage all --order oa-first --probe oa_probe.json --workers 6 \
  --refs refs_final.json --out paper-workspace/02-literature/papers --state state.json
```

执行规范：
1. **长任务后台跑**：使用后台进程 + 日志，避免前台阻塞。
2. **Sci-Hub 页面解析顺序**：先匹配 `<embed[^>]+src="([^"]+\.pdf[^"]*)"`（去掉 `#view=FitH`）→ 再判 `request this article|article not found` → 最后判 `Verification` 挑战页；**`mutual aid` 不是无文判据**。CDN 慢时将 `--workers` 降至 2。需要过 Turnstile 时按 `modules/lit/references/browser.md` §3 用真浏览器打开过一次取 `scihub_verified=1` cookie。
3. **OA 链顺序**：Unpaywall → OpenAlex → Europe PMC（走 REST `fullTextXML`，勿用 `?pdf=render` 403）→ arXiv → NBER（必须验魔数）→ 落地页 `<meta name="citation_pdf_url">` → 出版社模板（`modules/lit/references/publishers.md`，仅在有机构权限时用）。每条设 `MAX_CANDS` 与墙钟 `ITEM_BUDGET`。详情见 `modules/lit/references/channels.md`。

### ④½ `web_search` 补位、浏览器 CDP 与手工补录

OA 链全空不代表真没有，按以下顺序补位：
1. **`web_search` 扫库**：一次给 3 条查询（`"完整标题" pdf`、`"标题截断" 机构名 repository pdf`），优先挖机构库副本、作者主页与课程阅读页，分清期刊正式版与接收稿页数差异。
2. **浏览器 CDP 抓内联 PDF（403 机构库）**：对 `requests` 报 403 但浏览器能内联打开的库（如 IRIS/CINECA），按 `modules/lit/references/browser.md` §7 用 `page.goto` + `page.cdp("Page.getResourceContent", ...)` 取字节。
3. **免费网页全文打印**：无 PDF 但网页公开全文的刊物，按 `browser.md` §8 用 `Page.printToPDF` 生成并标注 `print:web` 与页码差异。
4. **慢速站 `curl -m 600` + `manual_add.py`**：作者主页/课程页用 `curl -m 600` 落盘后再交 `manual_add.py` 过四件套入账（支持 ≥20 页无文本层扫描件判 `scanned`）：

```bash
python3 modules/lit/scripts/manual_add.py pairs.json --refs refs_final.json --state state.json --out paper-workspace/02-literature/papers
```

### 书籍：单开一轮（`books_libgen.py`）

判据是**有没有 DOI**（`refs_final.json` 的 `kind` 为 `book`/`chapter`/`thesis` 且无 DOI 或论文链失败）：

```bash
python3 modules/lit/scripts/books_libgen.py --refs refs_final.json --state state_books.json \
  --out paper-workspace/02-literature/papers
```

- 必须带 `topics[]=l` 且走 `index.php?req=`（`search.php` 404）；
- 独立 state、慢节奏（3–5s），失败多为整站故障，允许整轮重跑；
- 合法路线优先（Springer OA、NBER 免费单章、HathiTrust 等，见 `modules/lit/references/books.md`）；
- 防**书评陷阱**：命中书评则返回书轮重找正书；章节仅拿到整书时须在清单注明，不以整书冒充章节。

---

## 中文文献第二跳：知网（CNKI）机构出口取全文

前提：可见浏览器（`ego-browser`）打开知网顶栏显示机构名称（无机构名即无权限）。流程与配置细节见 `modules/lit/references/cnki.md`。

```bash
# ① 入队：清洗脏作者/题名空格，分流专著到 books.json
python3 modules/lit/scripts/cnki_prepare.py --csv 中文清单.csv --out paper-workspace/02-literature/cnki-work

# ② 编写 paper-workspace/02-literature/cnki-work/cnki.config.json
#    { "queue": ".../batch.json", "out": ".../02-literature/papers", "log": ".../run-log.jsonl",
#      "space": "cnki-batch", "max": 10, "gap": 14000, "python": "python3",
#      "captchaScript": "<技能包路径>/modules/lit/scripts/cnki_captcha.py" }

# ③ 在 ego-browser 中执行批量取全文（专业检索 → 详情页取下载单 href → Node 带 Cookie+Referer 直取）
ego-browser nodejs -e "globalThis.LITDOWN_CNKI_CONFIG = '<绝对路径>/paper-workspace/02-literature/cnki-work/cnki.config.json'; await import('file:///<技能包绝对路径>/modules/lit/scripts/cnki_fetch_batch.mjs')"

# ④ 核验与清单（魔数 + 页数 + 中文字符级内容比对 + 重复检测）
python3 modules/lit/scripts/cnki_report.py --queue paper-workspace/02-literature/cnki-work/batch.json \
  --pdf paper-workspace/02-literature/papers --books paper-workspace/02-literature/cnki-work/books.json \
  --out paper-workspace/02-literature/cnki-work/下载清单.csv
```

四条硬规则：
1. **专业检索不用普通 URL**：`TI='完整题名' AND AU='作者'`（模糊用 `%`）；判期刊是否入库用 `LY='刊名'`。
2. **下载单 + Referer 直取，不走点击**：`ego-browser` 脚本点击不构成用户激活，弹窗必被拦；须取 `li.btn-dlpdf a` 的 `href`，由 Node 带 `Network.getCookies`（含 httpOnly）+ `Referer: 详情页` 请求，`redirect: "follow"` 自动走完三跳。
3. **验证码按次数触发，跳过冷却再补**：撞到 `bar/verify` 闸门时当次连重试无效，几分钟后重跑即过；规则是记 `verify` → 跳过 → 继续队列 → 下轮重跑。真需人工过验证用 `await task.handOff()`，交人后勿跑 `goto` 冲掉验证页。
4. **魔数至少取前 4 字节**：`%PDF` 才算真 PDF（CAJ 头为 `0xC8 0x00` 或 `HN\0`），不能轻信 `Content-Type`。

---

## ⑤ 四件套校验、清单输出与注册表同步（Step 9）

### 1. 四件套校验与清单（`verify_content.py` + `make_report.py`）

前三件（结构合法）+ 第四件（内容比对）缺一不可：
1. `raw.startswith(b"%PDF-")`（只信魔数，不信 `Content-Type`）；
2. `len(raw) > 20_000`（剔除 5–8KB HTML 拦截页）；
3. `fitz.open(stream=raw, filetype="pdf").page_count` 或 `pypdf` 计页（禁止正则数 `/Type /Page`）；
4. **内容比对**：DOI 匹配 + 词级最长公共子串 + 字符级最长公共子串（**必须设 `autojunk=False`**；首次前 10 页失败时放宽至前 40 页兜底）+ 非 `article` 条目的 **书评标记词拦截**（`REVIEW` 命中返回空串 `""`）。

```bash
python3 modules/lit/scripts/verify_content.py --dir paper-workspace/02-literature/papers \
  --queue refs_final.json --move-bad paper-workspace/02-literature/_rejected --csv 校验.csv
python3 modules/lit/scripts/make_report.py --queue refs_final.json \
  --state state.json --state state_books.json \
  --dir paper-workspace/02-literature/papers --out paper-workspace/02-literature/下载清单
```

合并多个 `state` 时**成功优先**，防止书轮失败记录覆盖论文轮成功记录。

### 2. 同步写入唯一注册表 `paper-registry.csv`（衔接下游）

所有校验通过并落盘至 `paper-workspace/02-literature/papers/` 的文献（英文 `make_report.py` 清单与中文 `cnki_report.py` 清单），均须登记至项目唯一事实源 `02-literature/paper-registry.csv` 并回写下载状态：

```bash
# 登记题录
python3 modules/lit/scripts/literature_registry.py register \
  --workspace paper-workspace --title "[题名]" --authors "[作者]" --year "[年份]" \
  --source "[来源渠道]" --doi "[DOI]" --abstract "[摘要]" --language "[zh/en]" \
  --selection-reason "[纳入理由]"

# 对已落盘并通过四件套校验的 PDF 回写哈希、页数与 download_status=downloaded
python3 modules/lit/scripts/literature_registry.py mark-download \
  --workspace paper-workspace --paper-id "<paper_id>" \
  --pdf-path "paper-workspace/02-literature/papers/<文件名>.pdf"
```

---

## Step 10–12：全文化解析、Zotero 归档与参考文献滚雪球

1. **Step 10：PDF 全文化解析（MinerU）**：调用模块内置脚本解析 `papers/` 下的 PDF 至 `fulltext/<paper_id>/document.md` 并回写 `parse_status`（详见 `modules/lit/references/mineru-pdf2md.md`，不得引用外部 MinerU skill 路径）：

```bash
python3 modules/lit/scripts/mineru/pdf2md.py --registry paper-workspace/02-literature/paper-registry.csv
```

2. **Step 11：Zotero 集合归档与全文笔记（仅 Step 0Q 启用 Zotero 时）**：按 `modules/lit/references/zotero-local-mcp.md` §5b 执行集合查重/创建、`zotero_add_item`（含 `abstractNote`）、`zotero_attach_file`（imported file）与 `zotero_manage_note`（纯文本骨架子笔记）。
3. **Step 12：参考文献交集滚雪球（模式 A / B / D）**：运行 `citation_intersection.py` 提取共引频次 ≥ 2 的基础文献，高共引未收录条目登记至 `paper-registry.csv` 并回流 ②–⑤ 检索下载，最多 2 轮或无新增即止：

```bash
python3 modules/lit/scripts/citation_intersection.py --workspace paper-workspace
```

---

## 二十条铁律（lit-down 实战沉淀）

1. **别在前台跑**：长下载队列用后台进程 + 日志文件。
2. **超时分段给**：`timeout=(8, 30)`，不用单值大超时。
3. **不要显式传 proxies**：系统 TUN/代理已接管时去掉 `proxies` 参数直连。
4. **429 要退避，403 要放弃**：429 `sleep(12+)`；403 换渠道或开浏览器。
5. **状态机留干净**：英文失败归一到 `not-in-stash / HTTP 403 / not-pdf / bad-pdf / no-doi / wrong-content / book-review`，知网归一到 `ok / no-match / no-link / not-pdf / verify / error`，按原因跳过已失败项。
6. **PyMuPDF 内存校验**：用 `fitz.open(stream=...)` 验内存字节，不先写盘再删。
7. **开工先判出口 IP 类型**：机房段被 CF 一票否决，区分“换节点”和“换渠道”。
8. **机构代理（EZproxy）通配子域常被 DNS 劫持**：先 curl 验证，别轻信表面提示。
9. **宿主内置 `google_search` 报 `include_server_side_tool_invocations`**：直接换 `web_search`，勿浪费时间调查询词。
10. **`timeout=(connect, read)` 管不住慢速吐字节**：`stream=True` + 墙钟 `deadline` 截断（见 `download.py`）。
11. **并发写 state 用 `threading.RLock`，不是 `Lock`**：防止锁内调 `log()` 自锁死锁。
12. **`pkill -f script.py` 会杀掉自己**：用 `pgrep -af` 查 PID 再杀。
13. **顺序比渠道重要**：年份在镜像截止年前为主用 `mirror-first`，之后用 `oa-first` + `--probe-oa`。
14. **书不是论文，判据是“有没有 DOI”**：无 DOI 专著进 LibGen 必须带 `topics[]=l`。
15. **知网撞验证码闸门：跳过，别当次死磕**：记 `verify`、跳过、冷却后下轮重跑；交人用 `task.handOff()`，交人后别跑检索冲掉验证页。
16. **中文条目不要进 Crossref**：汉字条目先分流到 `ncpssd_search.py` 再进知网链。
17. **`backend_error` 不等于“没有文献”**：NCPSSD `exit 1` 是后端故障或限流，先修渠道，勿记成无文献。
18. **NCPSSD 的 `pdfurl` / `is_open_access` 一律不采信**：`nssd.org` 已停用，只能用 `--download-oa` 验活。
19. **新增顶刊条目必须先验刊名回显**：用 `--issns` 单刊搜一次，以站内回显为准，宁缺毋滥。
20. **NCPSSD 限流返回 HTTP 200 + 「访问验证」HTML，不是 429**：连接器跨进程 1.2s 限速 + 递增退避；批量扫库加 `--no-detail`，浏览器点过验证可用 `LITDOWN_NCPSSD_COOKIE` 注入 `wzws_cid`。

## 失败模式速查

| 现象 | 真因 | 处理 |
|---|---|---|
| 全是 `not-pdf`、5–8 KB | 拿到落地页/权限页 | 抓 `citation_pdf_url`，或换 OA 渠道 |
| 全是 `HTTP 403` | Cloudflare / bot 指纹 | 换渠道；或走真浏览器 CDP `Page.getResourceContent` |
| 进程低 CPU、日志不出、worker 空闲 | `Lock` 重入死锁 | 换 `RLock` |
| 下载卡死、`Ctrl-C` 等很久 | 慢速吐字节不触发 socket timeout | `stream=True` + 墙钟 deadline |
| 抓下的“书”只有几页且首页写 `Book Reviews` | 书评题名页含全书名 | 用 `verify_content.py` 书评检测拦截，回 LibGen 找正书 |
| LibGen 搜书全是期刊文章 | `index.php?req=` 默认搜 scimag | 加 `topics[]=l` |
| 好 PDF 被判 `bad-pdf` | 正则数页数对压缩流失效 | 用 `fitz` / `pypdf` |
| 魔数/大小/页数全对但内容错 | 落地页正则过宽或模糊匹配抓错 | 上四件套内容比对（`autojunk=False`） |
| 多站返回同一字节数（5620–5811B 等） | 机房 IP 被 CF 或本地代理统一拦截 | 换节点，别换渠道 |
| `google_search` 报 `include_server_side_tool_invocations` | 宿主服务端开关未开 | 换 `web_search` |
| 浏览器能打开 PDF 但页内 `fetch` 403/405 | CSP / CORS / WAF 拦截 | `page.goto` + CDP `Page.getResourceContent`（`browser.md` §7） |
| 报告成功率对不上文件数 | 书轮失败覆盖论文轮成功 | `make_report.py` 合并时成功优先 |
| 知网返回几 KB `text/html` | 撞验证码闸门（每 8–25 篇一次） | 记 `verify` 跳过，几分钟后重跑 |
| 知网点下载按钮目录永远空 | `target=_blank` 在 `ego-browser` 被弹窗拦截 | 取下载单 `href` 由 Node 带 `Cookie` + `Referer` 直取 |
| 知网返回 `ErrorMsg.html`「来源应用不正常」 | 直接 `goto` 下载单缺 `Referer` | 必须带 `Referer: 详情页` 请求 |
| 真 PDF 被判 `not-pdf` 且 `snippet` 为 `%PDF-1.6` | 魔数只取了 3 字节 `%PD` | 取前 4–5 字节比 `%PDF` |
| NCPSSD 条条 `pdfurl` 返回 4 660 B HTML | `nssd.org` 已停用 | 勿当 OA；全文走知网 |
| NCPSSD 返回 HTTP 200 但正文是「访问验证」 | iCloudWAF 按 IP+时间窗限流 | 连接器自动退避；注入 `wzws_cid` 或加 `--no-detail` |
| 中文题名进 Crossref 全空或匹到英文文 | 中文刊基本无 DOI | 汉字条目走 `ncpssd_search.py` |

## 附带脚本索引（`modules/lit/scripts/`）

- **英文/通用链**：`probe_channels.py`、`refs_from_pdf.py`、`enrich_crossref.py`、`download.py`、`books_libgen.py`、`manual_add.py`、`verify_content.py`、`make_report.py`、`litdown.py`
- **中文定位与知网链**：`ncpssd.py`、`ncpssd_search.py`、`cnki_prepare.py`、`cnki_fetch_batch.mjs`、`cnki_captcha.py`、`cnki_report.py`
- **注册表、全文化与滚雪球衔接**：`literature_registry.py`、`mineru/pdf2md.py`、`citation_intersection.py`
