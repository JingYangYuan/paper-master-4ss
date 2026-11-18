# 渠道总表

分三类：**元数据**（给 DOI）、**开放获取**（给合法 PDF）、**镜像兜底**（给剩下的）。

状态列全部是本机实测（2026 年 10 月末，Windows + Clash TUN 全局代理，出口 IP 在境外）。**任何状态都可能在下个月失效**——开工先跑 `scripts/probe_channels.py`。

---

## 一、元数据 / 定位

| 渠道 | 端点 | 鉴权 | 实测 | 说明 |
|---|---|---|---|---|
| Crossref | `api.crossref.org/works?query.bibliographic=…&rows=3&mailto=…` | 无 | 200 | 217M 条；`alternative-id` 藏 Elsevier PII；无 DOI 的条目在这里查不到就是"记录不存在"，不是"付费墙" |
| OpenAlex | `api.openalex.org/works/doi:{doi}`、`?search={标题}` | 无 | 200 | 同时充当元数据与 OA 来源；`best_oa_location.pdf_url` 常是落地页 |
| DataCite | `api.datacite.org/dois/{doi}` | 无 | 未测 | 数据集、预印本、机构库的 DOI 归属 |
| Semantic Scholar | `api.semanticscholar.org/graph/v1/paper/DOI:{doi}?fields=title,openAccessPdf` | 无 | 200 / **搜索接口 429** | 按 DOI 查稳，按标题 search 极容易撞限流（退避 15–25s，最多 3 次） |
| Unpaywall | `api.unpaywall.org/v2/{doi}?email=…` | **email 必填** | 200 | 缺 email 返回 422。它现在跑在 OpenAlex 之上，`is_oa`/`oa_status` 与 OpenAlex 一致 |

DOI 只是"门票"：拿到 DOI 不等于能下，`is_oa=false` 时后面每条 OA 渠道都会白跑，先看这一位能省 80% 的请求。

---

## 二、开放获取

| 渠道 | 端点 | 实测 | 覆盖与坑 |
|---|---|---|---|
| Unpaywall | `best_oa_location.url_for_pdf` | 200 | 精度最高；`version=submittedVersion` 是**预印本**，引用页码只能取 `publishedVersion` |
| OpenAlex | `best_oa_location.pdf_url` / `locations[].pdf_url` | 200 | 比 Unpaywall 宽；`oa_status` 的 `bronze` 常给出版商页面的"免费但无授权"PDF |
| OpenAlex 全文 API | `content.openalex.org/works/{W....}.pdf` | **401** | 需要鉴权，匿名不可用。别照抄旧文档 |
| Europe PMC 搜索 | `www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:"{doi}"&format=json&resultType=core` | 200 | 拿 `pmcid` |
| Europe PMC 全文 | `www.ebi.ac.uk/europepmc/webservices/rest/{PMCID}/fullTextXML` | 200 | **可用**，返回 JATS XML（不是 PDF，正文齐全） |
| Europe PMC PDF | `europepmc.org/articles/{PMCID}?pdf=render` | **403** | 被 Cloudflare 挡，别用 |
| arXiv API | `export.arxiv.org/api/query?search_query=ti:"…"` | 200 | 标题必须完全一致才命中；改为逐词 `AND` + Jaccard ≥0.45 后召回率显著上升 |
| arXiv PDF | `arxiv.org/pdf/{id}` | 200 | 稳定；`10.48550/arXiv.*` 的 DOI 直接换 |
| NBER | `nber.org/system/files/working_papers/{w}/{w}.pdf` | 200 | DOI 形如 `10.3386/w24963`。**文件不存在时也返回 200 + 3 KB HTML**，必须验魔数 |
| CORE | `api.core.ac.uk/v3/search/works` | 需 Bearer key（免费注册） | 37M 全文，绿色 OA 与学位论文的最佳补充；配额 `search` 1 次/10s、单条 5 次/10s |
| DOAJ | `doaj.org/api/search/articles/{query}` | 未测 | 纯 OA 期刊目录，gold OA 命中率高 |
| OpenAIRE（老接口） | `api.openaire.eu/search/publications?doi={doi}&format=json` | **200，可用** | 返回 30–40KB 富元数据。**90% 的 URL 是作者机构首页**（`www.bnu.edu.cn`、`www.utexas.edu`、`www.russianlawjournal.org/jour/about/...`），不是全文链。拿它做文献发现可以，做下载主力不行 |
| OpenAIRE（graph v1） | `api.openaire.eu/graph/v1/researchProducts?doi={doi}` | **400** | 参数名不是 `doi` 而是 `pid`。报 `"Unknown parameter: doi"` 时别以为是接口挂了 |
| bioRxiv/medRxiv | `api.biorxiv.org/details/biorxiv/{doi}` | 未测 | 生物医学预印本 |
| SSRN | `papers.ssrn.com` | **curl 403** | 需浏览器；`Delivery.cfm` 直链也无 cookie 不可用 |
| RePEc/IDEAS | `ideas.repec.org` | 首页 200，`cgi-bin/htsearch` 无结果 | 经济学工作论文索引，实际下载链在 `econpapers.repec.org`（**本机 000**） |
| Zenodo / OSF / Figshare | 各自 API | 未测 | 数据集与预印本 |
| Semantic Scholar OA | `openAccessPdf.url` | 200 | 常指回 PMC 或机构库 |

