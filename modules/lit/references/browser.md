# 浏览器兜底

只在三种情况下开浏览器，其余一律纯 HTTP：

1. 目标站要过 Cloudflare / Turnstile（Sci-Hub、ScienceDirect）；
2. 直链是 JS 渲染出来的（`citation_pdf_url` 在 DOM 里拼出来的站）；
3. 需要你的登录态（机构订阅、个人账号）。

## 一、ego-browser 基本用法

先在终端跑一次 `ego-browser skill`，读它给的使用手册（版本会变，手册跟着版本走）。

```powershell
# 每轮写一个独立的 .mjs，再让 ego-browser 执行——比 -e 里塞长脚本稳
ego-browser nodejs -e "await import('file:///C:/Users/<你>/ego/任务目录/round-01.mjs')"
```

脚本骨架：

```js
const task = await taskSpace("paper-20260101").catch(() => taskSpace("paper"));  // 空间会失效，兜一层
const page = task.page("p1");
await page.goto(url, { timeout: 45000 });        // 默认只有 15s
await page.waitForTimeout(3000);                  // 让 JS 跑完
const info = await page.evaluate(() => ({
  url: location.href,
  pdf: document.querySelector('meta[name="citation_pdf_url"]')?.content || null,
}));
console.log(JSON.stringify(info));
```

## 二、硬限制（都踩过）

| 限制 | 表现 | 对策 |
|---|---|---|
| `page.goto` 默认 15s | 慢站直接超时 | 显式传 `{ timeout: 45000 }` |
| `page.evaluate` 15s 上限 | `PageEvaluationTimeoutError: page.evaluate timed out after 15000ms and the Page is still unresponsive` | 页面已卡死，**必须 reload 或换页**，重试同一调用没用 |
| `page.fetch` 是 window.fetch | 跨域直接 `TypeError: Failed to fetch`；同域也会被 CSP 的 `connect-src` 拦（Wiley 就是这类） | 拿 PDF 地址回 Python 下；下不下来就上第七节的 CDP 取字节，别在页面里 fetch |
| ego-browser 没有代理参数 | 出口永远是本机 IP，加不加 `HTTPS_PROXY` 都一样 | 改 **Windows 系统代理**（`HKCU:\...\Internet Settings` 的 `ProxyEnable`/`ProxyServer`），跑完恢复原值 |
| `taskSpace(8)` 这种数字 id | `Error: task space not found: 8` | 参数是名字不是 id：`await taskSpace("litdown round9")` |
| `task.cdp` 与 `page.cdp` 分层 | 任务级只收 `Target.`/`Browser.`：`Storage.getCookies` 报 `task.cdp only supports Target. and Browser. commands`；但 **`page.cdp` 可以发 `Page.*`**（`Page.getFrameTree` / `Page.getResourceContent` / `Page.printToPDF` 均已实测可用） | cookie 用 `page.evaluate(() => document.cookie)` 或 `Page.getCookies`；取字节、打印 PDF 走 `page.cdp` |
| 页面状态会丢 | 空间 id 失效报 `task space not found: N` | 用 `.catch(() => taskSpace("备用名"))` |

## 三、Turnstile 的正确用法

Sci-Hub 的 Cloudflare 校验在真实 Chromium 里**会自动通过**：页面显示"成功！"，随后自己 `POST /api/verify-turnstile` 并写入 `document.cookie='scihub_verified=1; path=/; max-age=1800'`。

因此只需**第一次**用浏览器：

```js
await page.goto("https://sci-hub.ren/10.1093/qje/qjx032", { timeout: 60000 });
await page.waitForTimeout(8000);
const cookie = await page.evaluate(() => document.cookie);   // 含 scihub_verified=1
console.log(cookie);
```

拿到后把 `Cookie: scihub_verified=1` 塞进 requests 头，剩下几百条纯 HTTP 跑完。cookie 有效期约 30 分钟，过期了再开一次浏览器刷新。

## 四、在页面里捞 PDF 地址的通用写法

```js
const c = await page.evaluate(() => {
  const meta = document.querySelector('meta[name="citation_pdf_url"]');
  const embed = document.querySelector('embed[src*=".pdf"], iframe[src*=".pdf"]');
  const links = [...document.querySelectorAll('a')]
    .map(a => a.href).filter(h => /\.pdf(\?|#|$)/i.test(h));
  return { meta: meta?.content || null, embed: embed?.src || null, links: links.slice(0, 5),
           text: document.body.innerText.slice(0, 200) };
});
```

`embed.src` 常带 `#view=FitH` 之类片段，**下载前必须 `.split("#")[0]`**，否则 404。

