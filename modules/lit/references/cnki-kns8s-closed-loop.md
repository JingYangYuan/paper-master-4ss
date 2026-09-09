# CNKI kns8s 新版闭环协议：检索 → 分析摘要 → 选择下载全文

本协议是 lit 模块模式 E 的**唯一 CNKI 执行轨道**，使用 ZCode 内置浏览器控制（browser-use，`mcp__node_repl__js` + browser client），经验来源为 `~/.zcode/skills/cnki-skill/SKILL.md`（已经多轮全流程实跑验证）。

- 入口：`https://kns.cnki.net/starter/advanced` → 自动跳转 `kns.cnki.net/kns8s/AdvSearch`，再切「专业检索」标签。
- 人工闸门（登录、验证码）由用户在可见的浏览器面板中手动完成；自动化遇到闸门即停止询问。
- 状态词表：`浏览器控制正常` / `浏览器控制不可用` / `浏览器页面未完成` / `CNKI 页面未完成` / `captcha_visible` / `captcha_preloaded_hidden` / `zero_results`。
- 通用状态口径：每次检索动作记录 `status: "ok" | "zero_results" | "captcha" | "page_error"`，配合 `fallbackAction`。
- browser-use 不可用时记录 `浏览器控制不可用`，停止 CNKI 阶段；不得用 WebSearch/Scholar/agents 冒充 CNKI 结果。

---

## 闭环总览

```text
① 检索（专业检索式 → 筛期刊 → 双排序）
② 分析摘要（批量提取 → 逐篇评分分类 → 生成分析表）
③ 选择下载（按规则选篇 → Cookie+curl 下载 → 验证 → 清单）
```

三段各自产出独立工件，任何一段失败只重跑该段，不回滚已验证工件。

---

## ① 检索段

### 硬性经验（违反即失败，不要尝试替代方案）

1. 切换"专业检索"标签必须页内 JS 点击（页面有隐藏重复 DOM，Playwright 点击会落空）：
   `evaluate(() => document.querySelector('li[name="majorSearch"]').click())`
2. 检索按钮必须用**专业检索面板容器限定**的 `#ModuleSearch input.btn-search`。裸 `input.btn-search` 会命中页面里隐藏的镜像按钮（`input.search-btn`），trigger 打到隐藏按钮上会静默失败：无结果表、命中 0、检索词仍留在输入框。任何坐标/locator 真实点击都会因页面点击瞬间重排而失败，唯一可靠方式：
   `evaluate(() => window.jQuery(document.querySelector('#ModuleSearch input.btn-search')).trigger('click'))`
3. 结果 AJAX 就地加载（POST `/kns8s/brief/grid`），URL 不变；触发后等 4 秒再读结果表。
4. 会话开始 `tabs.list()` 可能为空，直接 `tabs.new()` 重开；登录态在 Cookie 中保持。
5. 同一标签页可连续换词重查（幂等），无需刷新。

### 步骤

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

// 2. 切专业检索 + 填检索式（输入框同样以 #ModuleSearch 容器限定）
await tab.playwright.evaluate(() => document.querySelector('li[name="majorSearch"]').click());
await tab.playwright.waitForTimeout(1200);
const ta = tab.playwright.locator("#ModuleSearch textarea.majorSearch");
if ((await ta.count()) !== 1) throw new Error("输入框不唯一");
await ta.fill(query);

// 3. 触发检索（按钮必须带 #ModuleSearch 容器，见硬性经验第 2 条）
await tab.playwright.evaluate(() => {
  window.jQuery(document.querySelector('#ModuleSearch input.btn-search')).trigger('click');
});
await tab.playwright.waitForTimeout(4000);
```

**检索式构造**（与检索策略顾问协作）：字段 `SU/TI/KY/TKA/AB/AU/LY`；运算符 `*` 与、`+` 或、`-` 非、`''` 短语、`()` 分组。两条硬规则（2026-09-09 实测）：

- `+`/`*`/`-` **只能做同一字段内的组合**（同义/近义词并入同一 `SU=(...)` 组）；**跨字段**的逻辑组合必须用字面运算符 `AND`/`OR`/`NOT`。跨字段误用 `+`（如 `AU='周黎安' AND (TI='x' + AB='x')`）不会报错，而是**静默失败**：页面停在输入态、无结果表、命中 0。跨字段正确写法示例：
  `AU='周黎安' AND (TI='不可能三角' OR AB='不可能三角' OR KY='不可能三角')`
- 排障顺序：检索触发后无结果表且检索词仍留在输入框 → 先检查是否跨字段用了 `+`（改 `OR` 重试一次），再按验证码几何判据与网络状态排查；不得把语法性静默失败记成 `zero_results` 或 `captcha`。

同字段组合示例：
`SU=('新就业群体' + '新就业形态劳动者' + '新业态从业人员' + '灵活就业人员')`

**验证码判断**：腾讯滑块常驻 DOM 但藏于视口外，唯一有效判据是几何可见性——
```js
const cap = await tab.playwright.evaluate(() => {
  const w = document.querySelector('#tCaptchaDyMainWrap');
  if (!w) return false;
  const r = w.getBoundingClientRect();
  return r.y > -1000 && r.height > 100;
});
```
`true` → 记录 `status:"captcha"`，**停止自动化并请用户在浏览器面板手动拖动完成**，完成后从第 3 步重试。页面文本含"验证码/拖动"但几何判断为 false 时，属于 `captcha_preloaded_hidden`，只记录诊断，不打扰用户。

**筛选与排序**（双排序取并集，兼顾政策阐释经典与近期实证）：
```js
// 筛学术期刊（文本形如"学术期刊2486"）
await tab.playwright.evaluate(() => {
  Array.from(document.querySelectorAll('a'))
    .find(e => /^学术期刊\d+$/.test((e.textContent||'').trim()) && e.offsetParent)?.click();
});
await tab.playwright.waitForTimeout(3500);
// 排序：li#FFD 相关度 | li#CF 被引 | li#DFR 下载；每次排序后等 3.5 秒
```

**列表提取**：
```js
const rows = await tab.playwright.evaluate(() =>
  Array.from(document.querySelectorAll('table.result-table-list tbody tr')).slice(0, 20).map(tr => ({
    title: tr.querySelector('td.name a.fz14')?.textContent.trim() ?? '',
    href: tr.querySelector('td.name a.fz14')?.href ?? '',
    author: tr.querySelector('td.author')?.textContent.trim() ?? '',
    source: tr.querySelector('td.source')?.textContent.trim() ?? '',
    date: tr.querySelector('td.date')?.textContent.trim() ?? '',
  })));
