# lit module 安装说明

本模块用于中英文文献检索与批量落地（`lit-down` 管线）、本地文献库联动、PDF 全文化解析、文献景观地图与假设推导。

- **英文检索/定位/下载与中文 NCPSSD 免登录定位**：仅需 Python 3 及标准库外少量 HTTP/PDF 包（`requests`、`httpx`、`pymupdf` 或 `pypdf`），无需浏览器即可运行；
- **CNKI 全文取回与浏览器兜底（Turnstile / CDP `Page.getResourceContent` / `Page.printToPDF`）**：依赖可见浏览器控制后端 `ego-browser`（ego lite 浏览器 + `ego-browser` 命令，见 [browser.md](browser.md) 与 [cnki.md](cnki.md)）；
- **Zotero 与 Zotero MCP**：可选增强，仅当用户希望保存题录、管理全文 PDF、检索本地库或深读已收藏文献时才要求启用。

## 安装模式

| 模式 | 适用场景 | 必需依赖 | Zotero 状态 |
|---|---|---|---|
| 英文/NCPSSD 免登录检索下载 | 英文 Crossref/OA/Sci-Hub/LibGen 下载、中文 NCPSSD 定位分级 | Python 3 + `requests`、`httpx`、`pymupdf`（或 `pypdf`） | 可跳过，记录为 `用户明确暂缓` |
| 含 CNKI 全文取回 / 浏览器兜底 | 机构 IP 取知网全文、过 Turnstile、抓 403 内联 PDF | 上述 Python 包 + `ego-browser`（ego lite） | 可跳过，记录为 `用户明确暂缓` |
| 文献库联动与深读 | 本地库去重、即时入库、保存 PDF、全文子笔记 | 上述依赖 + Zotero Desktop/Connector + `zotero-local-mcp` | 启用 Zotero / Zotero MCP |

**用不用 Zotero，先问用户**：Phase 0 / Step 0Q 必须询问用户是否启用 Zotero 和 Zotero MCP。用户暂缓时不得强制安装，继续执行在线检索与 `lit-down` 下载。

## 强制依赖 1：Python 环境与 `LITDOWN_EMAIL`

```bash
# 核心包：requests（英文下载/Crossref/探活）、httpx（NCPSSD）、pymupdf/pypdf（四件套校验与切参考文献）
python3 -m pip install requests httpx pymupdf pypdf
# 可选（仅使用 cnki_captcha.py 自动点选腾讯验证码时需要）
python3 -m pip install pillow numpy
```

Crossref 与 Unpaywall 接口要求提供有效联系邮箱（`example.com` 会被 Unpaywall 直接拒绝并返回 422）：

```bash
export LITDOWN_EMAIL="you@university.edu"
```

## 强制依赖 2（仅 CNKI 取全文与浏览器兜底）：`ego-browser`

CNKI 全文取回（`cnki_fetch_batch.mjs`）与浏览器兜底（[browser.md](browser.md)）依赖 `ego-browser` 驱动可见的 ego lite 浏览器（机构登录态与 cookie 存在真实 profile 中）：

| 后端 | 软件 | 安装 | 适配文件 |
|---|---|---|---|
| `ego-browser` | 任意 agent 宿主 | 装 ego lite 并完成 onboarding（Windows 从 <https://lite.ego.app/> 下载安装器；其余平台见 `ego-browser skill` 自带安装指南），之后 `ego-browser` 命令进入 PATH | **[browser.md](browser.md)**、**[cnki.md](cnki.md)** |

每次浏览器任务前运行：

```bash
ego-browser skill
```

输出末尾应含 `[ego-browser:skill] end of guide`。

CNKI 权限检查：用 ego lite 打开 `https://kns.cnki.net/kns8s/AdvSearch`，确认页面顶栏出现机构名称（未出现机构名即无机构下载权限，只能检索题录、不能取全文）。

状态词表：
- `浏览器控制正常`：任务空间与页面可建/复用、`goto`/`evaluate` 正常且 CNKI 可达；
- `浏览器控制不可用`：`ego-browser` 缺失、ego lite 未运行或命令报错；停止 CNKI 取全文与 CDP 兜底阶段，不得用 `web_search` 替代 CNKI 状态。

