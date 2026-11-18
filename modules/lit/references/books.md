# 书籍：先认清这是另一条赛道

参考文献清单里书通常占很大比例（社科/人文尤其高）。**书不能用论文那一套渠道解决**：
Crossref 往往查不到 DOI，Unpaywall/OpenAlex 基本不给 pdf，出版社模板全部指向付费页。

判据不是"是不是书"，而是**有没有 DOI**：有 DOI 的（工作论文、政府报告、有 DOI 的专著章节）
论文链照样能拿；真正只能走书轮的是**没 DOI 的专著**。

## 一、合法路线（优先）

| 路线 | 说明 |
|---|---|
| 出版社 OA 教材 | Springer、MIT Press、OECD、World Bank、IMF 的部分书整本免费；Springer 用 `link.springer.com/content/pdf/{doi}.pdf` 常成功 |
| 作者主页 / 个人网站 | 教科书作者的课程页常有样章或全书 PDF |
| NBER 绝版文集 | 单章免费：`nber.org/system/files/chapters/{cXXXX}/{cXXXX}.pdf` |
| Open Library / Internet Archive 借阅 | 网络不通时不可达，换网络再试 |
| HathiTrust | 公版书可下载整本 PDF；受版权保护的书只能逐页看 |
| Project Gutenberg | 公版老书（Hume、Smith、Mill），**只有 epub/html/txt，没有 PDF**；`/cache/epub/{id}/pg{id}-images.pdf` 这条常见写法多数 404 |
| 馆际互借 / 学校 VPN | 付费墙前唯一稳的路 |

## 二、镜像路线（LibGen 家族）

链路：

```
https://libgen.gl/index.php?req={书名+作者}&topics[]=l&res=50
  → 解析表格，找 md5（32 位 hex）
  → https://libgen.gl/ads.php?md5={md5}
  → 页内正则 get\.php\?md5=[0-9a-f]{32}&key=[A-Z0-9]+
  → 下载，校验 %PDF-
```

注意：

- **`topics[]=l` 是成败分水岭。** 不带它，`index.php?req=` 返回的几乎全是期刊文章（scimag），
  搜一本专著会看到满屏同主题论文，看上去像"库里没有这本书"。带上之后才会出图书库结果。
  （`topics[]` 可选值见首页链接：`l`=图书、`a`=文章、`f`=fiction、`c`=comics、`m`=杂志、`s`=标准）
- **`search.php?req=` 是 404，只有 `index.php?req=` 有效**。
- 表格列序：title / author / publisher / year / language / pages / size / ext / mirrors。
  title 列常带 ISBN、文件名、`" href=` 碎片，先清洗再比（`books_libgen.py: clean_title`）。
- **匹配用"包含关系 + 长度折算"，不要直接给满分**：短书名常常是长书名的子串
  （"X" 是 "…: An Introduction to X" 的子串），直接判 1.0 会把不相干的书排到第一。
  前缀关系给高分，纯包含按长度比例折算。
- **同名书评会排在正书前面**（类型 `a`，几十 kB、页数为 0）。看 size 和 pages 能分辨。
- 同名书常有多个版本，挑 `pdf` 且页数匹配的；`epub`、`djvu` 要转换。
- **大文件会断**：几十 MB 的扫描书常 `ChunkedEncodingError`，重试或换 md5；`timeout` 给到 600s。
- 高频请求会被单独拉黑，表现为长期 503。节奏 3–6s，失败退避 6–14s。

## 三、Anna's Archive

- 域名轮换极快（`.org` `.se` `.li` `.gd` `.gs`）。
- 它自己不存文件，`/slow_download/` 与 `/fast_download/` 最终指向 LibGen / IPFS 等合作方——
  所以 LibGen 挂的时候它也跟着废。
- 官方博客会公告当前可用域；**用浏览器读，别用 curl**（页面是重度 JS）。
- 有第三方付费 API 和社区包，需 key，按量计费。

## 四、其它

| 站点 | 典型现象 | 备注 |
|---|---|---|
| `z-lib.*` / `zlibrary.*` / `1lib.*` / `singlelogin.re` | 000 / 503 | 需登录，域名常全灭 |
| `dokumen.pub` / `vdoc.pub` / `epdf.pub` | 000 / 403 | |
| `pdfdrive.com` | 首页 200，搜索空 | 结果页 JS 渲染 + 反爬 |
| `bdebooks` / `ebook3000` 之类 | 未测 | 质量参差，慎下 |

## 五、工程建议

书的处理**从论文流程里分出去单独跑**：

1. 划分看 `refs_final.json` 的 `kind`：`book` / `chapter` / `thesis` 归书轮，`article` 归论文轮。
   但 `kind` 来自 Crossref，`report`/`working paper` 也会被归成 `book`，别被字面骗了。
2. 书轮用独立脚本（`scripts/books_libgen.py`）、独立 state 文件、更慢的节奏（每本间隔 3–5s）。
3. 书轮的失败原因常是"整站故障"而不是"这条没有"，所以**允许整轮重跑**——
   这与论文轮"按原因跳过"的策略相反。
4. 交付时把书单独列一节，注明未完成原因，不要混进论文成功率。
5. **合并报告时成功优先**：书轮会为论文条目也写一条 failed，
   `dict.update()` 会让它盖掉论文轮的成功记录。

### 五½、书评陷阱

Sci-Hub 对书的章节、书的 DOI 基本无效，于是书会落到搜索/落地页，然后抓到的是**书评**：
`Book Reviews / 823  <被评书名>. By <作者>` —— 只有几页、合法 PDF、标题一模一样，
内容比对必然通过。识别靠标记词（见 `modules/lit/phases/phase-1-search.md` 校验第四件套）。

命中书评 = 这条书没拿到，回书轮重找。

### 五¾、章节怎么办

`chapter` 类条目（手册章节、文集章节）分三种情况：

| 情况 | 做法 |
|---|---|
| 作者主页 / 课程页有单章 PDF | `web_search` + `manual_add.py` |
| NBER 等开放文集章节 | 官方免费单章 PDF，路径从书页里取 |
| 只能拿到整本书 | 下整本书，报告里注明"页数为全书" |

拿不到的就写"书中章节，需整本书"，**不要用整本书冒充章节交付**。
