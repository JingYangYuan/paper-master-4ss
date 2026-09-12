# CNKI kns8s 新版闭环协议：检索 → 分析摘要 → 选择下载全文

本协议是 lit 模块模式 E 的**唯一 CNKI 执行轨道**：检索→分析摘要→选择下载全文一体化。协议分两层：

- **页面层**（本文件主体）：检索式构造、页面动作判据、结果解析、验证码判据、下载与归档。与浏览器后端无关，所有后端一律遵守。
- **后端层**（本文 §2）：把同一页面动作落到具体浏览器控制后端。当前支持两个后端，各自有独立适配文件。

| 后端 | 宿主 | 调用面 | 适配文件 |
|---|---|---|---|
| `ZCode` | ZCode 桌面版 | 内置 browser-use（`mcp__node_repl__js` + browser client） | 本文 §2.1 |
| `OMP` | OMP（Oh My Pi） | pi-chrome `chrome_*` 工具集 | [pi-chrome-browser.md](pi-chrome-browser.md) |

经验来源：`~/.zcode/skills/cnki-skill/SKILL.md`（ZCode 多轮实跑）与 2026-09-12 pi-chrome OMP 全流程实测。

- 入口：`https://kns.cnki.net/starter/advanced` → 自动跳转 `kns.cnki.net/kns8s/AdvSearch`，再切「专业检索」标签。
- 人工闸门（登录、验证码）由用户在可见浏览器中手动完成；自动化遇到闸门即停止询问。
- 状态词表：`浏览器控制正常` / `浏览器控制不可用` / `浏览器页面未完成` / `CNKI 页面未完成` / `captcha_visible` / `captcha_preloaded_hidden` / `zero_results`。
- 通用状态口径：每次检索动作记录 `status: "ok" | "zero_results" | "captcha" | "page_error"`，配合 `fallbackAction`。
- 后端不可用时记录 `浏览器控制不可用`，停止 CNKI 阶段；不得用 WebSearch/Scholar/agents 冒充 CNKI 结果。

---

## 1. 闭环总览

```text
① 检索（专业检索式 → 筛期刊 → 双排序）
② 分析摘要（批量提取 → 逐篇评分分类 → 生成分析表）
③ 选择下载（按规则选篇 → Cookie+curl 下载 → 验证 → 清单）
```

三段各自产出独立工件，任何一段失败只重跑该段，不回滚已验证工件。

---

## 2. 后端层：同一动作的两个后端

### 2.1 ZCode 内置 browser-use

```js
// 0. bootstrap（每次 mcp__node_repl__js 调用都要重新执行）
const browserPluginRoot = process.env.ZCODE_PLUGIN_ROOT ?? process.env.CLAUDE_PLUGIN_ROOT;
const { join } = await import("node:path");
const { pathToFileURL } = await import("node:url");
const browserClientUrl = pathToFileURL(join(browserPluginRoot, "scripts", "browser-client.mjs")).href;
const { setupBrowserRuntime } = await import(browserClientUrl);
await setupBrowserRuntime({ globals: globalThis });
const browser = await agent.browsers.getForUrl("https://www.cnki.net/");

// 1. 打开/复用检索页；登录检查（页头出现"大学/学院名 + 手机号"=机构授权可用）
//    未登录：停止，请用户先在浏览器面板完成机构登录，记录 status:"未登录"
```

页面动作通过 `tab.playwright.evaluate(...)`；等待通过 `tab.playwright.waitForTimeout(...)`；页面内异步（批量 fetch 详情页）可直接 `await`。Cookie 由页内读取后交宿主 `fs.writeFileSync` 落盘（权限 0600，不回显）。

### 2.2 OMP pi-chrome

完整安装、授权、目标模型与失败模式见 [pi-chrome-browser.md](pi-chrome-browser.md)。对本协议影响最大的四条：

