# 社会科学文献搜索策略

本文档涵盖学科特定期刊、布尔搜索构建、引文映射和文献管理方法。由 `lit module/SKILL.md` Phase 1 按需加载。

---

## 系统搜索协议（PRISMA 风格）

```
文献识别
  本地Zotero/Mendeley搜索         → N₁ 条
  CNKI中文搜索                     → N_cnki 条
  WebSearch多轮搜索                 → N₂ 条
  Annual Reviews / 手册            → N₃ 条
  引文链扩展                       → N₄ 条
  总计识别                         → N₁+N_cnki+N₂+N₃+N₄

筛选
  去重                             → N₅ 条去除
  标题/摘要筛选                     → N₆ 条排除（附理由）
  筛选后保留                       → N₇

合格性评估
  全文审读                         → N₈ 条排除（附理由）
  合格后保留                       → N₉

纳入
  最终纳入文献                     → N₁₀
  其中：基础经典                     → 数量
  其中：近5年                        → 数量
  其中：综述文章                     → 数量
```

---

## 学科搜索引擎优化

### 社会学期刊

**核心期刊**：American Sociological Review (ASR)、American Journal of Sociology (AJS)、Social Forces、Sociological Theory、Sociological Methods & Research、Annual Review of Sociology、Theory and Society

**搜索策略**：
1. 从 Annual Review of Sociology 文章开始——它们绘制了整个子领域的地图
2. 使用 Google Scholar "Cited by" 从经典论文向前追踪引文
3. 搜索 ASA 期刊群
4. 使用 JSTOR 获取 2000 年前的经典文献

**关键理论谱系（按子领域）**：
- 分层：Blau & Duncan (1967) → Sewell et al. (1969) → Jencks et al. (1972) → DiPrete & Eirich (2006)
- 网络：Granovetter (1973) → Burt (1992) → Lin (2001) → Centola (2010)
- 文化：Bourdieu (1984) → Lamont (1992) → DiMaggio (1982) → Vaisey (2009)
- 移民：Gordon (1964) → Alba & Nee (2003) → Massey et al. (1987)
- 种族/族群：Du Bois (1899) → Wilson (1978) → Bonilla-Silva (1997) → Ray (2019)

### 人口学期刊

**核心期刊**：Demography、Population and Development Review、Demographic Research、Population Studies、Journal of Marriage and Family

**人口数据库**：HMD（死亡率）、HFD（生育率）、IPUMS（普查微数据）、DHS（发展中国家）

### 语言学期刊

**核心期刊**：Language in Society、Journal of Sociolinguistics、Language、Annual Review of Linguistics、Applied Linguistics

**关键搜索词**：language ideologies + [群体]、code-switching + [人群]、linguistic assimilation / language shift、heritage language maintenance、sociolinguistic variation

### 计算社会科学期刊

**核心期刊**：Nature Human Behaviour、Nature Computational Science、PNAS、Science Advances、Journal of Computational Social Science、EPJ Data Science

搜索 arXiv (cs.SI, cs.CL, stat.AP) 获取预印本，关注引用经典计算社会科学论文（Lazer et al. 2009 Science; Watts 2007 Nature）的最新论文。

### 公共管理期刊

**核心期刊**：Journal of Public Administration Research and Theory (JPART)、Public Administration Review (PAR)、Governance、Public Administration、Journal of Public Policy、Public Management Review、Policy Studies Journal、American Review of Public Administration

**关键搜索词**：bureaucracy + performance、collaborative governance + [领域]、policy implementation + [国家/地区]、public service motivation、privatization + contracting out、representative bureaucracy + [群体]、performance management + gaming、coproduction + citizen

**搜索策略**：
1. JPART 和 PAR 是最权威的两本期刊，优先搜索
2. 政策过程理论集中在 Policy Studies Journal
3. 网络治理和协同治理在 Public Management Review 和 Governance 中更集中

### 心理学期刊

**核心期刊**：Annual Review of Psychology、Psychological Bulletin、Psychological Review、American Psychologist、Journal of Personality and Social Psychology (JPSP)、Psychological Science、Perspectives on Psychological Science、Health Psychology

**关键搜索词**：social identity + [群体]、cognitive dissonance + [行为]、self-determination theory + [领域]、self-efficacy + [行为]、dual process + judgment、attachment theory + [人群]、Big Five + [结果]

**搜索策略**：
1. Annual Review of Psychology 和 Psychological Bulletin 提供权威综述
2. JPSP 是社会心理学核心期刊
3. 行为改变研究在 Health Psychology 和 Psychology & Health 中集中
4. 跨文化心理学搜索 Journal of Cross-Cultural Psychology

### 传播学期刊

**核心期刊**：Journal of Communication、Communication Research、Human Communication Research、Communication Theory、Journal of Broadcasting & Electronic Media、Public Opinion Quarterly、Health Communication、Political Communication、New Media & Society

**关键搜索词**：agenda-setting + [议题]、framing + [议题]、cultivation + [媒介]、spiral of silence + [环境]、uses and gratifications + [平台]、narrative transportation + [行为]、selective exposure + [媒介]、knowledge gap + [群体]