## 五、反检测

- 无头 / `navigator.webdriver === true` 的浏览器会被 ScienceDirect、Wiley 直接挡。
- ego-browser 是真实 Chromium 带完整 profile，这点比 Playwright 裸启动强；但仍要避免高频，一个页面只做一件事。
- 需要登录态的站，先人工登录好，再用同一个 profile 跑批量——不要每次新建上下文。

## 六、什么时候别开浏览器

浏览器一条要 8–15 秒，纯 HTTP 一条 1–3 秒。**先用 `scripts/probe_channels.py` 判定哪些站是"HTTP 可下"，剩下的才进浏览器队列。** 本机经验：258 条里只有 20% 左右需要浏览器介入。

## 七、抓内联渲染的 PDF（CDP `Page.getResourceContent`）

有一类站很折磨：**requests 和页内 fetch 都 403，但 `page.goto` 能让 Chrome 把 PDF 内联渲染出来**。IRIS/CINECA 系机构库（`publicatt.unicatt.it/retrieve/...`）、部分高校库都这样。此时 `fetch` 已无路可走（CSP、CORS、405 各拦一道），但 CDP 能直接取字节：

```js
await page.goto(url, { timeout: 90000 });
await page.waitForTimeout(7000);                     // 等阅读器把字节拿完
const { frameTree } = await page.cdp("Page.getFrameTree");
const r = await page.cdp("Page.getResourceContent", {
  frameId: frameTree.frame.id,
  url,                                              // 用请求时的原始 URL，不是帧后的 URL
});
const buf = Buffer.from(r.content, "base64");
if (r.base64Encoded && buf.subarray(0, 5).toString() === "%PDF-" && buf.length > 20000) {
  await writeFile(outPath, buf);
}
```

实测：`publicatt.unicatt.it` 一条 655 KB、10 页，`r.base64Encoded === true`，首页印着 CC BY-NC-ND——明明是 OA，却被前四轮的 Unpaywall/OpenAlex 全量重扫判成“无 OA 副本”。

失败长相与含义：

| 现象 | 含义 |
|---|---|
| `No resource with given URL found` | 响应根本没到浏览器。去看帧 URL：剩 `m/doi/pdfdirect/10.1111/aspp.12752` 这种 base64 残影（`bS9kb2kvcGRmZGlyZWN0...` 解码就是 `m/doi/pdfdirect/...`），说明 Chrome 想打开但服务器给了 403 页 |
| 取到字节但不是 `%PDF-` | 拿到的是错误页/登录页；别硬写盘 |
| 页内被 AWS WAF 换掉 | `scispace.com/pdf/...` 就是这样：直链在 requests、页内 fetch、真浏览器里都 405，页面只剩 `awswaf.com/.../captcha.js`。这个源直接放弃 |

几个没用的备选，别再试：`Browser.setDownloadBehavior` + `goto`（Wiley、unicatt 都只是内联打开，不触发下载）；`Page.getResourceTree` 逐帧扫 `resources[]`（本版本 ego-browser 返回空数组，不如直接 `getFrameTree` + 请求 URL）；`Page.getResourceContent` 换帧 id 反复试（一个 URL 只有一个帧命中，全错就是没戏）。

## 八、免费网页全文打印成 PDF（`Page.printToPDF`）

有些刊物（American Affairs、部分智库与评论刊）把全文免费放在网页上、只给持纸本订户 PDF。这类条目用 CDP 打印，比缺一篇强：

```js
await page.goto(articleUrl, { timeout: 60000 });
await page.waitForTimeout(3000);
const r = await page.cdp("Page.printToPDF", {
  printBackground: false, paperWidth: 8.27, paperHeight: 11.69,     // A4，单位英寸
  marginTop: 0.7, marginBottom: 0.7, marginLeft: 0.75, marginRight: 0.75,
});
await writeFile(outPath, Buffer.from(r.data, "base64"));
```

三条必做：

1. **验完整性**：用 `fitz` 数页数 + 总字符数，再翻到末页看尾注编到几号（实测 15 页、31,620 字符、尾注 25–27 完整）。
2. **记付费墙横幅**：首稿常把 `You have reached your limit of 1 free article this month` 打在最上方（客户端遮挡、DOM 里正文没删）。清单备注里写明，别让人误以为是正文缺陷。
3. **对页码**：网页版页码 ≠ 期刊页码（本例期刊 136–148，引文里的 194–206 是 SSRN 版分页）。来源渠道写 `print:web`，并在备注里给正页码。

合规上只取站点公开提供的全文，不靠换 IP/清 cookie 刷卡次。
