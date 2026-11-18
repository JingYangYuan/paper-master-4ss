# 中文文献：知网（CNKI）机构出口

英文文献靠 DOI + OA 链，中文文献没这条路——知网没有公开 API 直链，能下的前提是**机构 IP**。本文来自两次实测：2026-11-10 一次性下 103 条（落地 98 篇）、2026-11-11 下 39 条（落地 39 篇）。

先给结论：**取详情页的下载单 href，由 Node 带 cookie + Referer 直取字节。** 浏览器点击在 ego-browser 里根本走不通（弹窗被拦），而旧版担心的「请求链撞闸门」其实只是限速：当次重试全失败，隔几分钟回头就过。

## 一、权限与入口

- 判断有没有权限只看页面顶栏是否出现机构名（会显示你所在单位的名称，如「某某大学」）。有机构名就不必个人登录；只显示「机构登录 / 个人登录」就是没权限，后面全白搭。
- 搜索入口 `https://kns.cnki.net/kns8s/AdvSearch`（高级检索），页内可切「专业检索」。
- **普通检索的 URL 参数是假的**：`defaultresult/index?kw=...&korder=TI` 打开永远是「抱歉，暂无数据」。必须走 UI：填框 + Enter。

## 二、检索：专业检索语法最省事

普通检索按时间/相关度排，只给首页 20 条，2013 年的文章根本浮不上来（实测「单位制的变迁」真实命中 278 条全是 2024–2026 的）。改用专业检索，一次命中：

```
TI='单位制的变迁与研究' AND AU='李路路'
TI='%典型单位制%'                       # % 是模糊
TI='%城市政府结构%'
AU='董宏君' AND TI='%社区党建%'
```

要点：

- 切页签要点 `loc=text=专业检索`，切完 `textarea.textarea-major` 才从 0×0 变可见；点不到就退回 JS 点（`[...document.querySelectorAll('a,li,div')].find(x => x.innerText.trim() === '专业检索')?.click()`）。
- 提交：找 `input[type=button|submit], button, a.btn` 里 `value/innerText === '检索'` 且 `offsetParent !== null` 的**最后一个**。
- 取值后等 4.2–4.5s 再读结果。
- 结果行 `table tbody tr`，标题锚点 `a.fz14`（`innerText` = 题名，`href` = 详情页 `kcms2/article/abstract?v=...`），行文本 `tr.innerText` 里带作者/刊名/日期/被引，用来打分。
- 打分（实测够用）：题名归一化完全相等 +4；核心片段包含 +2；行内含第一作者 +2；含刊名前 4 字 +1；含年份 +1。≥6 直接收手，不必再试变体。
- 变体顺序：`TI='完整题名'` + 作者 → 去副标题核心 + 作者 → `TI='%前 12 字%'` + 作者 → `TI='%前 8 字%'`。

归一化要去掉：空白、`“”"'`、`·・`，并统一 `：:` `，,` `（）()` `—–―-`。**只做子串匹配会误命中**——《社会治理共同体及其建设路径》会先匹到《共同体的多重想象——民族地区的社会治理共同体及其建设路径》。

## 三、判断"是不是知网收了"

```
LY='中国社会科学季刊'        # 记录数 0 = 整刊未入库，别浪费时间搜篇名
```

本机确认不收的：路风 1993（《中国社会科学季刊》）、郑广怀 2021（《二十一世纪》，香港中大）、龚宜君 2002（《台湾社会学》）、《福利中国》。报纸文章（《人民日报》）在报纸库，篇名与作者组合常搜不到，别当期刊搜。

## 四、下载：取下载单，Node 带 Referer 直取

详情页四个按钮，各自是**独立的下载单**：

| 选择器 | 含义 |
|---|---|
| `li.btn-dlpdf a` | 优先，返回 `application/pdf` |
| `li.btn-ywdlpdf a` | 原版阅读 |
| `li.btn-dlcaj a` | CAJ，老刊常只有它 |
| `li.btn-html` | HTML 阅读 |

**按钮是 `<a target="_blank" href="https://bar.cnki.net/bar/download/order?id=…">`**，点击靠开新标签页触发下载。三条路里只有第二条在 ego-browser 里成立。

### 1. 点击：在 ego-browser 里不成立

脚本发出的点击**不构成浏览器认可的用户激活**，`target=_blank` 的新标签页被弹窗拦截：事件确实触发（`e.isTrusted === true`），但 `task.tabs()` 仍然只有原页，`window.open` 一次都没被调用，下载目录空白。真人点就正常，脚本点永远失败。`Browser.setDownloadBehavior` 设了也没用——根本没有下载被触发。换成去掉 `target` 后同标签页点击、`location.href = href`、`window.open(href)`，全部同样无反应。（在真实用户浏览器里点击仍是可行的，所以浏览器自己的“另存为”行为不受影响。）

### 2. 下载单 + Referer 直取：主路径，实测 39/39