**搜索策略**：
1. Journal of Communication 和 Communication Research 是顶级综合期刊
2. 媒介效果研究集中在以上两本期刊
3. 政治传播在 Political Communication 和 Public Opinion Quarterly
4. 健康传播在 Health Communication 和 Journal of Health Communication

### 经济学期刊

**核心期刊**：American Economic Review (AER)、Econometrica、Journal of Political Economy (JPE)、Quarterly Journal of Economics (QJE)、Review of Economic Studies (REStud)、Journal of Economic Literature (JEL)、Journal of Economic Perspectives (JEP)、Annual Review of Economics

**关键搜索词**：human capital + returns、discrimination + labor market、minimum wage + employment、prospect theory + decision、nudge + behavior、institutions + development、trade + inequality

**搜索策略**：
1. JEL 和 JEP 提供权威文献综述
2. 自然实验和因果推断在经济学期刊中广泛应用
3. 发展经济学集中在 Journal of Development Economics
4. 劳动经济学在 Journal of Labor Economics 和 ILRR

### 教育学期刊

**核心期刊**：Review of Educational Research、American Educational Research Journal、Educational Researcher、Journal of Educational Psychology、Sociology of Education、Comparative Education Review、British Journal of Educational Research、Computers & Education

**关键搜索词**：self-regulated learning + [人群]、achievement motivation + [学科]、teacher efficacy + [阶段]、Bourdieu + education + [国家]、online learning + outcomes、feedback + achievement、peer effects + classroom

**搜索策略**：
1. Review of Educational Research 提供权威元分析和综述
2. Journal of Educational Psychology 关注学习机制和干预
3. Sociology of Education 关注教育不平等和制度分析
4. Hattie 的 Visible Learning 元分析数据库可作为效应量参考基准

### 政治学期刊

**核心期刊**：American Political Science Review (APSR)、American Journal of Political Science (AJPS)、Journal of Politics (JOP)、British Journal of Political Science (BJPS)、Comparative Political Studies、International Organization (IO)、World Politics、Annual Review of Political Science

**关键搜索词**：democratization + [地区]、state capacity + [结果]、regime type + [政策]、voting behavior + [群体]、partisan polarization + [国家]、institutional design + [结果]、conflict + bargaining

**搜索策略**：
1. APSR、AJPS、JOP 是政治学三大顶刊
2. 比较政治集中在 Comparative Political Studies 和 World Politics
3. 国际关系在 International Organization 和 International Security
4. 政治方法论在 Political Analysis 中集中

### 中文核心期刊

**重点搜索**：中国社会科学、社会学研究、管理世界、社会、中国人口科学、经济研究、人口研究、中国农村经济、社会学评论、青年研究、公共管理学报、中国行政管理、心理学报、新闻与传播研究、教育研究、政治学研究

CNKI 正式检索默认且只默认专业检索页 `https://kns.cnki.net/starter/advanced`（跳转 kns8s 后切「专业检索」）。第一轮用单一主概念的宽松检索式；当结果过大时，先点「学术期刊N」筛选，再按被引排序（`li#CF`）取高影响文献。若筛选后 0 条，回退宽检索。

---

## 布尔搜索策略

**适用范围**：本节布尔串主要用于 WebSearch、Google Scholar、Semantic Scholar、期刊站内搜索等支持自然布尔表达式的来源。CNKI 不得把这些检索式原样粘贴到基本检索框；CNKI 正式检索必须先转换为高级检索概念组。

**基本结构**：
```
[主要概念] AND [理论视角 OR 机制] AND [人群 OR 情境]
```

**构建示例**：
```
"social capital" AND "labor market" AND (immigrants OR minorities)
"income inequality" AND (education OR "skill premium") AND "United States"
"社会资本" AND "劳动力市场" AND (流动 OR 分层)
"共同富裕" AND (收入分配 OR 城乡差距)
```

**同义词扩展**：
- inequality = stratification = disparity = gap = difference
- social capital = social networks = ties = connections
- mechanism = pathway = channel = mediator = process
- 不平等 = 差距 = 差异 = 分层
- 社会资本 = 社会网络 = 关系

### CNKI 高级检索转换

CNKI 的默认策略是“kns8s 专业检索 + 宽检索优先 + 概念组转换”，而不是把多个中文关键词放进基础检索框。

**默认入口**：CNKI 正式检索只默认 `https://kns.cnki.net/starter/advanced`（kns8s 专业检索）。基础检索框只允许单个自然短语、专名或站点可达性临时测试，不进入正式流程。

**落地前置**：CNKI 概念组只是检索计划；真正执行前必须先完成浏览器控制可用性检查。检查未通过时，不得把概念组转换为专业检索式执行，不得把 WebSearch/Scholar 或 agent 输出写成 CNKI 结果。