1. **不传 `targetId`**：本构建中 `chrome_evaluate`/`chrome_snapshot`/`chrome_click` 传 `targetId` 会返回 `Detached while handling command`。全流程只走 `chrome_navigate` 建立的单一自动化目标。
2. **点击一律走页内 `chrome_evaluate`**：`chrome_click` 在 kns8s 重页面上 `DOM click fallback ... timed out`，`chrome_snapshot` 会 `inject snapshot script ... timed out`。
3. **页面内异步不得 `awaitPromise`**：await 慢 fetch 会中断调用。统一写成 fire-and-forget 写 `window.__x`，再用 `chrome_wait_for { kind: "expression" }` 轮询（见 §4.3）。
4. **Cookie 走回环 sink**：`python3 modules/lit/scripts/cnki/cookie_sink.py --out /tmp/cnki_cookie.txt`，页面 `fetch('http://127.0.0.1:PORT/c', { method:'POST', body: document.cookie })`；用完 `rm -f`。

等待一律用 `chrome_wait_for { kind: "selector" | "expression" }` 代替固定 `waitForTimeout`。

### 2.3 后端等价动作对照

| 协议动作 | 页面层载荷 | ZCode | OMP pi-chrome |
|---|---|---|---|
| 导航 | — | `tabs.new()` + `navigate` | `chrome_navigate`（不带 target） |
| 就绪等待 | — | `waitForTimeout(ms)` | `chrome_wait_for`（selector/expression） |
| 执行页内 JS | 见 §3–§4 | `tab.playwright.evaluate(fn)` | `chrome_evaluate({ expression })`，返回 `JSON.stringify(...)` |
| 填检索式 | 写 `#ModuleSearch textarea.majorSearch` | `locator.fill(query)` | `chrome_fill({ selector, text })` |
| 点击 | 页内 `.click()` / `jQuery(...).trigger('click')` | `evaluate` 或 `locator.click` | `chrome_evaluate`（不用 `chrome_click`） |
| 验证码判据 | 几何可见性 | `evaluate` | `chrome_evaluate` |
| Cookie 落盘 | `document.cookie` | 页内读取 + 宿主写盘 | 回环 sink（`cookie_sink.py`） |
| 截图留证 | — | `screenshot()` | `chrome_screenshot` |

---

## 3. ① 检索段

### 3.1 硬性经验（页面层，违反即失败，不要尝试替代方案）

1. 切换"专业检索"标签必须页内 JS 点击（页面有隐藏重复 DOM，坐标/locator 点击会落空）：
   `evaluate(() => document.querySelector('li[name="majorSearch"]').click())`
2. 检索按钮必须用**专业检索面板容器限定**的 `#ModuleSearch input.btn-search`。裸 `input.btn-search` 会命中页面里隐藏的镜像按钮（`input.search-btn`），trigger 打到隐藏按钮上会静默失败：无结果表、命中 0、检索词仍留在输入框。任何坐标/locator 真实点击都会因页面点击瞬间重排而失败，唯一可靠方式：
   `evaluate(() => window.jQuery(document.querySelector('#ModuleSearch input.btn-search')).trigger('click'))`
3. 结果 AJAX 就地加载（POST `/kns8s/brief/grid`），URL 不变；触发后等结果表出现再读（ZCode 等 4 秒；OMP 用 `chrome_wait_for` 等 `table.result-table-list tbody tr`）。
4. 会话开始标签列表可能为空，直接新建标签；登录态在 Cookie 中保持。
5. 同一标签页可连续换词重查（幂等），无需刷新。

### 3.2 检索式构造（与检索策略顾问协作）

字段 `SU/TI/KY/TKA/AB/AU/LY`；运算符 `*` 与、`+` 或、`-` 非、`''` 短语、`()` 分组。两条硬规则（2026-09-09 实测）：

- `+`/`*`/`-` **只能做同一字段内的组合**（同义/近义词并入同一 `SU=(...)` 组）；**跨字段**的逻辑组合必须用字面运算符 `AND`/`OR`/`NOT`。跨字段误用 `+`（如 `AU='周黎安' AND (TI='x' + AB='x')`）不会报错，而是**静默失败**：页面停在输入态、无结果表、命中 0。跨字段正确写法示例：
  `AU='周黎安' AND (TI='不可能三角' OR AB='不可能三角' OR KY='不可能三角')`
- 排障顺序：检索触发后无结果表且检索词仍留在输入框 → 先检查是否跨字段用了 `+`（改 `OR` 重试一次），再按验证码几何判据与网络状态排查；不得把语法性静默失败记成 `zero_results` 或 `captcha`。