```

**①段产出**：`search-log.md` 追加一条：检索式、命中总数、期刊筛后数、排序状态、验证码状态（`captcha_visible` / `captcha_preloaded_hidden` / `none`）、结果行数。字段规范：`status: ok | zero_results | captcha | page_error`。

---

## ② 分析摘要段

### 批量提取（每批 ≤3 个 URL，evaluate 3 秒预算）

```js
const details = await tab.playwright.evaluate(async (urls) => {
  const parse = (html) => {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    return {
      title: doc.querySelector('h1')?.textContent.trim().slice(0, 60) ?? '',
      abstract: doc.querySelector('#ChDivSummary')?.textContent.trim() ?? '',
      keywords: Array.from(doc.querySelectorAll('p.keywords a')).map(a => a.textContent.trim().replace(/;$/, '')),
      pdfHref: doc.querySelector('a#pdfDown')?.href ?? null,
    };
  };
  const out = [];
  for (const u of urls) {
    try { out.push(parse(await (await fetch(u, { credentials: 'include' })).text())); }
    catch (e) { out.push({ err: String(e).slice(0, 80) }); }
  }
  return out;
}, batchUrls);
```

### 逐篇分析（代理执行，规则化评分）

对每篇按以下量规打分并分类，写入分析表：

**相关性分（0–5，对照研究主题的核心概念）**
- 5 题名或关键词直接命中核心概念（如"新就业群体"本身）
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

### ②段产出

`02-literature/abstract-analysis-table.md`：表格列 = 序号｜题名｜作者｜来源｜日期｜关键词｜相关性分｜类型｜优先级｜下载决策（✅/⏸/❌+理由）。表前写明研究主题与评分口径，表后写 2–4 条总体观察（文献结构、缺口信号）。

---

## ③ 选择下载段

**选择规则（默认，可被用户覆盖）**：优先级降序取前 N（默认 N=8）；同分先取实证类；已在本工作区下载过的跳过（对照既有清单）；相关性 ≤2 的不下载。

**免弹窗下载（Cookie + curl）**——不要走浏览器下载（必弹 Save-As，无人点即取消 `download cancelled`），不要页内 fetch（kns→bar 跨域 CORS 拦截）：

```js
// a. 导出 Cookie 到临时文件（不打印到日志）
const ck = await tab.playwright.evaluate(() => document.cookie);
const fs = await import("node:fs");
fs.writeFileSync("/tmp/cnki_cookie.txt", ck);
```

```bash
# b. 从项目注册表生成计划并批量下载
python3 "modules/lit/scripts/literature_registry.py" download-plan \
  --workspace <paper-workspace> --out <paper-workspace>/02-literature/plans/download-plan.tsv
bash "modules/lit/scripts/cnki/kns8s-download.sh" \
  /tmp/cnki_cookie.txt <paper-workspace> <paper-workspace>/02-literature/plans/download-plan.tsv
# 计划由注册表生成，每行：paper_id\tpdf_path\tPDF直链URL
```

```bash
# c. 验证由脚本完成：先写 .part，再用 pypdf、pdfinfo 或 qpdf 解析后归档；首次 HTML/频控页即停止本批
```

下载后 `rm -f /tmp/cnki_cookie.txt`。

**③段产出**：02-literature/papers/（题名 PDF；同题冲突时使用 paper_id 子目录）与 paper-registry.csv。后者记录文件路径、哈希、页数、下载状态和失败原因，是所有来源共用的唯一清单。

---

## 日志与状态

- 每段完成后向 `paper-workspace/_logs/process-log-lit-cnki-<日期>.md` 追加：时间、动作、前置页、检索式/URL、status、命中/处理数、验证码状态、fallbackAction。
- 三段全部完成才可写 `CNKI 已执行`；只完成①段写 `CNKI 检索已完成(仅题录)`。
- 来源不可替代协议继续有效：CNKI 状态只能来自本协议的网页操纵结果，WebSearch/agents 只做关键词准备。

## 研究者确认点（overlay）

按 researcher-agency-overlay，以下节点先呈现方案等确认，**用户本轮目标指令"迭代直至完成闭环"已构成对①②③全流程的预授权**，逐次确认可省略，但每次下载的选篇清单仍需在最终回复中完整呈现供事后审阅：改检索式收窄/扩宽、调整 N 或阈值、下载 ≥15 篇、输出目录变更。
