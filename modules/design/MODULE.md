---
name: paper-design-4ss
description: 社会科学论文设计路由系统。保留 FRAME、STORM、DESIGN、FULL 的拆分版操作流程；模式确认后强制确认研究取向，并在原流程内支持实证、概念/解释理论、规范理论、思想史/文本阐释与混合设计。
capabilities: read_file, run_shell, write_file, web_search, web_fetch, spawn_agent, search_text, ask_user
---

# Paper Design 4SS：社会科学论文设计路由系统

> 参数提示：[frame|storm|design|full] [研究主题/关键词] [可选: 学科领域, 目标期刊, 数据来源] — 例如 `storm 数字平台劳动治理` 或 `design 教育不平等 社会学 ASR`

本模块负责将初步研究兴趣转化为可往下推进的研究设计方案（理论锚点、研究问题、论证路径、材料要求与方法可行性评估）。模块内置 14 个学科与领域的理论框架库及《当代中国》章节级框架，按任务需求将研究主题路由至对应框架库并交由各操作阶段执行。

## 研究者主导权覆盖规则

执行前先读取 `references/researcher-agency-overlay.md`（研究者主导权覆盖规则），再读取总控包根目录的 `references/runtime-adapter.md` 与 `references/agent-software-adapters.md`。

当本文件默认流程与覆盖规则冲突时，以覆盖规则为准。未经研究者明确同意，不得自动连续推进多个阶段、自动派发顾问、自动启动并行复核，或擅自执行外部检索、脚本运行、文件导出与变更项目状态的写入操作；此类动作前须先列出方案、风险与证据缺口。

## 路径约定

本文件中的相对路径默认相对于本模块根目录解析（独立导出包中即为包根目录）；在总控包中引用跨模块或总控协议时，使用 `master/...`、`references/...`、`modules/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md`。本模块所有报告、顾问意见、综合文件与最终回复均使用中文 Markdown；理论机制、研究设计流程、跨学科理论嫁接、阶段门控与顾问派活链路须附 Mermaid 图及 2–4 条中文解释。

## 零、顾问派发原则

依据当前步骤的概念冲突、材料与方法可行性、领域定位、规范原则、文本语境、期刊限制、反例或交接风险，选派最少必要顾问，不得仅因研究取向或模式标签套用固定名单。每次派发须在 `agent-brief.md` 中写明待决问题、选派角色、预期产出及未选派其他角色的原因。

| 待解决的决策风险 | 对应顾问文件 |
|---|---|
| 理论框架定位不清、机制链条断裂或理论贡献不明确 | `agents/theory-consultant.md` |
| 题目可检验性、概念操作化、因果识别路径或资料可得性存疑 | `agents/method-consultant.md` |
| 领域定位不明、贡献可见度不足或期刊/论文类型适配风险 | `agents/positioning-consultant.md` |
| 排查致命缺陷、最强反例与不可执行环节（持有阶段放行阻断权） | `agents/critical-review-consultant.md` |

执行时以 `references/agent-registry.md` 中的标准名为准，主流程负责将顾问意见综合为理论锚点、研究问题、设计蓝图与交付前检查结论。

顾问意见写入 `paper-workspace/_logs/agents/design-[YYYY-MM-DD]/`，并生成 `agent-synthesis-design-[YYYY-MM-DD].md`。运行环境不支持并行时按上表顺序复核并记录 `sequential-review`。派发前须按 `agents/_reference-base.md` B3 注入 B1 切片与附加参考内容，顾问意见开头须回填 `参考库回查:`（`base=design-2026.10.24` + `tier` + 判据条目号 + 缺口），注入方式见文末附录。

## 零之二、范式专属复核清单

以下四项为模块内置专项复核清单，不单独占用顾问编号。需要专项复核时，由主流程按本节逐项自检，或按 T2 增派一次 `paper-design-critical-review-consultant` 并将对应条目号写入判据行。

### 概念（C11）

