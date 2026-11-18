// 知网批量下载：专业检索 → 详情页取下载单 → Node 带 cookie + Referer 直取字节。
// 撞验证码先同轮重试，再解验证码，都不成就记 verify 跳过（闸门按次数触发，隔几分钟重跑即过）。
//
// 用法（PowerShell；全程单引号，ASCII 安全）：
//   ego-browser nodejs -e "globalThis.LITDOWN_CNKI_CONFIG = 'E:/work/cnki/cnki.config.json'; await import('file:///C:/path/to/lit-down/scripts/cnki_fetch_batch.mjs')"
// 也可直接把配置对象塞进去： globalThis.LITDOWN_CNKI = { queue: '...', out: '...' }
//
// 配置（JSON）：
//   queue          batch.json 路径（cnki_prepare.py 产出），必需
//   out            PDF 输出目录，必需
//   log            运行日志 jsonl，默认 <out 同级>/run-log.jsonl
//   space          ego-browser 任务空间：数字=按 id 接管，字符串=按名字新建/续用，默认 "cnki-litdown"
//   max            本次跑多少条，默认 10
//   gap            条间隔毫秒，默认 14000
//   python         解释器，默认 "python"
//   captchaScript  验证码识别脚本路径（scripts/cnki_captcha.py）；不填则跳过自动解
//   ua             覆盖 User-Agent
//   only           只跑这些 seq，如 [1,5,9]
const fs = await import("node:fs/promises");
const path = await import("node:path");
const cp = await import("node:child_process");

const raw = globalThis.LITDOWN_CNKI
  || (globalThis.LITDOWN_CNKI_CONFIG
    ? JSON.parse(await fs.readFile(globalThis.LITDOWN_CNKI_CONFIG, "utf8"))
    : null);
if (!raw) throw new Error("缺少配置：设 globalThis.LITDOWN_CNKI_CONFIG（配置文件路径）或 globalThis.LITDOWN_CNKI（对象）");
if (!raw.queue || !raw.out) throw new Error("配置至少要给 queue 与 out");

const WORK = path.dirname(path.resolve(raw.queue));
const QUEUE = path.resolve(raw.queue);
const OUT = path.resolve(raw.out);
const LOG = path.resolve(raw.log || path.join(WORK, "run-log.jsonl"));
const SPACE = raw.space === undefined ? "cnki-litdown" : raw.space;
const MAX = Number(raw.max || 10);
const GAP = Number(raw.gap || 14000);
const PY = raw.python || "python";
const CAPTCHA = raw.captchaScript ? path.resolve(raw.captchaScript) : null;
const UA = raw.ua || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36";
const ONLY = Array.isArray(raw.only) && raw.only.length ? new Set(raw.only.map(String)) : null;

await fs.mkdir(OUT, { recursive: true });
const task = await taskSpace(SPACE);
const page = task.page("p1");
console.log("space:", task.spaceId, task.ownership, "| out:", OUT);

const rows = await loadRows();
console.log(`待跑 ${rows.length} 条:`, rows.map((r) => r.seq).join(",") || "（无）");

if (!rows.length) {
  console.log("=== 没有待跑条目 ===");
} else {
  let consecErr = 0;
  for (const row of rows) {
    const rec = { seq: String(row.seq), author: row.author, year: row.year, title: row.title, journal: row.journal, at: new Date().toISOString() };
    try {
      const best = await findArticle(row, rec);
      if (!best) {
        rec.result = "no-match";
      } else {
        let g = await fetchOne(best.detail, 3);
        if (g.verify) {
          rec.gate = true;
          const p = CAPTCHA ? await passGate(best.detail, rec.seq) : { ok: false, why: "no-captcha-script" };
          rec.gateOk = p.ok;
          if (p.ok) g = await fetchOne(best.detail, 2);
        }
        if (g.result === "no-link") rec.result = "no-link";
        else if (g.verify) rec.result = "verify";
        else if (g.isPdf || g.isCaj) {
          const ext = g.isCaj ? ".caj" : ".pdf";
          const name = safeName(`${String(row.seq).padStart(2, "0")}-${firstAuthor(row.author)}${row.year} ${row.title}`) + ext;
          await fs.writeFile(path.join(OUT, name), g.buf);
          rec.result = "ok";
          rec.file = name;
          rec.bytes = g.buf.length;
        } else {
          rec.result = "not-pdf";
          rec.snippet = g.buf.slice(0, 200).toString("utf8").replace(/\s+/g, " ");
        }
      }
    } catch (e) {
      rec.result = "error";
      rec.error = String(e).slice(0, 240);
      consecErr += 1;
    }
    await fs.appendFile(LOG, JSON.stringify(rec) + "\n", "utf8");
    console.log(`${rec.seq} ${rec.result} ${rec.via || ""} ${rec.bytes || ""} | ${(rec.found || row.title).slice(0, 40)} ${rec.error || rec.snippet || ""}`.slice(0, 260));
    if (rec.result === "ok" || rec.result === "no-match" || rec.result === "no-link") consecErr = 0;
    else if (rec.result !== "error") consecErr += 1;
    if (consecErr >= 3) { console.log("aborting: 3 consecutive errors"); break; }
    await new Promise((r) => setTimeout(r, GAP));
  }
  console.log("=== done ===");
}