| Web/Scholar 布尔意图 | CNKI 转换 |
|---|---|
| `[主要概念] AND [机制] AND [人群]` | 先用 `[主要概念]` 在 `SU/TKA` 宽检索；结果过大且用户确认后，再追加机制或人群 |
| `[同义词1 OR 同义词2 OR 同义词3]` | 同一概念组，优先在高级检索中用 `OR`，不得拆成 `AND` |
| 多个空格分隔中文词 | 先拆概念组；不同概念分轮检索，同义/近义词用 `OR` |
| 0 条结果 | 记录 `zero_results`，回退上一轮宽检索，不继续追加限制，不按验证码处理 |
| 宽检索结果过长 | 若 `total > 200`，默认尝试 CSSCI → hx → CSSCI + hx 核心期刊筛选；每页显示尝试切到 50 条，失败只记录 `pageSizeState` |

示例：

```text
用户词：社会资本 劳动力市场 流动 分层
CNKI：先分别用“社会资本”“劳动力市场”做 SU/TKA 宽检索；“流动/分层”作为后续机制/结果概念组，必要时再筛。

用户词：不平等 差距 分层
CNKI：视为同一概念组，优先 OR 扩展。
```

**时间过滤**：
- 前沿：添加 `2022 OR 2023 OR 2024 OR 2025 OR 2026`
- 经典：使用 JSTOR，筛选 pre-2000
- Google Scholar 中使用 `after:YYYY`

---

## 引文映射

### 向前引文搜索（谁引用了X）
1. 在 Google Scholar 找到关键论文
2. 点击 "Cited by N"
3. 按年份筛选，按相关性排序

### 向后引文搜索（X引用了谁）
1. 阅读关键论文的参考文献列表
2. 识别基础经典著作
3. 找到那些论文并重复

### 共引分析
- 经常引用同一来源的论文共享学术谱系
- 密集引文簇 = 理论学派

### Semantic Scholar API（引文图遍历）

```bash
# 按 DOI 获取论文详情+引文
PAPER_DOI="10.1177/00031224211024294"
curl -s "https://api.semanticscholar.org/graph/v1/paper/DOI:$PAPER_DOI?fields=title,year,authors,citationCount,citations.title,citations.year,citations.authors,references.title,references.year" | python3 -m json.tool | head -100

# 按关键词搜索
QUERY="residential+segregation+health"
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=$QUERY&fields=title,year,authors,citationCount&limit=20&fieldsOfStudy=Sociology" | python3 -m json.tool
```

注意：Semantic Scholar API 有速率限制（100请求/5分钟，无API key）。谨慎用于定向扩展，不用于批量搜索。

### CrossRef API（DOI 元数据和被引次数）

```bash
# 按关键词搜索
QUERY="residential+segregation+health+disparities"
curl -s "https://api.crossref.org/works?query=$QUERY&rows=10&filter=type:journal-article&sort=relevance" | python3 -m json.tool | head -100

# 获取特定 DOI 的元数据
DOI="10.1177/00031224211024294"
curl -s "https://api.crossref.org/works/$DOI" | python3 -m json.tool
```

---

## 文献管理

### 论文清单模板

在整个综述过程中跟踪所有论文。此清单与文献矩阵只是分析辅助视图；论文身份、文件路径与处理状态一律以 `02-literature/paper-registry.csv` 为唯一事实来源，不得在本模板中手工维护第二份状态清单：

| # | 作者 | 年份 | 标题 | 期刊 | 方法 | 人群/数据 | 关键发现 | 来源 | 相关度(H/M/L) | 对应空白 |
|---|------|------|------|------|------|----------|----------|------|---------------|---------|

### 文献矩阵（深度分析用）

| 作者 | 年份 | 期刊 | 理论 | 结果变量 | 数据 | 方法 | 发现 | 局限 | 检验的机制 | 备注 |
|------|------|------|------|----------|------|------|------|------|-----------|------|

---

## exa MCP 检索协议（英文文献首选通道，2026-09-05 实测修订）

`web_search_exa` / `web_fetch_exa` 是英文文献检索的**主动首选**，不因 WebSearch 可用而跳过：

- **语义化查询**：exa 按页面语义而非关键词匹配，query 写成"理想文献描述"（如 `paper examining how government funding reshapes NGO autonomy in authoritarian China using resource dependence theory`），比布尔串命中更准；关键词布尔串留给 WebSearch。
- **分工**：exa 负责（1）发现核心英文文献与其 OA 全文页，（2）`web_fetch_exa` 批量抓取摘要页/出版页内容（一次调用可传多个 URL，`maxCharacters` 设 3000–5000 拿摘要足够）；WebSearch 负责（1）中文内容与新闻线索，（2）交叉验证 exa 结果的引用数与年份。
- **摘要铁律兼容**：exa fetch 返回的页面正文含摘要即视为【摘要已核】，来源记 `exa-fetch:<url>`。
- **失败回退**：exa 超时/空结果时降级 WebSearch，并在搜索日志记录 `exa=不可用`；不得假装已用 exa。
- 与 Step 9 衔接：exa fetch 抓到的 OA PDF 直链登记到 `paper-registry.csv` 对应条目的 `download_url`，再由 `download-plan` 子命令生成下载计划，走"外文 OA"下载路径。