适用：概念重构、理论整合类选题。核查核心概念是否自洽、可区分、能否处理边界案例，以及所提新概念是否真正提升解释或规范能力。判据来源：`references/argument-standards.md` §概念分析。输出：判断结论、概念冲突、边界案例、需修订定义、可保留贡献与风险。

### 规范（C12）

适用：价值标准、原则冲突、制度正当性类选题。核查事实/价值/可行性前提是否区分、竞争原则是否得到公平对待、反例与代价是否改变结论适用范围。判据来源：`references/argument-standards.md` §规范论证、§反驳策略。输出：判断结论、隐含前提、最强反例、回应建议、需保留代价与风险。

### 阐释（C13）

适用：思想史、文本阐释类选题。核查文本版本、历史语境、解释单位、时代错置风险与竞争诠释是否得到处理。判据来源：`references/argument-standards.md` §思想史与文本阐释方法、§理论谱系与竞争框架。输出：判断结论、语境缺口、竞争诠释、不可推广边界与补证建议。

### 论证压力测试（Toulmin 四问）

适用：任意取向的核心主张压力测试。逐项回答：担保（warrant）为何成立？限定语（qualifier）适用范围是什么？最强异议是什么及如何回应？缺失何种支撑（backing）？判据来源：`references/argument-standards.md` §Toulmin 论证框架、§反驳策略。输出：论证强度、断裂点、最强反驳、可接受限定、阻断项与修订顺序。

---

## 第一层：问询用户层

### 1.1 解析用户输入

从 `$ARGUMENTS` 提取以下字段：

| 字段 | 提取规则 | 默认值 |
|---|---|---|
| **模式** | 匹配 `frame` / `storm` / `design` / `full` | 须询问确认 |
| **研究主题** | 去除模式关键词后的主体文本 | 必填；缺失则进入 1.2 |
| **学科领域** | `社会学` / `公共管理` / `心理学` / `传播学` / `经济学` / `教育学` / `政治学` / `哲学` / `马克思主义` / `法学` / `新时代思想` / `党史党建` / `国际政治` | 自动推断后确认 |
| **目标期刊** | 如 ASR / AJS / Demography / NHB / 管理世界 / 社会学研究 | 无 |
| **数据来源** | 如 CFPS / CGSS / CHARLS / CHFS / 自采数据 / 无 | 无 |
| **特殊约束** | 方法偏好、样本限制、时间线等 | 无 |

### 1.2 信息完整性检查（使用 `ask_user`）

提问格式统一遵守 `references/user-question-examples.md`。

**Step 1 — 必填询问（研究主题缺失时）**

```text
question: "请提供你的研究主题或感兴趣的研究方向。"
header: "研究主题"
options: []
```

**Step 2 — 学科推断确认（学科未指定时）**

先依据主题关键词做初步学科推断，再向用户确认：

```text
question: "根据研究主题初步推断学科领域为 [{推断学科}]，是否确认或补充第二学科视角？"
header: "学科确认"
options: [
  {label: "确认，只用 {推断学科}", description: "仅加载该学科理论框架库"},
  {label: "加入第二学科", description: "开展多学科交叉扫描"},
  {label: "手动指定学科", description: "由用户直接指定目标学科"}
]
```

**Step 3 — 可选约束追问（非阻断）**

目标期刊、数据来源或方法偏好缺失时，可在同一轮合并追问以提升设计精度：

```text
question: "是否有目标期刊、可用数据来源或研究方法偏好？"
header: "设计约束"
options: [
  {label: "补充约束", description: "由用户提供目标期刊、数据来源或方法偏好后再设计"},
  {label: "暂不指定", description: "先按主题和学科默认路径推进，后续可再调整"},
  {label: "不确定，请推荐", description: "依据研究主题推荐匹配的期刊、数据与方法组合"}
]
```

### 1.3 工作模式确认（强制前置）

进入任何阶段操作前，须通过 `ask_user` 确认模式为 `FRAME`、`STORM`、`DESIGN` 或 `FULL`。即使用户输入包含模式词，仍须将推断模式列为首位推荐项请用户确认；确认后将 `mode-lock` 写入过程日志。未完成模式确认前，不得读取 `phases/` 文件或输出设计结论。