// ---------- helpers ----------

async function loadRows() {
  const all = JSON.parse(await fs.readFile(QUEUE, "utf8"));
  const done = new Set();
  try {
    for (const line of (await fs.readFile(LOG, "utf8")).split("\n")) {
      if (!line.trim()) continue;
      try {
        const r = JSON.parse(line);
        if (r.result === "ok") done.add(String(r.seq));   // 只信 ok；verify/no-file 下轮自动重跑
      } catch {}
    }
  } catch {}
  return all
    .filter((r) => !done.has(String(r.seq)))
    .filter((r) => !ONLY || ONLY.has(String(r.seq)))
    .slice(0, MAX);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const norm = (s) => (s || "").replace(/\s+/g, "")
  .replace(/[—–－―]/g, "-").replace(/[：:]/g, ":").replace(/[，,]/g, ",")
  .replace(/[（(]/g, "(").replace(/[）)]/g, ")").replace(/[“”"']/g, "").replace(/[·・]/g, "");
const clean = (s) => (s || "").replace(/\s+/g, "").replace(/['’"]/g, "");
const firstAuthor = (a) => String(a || "").split(/[、,，/／;；\s]+/).filter(Boolean)[0] || "";
const safeName = (s) => s.replace(/[<>:"/\\|?*\x00-\x1f]/g, "").replace(/\s+/g, " ").trim().slice(0, 120);

async function findArticle(row, rec) {
  const t = clean(row.title);
  const au = firstAuthor(row.author);
  const core = t.split(/[：:—-]/)[0];
  const variants = [`TI='${t}'${au ? ` AND AU='${au}'` : ""}`];
  if (core && core !== t) variants.push(`TI='${core}'${au ? ` AND AU='${au}'` : ""}`);
  if (t.length > 12) variants.push(`TI='%${t.slice(0, 12)}%'${au ? ` AND AU='${au}'` : ""}`);
  if (t.length > 8) variants.push(`TI='%${t.slice(0, 8)}%'${au ? ` AND AU='${au}'` : ""}`);
  if (t.length > 8) variants.push(`TI='%${t.slice(0, 8)}%'`);

  let best = null;
  let bestScore = 0;
  for (const q of variants) {
    for (const r of await proSearch(q)) {
      const nt = norm(r.t);
      let s = 0;
      if (nt === norm(row.title)) s += 4;
      else if (nt.includes(norm(core).slice(0, 10))) s += 2;
      else continue;
      if (au && r.row.includes(au)) s += 2;
      if (row.journal && r.row.includes(String(row.journal).slice(0, 4))) s += 1;
      if (String(row.year) && r.row.includes(String(row.year))) s += 1;
      if (s > bestScore) { bestScore = s; best = r; }
    }
    if (bestScore >= 6) break;
  }
  rec.found = best ? best.t : null;
  rec.score = bestScore;
  rec.detail = best ? best.detail : null;
  return best;
}

async function proSearch(q) {
  await page.goto("https://kns.cnki.net/kns8s/AdvSearch", { timeout: 60000 });
  await page.waitForTimeout(1000);
  try {
    await page.click("loc=text=专业检索", { timeout: 6000 });
  } catch {
    await page.waitForTimeout(400);
    await page.evaluate(() => [...document.querySelectorAll("a,li,div")].find((x) => (x.innerText || "").trim() === "专业检索")?.click());
  }
  await page.waitForTimeout(700);
  await page.fill("css:textarea.textarea-major", q);
  await page.evaluate(() => {
    const b = [...document.querySelectorAll("input[type=button],input[type=submit],button,a.btn")]
      .filter((x) => /^检索$/.test((x.value || x.innerText || "").trim()) && x.offsetParent !== null);
    b[b.length - 1]?.click();
  });
  await page.waitForTimeout(4000);
  return page.evaluate(() => [...document.querySelectorAll("table tbody tr")].map((tr) => {
    const a = tr.querySelector("a.fz14");
    return a ? { t: a.innerText.trim(), detail: a.href, row: tr.innerText.replace(/\s+/g, " ") } : null;
  }).filter(Boolean));
}

async function cookieStr() {
  const ck = await page.cdp("Network.getCookies", { urls: ["https://kns.cnki.net/", "https://bar.cnki.net/"] }).catch(() => ({ cookies: [] }));
  return (ck.cookies || []).map((c) => `${c.name}=${c.value}`).join("; ");
}

async function grab(detail) {
  const order = await page.evaluate(() =>
    document.querySelector("li.btn-dlpdf a")?.href || document.querySelector("li.btn-ywdlpdf a")?.href || null);
  if (!order) return { result: "no-link" };
  const r = await fetch(order, {
    headers: { Cookie: await cookieStr(), Referer: detail, "User-Agent": UA, Accept: "*/*", "Accept-Language": "zh-CN,zh;q=0.9" },
    redirect: "follow",
  });
  const buf = Buffer.from(await r.arrayBuffer());
  const head = buf.subarray(0, 5).toString("latin1");
  const isCaj = buf[0] === 0xc8 || (buf[0] === 0x48 && buf[1] === 0x4e);
  return {
    buf,
    isPdf: buf.length > 20000 && head.startsWith("%PDF"),   // 至少 4 字节，3 字节永远不等于 %PDF
    isCaj,
    verify: /\/bar\/verify\//.test(r.url || ""),
  };
}

async function fetchOne(detail, tries = 1) {
  let last = null;
  for (let i = 0; i < tries; i++) {
    await page.goto(detail, { timeout: 45000 });
    await page.waitForTimeout(1200);
    const g = await grab(detail);
    if (g.result === "no-link") return g;
    if (!g.verify) return g;
    last = g;
    if (i < tries - 1) await sleep(7000);
  }
  return last;
}

async function solveCaptcha(tag) {
  const meta = await page.evaluate(() => {
    const el = document.getElementById("captcha-element");
    if (!el) return { none: true, body: document.body.innerText.replace(/\s+/g, " ").slice(0, 120) };
    const r = el.getBoundingClientRect();
    const btn = [...el.querySelectorAll("div,span,a")].find((e) => (e.innerText || "").trim() === "确定");
    const br = btn?.getBoundingClientRect();
    return {
      rect: { x: r.left, y: r.top, width: r.width, height: r.height },
      btn: br ? { x: br.left + br.width / 2, y: br.top + br.height / 2 } : { x: r.left + r.width / 2, y: r.top + r.height * 0.8 },
      body: document.body.innerText.replace(/\s+/g, " ").slice(0, 80),
    };
  });
  if (meta.none) return { ok: false, why: "no-captcha", body: meta.body };
  const m = meta.body.match(/请依次点击[：:]\s*(.+?)\s*AI生成背景/) || meta.body.match(/请依次点击[：:]\s*(\S{3})/);
  const chars = m ? Array.from(m[1].replace(/\s+/g, "")).slice(0, 3) : [];
  if (chars.length !== 3) return { ok: false, why: "no-chars", body: meta.body };

  const shot = path.join(WORK, `cap-${tag}.png`);
  await page.screenshot({ path: shot, clip: meta.rect, scale: "css" });   // clip 是 CSS 像素，1:1
  let sol;
  try {
    const out = cp.execFileSync(PY, [CAPTCHA, shot, chars.join("")], { encoding: "utf8", timeout: 90000 });
    sol = JSON.parse(out.trim().split("\n").pop());
  } catch (e) {
    return { ok: false, why: "solver-err", err: String(e).slice(0, 200), chars };
  }
  if (sol.error) return { ok: false, why: sol.error, chars };

  await page.mouse.move(meta.rect.x + 30, meta.rect.y + meta.rect.height - 100).catch(() => {});
  for (let i = 0; i < sol.points.length; i++) {
    const tx = meta.rect.x + sol.points[i][0], ty = meta.rect.y + sol.points[i][1];
    await page.mouse.move(tx - 60, ty + 20, { steps: 7 }).catch(() => {});   // 无轨迹的离散点击会被判机器人
    await sleep(80);
    await page.mouse.move(tx, ty, { steps: 4 }).catch(() => {});
    await sleep(60);
    await page.mouse.click(tx, ty, { label: `点选 ${sol.chars[i]}` });
    await sleep(280);
  }
  await page.mouse.move(meta.btn.x, meta.btn.y - 12, { steps: 5 }).catch(() => {});
  await page.mouse.click(meta.btn.x, meta.btn.y, { label: "点确定" });
  await sleep(2600);
  const after = await page.evaluate(() => document.body.innerText.replace(/\s+/g, " ").slice(0, 80)).catch(() => "");
  const url = await page.url();
  return { ok: /verifySuccess/.test(url) || /验证完成/.test(after), why: after.slice(0, 40), chars, points: sol.points };
}

async function passGate(detail, tag) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    await page.goto(detail, { timeout: 45000 });
    await page.waitForTimeout(1200);
    const order = await page.evaluate(() =>
      document.querySelector("li.btn-dlpdf a")?.href || document.querySelector("li.btn-ywdlpdf a")?.href || null);
    if (!order) return { ok: false, why: "no-order" };
    // 验证码页只能带 referrer 进；普通 goto 会被判“来源应用不正常”
    await page.cdp("Page.navigate", { url: order, referrer: detail }).catch(() => {});
    await sleep(2200);
    if (/verifySuccess/.test(await page.url())) return { ok: true, attempt, via: "already" };
    const s = await solveCaptcha(`${tag}-${attempt}`);
    console.log(`  gate#${attempt}:`, JSON.stringify({ ok: s.ok, why: s.why, chars: s.chars, points: s.points }));
    if (s.ok) return { ok: true, attempt };
    await page.evaluate(() => document.querySelector('[class*="refresh"]')?.click());
    await sleep(2200);
  }
  return { ok: false, why: "gate-fail" };
}