同字段组合示例：
`SU=('新就业群体' + '新就业形态劳动者' + '新业态从业人员' + '灵活就业人员')`

### 3.3 填式与触发

```js
// 切专业检索（页面重排前不要抓元素引用）
evaluate(() => document.querySelector('li[name="majorSearch"]').click());
// 等 #ModuleSearch textarea.majorSearch 就绪，再填式：
fill("#ModuleSearch textarea.majorSearch", query);     // 输入框同样以 #ModuleSearch 容器限定
// 触发检索（容器限定 + jQuery trigger，见 3.1 第 2 条）
evaluate(() => window.jQuery(document.querySelector('#ModuleSearch input.btn-search')).trigger('click'));
```

### 3.4 验证码判断

腾讯滑块常驻 DOM 但藏于视口外，唯一有效判据是几何可见性：

```js
const cap = evaluate(() => {
  const w = document.querySelector('#tCaptchaDyMainWrap');
  if (!w) return false;
  const r = w.getBoundingClientRect();
  return r.y > -1000 && r.height > 100;
});
```

`true` → 记录 `status:"captcha"`，**停止自动化并请用户在浏览器中手动拖动完成**，完成后从触发步骤重试。页面文本含"验证码/拖动"但几何判断为 false 时，属于 `captcha_preloaded_hidden`，只记录诊断，不打扰用户。

### 3.5 筛选与排序（双排序取并集，兼顾政策阐释经典与近期实证）

```js
// 筛学术期刊（文本形如"学术期刊2486"）
evaluate(() => {
  Array.from(document.querySelectorAll('a'))
    .find(e => /^学术期刊\d+$/.test((e.textContent||'').trim()) && e.offsetParent)?.click();
});
// 排序：li#FFD 相关度 | li#CF 被引 | li#DFR 下载；每次排序后等结果表刷新
evaluate(() => document.querySelector('li#CF').click());
```

### 3.6 列表提取

```js
const rows = evaluate(() =>
  Array.from(document.querySelectorAll('table.result-table-list tbody tr')).slice(0, 20).map(tr => ({
    title: tr.querySelector('td.name a.fz14')?.textContent.trim() ?? '',
    href: tr.querySelector('td.name a.fz14')?.href ?? '',
    author: tr.querySelector('td.author')?.textContent.trim() ?? '',
    source: tr.querySelector('td.source')?.textContent.trim() ?? '',
    date: tr.querySelector('td.date')?.textContent.trim() ?? '',
  })));
```

OMP 端必须 `JSON.stringify(...)` 包装为字符串返回。

### 3.7 ①段产出

`search-log.md` 追加一条：检索式、命中总数、期刊筛后数、排序状态、验证码状态（`captcha_visible` / `captcha_preloaded_hidden` / `none`）、结果行数。字段规范：`status: ok | zero_results | captcha | page_error`。

每轮检索返回后必须在回复中显式报告命中总数与是否触发筛选收窄。

---

## 4. ② 分析摘要段

### 4.1 批量提取

同一页内 `fetch(detailUrl, { credentials: 'include' })` + `DOMParser` 解析，**每批 ≤3 个 URL**。

```js
const parse = (html) => {
  const doc = new DOMParser().parseFromString(html, 'text/html');
  return {
    title: doc.querySelector('h1')?.textContent.trim().slice(0, 60) ?? '',
    abstract: doc.querySelector('#ChDivSummary')?.textContent.trim() ?? '',
    keywords: Array.from(doc.querySelectorAll('p.keywords a')).map(a => a.textContent.trim().replace(/;$/, '')),
    pdfHref: doc.querySelector('a#pdfDown')?.href ?? null,
  };
};
```

- **ZCode**：`await` 循环 fetch（`evaluate` 3 秒预算内分批）。
- **OMP**：不得 `awaitPromise`。写成立即返回的 fire-and-forget，把结果挂到 `window.__cnki`，再用 `chrome_wait_for { kind: "expression", value: "window.__cnki !== null" }` 等，最后 `chrome_evaluate` 读 `JSON.stringify(window.__cnki)`。

### 4.2 逐篇分析（代理执行，规则化评分）

对每篇按以下量规打分并分类，写入分析表：

