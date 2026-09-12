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
| `workflow-protocol` | `modules/lit/references/cnki-kns8s-closed-loop.md` | CNKI 检索→分析→下载闭环协议（后端中立：页面层 + 后端层） | high |
| `workflow-protocol` | `modules/lit/references/pi-chrome-browser.md` | OMP pi-chrome 后端的安装、授权、能力映射与失败恢复 | high |
| `tooling-template` | `modules/lit/scripts/cnki/kns8s-download.sh`、`modules/lit/scripts/cnki/cookie_sink.py`、`modules/lit/scripts/mineru/pdf2md.py`、`modules/lit/scripts/literature_registry.py` | 免弹窗下载器、Cookie 回环 sink、全文化解析器、文献注册表工具 | high |

## 路由提示

- CNKI 或 Scholar 操作经验优先进入 `references/cnki-kns8s-closed-loop.md`（kns8s 浏览器控制轨道）；若涉及下载逻辑，再更新 `scripts/cnki/kns8s-download.sh` 候选。
- 浏览器后端经验分流：页面级判据（检索式、点击、验证码几何、结果解析、下载）进 `cnki-kns8s-closed-loop.md`；后端级调用面（工具名、目标选择、Cookie 落盘、超时与恢复）进对应适配文件，OMP 为 `references/pi-chrome-browser.md`，新增后端时同步在闭环协议 §2 增量表登记。
- 文献综述结构经验优先进入 `synthesis-guide.md`；涉及 lit 与 write 交接规则（证据表、净稿落点）的候选指向 `master/literature-review-protocol.md`（output-contract 面）。
- 假设推导经验优先进入 `gap-to-hypothesis.md`。
- Zotero / 本地文献库操作经验优先进入 `references/zotero-local-mcp.md`；安装命令、授权和排障留在 `install-dependencies.md`。
- 所有工具候选必须说明浏览器可见性（ZCode 面板或 OMP `Pi Session:` 标签）、验证码几何判据和页面可达性验证方式。Zotero MCP 候选必须说明能力检查方式、摘要准入和不替代 CNKI 的边界。
- pi-chrome 后端版本的完整性判据（`offscreen` 权限、`offscreen.html`/`offscreen.js`、service worker 保活）属 `tooling-template` 面：源改动落到本机安装目录后，由 `scripts/export_pi_chrome_plugin.py` 重导镜像仓 <https://github.com/JingYangYuan/pi-chrome-mirror>。
