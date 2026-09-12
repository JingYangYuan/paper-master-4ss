# pi-chrome 浏览器控制后端（OMP 宿主）

> **公开文档**：https://github.com/JingYangYuan/pi-chrome-cnki — 本文件与该仓库的 `pi-chrome-browser.md` 同步，由 `scripts/export_pi_chrome_doc.py` 生成对外发布版。可直接分享该链接给需要看适配说明的人。

本文件是 `browser_control` 通用能力在 OMP（Oh My Pi / Pi coding agent）宿主上的后端配置与适配协议。CNKI kns8s 闭环（[cnki-kns8s-closed-loop.md](cnki-kns8s-closed-loop.md)）的浏览器操纵可由本后端或 ZCode 内置 browser-use 承担，两者共用同一闭环协议与同一来源不可替代铁律。

- 适用宿主：OMP。ZCode 宿主读 [cnki-kns8s-closed-loop.md](cnki-kns8s-closed-loop.md) §2.1 的 browser-use 分支。
- 能力映射：`browser_control`（见 `references/runtime-adapter.md`、`references/agent-software-adapters.md`）。
- 本文件不含任何 CNKI 检索式、结果解析或下载逻辑；那些属于闭环协议。

---

## 1. pi-chrome 是什么

pi-chrome 是 OMP 的浏览器控制扩展：通过伴生 Chrome 扩展驱动**用户已登录的 Chrome profile**，暴露 `chrome_*` 工具集（navigate / snapshot / evaluate / click / type / fill / key / hover / drag / scroll / wait_for / screenshot / tab / list_console_messages / list_network_requests）。

- 与 CNKI 相关的价值：机构登录态、下载权限、Cookie 都在用户真实 profile 中，无需单独登录自动化浏览器。
- 边界：这是浏览器自动化，不是操作系统控制。原生系统/Chrome 弹窗、passkey/生物识别、验证码、跨域 iframe DOM 均在可靠面之外；验证码必须由用户手动完成。
- 本地桥：扩展轮询 `127.0.0.1:17318`。桥只拒绝浏览器来源的命令请求，不是针对本机恶意进程的隔离——只授权可信任务。

---

## 2. 安装与授权（一次性）

### 2.1 OMP 侧

```bash
pi install npm:pi-chrome     # OMP 与 pi 为同一 CLI；已安装则跳过
```

- 若 OMP 正在运行：先在该会话执行 `/reload`，再使用 `/chrome` 命令。
- 本机安装位置：`~/.omp/plugins/node_modules/pi-chrome/`（验收时为 0.15.51）。

**npm 通道不可用时改用离线镜像**（公开仓 <https://github.com/JingYangYuan/pi-chrome-mirror>）：

```bash
git clone https://github.com/JingYangYuan/pi-chrome-mirror.git
omp install ./pi-chrome-mirror      # 本地路径安装，不走 npm 下载；先 --dry-run 看计划
```

> **为什么需要镜像（2026-09-12 实测）**：npm 上 `pi-chrome@0.15.51` 的 tarball 与本机安装的同名版本**不是同一份代码**——tarball 缺 `browser-extension/offscreen.html`、`offscreen.js` 与 manifest 的 `offscreen` 权限，MV3 service worker 没有保活文档。Chrome 升级后会更快回收空闲 worker，桥接轮询随之停止，表现为**"扩展已加载但 `/chrome doctor` 连不上"**。镜像逐字节复制本机已验证可用的构建（含 offscreen 保活），并附 `checksums.sha256`。

### 2.2 Chrome 侧（手动加载伴生扩展）

```text
/chrome onboard
```

对话框会显示伴生扩展目录。macOS 上 OMP 会打开 `chrome://extensions`、在 Finder 中定位该目录并把路径写入剪贴板。

在 Chrome 中：开启**开发者模式** → **加载已解压的扩展程序** → 选择

```text
~/.omp/plugins/node_modules/pi-chrome/extensions/chrome-profile-bridge/browser-extension
```

（macOS 文件夹选择器中按 Cmd+Shift+G 粘贴路径。）

