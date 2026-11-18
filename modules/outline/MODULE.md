---
name: paper-outline-4ss
description: 将用户指定输入路径、master 输入登记表或当前目录候选材料转换为结构化论文撰写大纲。支持毕业论文（五章结构）和期刊论文（五要素紧凑结构）双轨输出，支持规范研究、实证研究、阐释研究、混合研究四种方法协议，以及社会学研究范式和管理世界案例研究范式两类发表风格。当用户需要从已有文献素材生成论文大纲、将材料转化为写作框架、或需要论文结构设计时使用。
---

# Paper Outline 4SS：素材转化与大纲构建

> 参数提示：[研究主题] [可选: 学科, 目标期刊, 范式偏好]

本模块负责将已有文献、设计与数据/文本素材转化为带章节顺序、段落级写作蓝图、证据映射与缺口清单的结构化论文大纲。缺少材料支撑的章节与段落须显式标记，不得隐匿或虚构支撑。

## 路径约定

本文件中的 `modules/...` 路径默认相对于 `paper-master-4ss/` 根目录解析；在模块目录内单独运行时可直接使用 `agents/...`、`phases/...`、`references/...`。

## 全局输出协议

先读取并遵守 `master/output-protocol.md`。本模块所有素材清单、大纲、段落级写作蓝图、证据映射、缺口报告、顾问意见、综合文件与最终回复均使用中文 Markdown；章节逻辑、证据流、缺口退回路径、模块交接及顾问调度链须附 Mermaid 图及 2–4 句中文解释。

## 0. 顾问派发规范

依据 `master/agent-orchestration.md` 决定派发档位。当材料量较大、论文目的待定、涉及学位论文/期刊论文结构抉择或需要评估证据映射与缺口阻断时，按需派发以下顾问（输入须包含素材清单、研究主题、论文目的、目标风格及上游设计与文献产物；执行身份以 `references/agent-registry.md` 标准名为准）：

| 触发场景 | 对应顾问文件 |
|---|---|
| 判定学位论文/期刊论文与研究类型结构深度 | `modules/outline/agents/structure-consultant.md` |
| 材料功能归类、论点—证据映射及证据等级达标检查 | `modules/outline/agents/evidence-map-consultant.md` |
| 核查章节顺序、层级递进、材料与论证缺口（持有进入写作阻断权） | `modules/outline/agents/gap-review-consultant.md` |

顾问意见写入 `paper-workspace/_logs/agents/outline-[YYYY-MM-DD]/`，综合结果写入 `agent-synthesis-outline-[YYYY-MM-DD].md`。运行环境不支持并行时按上表顺序复核并记录 `sequential-review`。

## 1. 素材定位与用户确认

### 1.1 素材来源定位优先级

1. 用户显式指定的输入路径；
2. `paper-workspace/_index/input-registry.md` 中登记的材料路径；
3. 当前目录下的候选文本材料。

若工作区已存在 `paper-workspace/01-design/design-report-*.md` 或 `full-report-*.md`，须先读取其中的研究取向、论证链、不可声称内容与下游交接任务；纯理论路径不得被改写为实证「假设—验证」结构。

```bash
find "$INPUT_PATH" -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.csv" \) | head -30
```

常见输入材料对照：

| 素材类型 | 常见路径 |
|---|---|
| 文献题录与证据表 | `paper-workspace/02-literature/paper-registry.csv`、`review-evidence.csv`（按索引读取，不全表载入） |
| 文献地图与综述蓝图 | `paper-workspace/02-literature/literature-map.md`、`review-outline.md`、`review-gaps.md` |
| 逐篇全文 Markdown | `paper-workspace/02-literature/fulltext/<paper_id>/document.md` |
| 综述正文净稿 | `paper-workspace/05-writing/literature-review.md` |
| 上游研究设计报告 | `paper-workspace/01-design/` |
| PDF 转 Markdown 全文或文献笔记 | 用户指定路径 |
| 数据清洗与分析报告 | 用户指定路径或 `paper-workspace/04-analysis/` |

**空材料硬停止**：上述三类来源均未检出任何 `.md`/`.txt`/`.json`/`.csv` 素材时，立即停止构建大纲，提示用户补充素材路径或先完成文献检索。

### 1.2 素材清单输出格式

```markdown
## 已发现素材清单

| # | 文件名 | 路径 | 推测内容类型 |
|---|---|---|---|
| 1 | xxx.md | paper-workspace/02-literature/ | 文献综述或证据材料 |
| 2 | xxx.md | 用户指定目录 | 论文全文（PDF 转写） |

**素材摘要**：
- 文献综述类文件：N 篇
- 论文全文类文件：N 篇
- 数据/方法报告：N 篇
- 其他：N 篇
```

### 1.3 用户确认流程（使用 `ask_user`）

提问结构遵守 `references/user-question-examples.md`，输出素材清单后依次确认以下五项：

