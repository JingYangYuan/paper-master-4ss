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
| `workflow-protocol` | `modules/lit/SKILL.md` | 模式路由、依赖验收、CNKI/Scholar 规则 | medium |
| `workflow-protocol` | `modules/lit/references/cnki-kns8s-closed-loop.md` | CNKI 检索→分析→下载闭环协议 | high |
| `tooling-template` | `modules/lit/scripts/cnki/kns8s-download.sh`、`modules/lit/scripts/mineru/pdf2md.py`、`modules/lit/scripts/literature_registry.py` | 免弹窗下载器、全文化解析器、文献注册表工具 | high |

## 路由提示

- CNKI 或 Scholar 操作经验优先进入 `references/cnki-kns8s-closed-loop.md`（kns8s 浏览器控制轨道）；若涉及下载逻辑，再更新 `scripts/cnki/kns8s-download.sh` 候选。
- 文献综述结构经验优先进入 `synthesis-guide.md`；涉及 lit 与 write 交接规则（证据表、净稿落点）的候选指向 `master/literature-review-protocol.md`（output-contract 面）。
- 假设推导经验优先进入 `gap-to-hypothesis.md`。
- Zotero / 本地文献库操作经验优先进入 `references/zotero-local-mcp.md`；安装命令、授权和排障留在 `install-dependencies.md`。
- 所有工具候选必须说明浏览器面板可见性、验证码几何判据和页面可达性验证方式。Zotero MCP 候选必须说明能力检查方式、摘要准入和不替代 CNKI 的边界。