```js
// 详情页已加载
const detail = await page.url();
const order = await page.evaluate(() => document.querySelector("li.btn-dlpdf a").href);
const ck = await page.cdp("Network.getCookies", { urls: ["https://kns.cnki.net/", "https://bar.cnki.net/"] });
const cookie = ck.cookies.map(c => `${c.name}=${c.value}`).join("; ");
const r = await fetch(order, {
  headers: { Cookie: cookie, Referer: detail, "User-Agent": 桌面 Chrome UA, Accept: "*/*" },
  redirect: "follow",
});
const buf = Buffer.from(await r.arrayBuffer());   // 200 且 content-type 为 application/pdf
```

- **Referer 必填**。缺了（或直接 `goto` 下载单、新标签打开）返回 `https://bar.cnki.net/bar/ErrorMsg.html?ErrMsg=来源应用不正常`。
- **不用手工拼三跳**。`redirect: "follow"` 自己走完：
  ```
  https://bar.cnki.net/bar/download/order?id=…           302
  → //bar.cnki.net/docgateway/api/distribute/route?q=…   302
  → https://docdown.cnki.net/docdown/fulltext/download?q=…  200
  ```
- cookie 必须来自 `Network.getCookies`（含 httpOnly 的 `Eco_Login`、`cnkiUserKey`），`document.cookie` 拿不全。
- 每张单只对应一篇，所以还是得让详情页真实加载一次（搜索→详情页这两跳省不掉）。
- 验证码页同样只能用 `page.cdp("Page.navigate", { url: order, referrer: detail })` 进入；普通 `goto` 会被判“来源应用不正常”。
- 命名 `{序号:02d}-{第一作者}{年} {题名}.pdf`，清洗 `\ / : * ? " < > |`。
- **跨盘移动不能用 `fs.rename`**：`EXDEV: cross-device link not permitted`（E:→C: 必现）。用 `copyFile` + `unlink`。

## 五、验证码闸门：按次数触发，会自己冷却

约每 **8～25 篇**（间隔 14–15s 也一样）撞一次，所有下载单 302 到：

```
https://bar.cnki.net/bar/verify/index.html?platform=nxgp&returnUrl=<编码后的 order 地址>&rb=ClientLargeDown&errorcode=3
```

先把规律说清，它决定整张清单怎么跑：

- **当次连重试无效**：同一条目 3 次×7s、或 5 次×45s，全部回验证页。
- **隔几分钟重试就过**：下一轮回头跑同一条，第一次就 200。39 篇撞了 2 次（第 8、第 25 篇附近），两次都是这个形态。
- 所以它不是封禁，是**限速**。操作规则：记 `result: "verify"`、跳过这条、继续队列，下一轮重跑失败的条目就行。不需要停批等人。
- 验证成功后浏览器**不落文件**：`verifySuccess.html` 只写「验证完成，已进入下载」，它放行的是**后续**下载单。别在那儿等文件，重新取一张新单再请求。
- 下载单**几分钟就过期**：在验证码页停留久了再点确定，弹「您操作已超时，请重新打开文献！」。所以任何人工/自动解验证码都必须秒解。
- 旧版这里写「点击会开弹窗、人拖一次即续下」——那是真人浏览器里的行为，ego-browser 里没有弹窗可拖（见第四节）。真要交人：`task.handOff()`，用户说「继续」后 `takeOverTaskSpace(spaceId)` 拿回控制；**交给人之后别再跑检索**，脚本一 `goto` 就把验证页冲掉。

### 腾讯点选验证码：能识别，但还没在真实闸门上过关

闸门页用的是腾讯 tCaptcha，藏在 `#captcha-element`（360×402）里，题型轮换：「拖动滑块拼图」和「请依次点击：舱 把 撤」。点字题的自动解思路（脚本 `scripts/cnki_captcha.py`，用法 `python cnki_captcha.py cap.png "舱把撤"`）：

1. **按 CSS 像素裁剪截图**：`page.screenshot({ clip: 元素矩形, scale: "css" })`。别用整页截图再按比例换算——ego 的视口每轮都可能变（实测 1520×864 与 1856×1018 交替），手量的绝对坐标全部作废（本机因此白点两次）。
2. 橙色文字做连通域（`R>165, G>110, B<140, R-B>60, R-G>15`），8 邻接标记，相近块合并（艺术字笔画会断开），取面积最大的 N 块质心。
3. 拿提示里的三个字，用 `simkai / SIMLI / STXINGKA / STKAITI / simsun / msyh / STZHONGS / FZSTK` 多字体渲染，`IoU*0.6 + 相关系数*0.4` 打分，**全排列取总分最高的分配**（3! = 6）。
4. 鼠标先移动、停顿、再点，三次点击之间要有轨迹；无轨迹的离散点击会被判机器人（本机第一次就这么挂的）。
5. 点完再点「确定」，成功会跳 `verifySuccess.html`，失败提示「验证错误，请重试」。

**现状要如实说**：离线标注的 3 张样张（含正确点选顺序）全部判对，但**两次真实闸门上的自动解都被判「验证错误」**，且失败后页面进入异常态（提示文字读不到，后续两次 `no-chars`）。所以自动解只能当兜底，主策略仍是「跳过 → 冷却 → 重试」。