```text
question: "当前需要进入哪个研究设计模式？"
header: "选择模式"
options: [
  {label: "FRAME — 理论锚定", description: "定位单学科理论框架，识别理论空白与问题方向"},
  {label: "STORM — 跨学科选题", description: "开展多学科头脑风暴与理论嫁接，筛选 Top 10 研究问题"},
  {label: "DESIGN — 研究设计蓝图", description: "从既定理论锚点出发，生成可执行的研究设计方案"},
  {label: "FULL — 全流程", description: "按 FRAME -> STORM -> DESIGN 顺序完成全套设计"}
]
```

确认后严格按对应 `phases/` 执行。`FULL` 须按 `FRAME -> STORM -> DESIGN` 顺序推进；选择 `DESIGN` 但缺少理论锚点或候选研究问题时，须先询问用户是否补跑 `FRAME` / `STORM`，不得无依据直接生成蓝图。

### 1.4 研究取向确认（强制）

模式确认后、读取任何 `phases/` 文件前，须确认研究取向。取向仅决定阶段内启用的论证与方法核查条目，不改变四模式路由，也不固定顾问名单。

```text
question: "本研究主要以哪种研究取向展开？"
header: "研究取向"
options: [
  {label: "实证研究", description: "以定量数据、案例或经验材料检验关系或机制"},
  {label: "概念/解释理论", description: "以概念重构、理论整合或解释框架形成贡献"},
  {label: "规范理论", description: "以价值标准、原则冲突与制度正当性完成论证"},
  {label: "思想史/文本阐释", description: "以文本版本、历史语境、谱系或竞争诠释形成解释"},
  {label: "理论—经验混合", description: "同时明确理论部分与经验部分各自的论证问题及互证方式"},
  {label: "尚未确定", description: "仅对比备选取向与所需材料，暂不生成正式设计"}
]
```

选择混合取向时须追问主路径、次路径与互证方式；选择「尚未确定」时仅输出候选取向对比、材料门槛与待决问题。须将 `research_orientation`、`analysis_required` 与混合关系写入过程日志及最终 `design-report` / `full-report`。

---

## 第二层：质量门槛与输出约束

### 2.1 四层交付检查

所有产出须通过 `phases/05-quality-gates.md` 定义的检查门槛：

| 层级 | 核查内容 | 阻断条件 |
|---|---|---|
| **L0 路由** | 学科匹配准确，模式与研究取向均已锁定 | 未完成确认时仅做澄清，不得输出设计 |
| **L1 FRAME** | 理论定位充分，空白识别有据 | 候选理论少于 3 个时扩大检索或切换学科 |
| **L2 STORM** | 跨学科扫描覆盖充分，已剔除 FATAL FLAW | 未覆盖至少 2 个学科或未清理致命缺陷时须补充修正 |
| **L3 DESIGN** | 理论—方法对齐，稳健性与反驳回应充分 | 存在「不通过」项时须修正并重检 |
| **L4 整体** | 实质内容完整、逻辑自洽、可操作 | 任一项不达标则返回修正 |

### 2.2 输出路径与命名

遵守 `master/output-protocol.md`（中文 Markdown，关键链路附 Mermaid 图）：

```text
paper-workspace/01-design/
├── frame-report-[discipline]-[slug]-[YYYY-MM-DD].md
├── storm-report-[slug]-[YYYY-MM-DD].md
├── design-report-[slug]-[YYYY-MM-DD].md
└── full-report-[slug]-[YYYY-MM-DD].md

paper-workspace/_logs/
└── process-log-design-[YYYY-MM-DD].md
```

### 2.3 边界约束

**强制要求**：
- 理论嫁接须给出实质机制链条，禁止仅作表面类比（如「A 类似于 B」）；
- 实证取向研究问题须具备可操作性；概念、规范与阐释取向核心论题须具可争辩性、材料可追溯性并能回应强反例或竞争诠释；
- 学科路由去重后最多保留 3 个学科并按相关度排序；
- 跨学科扫描至少覆盖 2 个学科；
- 存在 FATAL FLAW 的研究问题须移出 Top 10。

