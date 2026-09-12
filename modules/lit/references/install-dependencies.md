# lit module 安装说明

本发布包用于中英文文献综述、CNKI/Google Scholar 精准补充、本地文献库联动和假设推导。CNKI 检索依赖浏览器控制，后端按宿主二选一（ZCode 内置 browser-use，或 OMP pi-chrome）；Zotero 与 Zotero MCP 是可选增强，只有当用户希望保存论文、管理全文 PDF、检索本地库或深读已收藏文献时才要求启用。

## 安装模式

| 模式 | 适用场景 | 必需依赖 | Zotero 状态 |
|------|----------|----------|-------------|
| 轻量检索 | 只需要在线检索、摘要筛选和综述写作，不保存全文 | 浏览器控制后端（ZCode 内置，或 OMP pi-chrome） | 可跳过，记录为 `用户明确暂缓` |
| 文献库联动 | 需要检查已有文献、去重、导入题录 | 浏览器控制后端 + Zotero Desktop/Connector | 启用 Zotero |
| 全文保存/深读 | 需要保存 PDF、读取 Zotero 附件全文 | 浏览器控制后端 + Zotero Desktop/Connector + Zotero MCP | 启用 Zotero MCP |

**选择铁律**：Phase 0/Step 0Q 必须询问用户是否启用 Zotero 和 Zotero MCP。用户不想保存全文或不使用本地库时，不得强制安装 Zotero；把本地文献库阶段记录为 `用户明确暂缓`，继续执行 WebSearch、CNKI、Google Scholar 和摘要核验。

## 强制依赖：浏览器控制（后端二选一）

CNKI 阶段必须由浏览器控制完成，后端按宿主选择：

| 后端 | 宿主 | 安装 | 适配文件 |
|---|---|---|---|
| `ZCode` | ZCode 桌面版 | 内置能力，**无需安装** | [cnki-kns8s-closed-loop.md](cnki-kns8s-closed-loop.md) §2.1 |
| `OMP` | OMP（Oh My Pi / Pi coding agent） | 需一次性加载伴生 Chrome 扩展，约 10 分钟；发行仓 <https://github.com/JingYangYuan/pi-chrome-mirror>（自带完整插件，不使用上游官方安装通道） | **[pi-chrome-browser.md](pi-chrome-browser.md)** |

`ZCode` 后端：浏览器控制（browser-use，`mcp__node_repl__js` + browser client）由 ZCode 桌面版自带，浏览器面板对用户可见，验证码和登录由用户在面板中手动完成。

`OMP` 后端：pi-chrome 通过伴生 Chrome 扩展驱动用户已登录的 Chrome profile，登录态与下载权限天然可用。安装源是本项目的离线发行仓（自带完整插件本体，含 MV3 `offscreen` 保活），安装与授权见 [pi-chrome-browser.md](pi-chrome-browser.md) §2：

```bash
git clone https://github.com/JingYangYuan/pi-chrome-mirror.git
cd pi-chrome-mirror && omp install .   # 无外部下载通道；先 --dry-run 看计划
```

```text
/chrome onboard                   # 显示伴生扩展目录路径
chrome://extensions → 开发者模式 → 加载已解压的扩展程序 → 选该目录
/chrome authorize                 # 或 /chrome authorize indefinite
/chrome doctor                    # 应显示 ✓ Chrome is connected
```

> 不使用上游官方安装通道：上游发布的 0.15.51 缺 `offscreen.html` / `offscreen.js` 与 manifest 的 `offscreen` 权限，MV3 worker 被回收后不再轮询 `127.0.0.1:17318`（"装了连不上"）。发行仓逐字节提供已实测可用的构建，附 `checksums.sha256` 与 `NOTICE.md` 对照表。

安装后检查（每次 CNKI 阶段开始前执行可用性检查）：

1. 浏览器控制可列标签页/新建标签页/导航到 `about:blank` 或 `https://kns.cnki.net`，并读取 URL/title 轻量状态（OMP 四项验收命令见 [pi-chrome-browser.md](pi-chrome-browser.md) §3）。
2. 打开 `https://kns.cnki.net/starter/advanced` 后检查页头机构信息（"大学/学院名 + 手机号"）确认机构授权；未登录时提示用户先完成机构登录，未登录只能检索题录、不能下载全文。

状态词表：

- `浏览器控制正常`：可列页/新建页/导航且检索页可达。
- `浏览器控制不可用`：工具抛错、无法列页/新建页/导航；停止 CNKI 阶段（ZCode 提示重启宿主会话；OMP 先 `/chrome doctor` 并重载伴生扩展），不得用 WebSearch/Scholar 替代。
- `浏览器页面未完成` / `CNKI 页面未完成`：页面加载未完成或选择器失配；重试一次后仍失败即停止并记录。