**没有任何单点能覆盖全部。** 无 key、纯 OA 的实测天花板是 ~2/3（本机 258 条里 OA 只解决 52 条，因为清单里大量是被引经济学论文，绿色 OA 很少）。

---

## 三、出版社直链

见 `references/publishers.md`。一句话：模板都对，**没有机构订阅时几乎全部 403**，只有 gold/hybrid OA 的那部分能白拿。

---

## 四、镜像兜底（Sci-Hub）

| 域名 | 实测 | 备注 |
|---|---|---|
| `sci-hub.ren` | 200 | Cloudflare Turnstile，真浏览器自动过；过完后 cookie 可复用 |
| `sci-hub.ee` | 200 | 同一套后端 |
| `sci-hub.usualwant.com` | 200 | 同一套后端 |
| `sci-hub.se` | DNS 失败（ERR_NAME_NOT_RESOLVED） | |
| `sci-hub.st` | 超时 | |
| `sci-hub.ru` | DDoS-Guard 挑战页 | |
| `sci-hub.box` / `.mksa.top` | 403 | |
| `sci-hub.wf` | 200 但只有"Checking your browser" | 假活 |
| `sci-hub.do` / `.hk` / `.shop` / `.us` | 停放广告页 / 导航页 | 全部是假的 |

PDF 实际落在 `sci.bban.top` CDN，路径形如：

```
https://sci.bban.top/pdf/{DOI，将 / 替换为 %252F}.pdf
```

- `%252F`（双编码）✅ 200
- `%2F`（单编码）❌ 404
- 原样 `/` ❌ 404
- `pdf.bban.top/{doi}.pdf`（缺 `/pdf/` 段）❌ 404
- 偶发 429 + `text/plain` 17 字节 `error`，退避 12s 重试

**可靠做法**：不拼 URL，直接正则取页面里的 `<embed src="…">`：

```python
m = re.search(r'<embed[^>]+src="([^"]+\.pdf[^"]*)"', html)
url = m.group(1).split("#")[0]
```

覆盖缺口是结构性的：80 年代–90 年代的老 JPE/AER/ECMA 论文、以及 2022 年后的新文大量不在库。页面出现 `mutual aid` **不能**当“这条没有”的判据。必须先找 embed。

**入库停更年份要现查，不要写死。** 本机 2026 秋实测停在 2021，当年可当参考，不当常量。本机 86 条实测：镜像成功 9 条，年份分别是 2013–2021；2022–2026 的 15 条全部 `not-in-stash`。拿到清单先看年份分布，新文多就不要在镜像上耗时间。

一个值得单记的边界案例：Sci-Hub 有全文但**不是 PDF**。Zenodo 记录里 `files[].key` 可能是 `.docx`（本机 id10 就是只有一个阿拉伯语名的 Word），结构校验会判 `not-pdf` 直接丢弃。看到 `not-pdf` 先看一眼魔数前几个字节，`PK\x03\x04` 是 zip/docx，`{"` 是 JSON，别一律当垃圾。