改用镜像时，可直接下载 [pi-chrome-mirror 的 release zip](https://github.com/JingYangYuan/pi-chrome-mirror/releases) 解压后加载该目录，或选择镜像仓库内的 `extensions/chrome-profile-bridge/browser-extension/`。

### 2.3 授权与体检

```text
/chrome authorize            # 默认 15 分钟
/chrome authorize indefinite # 无时限，用完 revoke
/chrome doctor               # 应显示 ✓ Chrome is connected，并报告 background 状态
/chrome revoke               # 停止授权并请求清理本会话自动化标签
```

### 2.4 升级

```bash
pi update npm:pi-chrome
```

升级后：OMP 中 `/reload`，并在 `chrome://extensions` 重载 "Pi Chrome Connector"，再跑 `/chrome doctor`。

---

## 3. 后端可用性验收（每次 CNKI 阶段开始前）

| 步骤 | 命令 | 通过标准 |
|---|---|---|
| 1 | `chrome_tab action=list` | 返回标签页列表，不报错 |
| 2 | `chrome_tab action=version` | 返回 `extensionVersion`、`bridgeUrl`、`capabilities` |
| 3 | `chrome_navigate`（**不带 target**）到 `about:blank` | 返回 `Navigated to about:blank` |
| 4 | `chrome_evaluate`（**不带 targetId**）读 `location.href` | 返回 `about:blank` |

四项全过 → 记录 `浏览器控制正常`，进入 CNKI 检索页。
任一项失败 → 记录 `浏览器控制不可用`（含失败工具与错误文本），停止 CNKI 阶段；提示用户 `/chrome doctor`、检查伴生扩展是否启用、必要时 `/chrome authorize`。不得用 WebSearch/Scholar/顾问意见替代 CNKI 结果。

登录态检查（进入检索页后）：页头出现机构名（如"大学/学院名 + 手机号"）= 机构授权可用；未登录只能检索题录、不能下载全文，按闭环协议提示用户在可见标签中登录。

---

## 4. 目标模型（决定所有调用方式）

pi-chrome 拥有**一个专属自动化窗口/标签**。不带 `target` 的调用只作用于它，绝不改写用户当前标签；`targetId`/`urlIncludes`/`titleIncludes` 只有在确实要操作某个既有标签时才传。

CNKI 流程中的硬性约束（2026-09-12 实测，本机 0.15.51）：

1. **本构建中 `chrome_evaluate` / `chrome_snapshot` / `chrome_click` 传 `targetId` 会失败**，错误为 `Runtime.evaluate: Detached while handling command`（snapshot/click 则为注入超时）。已在 3 个不同标签（含自动化标签自身、用户标签、`chrome_tab new` 新建标签）复现。
   → CNKI 全流程只走**单一自动化目标**：`chrome_navigate` 不带 target 打开检索页，之后所有 `chrome_evaluate` / `chrome_wait_for` 都不带 `targetId`。
2. `capabilities.hardBackground: true`（`/chrome background on`，默认）→ `chrome_tab activate` 返回 `Tab activation is blocked by background mode`。这是预期：检索在后台运行，用户自行切换到 `Pi Session:` 分组标签完成登录/验证码。需要前台跟随演示时才请用户临时 `/chrome background off`。
3. 一个标签页可连续换词重查（幂等）；登录态在 Cookie 中跨标签保持。

---

## 5. 能力映射：CNKI 动作 → pi-chrome 工具

| 动作 | 工具 | 用法要点 |
|---|---|---|
| 打开/复用检索页 | `chrome_navigate(url, waitUntilLoad)` | 不带 target；入口见闭环协议 |
| 就绪判定 | `chrome_wait_for(kind=selector\|expression)` | `li[name="majorSearch"]`、`table.result-table-list tbody tr` 行数 > 0 |
| 切专业检索 / 提交 / facet / 排序 | `chrome_evaluate` | 页内 `.click()` 与 `jQuery(...).trigger('click')`，见闭环协议 |
| 填检索式 | `chrome_fill(selector, text)` | 真实输入层写入，selector 为 `#ModuleSearch textarea.majorSearch` |
| 读页面状态 / 结果行 / 详情摘要 | `chrome_evaluate` | 只读；返回值必须 `JSON.stringify` |
| 轮询异步结果 | `chrome_wait_for(kind=expression)` | 配合页面全局变量，见 §7 |
| Cookie 导出 | 回环 sink | 见 §8 |
| 全文下载 | Bash + curl | 见闭环协议 ③，与后端无关 |
| 留证截图 | `chrome_screenshot` | 写盘并返回路径，不激活标签 |

---

## 6. 输入层 vs 页内脚本

- `chrome_fill` / `chrome_type` / `chrome_click` / `chrome_key` 走 Chrome 真实输入层（CDP Input），不受页面 CSP 限制，并满足正常用户激活语义。
- `chrome_evaluate`、`chrome_snapshot` 走 CDP `Runtime.evaluate` / 注入脚本，同样不受页面 CSP 限制（kns 页面 CSP 严格，普通页内注入会被拦）。
- 但在 kns8s 这类重页面上，**注入式路径不稳定**：`chrome_snapshot` 与 `chrome_click` 会出现 `inject snapshot script ... timed out after 8000ms` / `DOM click fallback ... timed out`（实测）。CNKI 内的点击与状态读取因此**一律用 `chrome_evaluate`**，不要依赖 snapshot uid。

---

## 7. 失败模式与恢复（实测）

| 症状 | 原因 | 处理 |
|---|---|---|
| `Runtime.evaluate: Detached while handling command` | 传了 `targetId`；或 `awaitPromise` 内 await 了慢 fetch/长任务 | 去掉 `targetId`；异步改为 fire-and-forget 写 `window.__x`，再 `chrome_wait_for(kind=expression, value="window.__x !== null")` |
| 同一 `Detached` 且已去掉 targetId | 目标进入 detached 状态（常见于 `chrome_click` 超时或重页面 snapshot 超时之后） | `chrome_navigate` 到 `about:blank`，再导航回目标页；实测恢复 |
| `inject snapshot script ... timed out after 8000ms` | 重页面注入慢 | 改用 `chrome_evaluate`；不要重试 snapshot |
| `page.navigate timed out after 25000ms` | 目标页正忙 | 等 2–3 秒重试，或先导航到 `about:blank` |
| `Timed out after 30000ms: the Chrome extension received the command but never returned a result` | 扩展/桥异常 | `/chrome doctor`；在 `chrome://extensions` 重载 "Pi Chrome Connector"；必要时 `/chrome authorize` |
| `Tab activation is blocked by background mode` | `hardBackground` 默认开启 | 预期行为；改由用户切标签，或临时 `/chrome background off` |
| 扩展已加载但 `/chrome doctor` 不显示连接；工具条图标在、无轮询 | 从 npm 装的 0.15.51 缺 `offscreen.html` / `offscreen.js` 与 manifest `offscreen` 权限，MV3 worker 被回收后无保活（Chrome 升级后更易触发） | 换成含保活的构建：<https://github.com/JingYangYuan/pi-chrome-mirror>（`pi-chrome-browser.md` §2.1），重载扩展后 `/chrome doctor` 复查 |

**异步脚本标准写法（模式贯穿全流程）：**

```js
// chrome_evaluate，awaitPromise 可省略；立刻返回，不阻塞桥
window.__cnki = null;
fetch(url, { credentials: 'include' })
  .then(r => r.text())
  .then(html => { /* DOMParser 解析 */; window.__cnki = { /* 结果 */ }; })
  .catch(e => { window.__cnki = { err: String(e).slice(0, 120) }; });
// 随后：
// chrome_wait_for { kind: "expression", value: "window.__cnki !== null" }
// chrome_evaluate { expression: "JSON.stringify(window.__cnki)" }
```

理由：`awaitPromise: true` 且 await 慢请求时，工具调用会以 `Detached while handling command` 失败，实测三条详情页 URL 批量 fetch 必失败；单条 fetch 亦失败。fire-and-forget + 轮询是唯一稳定形态。

---

## 8. Cookie 导出（禁止经对话回传）

页面不能写文件；把 `document.cookie` 打印进对话等于把会话凭证写进日志与模型上下文。OMP 后端的唯一推荐做法是**本机回环 sink**：

```bash
# 1. 启动一次性 sink（读一次 POST 即退出；0600 落盘；只报告字节数与键数，不回显内容）
python3 modules/lit/scripts/cnki/cookie_sink.py --out /tmp/cnki_cookie.txt --port 17399 --timeout 240
```

```js
// 2. chrome_evaluate：页面把 cookie POST 给本机 sink
fetch('http://127.0.0.1:17399/c', { method: 'POST', body: document.cookie })
  .then(r => r.status)
```

```bash
# 3. sink 退出后核对，然后使用
wc -c /tmp/cnki_cookie.txt
# 4. 使用完毕立即删除
rm -f /tmp/cnki_cookie.txt
```

- sink 只绑定 `127.0.0.1`，路径固定 `/c`，拒绝多行或非 `k=v` 载荷，超时退出码 2、非法载荷 3。
- 页面侧 POST 到 `http://127.0.0.1:PORT` 属跨源请求，kns 页面 CSP 不阻塞 fetch 发起，sink 已返回 CORS 头；若某站点 connect-src 严格拦到本地端口，退回 ZCode 后端或让用户手动导出 cookie。
- 闭环协议中 cookie 文件路径与生命周期与此一致，后端只影响获取方式。

---

## 9. 与 ZCode 内置 browser-use 的差异摘要

| 项目 | ZCode 内置 browser-use | OMP pi-chrome |
|---|---|---|
| 调用面 | `mcp__node_repl__js` + browser client（`setupBrowserRuntime`） | `chrome_*` 工具集 |
| 目标选择 | `agent.browsers.getForUrl(...)`、`tabs.new()` | 单一自动化目标；**不要传 targetId** |
| 页内 JS | `tab.playwright.evaluate` | `chrome_evaluate`（CDP） |
| 点击 | `locator.click` / 页内 `evaluate` | 页内 `evaluate`（`chrome_click` 在 kns8s 会超时） |
| 等待 | `waitForTimeout` | `chrome_wait_for` |
| 结果列表 | `evaluate` 返回数组 | `evaluate` + `JSON.stringify`（返回值须可序列化） |
| Cookie 落盘 | 页内读取后由宿主 `fs.writeFileSync` | 回环 sink（`modules/lit/scripts/cnki/cookie_sink.py`） |
| 前台 | 浏览器面板对用户可见 | 默认后台；`hardBackground` 阻止 activate |
| 验证码 | 用户在面板手动完成 | 用户切到 `Pi Session:` 标签手动完成 |

两后端共同遵守：状态词表、验证码几何判据、来源不可替代铁律、Cookie 不进对话、下载走 Cookie+curl。

---

## 10. 实测验证记录（2026-09-12，pi-chrome 0.15.51）

在真实机构登录态下用 pi-chrome 完整跑通模式 E 的 ①检索 → ②分析摘要 → ③下载：

| 环节 | 操作 | 结果 |
|---|---|---|
| 可用性验收 | `chrome_tab list/version`、`chrome_navigate`、`chrome_evaluate` | 全过；`hardBackground: true` |
| 检索页 | `chrome_navigate` → `kns.cnki.net/kns8s/AdvSearch` | 标题「高级检索-中国知网」，`readyState: complete` |
| 切专业检索 | `chrome_evaluate` 点击 `li[name="majorSearch"]` | 成功；`#ModuleSearch textarea.majorSearch` 出现（`chrome_wait_for` 确认） |
| 填检索式 | `chrome_fill` 写 `SU=('耐心资本')` | 成功，值回读一致 |
| 提交 | `chrome_evaluate` `jQuery('#ModuleSearch input.btn-search').trigger('click')` | 成功；结果表渲染 |
| 命中数 | 读结果计数与 facet | 总命中 **1,871**；`学术期刊960` |
| 收窄与排序 | 点击「学术期刊960」facet → 点击 `li#CF` 被引排序 | 期刊筛后 **960**；被引序首页含《河海大学学报(哲学社会科学版)》《科学决策》《财经问题研究》 |
| 摘要抓取 | `chrome_evaluate`：`fetch(detail, {credentials:'include'})` + `DOMParser` 解析 `#ChDivSummary` / `p.keywords` / `a#pdfDown` | 详情页 35 KB；题名、摘要、关键词、PDF 直链全部取到（须用 §7 fire-and-forget 写法） |
| Cookie 导出 | 回环 sink 接收 `document.cookie` | 落盘成功（0600，键数 20+，内容未进入对话） |
| 全文下载 | 注册表 `download-plan` → `kns8s-download.sh`（Cookie + curl） | `OK 200 1665155B`；PDF 校验通过（6 页）；注册表回写 `downloaded` + sha256 + bytes + pages |

结论：pi-chrome 可作为 CNKI 闭环的完整后端；差异只在调用面与上述失败模式，协议逻辑不变。