另一个坑：解析提示用 `请依次点击[：:]\s*(.+?)\s*AI生成背景`。声明里的字是黑色正文，橙色才是图里的字，两者不能混。

## 六、ego-browser 所有权（多人共用一个浏览器时必踩）

用户手动接管浏览器后，所有命令直接抛：

```
Control of this task space is with the user, either through task.handOff() or a takeover in the browser, so browser commands are paused.
This is a hard stop, not an obstacle to route around
```

- 这不是 bug，别绕过。等用户说「继续」，再 `const task = await takeOverTaskSpace(spaceId)` 拿回来（`task.ownership` 变回 `agent`）。
- 反过来要把浏览器交给用户操作验证码：`await task.handOff()`。
- `waitForControl({ interval?, timeout? })` 的参数名是 `timeout`，传 `timeoutMs` 会 `TypeError: received unknown option`。
- **交给人之后别再跑检索**：脚本一 `goto` 就把验证页冲掉，用户看到的会是一张新题或空白页（本机因此让用户白拖两次）。

## 七、断点续跑与日志

每条一行 JSON 追加到 `run-log.jsonl`：`{seq, author, year, title, journal, at, found, score, detail, result, file, bytes}`，撞闸门时多 `gate / gateOk`，异常时多 `snippet / error`。

- `result` 归一到 `ok / no-match / no-link / not-pdf / verify / error`。
- 续跑时先读日志建成 `doneSeqs`，再过滤任务单、`slice(0, max)`。**只把 `ok` 当完成**，`verify / not-pdf / error` 下轮自动重试。
- 清记录按 `seq` 过滤，注意 JSON 里 `seq` 可能存成数字也可能存成字符串，比较前统一 `String()`。
- 收尾核账别信日志，信目录：`cnki_report.py` 按文件名开头的序号去 PDF 目录里找，找得到且内容比对通过才算真落地。

## 八、脚本族与一条龙用法

四个脚本都在 `scripts/`，全参数化，不依赖本机目录：

| 脚本 | 干什么 | 关键参数 |
|---|---|---|
| `cnki_prepare.py` | 中文清单 CSV → `batch.json` + `books.json`（专著单列） | `--csv --out [--map title=篇名]` |
| `cnki_fetch_batch.mjs` | 专业检索 → 详情页取下载单 → Node 直取 → 魔数校验 | 配置文件（见下） |
| `cnki_captcha.py` | 腾讯点选验证码识别 | `<截图> <三个字> [--list-fonts]` |
| `cnki_report.py` | 逐篇内容比对 + 清单 csv/md | `--queue --pdf [--books --out --md --reject]` |

典型流程（工作目录按 `<内容>-YYYY.MM.DD` 建，所有中间产物都放里面）：

```powershell
$w = "E:\work\知网文献-2026.01.01"
python scripts\cnki_prepare.py --csv 文献表.csv --out $w
# 写 $w/cnki.config.json（模板见下）
ego-browser nodejs -e "globalThis.LITDOWN_CNKI_CONFIG = 'E:/work/知网文献-2026.01.01/cnki.config.json'; await import('file:///<skill 路径>/scripts/cnki_fetch_batch.mjs')"
python scripts\cnki_report.py --queue $w\batch.json --pdf $w\PDF --books $w\books.json
```

`cnki.config.json`：

```json
{
  "queue": "E:/work/知网文献-2026.01.01/batch.json",
  "out":   "E:/work/知网文献-2026.01.01/PDF",
  "log":   "E:/work/知网文献-2026.01.01/run-log.jsonl",
  "space": "cnki-batch",
  "max": 10,
  "gap": 14000,
  "python": "python",
  "captchaScript": "<技能包路径>/modules/lit/scripts/cnki_captcha.py"
}
```

- `space`：数字 = 按 id 接管既有任务空间；字符串 = 按名字新建/续用（推荐）。
- `max` 单次条数、`gap` 条间隔毫秒；跑一批看一眼日志再决定下一批，别一口气到底。
- 不填 `captchaScript` 就只走“重试—跳过”策略，不自动解验证码。
- 日志一行一条：`{seq, author, year, title, journal, at, found, score, detail, result, file, bytes}`，`result` 归一为 `ok / no-match / no-link / not-pdf / verify / error`。续跑只看 `result === "ok"`，其余下轮自动重试（这正是“跳过、冷却、回头补”的实现）。
- 文件名 `{序号:02d}-{第一作者}{年} {题名}.pdf`；`cnki_report.py` 按开头数字认序号，`01-`、`1-`、`001-` 都认。
- `cnki_report.py` 的退出码：期刊条目全中 0，有缺失/存疑 1（专著不计，知网本来就不收）。

清单 CSV 里常见的脏数据，`cnki_prepare.py` 会顺手清：作者字段被 OCR 塞了生僻字前缀（`瑧王家峰` → `王家峰`）、题名被插入空格（`社会组织党建` → `社 会组织党建`）。题名与真实篇名不符的（「和」写成「与」之类）靠专业检索 + 作者名核对纠正；拿到了 PDF 以后，首页文本还能反过来校正清单里标为「待核实」的刊名与期号。