---

## 四½、搜索源（2026-10 末实测）

搜索引擎只能“发现地址”，不能“绕过权限”。分清客户端：

| 源 | requests | 真 Chromium + 系统代理 | 结论 |
|---|---|---|---|
| `www.google.com/search` | 94 KB 的 `enablejs` 页，`href` 只有 `/httpservice/retry/enablejs`；`gbv=1`、`udm=14` 同样无外链 | **可用**，15/15 条查询返回 18–27 个真实链接，无 CAPTCHA | 要 Google 就只能走浏览器 |
| `web_search`（Exa 后端） | 可用（宿主内的独立工具） | — | **首选**；会直接给机构库直链 |
| `google_search`（宿主内置） | 恒报 `Please enable tool_config.include_server_side_tool_invocations` | 同 | 不可用，见 `modules/lit/phases/phase-1-search.md` 铁律 9 |
| `www.bing.com/search` | HTML 里的 `&amp;u=a1...` 反解后是无关结果（如 “Nereida”）；`format=rss` 回到旅行广告 | 丢弃查询词 | 出口 IP 下被投毒，弃 |
| `html.duckduckgo.com` | 202 空壳，0 个外链 | — | 弃 |

搜索真正能用的场景只有一类：**OA 元数据没覆盖的机构库副本**。实测 41 条里，前四轮（Unpaywall 全量位置 + OpenAlex + Europe PMC + arXiv + 落地页）判定“无 OA 副本”的 #13，最后在 `publicatt.unicatt.it`（米兰圣心 IRIS/CINECA）找到 CC BY-NC-ND 正版。该库对 requests 403，需走 `references/browser.md` 七的 CDP 取字节。

搜索也顺手能当事实校验用：它直接告诉你 “Sci-Hub reports it as unavailable / `pdf_url_not_indexed`”（#2 就是这样），省掉一轮 Visitsci-Hub。

---

## 五、实测不可用（别再试）

| 站点 | 现象 |
|---|---|
| `scholar.google.com` | 200，但正文是「Sorry… your computer or network may be sending automated queries」 |
| `scholar.archive.org/search` | 「Rate limit reached」 |
| `cronfa.swan.ac.uk` | CONNECT 200 后 TLS 卡死（直连与代理一样）；Wayback 的 `.../Download/63585__...pdf` 快照回放也超时 |
| `diva-portal.org` / `hig.diva-portal.org` / `urn.kb.se` | 三个域全 ReadTimeout；`web.archive.org` 上的 `FULLTEXT01.pdf` 快照也 502 |
| `journals.openedition.org` | 200 但内容是 1585 B 的 `Anubis — Access Denied: error code bf584155dcd667f7`（出口 IP 被列黑，不是 PoW 挑战） |
| `papers.ssrn.com`（含 `Delivery.cfm/*.pdf`） | 403；真浏览器 + 代理同样 403，CDP 也取不到字节 |
| `publicatt.unicatt.it` / IRIS 系 `*/retrieve/*` | requests 与页内 fetch 全 403，**但 `page.goto` 后 CDP `Page.getResourceContent` 能拿到 655 KB 正版 PDF**（见 `browser.md` 七） |
| `scispace.com/pdf/*` | 405，页内被 `awswaf.com` 换成 captcha；真浏览器也一样 |
| `www.emerald.com/*/article-pdf/...` | 403（索引里有路径不代表能下，对爬虫放行、对读者收费） |
| `onlinelibrary.wiley.com/doi/pdfdirect/...` | 403；页内 fetch 被 CSP 拦（`Failed to fetch`） |
| `www.bing.com/search` | 真实浏览器里也**丢弃查询词**，`"长标题" filetype:pdf` 只返回 "machine" 的词典结果 |
| `html.duckduckgo.com` | 直连 ConnectTimeout；有代理时 202 空壳页、0 个外链 |
| `web.archive.org` / `archive.org` | 000（不可达） |
| `annas-archive.org/.se/.li/.gd/.gs` | 首页 200 但所有路径返回同一个 ~92 KB 空壳页；`.li` 浏览器连接超时 |
| `libgen.{gl,li,bz,la,is,st,rs,gs,fun,pm,vg}` | 整族 503（2026-10 末整站故障，非本地限流），32 页 PDF 的单本链路此前验证有效 |
| `z-lib.io` / `z-lib.gd` / `zlibrary.to` / `1lib.sk` / `singlelogin.re` | 000 / 503 |
| `dokumen.pub` / `vdoc.pub` / `epdf.pub` / `openlibrary.org` | 000 / 403 |
| `econpapers.repec.org` | 000 |
| `api.fatcat.wiki` | 000 |
| `search.fatcat.wiki/fatcat_release/_search` | **挂死**：跑了 1200 秒无任何响应，不是 403 也不是超时，是连接后不返回。别把它放进主流程 |
| `www.pdfdrive.com` | 首页 200，搜索结果为空（JS 渲染 + 反爬） |
| `researchgate.net` | Cloudflare 403 |