## PDF 四件套校验依赖

`download.py`、`verify_content.py`、`manual_add.py`、`cnki_report.py` 与 `literature_registry.py` 在归档前必须实际解析 PDF 页数与前页文本（严禁正则数 `/Type /Page`）。确认至少具备 `pymupdf`（`fitz`）或 `pypdf`：

```bash
python3 -c "import fitz; print(fitz.__doc__[:30])" || python3 -c "import pypdf; print(pypdf.__version__)"
```

## 可选增强：Zotero Desktop / Connector / Zotero MCP

仅在用户选择保存题录、保存全文、本地库联动或 PDF 深读时安装。操作协议（检索、即时入库、全文深读、集合、状态词）见 **[zotero-local-mcp.md](zotero-local-mcp.md)**。

### 安装前提与入口

- Zotero Desktop **10.0 及以上**：[zotero.org/download](https://www.zotero.org/download/)，并开启 设置 → 高级 → 「允许本机上的其他应用程序与 Zotero 通信」（端口 23119）。
- Zotero Connector：[Zotero Connector 文档](https://www.zotero.org/support/connector)；如需 citekey 可装 [Better BibTeX](https://retorque.re/zotero-better-bibtex/index.html)。
- `uv` / `uvx` 可用，且 Zotero Desktop 保持运行。

### `zotero-local-mcp` 安装与一次性授权

```bash
uv tool install --force git+https://github.com/JingYangYuan/zotero-local-mcp.git
pyzotero authorize --app-name "Zotero MCP Local"
zotero-cli --json config   # 应显示 ZOTERO_LOCAL: true
```

### MCP 客户端配置

将以下片段合并至当前宿主的 MCP 配置（勿再配置旧 `ZOTERO_API_KEY` / `ZOTERO_LIBRARY_ID`）：

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

### 功能验收与排障要点

- 读：`zotero_search_items` 返回条目或空结果；`zotero_get_pdf_outline` / `zotero_get_item_fulltext` 可读附件。
- 写：`zotero_add_item` 能创建测试条目并返回 `item_key`，`zotero_attach_file` 能挂载 PDF（验收后移入回收站）。
- 若报 `404 Not Found` on `/api/items/new...`：检查是否残留 `ZOTERO_API_KEY`/`ZOTERO_LIBRARY_ID`；兜底直写可用 Zotero 10 本地 API `POST /api/users/0/items`。
- 中文文献导入注意点：中文作者单字段整串写入 `{"creatorType": "author", "name": "周黎安"}`；集刊用 `bookSection` + `bookTitle`；正式条目必带 `abstractNote`。

## 在 `paper-master-4ss` 中的内置文件与验收命令

```bash
test -f modules/lit/MODULE.md
test -f modules/lit/phases/phase-1-search.md
test -f modules/lit/references/channels.md
test -f modules/lit/references/publishers.md
test -f modules/lit/references/books.md
test -f modules/lit/references/browser.md
test -f modules/lit/references/ncpssd.md
test -f modules/lit/references/cnki.md
test -f modules/lit/scripts/probe_channels.py
test -f modules/lit/scripts/refs_from_pdf.py
test -f modules/lit/scripts/enrich_crossref.py
test -f modules/lit/scripts/download.py
test -f modules/lit/scripts/books_libgen.py
test -f modules/lit/scripts/manual_add.py
test -f modules/lit/scripts/verify_content.py
test -f modules/lit/scripts/make_report.py
test -f modules/lit/scripts/ncpssd.py
test -f modules/lit/scripts/ncpssd_search.py
test -f modules/lit/scripts/cnki_prepare.py
test -f modules/lit/scripts/cnki_fetch_batch.mjs
test -f modules/lit/scripts/cnki_captcha.py
test -f modules/lit/scripts/cnki_report.py
test -f modules/lit/scripts/literature_registry.py
test -f modules/lit/scripts/citation_intersection.py
test -f modules/lit/scripts/mineru/pdf2md.py
python3 modules/lit/scripts/probe_channels.py --help >/dev/null
python3 modules/lit/scripts/ncpssd_search.py --help >/dev/null
python3 modules/lit/scripts/literature_registry.py --help >/dev/null
```