**相关性分（0–5，对照研究主题的核心概念）**
- 5 题名或关键词直接命中核心概念
- 4 摘要核心议题即该群体/概念
- 3 摘要以该群体为主要样本或对象之一
- 2 仅部分章节/变量涉及
- 1 仅背景提及，0 无关

**类型分类**（依摘要方法学信号）
- `实证`：数据+模型信号（问卷调查、Logistic/回归、精算模型、CFPS/CLDS、结构方程、DID/IV、PMC 指数等）
- `政策阐释`：制度/法理/政策信号（制度建构、法理探析、政策检视、路径设计、治理）
- `理论/综述`：文献综述、理论框架、概念辨析
- `其他`：无法判断

**优先级 = 相关性分 × 类型权重（实证 1.0 / 政策阐释 0.9 / 理论综述 0.7 / 其他 0.4）+ 0.5（核心期刊：管理世界、社会学研究、中国工业经济、公共管理学报等，或 CSSCI 信号）**

### 4.3 ②段产出

`02-literature/abstract-analysis-table.md`：表格列 = 序号｜题名｜作者｜来源｜日期｜关键词｜相关性分｜类型｜优先级｜下载决策（✅/⏸/❌+理由）。表前写明研究主题与评分口径，表后写 2–4 条总体观察（文献结构、缺口信号）。

---

## 5. ③ 选择下载段

**选择规则（默认，可被用户覆盖）**：优先级降序取前 N（默认 N=8）；同分先取实证类；已在本工作区下载过的跳过（对照既有清单）；相关性 ≤2 的不下载。

**免弹窗下载（Cookie + curl）**——不要走浏览器下载（必弹 Save-As，无人点即取消 `download cancelled`），不要页内 fetch（kns→bar 跨域 CORS 拦截）：

```bash
# a. 取 Cookie：ZCode 由页内读取后宿主写盘；OMP 走回环 sink
python3 modules/lit/scripts/cnki/cookie_sink.py --out /tmp/cnki_cookie.txt --port 17399 --timeout 240
#    页面侧（chrome_evaluate / playwright.evaluate）：
#    fetch('http://127.0.0.1:17399/c', { method: 'POST', body: document.cookie })

# b. 从项目注册表生成计划并批量下载
python3 modules/lit/scripts/literature_registry.py download-plan \
  --workspace <paper-workspace> --out <paper-workspace>/02-literature/plans/download-plan.tsv
bash modules/lit/scripts/cnki/kns8s-download.sh \
  /tmp/cnki_cookie.txt <paper-workspace> <paper-workspace>/02-literature/plans/download-plan.tsv
# 计划由注册表生成，每行：paper_id\tpdf_path\tPDF直链URL

# c. 验证由脚本完成：先写 .part，再用 pypdf、pdfinfo 或 qpdf 解析后归档；首次 HTML/频控页即停止本批

# d. 收尾
rm -f /tmp/cnki_cookie.txt
```

Cookie 文本不得回传对话或写入日志。

**③段产出**：`02-literature/papers/`（题名 PDF；同题冲突时使用 paper_id 子目录）与 `paper-registry.csv`。后者记录文件路径、哈希、页数、下载状态和失败原因，是所有来源共用的唯一清单。

---

## 6. 日志与状态

- 每段完成后向 `paper-workspace/_logs/process-log-lit-cnki-<日期>.md` 追加：时间、动作、后端（`ZCode` / `OMP pi-chrome`）、前置页、检索式/URL、status、命中/处理数、验证码状态、fallbackAction。
- 三段全部完成才可写 `CNKI 已执行`；只完成①段写 `CNKI 检索已完成(仅题录)`。
- 来源不可替代协议继续有效：CNKI 状态只能来自本协议的网页操纵结果，WebSearch/agents 只做关键词准备。

## 7. 研究者确认点（overlay）

按 researcher-agency-overlay，以下节点先呈现方案等确认，**用户本轮目标指令"迭代直至完成闭环"已构成对①②③全流程的预授权**，逐次确认可省略，但每次下载的选篇清单仍需在最终回复中完整呈现供事后审阅：改检索式收窄/扩宽、调整 N 或阈值、下载 ≥15 篇、输出目录变更。