**Step 0 — 论文目的**

```text
question: "本论文的写作目的是学位论文还是期刊论文？两者在章节结构与展开深度上存在本质差异。"
header: "论文目的"
options: [
  {label: "毕业论文", description: "本/硕/博学位论文，强调系统性、完整性与独立研究能力展示"},
  {label: "期刊论文", description: "面向学术期刊投稿，强调紧凑聚焦与边际创新贡献"}
]
```

若选择「毕业论文」，追加确认学历层次：

```text
question: "请确认毕业论文的学历层次。"
header: "学历层次"
options: [
  {label: "本科", description: "现象描述与对策建议，体现基本学术训练"},
  {label: "硕士", description: "具备明确理论应用或方法推进，完成论证闭环"},
  {label: "博士", description: "须有清晰理论、方法或应用创新及充分实证/文本支撑"}
]
```

**Step 1 — 研究主题与论文类型**

```text
question: "请确认论文主题及所属研究类型。"
header: "主题与类型"
options: [
  {label: "实证研究论文", description: "基于定量数据检验研究假设或因果/相关关系"},
  {label: "阐释研究论文", description: "基于案例、访谈或档案材料解释过程与机制"},
  {label: "规范研究论文", description: "基于理论与经典文献开展概念辨析或制度评价"},
  {label: "文献综述论文", description: "以学术文献为对象，系统梳理领域演进、争议与空白"}
]
```

**Step 2 — 目标期刊与发表范式**

```text
question: "请确认目标期刊风格或发表范式。"
header: "期刊范式"
options: [
  {label: "社会学研究范式", description: "以学术脉络中的知识缺口为驱动（如《社会学研究》《社会》）"},
  {label: "管理世界案例研究范式", description: "以中国现实问题与理论反常为驱动（如《管理世界》《公共管理学报》）"},
  {label: "通用学术范式", description: "标准 IMRaD 结构，适用于英文期刊或常规学位论文"},
  {label: "尚未确定", description: "根据现有素材特征推荐匹配的范式"}
]
```

**Step 3 — 预期字数**

若为毕业论文：

```text
question: "预期论文字数范围是多少？"
header: "论文字数"
options: [
  {label: "1.5万字以下", description: "本科毕业论文"},
  {label: "2-3万字", description: "标准硕士学位论文"},
  {label: "3-5万字", description: "深度硕士学位论文"},
  {label: "8万字以上", description: "博士学位论文"}
]
```

若为期刊论文：

```text
question: "预期论文字数范围是多少？"
header: "论文字数"
options: [
  {label: "1万字以下", description: "短文或研究笔记"},
  {label: "1.2-1.8万字", description: "中文核心期刊常见篇幅"},
  {label: "1.8-2.5万字", description: "长篇期刊论文或综述文章"},
  {label: "2.5万字以上", description: "长文或专著章节"}
]
```

**Step 4 — 素材覆盖度确认**

```text
question: "现有素材是否已覆盖核心论证需求？是否需要补充或精选？"
header: "素材确认"
options: [
  {label: "素材已充分", description: "直接基于当前素材构建大纲"},
  {label: "需要补充", description: "先识别并标出仍需补充的材料方向"},
  {label: "从素材中精选", description: "素材较多，筛选最核心文献用于大纲构建"}
]
```

---

## 2. 质量门槛与输出约束

### 2.1 四层质量门控

详细核查表见 `modules/outline/phases/03-quality-check.md`。

| 层级 | 检查重点 | 阻断 / 处理规则 |
|---|---|---|
| **L0 素材** | 素材可定位且达到最低数量 | 期刊论文素材 < 3 篇或毕业论文素材 < 8 篇 -> 硬停止，提示补材料 |
| **L1 分类** | 素材合理分配至论文章节 | 单一章节集中 > 60% 素材 -> 发出结构失衡警示 |
| **L2 大纲** | 章节完整、段落蓝图与证据映射齐全 | 核心章节无材料支撑 -> 标为「待补充」；可写段落缺段落大意 -> 返回补齐；无材料支撑段落 -> 标为「暂不写入正文」；毕业论文 ≥ 2 个核心章节缺材料 -> 硬停止 |
| **L3 整体** | 逻辑连贯、篇幅分配合理、具备可执行性 | 任一项不通过 -> 返回修正；毕业论文另须核查五章结构完整性 |

### 2.2 输出路径与文件

遵守 `master/output-protocol.md`，输出模板见 `modules/outline/references/output-formats.md`：

```text
paper-workspace/03-outline/
├── outline-[slug]-[YYYY-MM-DD].md              # 论文大纲正文
├── paragraph-blueprint-[slug]-[YYYY-MM-DD].md  # 段落级写作蓝图（write 模块直接输入）
├── evidence-map-[slug]-[YYYY-MM-DD].md         # 段落级证据映射表
└── gap-report-[slug]-[YYYY-MM-DD].md           # 缺口报告

paper-workspace/_logs/
└── process-log-outline-[YYYY-MM-DD].md
```