**职责边界**：
- 本模块仅输出理论定位、选题与研究设计蓝图，不撰写论文正文，也不执行具体数据分析脚本。
- 具体阶段操作细节由 `phases/` 文件承载。

### 2.4 目录初始化

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace}"
mkdir -p "${OUTPUT_ROOT}/01-design" "${OUTPUT_ROOT}/_logs"
```

---

## 第三层：路由与框架检索

### 3.0 关键词发散与框架库全库检索

完成模式与主题确认后，先通过 `web_search` 发散学术关键词（缺失联网搜索能力时按 `references/runtime-adapter.md` 记录能力缺失并请用户提供关键词），再调用 `frame_locator.py` 在全部框架文件中检索排序。不得跳过关键词发散而直接用口语题目匹配框架。

#### Step 3.0a：联网检索关键词发散

围绕研究主题执行至少 2 次不同角度的联网检索：
- **学术概念视角**：`"[研究主题] 理论框架 社会学 概念"`
- **跨学科视角**：`"[研究主题] 跨学科 研究 综述"`
- **方法视角（可选）**：`"[研究主题] 实证研究 方法 因果"`

从检索结果提炼 5–10 个候选词并筛选为 **3–8 个核心检索关键词**（优先学术概念词、覆盖 ≥2 个学科视角、包含机制或方法线索词、以空格分隔、不直接照搬完整题目）。每次搜索的检索式、候选词与最终筛选结果须写入过程日志。

#### Step 3.0b：调用 `frame_locator.py` 检索框架库

```bash
python3 scripts/frame_locator.py --topic "[研究主题]" --keywords "[发散得到的关键词，空格分隔]"
```

检索策略：
1. **首轮全库扫描**：默认不加 `--discipline`；若命中候选 ≥ 3 个且最高分 ≥ 10，可直接按 `read_ranges` 读取。
2. **命中不足时**（候选 < 3 或最高分 < 10）：扩展同义词、英文对应词或机制词重新检索。
3. **命中过多时**（候选 > 10 个文件）：追加 `--discipline "[学科key或中文名]"` 过滤，并在过程日志记录被排除学科及原因。
4. **内容读取**：主流程须依据返回的 `read_ranges` 读取对应行号区间内容后，再注入顾问 prompt。

脚本输出结果（发散关键词、候选框架、得分、命中词及 `read_ranges`）须写入过程日志或报告「路由依据」部分。

### 3.1 框架阅读与学科冗余参考

```text
研究主题 -> web_search 发散 3–8 个关键词 -> frame_locator.py 全库排序 -> 确定 Top 1–3 学科 -> 按 read_ranges 读取片段 -> 注入顾问 prompt -> 顾问复核
```

按行号区间读取框架文件片段示例：

```bash
sed -n '[start],[end]p' frame/theory-frameworks-[discipline].md
```

仅当指定行号区间不足以判断理论边界或竞争理论时再扩展阅读相邻段落；不得未先执行检索即通篇读取全库文件。

**学科重叠参考**：
- 高度重叠（通常选其一）：公共管理—政治学（65%）、哲学—政治学（70%）、马克思主义—经济学（60%）、法学—政治学（65%）、新时代思想—政治学（65%）、党史党建—政治学（65%）、国际政治—政治学（70%）。
- 互补或常用组合：社会学—经济学（20%）、国际政治—社会学（25%）、国际政治—传播学（35%）、心理学—哲学（40%）、国际政治—经济学（40%）、社会学—马克思主义（45%）、法学—哲学（45%）、国际政治—法学（45%）、马克思主义—法学（50%）、新时代思想—公共管理（50%）、新时代思想—马克思主义（70%）、党史党建—马克思主义（70%）、党史党建—新时代思想（75%）。

### 3.2 十五个框架库索引

| 学科 / 领域 | 框架文件 | 条目规模 |
|---|---|---|
| 社会学 | `frame/theory-frameworks-sociological.md` | 52 |
| 公共管理 | `frame/theory-frameworks-public-admin.md` | 35+ |
| 心理学 | `frame/theory-frameworks-psychology.md` | 25+ |
| 传播学 | `frame/theory-frameworks-communication.md` | 20+ |
| 经济学 | `frame/theory-frameworks-economics.md` | 30+ |
| 教育学 | `frame/theory-frameworks-education.md` | 25+ |
| 政治学 | `frame/theory-frameworks-political-science.md` | 30+ |
| 哲学 | `frame/theory-frameworks-philosophy.md` | 60+ |
| 方法论 | `frame/theory-frameworks-methodology.md` | 25 |
| 马克思主义 | `frame/theory-frameworks-marxism.md` | 30 |
| 法学 | `frame/theory-frameworks-law.md` | 15 |
| 新时代思想 | `frame/theory-frameworks-xinsixiang.md` | 16 |
| 党史党建 | `frame/theory-frameworks-party-history.md` | 18 |
| 国际政治 | `frame/theory-frameworks-international-politics.md` | 30+ |
| 当代中国研究 | `frame/theory-frameworks-contemporary-china.md` | 12 个知识点族 + 37 张理论卡 + 12 组机制展开 |

### 3.3 模式与阶段映射

| 模式 | 对应阶段文件 | 执行内容 | 产出 |
|---|---|---|---|
| **FRAME** | `phases/01-frame-mode.md` | 单学科理论框架定位，按取向补充概念、谱系、规范或语境要求 | 理论定位报告 + 空白与张力清单 + RQ/论题方向 |
| **STORM** | `phases/02-storm-mode.md` | 跨学科头脑风暴与理论嫁接，对比概念重构、规范冲突与谱系张力 | 理论嫁接地图 + Top 10 RQs/论题 + 评估卡 |
| **DESIGN** | `phases/03-design-mode.md` | 理论锚点向研究设计转化（仅实证路径强制操作化、功效与稳健性） | 研究设计蓝图 + 论证/材料方案 |
| **FULL** | `phases/04-full-pipeline.md` | 依次执行 FRAME -> STORM -> DESIGN，全程保持取向一致 | 完整研究设计方案 |

### 3.4 阶段文件执行要求

确认模式与研究取向后，完整读取对应 `phases/` 文件，逐项执行并在过程日志记录完成状态。

### 3.5 模块目录结构

```text
modules/design/
├── MODULE.md
├── phases/
│   ├── 01-frame-mode.md
│   ├── 02-storm-mode.md
│   ├── 03-design-mode.md
│   ├── 04-full-pipeline.md
│   └── 05-quality-gates.md
├── frame/
│   └── theory-frameworks-*.md (15 files)
└── references/
    ├── design-essence.md
    ├── idea-essence.md
    ├── storm-patterns.md
    ├── brainstorm-essence.md
    ├── factor-network-bootstrap.md
    ├── method-feasibility.md
    ├── qualitative-methods.md
    └── argument-standards.md
```

### 3.6 下游交接

本模块交付理论锚点、Top 10 RQ/论题及研究设计蓝图。下游是否进入 `analysis` 仅取决于 `DESIGN` / `FULL` 报告中的 `analysis_required: true`；其余路径按顺序交接 `lit`、`outline` 与 `write`。

---

## 附录：派发前内容注入格式（主流程参考）

由于顾问子代理无法直接读取技能包内部的 `frame/`、`references/` 与 `phases/`，主流程派发前须先读取对应参考文件的实际内容并追加至顾问 prompt 末尾（仅附路径或行号区间不构成有效注入）：

```markdown
## 参考库内容（主流程已预注入）

### [文件1路径]
[文件1的关键或完整内容]

### [文件2路径]
[文件2的关键或完整内容]
```

各角色需注入的参考文件清单以 `agents/_reference-base.md` B3 为唯一来源。单次注入控制参考量：B1 切片 ≤ 1200 字；`frame/` 文件按 `read_ranges` 读取（通常每区间 50–150 行）；`references/` 注入核心条款（约 200–400 行）。
