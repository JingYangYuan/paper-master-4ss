# 出版社直链模板

模板本身是确定的，**能不能下取决于你对该刊有没有订阅权**。没有权限时它们几乎一律 403，或者 200 但返回一页 HTML 登录墙。

## 一、通用两招（优先于模板）

### 1. `citation_pdf_url` 元标签

任何文章落地页（`https://doi.org/{doi}` 跳过去之后）都可能带：

```html
<meta name="citation_pdf_url" content="https://…/article.pdf">
```

抓到就是官方 PDF 地址，比猜模板可靠。AACR、部分 OUP、部分 Springer 都靠这个。

### 2. 阅读器路径 → PDF 路径

把 URL 里的 `/doi/reader/`、`/doi/epdf/`、`/doi/epub/`、`/doi/full/` 换成 `/doi/pdf/`。在 ACM、ACS、CUP、IEEE、JSTOR、Nature、OUP、PLOS、PNAS、Royal Society、Sage、Science、Springer、T&F、Wiley 上普遍成立。

机构代理（EZproxy）的 URL 形态各异，无法通用改写——**别试图猜**。

## 二、按 DOI 前缀分流

| 前缀 | 出版社 | 模板 |
|---|---|---|
| 10.1038 | Nature | `https://www.nature.com/articles/{doi 去掉 10.1038/}.pdf` |
| 10.1126 | Science | `https://www.science.org/doi/pdf/{doi}` |
| 10.1002 / 10.1111 | Wiley | `https://onlinelibrary.wiley.com/doi/pdfdirect/{doi}?download=true` |
| 10.1007 | Springer | `https://link.springer.com/content/pdf/{doi}.pdf` |
| 10.1016 | Elsevier | `https://www.sciencedirect.com/science/article/pii/{PII}/pdfft` |
| 10.1021 | ACS | `https://pubs.acs.org/doi/pdf/{doi}` |
| 10.1073 | PNAS | `https://www.pnas.org/doi/pdf/{doi}` |
| 10.1056 | NEJM | `https://www.nejm.org/doi/pdf/{doi}` |
| 10.1177 | Sage | `https://journals.sagepub.com/doi/pdf/{doi}` |
| 10.1080 | Taylor & Francis | `https://www.tandfonline.com/doi/pdf/{doi}` |
| 10.1093 | OUP | 落地页取 `citation_pdf_url` |
| 10.1086 | UChicago | 落地页取 `citation_pdf_url` |
| 10.1257 | AEA | **无直链**：`/articles/pdf/doi/{doi}` 返回 HTML |
| 10.3386 | NBER | `https://www.nber.org/system/files/working_papers/{w}/{w}.pdf`，`w` = DOI 中 `w` 之后 |
| 10.48550 | arXiv | `https://arxiv.org/pdf/{arXiv id}` |

### Elsevier 的 PII 从哪来

PII 形如 `S0304405X18301326`（`S` 开头，≥16 位），**不能从 DOI 推**。两个来源：

1. Crossref 记录里的 `alternative-id`；
2. 落地页 URL 里的 `pii/` 段。

拿到 PII 也不等于能下：ScienceDirect 对两类客户端一律 403——带 cookie 的普通 HTTP 请求，以及 `navigator.webdriver` 为真的自动化浏览器。真浏览器 + 真实登录态是唯一路径。

## 三、浏览器里下的注意事项

- **带 cookie 同源请求**：Wiley 的 `pdfdirect` 在 `credentials: 'include'` 下可下，但一次 evaluate 批 6–8 篇就到底，要分批。
- **文本兜底**：Elsevier 的 PDF 抓不到时，从 `document.body.innerText` 取正文往往还能拿到全文（图表会丢）。
- **别用无头特征**：`page.evaluate` 里 `navigator.webdriver` 必须为 false，否则 ScienceDirect 直接拦。

## 四、判断"这条到底有没有可能"

按 `oa_status` 分流，省掉盲目请求：

| oa_status | 含义 | 期望 |
|---|---|---|
| `gold` | 期刊本身 OA | 模板直接用 |
| `hybrid` | 订阅刊里单篇开放 | 模板可用 |
| `green` | 有机构库/预印本副本 | 走 OpenAlex `locations` 或 CORE |
| `bronze` | 出版商页面免费但无开放授权 | 模板试试，可能 200 |
| `closed` | 真付费墙 | 没订阅就只能馆际互借/向作者索要 |

`closed` 且镜像也没收录的，直接标记放弃，别反复重试——这类条目通常占清单的 10–15%，是硬性缺口。