出版商侧被 403 的：`sciencedirect`、`academic.oup.com`、`onlinelibrary.wiley.com`、`tandfonline.com`、`journals.uchicago.edu`、`pubsonline.informs.org`、`science.org`、`annualreviews.org`、`journals.sagepub.com`、`pnas.org`、`worldscientific.com`、`www.aeaweb.org`（`/articles/pdf/doi/…` 返回 HTML 假 PDF）、`cepr.org`、`imf.org`。

---

## 六、动态镜像清单
别硬编码。以下这类页面维护着当日可用的域名（用浏览器打开，不要 curl 它们的 API）：

- `open-slum.pages.dev`（LibGen / Z-Library / Anna's Archive 当日镜像）
- 各镜像自身首页的公告位

判断"真活"的标准只有一条：**能取到 `%PDF-` 开头的字节**。首页 200、标题 200、`Content-Type: application/pdf` 都不算。

## 七、四条容易误判的假信号

1. **同一字节数出现在多个不相关站点上**：这是本地代理/TUN 返回的统一拦截页，不是站点内容。`probe_channels.py` 会把它标成"假PDF"并提示重复字节数。
   - **5620–5811 字节 ⇔ Cloudflare 挑战页**。本机实测 `tandfonline.com` 5620、`academic.oup.com` 5693、`dl.acm.org` 5706、`ilo.org` 5626、`pub.norden.org` 5782、`fulcrum.org` 5687、`russianlawjournal.org` 5620、`doaj.org` 5743——全部同一张页。看到这个尺寸段，**别再费劲解析内容**，直接判“机房 IP 被 CF 拦”。
   - **1310 字节 ⇔ DSpace 7 前端空壳**（`rio.upo.es/bitstreams/{uuid}/download` 这类），要 JS 才渲染，单靠 requests 拿不到。
   - **`503` + 正文含 `en mantenimiento` / `under maintenance`**：站点自身维护，不是拦你。等半小时或换镜像。
2. **SSLError / ReadTimeout**：本机链路抖动频繁，同一域名一分钟前 200、一分钟后 ERR 是常态。**探活两遍再下结论**，别因为一次超时就把渠道删了。
3. **搜索引擎给的 PDF 假货率可以到 100%**。本机用 Bing 的 `u=a1<base64>` 解码取链接，6 个“命中”全是垃圾：三篇文献指向同一张哥伦比亚地址簿、一篇指向新加坡组屋指南、两篇指向同一份教材章节。而 `html.duckduckgo.com` 返 **202**（挑战页，不是超时），`scholar.google` 返 200 但正文是验证页。搜索引擎只能做“最后一搏”，且接到 PDF 后必须过内容比对。
4. **机构代理的通配子域可能被 DNS 劫持**：`https://<host>.login.<school>.idm.oclc.org/` 报 `NET::ERR_CERT_COMMON_NAME_INVALID` 而根域 `login.<school>.idm.oclc.org` 正常 302，说明这类子域在本机被污染。真正的机构权限往往根本没生效，页面上那些"I have access via: XXX University"多半是出版社根据别的信号显示的。
