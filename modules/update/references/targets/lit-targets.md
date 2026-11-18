# Lit Targets

## 模块边界

lit 模块负责文献检索、文献景观地图、研究空白识别、理论框架与假设推导。候选更新不得把未核验文献直接变成正式证据。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/lit/references/search-strategies.md` | 检索词、布尔式、数据库策略、引文链策略 | low |
| `knowledge-reference` | `modules/lit/references/synthesis-guide.md` | 文献综合结构、叙事模板、过渡句 | low |
| `knowledge-reference` | `modules/lit/references/gap-to-hypothesis.md` | 空白类型、机制规格、假设格式 | low |
| `knowledge-reference` | `modules/lit/references/theory-frameworks.md` | 理论框架路由索引和跨框架组合 | low |
| `knowledge-reference` | `modules/lit/references/mineru-pdf2md.md`、`modules/lit/references/install-dependencies.md`、`modules/lit/references/zotero-local-mcp.md` | PDF 全文化协议、依赖安装说明、Zotero 本地 MCP 操作协议 | low |
| `workflow-protocol` | `modules/lit/phases/*.md` | 检索顺序、用户确认闸门、景观地图和写作阶段 | medium |
| `workflow-protocol` | `modules/lit/agents/*.md` | 检索、筛选、理论地图、证据质量、假设桥接顾问职责 | medium |
| `workflow-protocol` | `modules/lit/MODULE.md` | 模式路由、依赖验收、CNKI/Scholar 规则 | medium |
| `workflow-protocol` | `modules/lit/references/cnki.md` | 知网机构出口协议：专业检索、下载单+Referer 直取、验证码冷却规律 | high |
| `workflow-protocol` | `modules/lit/references/ncpssd.md` | 中文定位入口 NCPSSD、64 种顶刊分级、限流退避与 iCloudWAF 处置 | high |
| `workflow-protocol` | `modules/lit/references/channels.md`、`modules/lit/references/publishers.md`、`modules/lit/references/books.md`、`modules/lit/references/browser.md` | 英文渠道与假信号诊断、出版社直链、LibGen 专著书轮与书评陷阱、ego-browser 兜底（Turnstile/CDP） | high |
| `tooling-template` | `modules/lit/scripts/probe_channels.py`、`refs_from_pdf.py`、`enrich_crossref.py`、`download.py`、`books_libgen.py`、`manual_add.py`、`verify_content.py`、`make_report.py`、`ncpssd.py`、`ncpssd_search.py`、`cnki_prepare.py`、`cnki_fetch_batch.mjs`、`cnki_captcha.py`、`cnki_report.py`、`mineru/pdf2md.py`、`literature_registry.py`、`citation_intersection.py` | 探活、切参考文献、Crossref 定位审核、并发下载、LibGen 书轮、手工补录、四件套校验、清单统计、NCPSSD 检索、知网建队/直取/点选/核验、MinerU 全文化、注册表、共引滚雪球 | high |

## 路由提示

- CNKI 机构出口取全文经验（专业检索 `TI`/`AU`/`LY`、下载单+Referer 直取、验证码冷却与断点续跑）优先进入 `references/cnki.md`；涉及 NCPSSD 检索、64 种 CSSCI 顶刊清单与限流退避的经验进 `references/ncpssd.md`。
- 英文文献渠道状态、假信号判据、出版社直链、LibGen 专著书轮与书评陷阱分流进入 `references/channels.md`、`publishers.md`、`books.md`。
- `ego-browser` 浏览器兜底经验（脚本形态、TaskSpace、Turnstile、CDP `Page.getResourceContent` / `Page.printToPDF`）进 `references/browser.md`。
- 文献综述结构经验优先进入 `synthesis-guide.md`；涉及 lit 与 write 交接规则（证据表、净稿落点）的候选指向 `master/literature-review-protocol.md`（output-contract 面）。
- 假设推导经验优先进入 `gap-to-hypothesis.md`。
- Zotero / 本地文献库操作经验优先进入 `references/zotero-local-mcp.md`；安装命令、授权和排障留在 `install-dependencies.md`。
- 所有工具候选必须说明浏览器可见性（ego lite 窗口）与页面可达性验证方式，并区分知网验证码闸门冷却策略与点选提示判据。Zotero MCP 候选必须说明能力检查方式、摘要准入和不替代 CNKI 的边界。
- 浏览器兜底经验属 `workflow-protocol` 面：优先更新 `modules/lit/references/browser.md`。