验证码与下载约定：验证码出现时停止自动化并请用户在可见浏览器中手动拖动完成（OMP 下用户切到 `Pi Session:` 分组标签）；PDF 下载不走浏览器下载管线（必弹 Save-As），使用 `modules/lit/scripts/cnki/kns8s-download.sh`（Cookie + curl）免弹窗下载；Cookie 获取 OMP 走回环 sink（`modules/lit/scripts/cnki/cookie_sink.py`），不得经对话回传。完整协议见 [cnki-kns8s-closed-loop.md](cnki-kns8s-closed-loop.md)。

Google Scholar 阶段无需浏览器，用 WebFetch/WebSearch 直接访问即可。

## PDF 归档校验

项目内下载器在归档前必须实际解析 PDF。安装或确认以下任一工具可用：Python 包 pypdf、Poppler 的 pdfinfo，或 qpdf。当前环境缺少三者时，下载器会保留文件为未归档状态，而不会只根据 %PDF 文件头声称成功。

```bash
python3 -c "import pypdf" || command -v pdfinfo || command -v qpdf
```

## 可选增强：Zotero Desktop / Connector

仅在用户选择保存题录、保存全文、本地库联动或 PDF 深读时安装。

官方入口：

- Zotero Desktop: [zotero.org/download](https://www.zotero.org/download/)
- Zotero Connector: [Zotero Connector 文档](https://www.zotero.org/support/connector)
- Better BibTeX: [Better BibTeX for Zotero](https://retorque.re/zotero-better-bibtex/index.html)

安装顺序：

1. 安装 Zotero Desktop。
2. 安装浏览器对应的 Zotero Connector。
3. 打开 Zotero Desktop，并保持运行。
4. 在 Chrome 中确认 Zotero Connector 图标可用。
5. 如需稳定 citation key，安装 Better BibTeX for Zotero。

验收标准：

- Zotero Desktop 能打开本地文献库。
- Zotero Connector 能把当前论文页保存到 Zotero。
- 测试条目包含标题、作者、年份、来源和 URL/DOI 中的多数元数据。
- 如需全文保存，测试条目应能关联 PDF 附件。

没有 Zotero 时，本地文献库阶段不得标记为 `已执行`；应记录为 `用户明确暂缓` 或 `能力缺失`，继续其他在线检索阶段。

## 可选增强：Zotero MCP（已验证实现：zotero-local-mcp）

Zotero MCP 只在用户需要 Agent 直接搜索 Zotero、写入题录/摘要、管理分类或读取附件全文时启用。本模块不假设宿主已经安装或暴露任何固定名称的 Zotero MCP；下方以 2026-09-09 实跑验证的 `zotero-local-mcp`（本地 Zotero 10 API，无需 Web API key）为推荐实现，其他实现仍按各自项目说明配置，但验收口径不变。

**操作协议**（检索、即时入库、全文深读、集合、状态词）：[zotero-local-mcp.md](zotero-local-mcp.md)。本节只负责安装、授权、客户端配置与排障。

### 安装前提

1. Zotero Desktop **10.0 及以上**，且已开启 设置 → 高级 → 「允许本机上的其他应用程序与 Zotero 通信」（本地 HTTP API，端口 23119）。
2. 本机已安装 uv（`uv`/`uvx` 可用）。
3. Zotero Desktop 处于运行状态（本地授权与写入都依赖它）。

### 安装与一次性授权

```bash
# 1. 安装/更新（升级版本用同一命令重装覆盖）
uv tool install --force git+https://github.com/JingYangYuan/zotero-local-mcp.git

# 2. 一次性本地授权：会触发 Zotero 授权弹窗，手动点 Always Allow
pyzotero authorize --app-name "Zotero MCP Local"
#    密钥落盘 ~/.config/pyzotero/local-api-key.json（含 server_id 与 key）

# 3. 自检：应显示 ZOTERO_LOCAL: true
zotero-cli --json config
```

### MCP 客户端配置

常见配置文件：

- Oh My Pi (OMP)：`~/.omp/agent/mcp.json`
- Claude Desktop：macOS `~/Library/Application Support/Claude/claude_desktop_config.json`；Windows `%APPDATA%\Claude\claude_desktop_config.json`
- Cursor：项目或用户 `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "zotero": {
      "type": "stdio",
      "command": "zotero-mcp-server",
      "args": ["serve"],
      "env": {
        "ZOTERO_LOCAL": "true",
        "ZOTERO_MCP_SCHEMA_REFRESH": "0"
      }
    }
  }
}
```

**不要**再配置 `ZOTERO_API_KEY` / `ZOTERO_LIBRARY_ID`：这两个是旧 Web/混合模式残留。残留时 MCP 写入会走错误路径并失败（典型症状见下文排障）。修改配置后必须重启宿主会话，新 env 才会作用于 MCP 进程。

### 功能验收

- 读：按关键词检索条目；读取标题、作者、年份、DOI/URL、期刊等元数据；需要全文深读时能读取附件全文。
- **写（本地模式必须验收）**：`zotero_add_item` 能创建测试条目并返回 item_key；`zotero_attach_file` 能挂上 PDF 附件；验收后删除测试条目。
- 验收不过时记录 `能力缺失`；Zotero/Zotero MCP 只影响本地库与全文保存阶段，不影响在线检索与摘要核验。

### 排障记录（2026-09-09 实测）

- 症状：`zotero_add_item`（csl_json/bibtex）报 `conversion failed: Client error '404 Not Found' for url 'http://localhost:23119/api/items/new...'`。
- 根因：宿主 env 残留 `ZOTERO_API_KEY`/`ZOTERO_LIBRARY_ID`，或 MCP 实现调用了 Zotero 本地 API 不存在的 `/api/items/new` 模板端点（本地 API 只提供 `/api/users/0/items` 等原生端点）。
- 兜底直写方案（Zotero 10 本地写 API 三步，可用于脚本化导入）：
  1. `curl -s -D - -o /dev/null http://localhost:23119/api/` 取响应头 `Zotero-Server-ID`；
  2. 取授权 key：`~/.config/pyzotero/local-api-key.json` 已有则直接用，否则 `POST /api/local/authorize`（body 需含 `appName`）换新 key；
  3. 带 `Authorization: Bearer <key>` 调 `POST /api/users/0/items`，条目 JSON 数组内直接写 `collections: ["<分类key>"]`、`tags`、`abstractNote`，一次请求完成创建、归类与摘要写入。

### 中文文献导入注意点

- 中文作者使用**单字段模式整串写入**：creators 写 `{"creatorType": "author", "name": "周黎安"}`（姓+名连写，不拆分 lastName/firstName；Zotero 以 fieldMode=1 存储，条目与引文中均显示完整中文姓名）。不要拆成 `lastName=姓`/`firstName=名` 两字段——中文姓名拆分依赖人工判断（复姓、双字姓），拆错会造成引文格式错误。
- 集刊文献（如《清华社会科学》《中国非营利评论》）用 `bookSection` 类型，`bookTitle` 填集刊名；不要伪装成 journalArticle。
- 每条正式条目必须带 `abstractNote`（呼应摘要存储铁律），并把返回的 item_key 记入搜索日志论文清单。

本地 Zotero Connector 也可提供轻量保存能力，常见本地接口为：

```text
http://127.0.0.1:23119/connector/saveItems
```

**限制**：Zotero MCP 或 Connector 只解决保存、检索和全文读取；不能替代摘要准入规则。所有正式纳入论文仍必须有摘要或等价全文摘要信息。

## 在 paper-master-4ss 中的位置

本模块已经内置于 `paper-master-4ss/modules/lit/`。依赖检查只用于 CNKI、Google Scholar、Zotero 和本地浏览器能力。

内置文件检查：

```text
paper-master-4ss/modules/lit/
├── SKILL.md
├── phases/
├── references/
└── scripts/cnki/
```

## 依赖验收

```bash
test -f modules/lit/SKILL.md
test -f modules/lit/phases/phase-1-search.md
test -f modules/lit/references/cnki-kns8s-closed-loop.md
test -f modules/lit/references/pi-chrome-browser.md
test -f modules/lit/scripts/cnki/kns8s-download.sh
test -f modules/lit/scripts/cnki/cookie_sink.py
python3 modules/lit/scripts/cnki/cookie_sink.py --help
```

人工确认：

- 浏览器控制可列页/新建页/导航且页面可达（ZCode 内置 browser-use；OMP pi-chrome 按 [pi-chrome-browser.md](pi-chrome-browser.md) §3 四项验收通过）。
- CNKI 检索页可打开；如遇验证码，用户能手动完成。
- OMP 后端：`/chrome doctor` 显示已连接；Cookie 回环 sink 能落盘（0600）并只报告字节数/键数。
- Google Scholar 页面完成可达性检查。
- 如用户选择 Zotero：Zotero Desktop/Connector 可保存测试文献。
- 如用户选择 Zotero MCP：所选 Zotero MCP 实现可完成条目检索、元数据读取；需要全文深读时还要能读取附件全文。

未通过浏览器控制可用性检查时，不得正式检索 CNKI。CNKI 阶段不得由 WebSearch、Google Scholar、普通网页搜索或代理替代。未通过 Zotero/Zotero MCP 验收时，只影响本地库和全文保存阶段，不影响在线检索与摘要核验。