### 2.3 边界约束

**强制规范**：
- 毕业论文采用五章结构（绪论 -> 理论界定与文献综述 -> 研究方法与设计 -> 研究发现与机制解释 -> 结论与讨论）；
- 期刊论文采用五要素紧凑结构，经验分析与理论对话合并为同一章节；定量期刊论文的文献综述每条脉络末尾须包含「分析框架与假设」子节；
- 每个章节须注明素材来源（文件路径与对应段落）；
- 每个最末级标题下须生成段落级写作蓝图，固定包含八个字段：段落编号、段落大意、论证功能、中心判断、使用材料、预期证据、衔接关系、不可声称内容；
- 无材料支撑的章节须标明「待补充」及补充方向；无材料支撑的计划段落须标明「暂不写入正文」，严禁传入 `write` 成稿；
- 论点与主张须有素材依据，不得虚构文献、数据或结论；
- 标题层级要求：毕业论文 ≥ 四级标题，期刊论文 ≥ 三级标题。

**职责边界**：
- 本模块仅输出大纲、段落级写作蓝图、证据映射与缺口报告；不撰写论文正文，也不代为执行文献检索。

### 2.4 初始化

```bash
mkdir -p paper-workspace/03-outline paper-workspace/_logs
```

---

## 3. 结构路由规则

### 3.0 论文目的决定结构深度（优先于研究类型）

| 论文目的 | 结构模式 | 文献综述 | 方法章节 | 理论对话 | 模板索引 |
|---|---|---|---|---|---|
| **毕业论文** | 五章结构 | 独立成章，篇幅占 15–20%，三维分类含述评 | 独立成章，含研究伦理与信效度 | 并入讨论/结论章 | `outline-patterns.md` §七 |
| **期刊论文** | 五要素紧凑结构 | 篇幅占 10–15%，常与理论框架合并，脉络末尾出假设 | 精简至可复现边界 | **与经验分析合并**，边呈现边对话 | `outline-patterns.md` §八 |

双轨对比与双轨要素标准详见 `modules/outline/references/outline-patterns.md` §十、§十二。

### 3.1 研究类型与模板映射

依据研究类型加载 `modules/outline/references/outline-patterns.md` 对应章节：

| 研究类型 | 毕业论文（五章结构） | 期刊论文（五要素结构） |
|---|---|---|
| 实证研究 | §七-A | §八-A |
| 阐释研究 | §七-B | §八-B |
| 规范研究 | §七-C | §八-C |
| 文献综述 | §七-D | §八-D |

### 3.2 发表范式微调

| 发表范式 | 结构调整重点 | 参考位置 |
|---|---|---|
| 社会学研究范式 | 文献综述独立成章，突出「知识缺口 -> 经验困惑 -> 理论对话」链条 | `outline-patterns.md` §五 |
| 管理世界案例研究范式 | 文献综述与理论框架合并，突出「现实问题 -> 理论反常 -> 机制建构」链条 | `outline-patterns.md` §五 |
| 通用学术范式 | 标准 IMRaD（引言—文献—方法—结果—讨论—结论） | `outline-patterns.md` §五 |

### 3.3 工作模式路由

| 模式 | 执行阶段 | 触发条件 |
|---|---|---|
| **快速大纲** | `01-scan-materials.md` -> 直接生成 | 素材 ≥ 10 篇、期刊论文且用户确认「素材已充分」 |
| **标准大纲** | `01-scan-materials.md` -> `02-build-outline.md` | 期刊论文默认路径 |
| **完整大纲** | `01-scan-materials.md` -> `02-build-outline.md` -> `03-quality-check.md` | 所有毕业论文，或预期字数 > 2.5 万字 |

---

## 4. 阶段执行规范

- **Phase 1（`modules/outline/phases/01-scan-materials.md`）**：全量扫描并分批读取素材，按双轨章节功能归类，评估素材充分度。
- **Phase 2（`modules/outline/phases/02-build-outline.md`）**：提取核心主张，加载选定模板搭建标题层级（毕业论文四级、期刊论文三级），生成八字段段落级写作蓝图与证据映射，标出结构缺口，并按 `output-formats.md` 写出四份交付文件（定量期刊论文须在综述脉络末尾附分析框架与假设；期刊论文须合并经验分析与理论对话）。
- **Phase 3（`modules/outline/phases/03-quality-check.md`）**：执行五轮质量核查（结构完整性 -> 论证严密性 -> 证据映射质量 -> 范式一致性 -> 可操作性），所有「需修正项」清零后方可交付。

---

## 5. 模块目录结构

```text
modules/outline/
├── MODULE.md
├── phases/
│   ├── 01-scan-materials.md
│   ├── 02-build-outline.md
│   └── 03-quality-check.md
└── references/
    ├── outline-patterns.md
    └── output-formats.md
```
