---
name: paper-analysis-4ss
description: 中文社会科学论文数据分析技能。用于结构化数据清洗、描述统计、主回归、中介/机制、调节、异质性、门槛、非线性、政策识别、稳健性检验、机器学习与因果机器学习（挑控制变量、挑工具变量、CATE／GATES／BLP）、质性材料编码、主题/内容分析、混合方法整合和论文结果呈现。支持 Stata、R、Python，内置常用社科基础模型、三语言模板和案例。当用户需要从数据或访谈/文本材料产出论文级表格、图形、代码、方法说明和结果段落时使用。
---

# Paper Analysis 4SS：社会科学数据分析

> 参数提示：[模式] [数据或文本路径] [可选: stata|r|python]

本模块将结构化数据、访谈记录与开放文本转化为可复现的分析脚本、论文级表图、质性编码产物及结果文字素材。

核心约束：
1. 分析脚本生成后须实际执行，不得仅交付未运行脚本并编写统计结论；
2. 无法执行时须输出阻断日志、可复现脚本及缺失条件说明，严禁输出虚构数值；
3. 正文引用的所有统计数值均须可追溯至真实 `run-log` 与输出文件。

## 执行前提

1. **路径约定**：`modules/...` 相对于 `paper-master-4ss/` 根目录解析；在本模块目录内单独运行时可使用 `agents/...`、`phases/...`、`references/...`、`templates/...`。
2. **输出格式**：先读取 `master/output-protocol.md`。分析计划、运行日志摘要、结果说明、质性/混合方法报告、顾问意见、综合文件与最终回复均使用中文 Markdown（变量名、模型名、代码、命令、软件名与统计指标保留原文）；分析流程、模型识别链、稳健性/机制检验路径、质性编码流程、混合方法整合链路与顾问派活链须附 Mermaid 图及 2–4 句中文解释。
3. **脚本实跑要求**：所有结果须来自真实命令执行（详见 §4.1）。

## 顾问角色与选派时机

根据变量复杂度、识别策略风险与任务类型按需选派顾问（执行身份以 `references/agent-registry.md` 标准名为准；输入须包含研究问题、数据类型、变量设定及已有脚本或结果表）：

| 决策风险 / 任务环节 | 对应顾问文件 |
|---|---|
| 识别字段、解析问卷/codebook、映射 19 类变量角色并预判数据质量（产出 `variable-discovery-pack`） | `modules/analysis/agents/variable-discovery-consultant.md` |
| 复核清洗逻辑、样本筛选、缺失/异常值处理与变量字典定稿 | `modules/analysis/agents/variable-cleaning-consultant.md` |
| 依据上游 `design`/`lit`/`outline` 变量蓝图生成 `analysis-execution-plan` | `modules/analysis/agents/analysis-plan-consultant.md` |
| 裁决模型选择、识别策略、固定效应、标准误与必做/可选检验清单 | `modules/analysis/agents/identification-consultant.md` |
| 按 `task_id` 编写主回归、机制扩展、因果稳健性代码草案 | `modules/analysis/agents/code-writer.md` |
| 质性编码、主题分析、过程追踪与混合方法整合 | `modules/analysis/agents/qual-mixed-consultant.md` |
| 裁决机器学习适用性、防泄漏折分、样本外口径、PDS/DML/IV 选择及 CATE 政策建议边界 | `modules/analysis/agents/ml-causal-consultant.md` |
| 裁决表格规范（CSV 宽表、`display_name`）、作图与结果文字、生成 `script-index` 与导出代码 | `modules/analysis/agents/reporting-consultant.md` |

## 不可逆顺序约束

- **清洗阶段**：变量发现（字段清单 / 角色映射 / 质量预判）-> 变量清洗复核 -> 执行命令行清洗脚本。
- **回归与扩展检验阶段**：分析计划 -> 识别策略裁决 -> 代码编写 -> 命令行执行 -> 结果呈现与导出。

严禁颠倒顺序或跳过变量发现与识别裁决直接生成脚本。

## 变量不明时的处理原则

若核心变量、角色映射或模型条件不明确，须退回变量发现与清洗复核阶段，通过读取数据字段、变量字典、codebook、问卷或上游设计产物补齐依据；仅当数据路径、命令行工具、软件许可或必需文件缺失时，才标记阻断并请求用户补充最小材料。不得用交互选项向用户转嫁「选择 OLS 还是 Logit」等应由研究设计与数据结构决定的技术判断。

## 顾问归档与回查

顾问意见写入 `paper-workspace/_logs/agents/analysis-[YYYY-MM-DD]/`，综合结果写入 `agent-synthesis-analysis-[YYYY-MM-DD].md`（记录共识、分歧、采纳与未采纳理由）。运行环境不支持并行时按序复核并记录 `sequential-review`。每条顾问意见开头须含一行 `参考库回查:`（`base=analysis-2026.10.24` + `tier` + 判据条目号 + 缺口，规则见 `references/agent-registry.md` §2），缺失该行视为无效。

## 1. 参数解析

从 `$ARGUMENTS` 提取以下参数：

| 字段 | 解析规则 | 默认值 |
|---|---|---|
| 模式 | `clean` / `describe` / `regression` / `ml` / `qual` / `mixed` / `robustness` / `export` / `full` | `full` |
| 数据类型 | `.csv/.xlsx/.dta/.sav/.rds/.parquet` 为结构化；`.txt/.md/.docx` 为文本；两者兼有为混合 | 自动推断 |
| 语言 | `stata` / `r` / `python` | `.dta` 或指定 Stata 时用 `stata`；文本与机器学习默认 `python`；其余通用默认 `r` |
| 核心变量 | `Y=`、`X=`、`controls=`、`fe=`、`cluster=`、`weight=`、`id=`、`time=`、`mediator=`、`moderator=`、`heterogeneity=`、`threshold=`、`instrument=`、`treatment=`、`post=`、`running=`、`cutoff=` | 从上游产物、变量发现包或变量字典推断；缺失则退回变量发现与清洗复核 |
| 质性路径 | `codebook`、`open-coding`、`thematic`、`content`、`reliability`、`llm-coding` | 按材料与需求推断 |
| 目标输出 | 表格、图形、结果文字、脚本、报告 | 全部 |

缺失数据路径或研究问题时，先检索当前目录、`paper-workspace/_index/input-registry.md` 及 `01-design/`、`02-literature/`、`03-outline/`；仍无法确定时记录阻断并请用户提供最小数据路径。

## 2. 输出目录与双日志

遵守 `master/output-protocol.md`（报告使用中文 Markdown，关键分析链附 Mermaid 图，表图保留标准数据/图形格式）。首次执行须初始化目录：

```bash
OUTPUT_ROOT="${OUTPUT_ROOT:-paper-workspace/04-analysis}"
mkdir -p "$OUTPUT_ROOT"/{data,scripts,tables,figures,reports,qual/codebooks,qual/coded-data,qual/memos,qual/anonymized,qual/reliability}
mkdir -p paper-workspace/_logs
```

- **过程日志**：写入 `paper-workspace/_logs/process-log-analysis-[YYYY-MM-DD].md`，记录数据来源、样本口径、变量构造、模型选择、标准误、质性编码规则与输出文件。
- **运行日志**：写入 `paper-workspace/04-analysis/reports/run-log-[YYYY-MM-DD].md`，每次脚本运行后**即时记录**：执行命令、脚本路径、退出码、stdout/stderr 路径、产物清单及失败原因（不得事后补写，该日志为 `post-bash` 审计依据）。

## 3. 模块结构

| 目录 | 职能 |
|---|---|
| `phases/` | 阶段执行手册（初始化、清洗、回归、机器学习与因果 ML、质性、混合方法、导出门控） |
| `references/` | 模型路由与诊断阈值、识别设计协议族（DiD 九步 / IV 三阶段 / RDD 四阶段 / 合成控制八动作 / shift-share 两路径 / 宽严度五步 / 协变量三步）与高级方法目录（20 族 139 条）、机器学习与因果 ML 方法库（`ml-causal-ml-methods.md`）、质性方法、报告规范与三语言生态配置 |
| `templates/` | 三语言（Stata / R / Python）可执行脚本模板：`01-init`、`02-clean-describe`、`03-regression`（含 `08-spatial`）、`07-ml`（4 个子流程）、`04-qual`、`05-mixed`、`06-export` |

## 4. 模式路由与按需参考

先读取 [01-init-and-routing.md](modules/analysis/phases/01-init-and-routing.md)，再按选定模式读取对应阶段文件：

| 模式 | 阶段文件 | 核心产出 |
|---|---|---|
| `clean` | [02-quant-cleaning.md](modules/analysis/phases/02-quant-cleaning.md) | 清洗脚本、变量字典、样本流失表、清洗后数据 |
| `describe` | [02-quant-cleaning.md](modules/analysis/phases/02-quant-cleaning.md) | 描述统计、相关矩阵、基础图形 |
| `regression` | [03-basic-regression.md](modules/analysis/phases/03-basic-regression.md) | 分析执行计划、主回归、中介/调节/异质性/门槛/非线性/政策识别、稳健性与表图导出 |
| `qual` | [04-qual-analysis.md](modules/analysis/phases/04-qual-analysis.md) | 去标识化文本、编码本、编码数据、主题/内容分析、信度报告 |
| `mixed` | [05-mixed-methods.md](modules/analysis/phases/05-mixed-methods.md) | joint display、案例选择、编码变量化与整合解释 |
| `robustness` | [03-basic-regression.md](modules/analysis/phases/03-basic-regression.md) | 稳健性、异质性、机制、安慰剂及设计蓝图要求的扩展检验 |
| `ml` | [07-ml-and-causal-ml.md](modules/analysis/phases/07-ml-and-causal-ml.md) | 折分方案、超参调优、样本外评估、PDS/DML/IV 选择、CATE/GATES/BLP、ML 宽表与方法说明 |
| `export` | [06-export-and-quality-gates.md](modules/analysis/phases/06-export-and-quality-gates.md) | 成品表图导出、方法说明与中文结果段落 |
| `full` | 依次执行 01–06 | 完整论文分析包 |

**因果识别前置规则**：若研究设计命中 `references/quantitative-model-router.md` §12 分流表（DiD / IV / RD / 合成控制 / shift-share / 宽严度 / 可观测选择等），`regression` 与 `robustness` 模式在编写代码前须先生成 `identification-protocol-pack-[date].md`（包含目标参数、假设版本、必做诊断、退出判据初判与结论适用范围），交由 `paper-analysis-identification-consultant` 裁决（详见 `phases/03-basic-regression.md` §2.5）。纯描述、无因果声称关联及质性路径不触发此规则。

按需参考文档（禁止一次性全量载入）：
- **模型选择与诊断**：[quantitative-model-router.md](modules/analysis/references/quantitative-model-router.md)
- **机器学习方法库（`ml` 模式专用）**：[ml-causal-ml-methods.md](modules/analysis/references/ml-causal-ml-methods.md)（含进入三条件、五条纪律、特征工程、正则化、集成、因果 ML、异质性、判据 C24–C31 及报告口径）
- **模板索引**：[templates/README.md](modules/analysis/templates/README.md) 与 [03-regression/README.md](modules/analysis/templates/03-regression/README.md)
- **质性方法**：[qualitative-routing-design.md](modules/analysis/references/qualitative-routing-design.md)（路由至 `qualitative-analysis-methods.md` 与 `qualitative-quality-integration.md`）
- **报告规范**：[quantitative-reporting-standards.md](modules/analysis/references/quantitative-reporting-standards.md)
- **语言环境配置**：[python-ecosystem-setup.md](modules/analysis/references/python-ecosystem-setup.md)、[r-ecosystem-setup.md](modules/analysis/references/r-ecosystem-setup.md)、[stata-ecosystem-setup.md](modules/analysis/references/stata-ecosystem-setup.md)

### 4.1 强制实跑要求

| 分析语言 | 执行方式 | 环境缺失或失败时的处理 |
|---|---|---|
| Stata | 统一经 `statamcp`：`.do` 文件用 `stata_run_file`（传 `file_path` 与 `working_dir`，长任务显式设置 `timeout`）；环境探测用 `stata_run_selection` | 按 `modules/analysis/references/stata-ecosystem-setup.md` §1–§2 安装配置与验收；未通过则输出阻断说明与安装指引 |
| R | `Rscript "script.R"` | 按 `modules/analysis/references/r-ecosystem-setup.md` 安装或补齐依赖并记录 |
| Python | `python3 "script.py"` | 按 `modules/analysis/references/python-ecosystem-setup.md` 配置虚拟环境与依赖 |

所有表格、图形、数值与结果段落必须源于已成功执行的脚本；因缺少许可、数据或依赖导致无法运行时，仅交付阻断日志、可复现脚本及缺失项清单。

### 4.2 Stata 默认双总代码结构

Stata 生产交付默认拆分为两份主脚本，均须通过 `stata_run_file` 实际运行并记入 `run-log`（`templates/03-regression/` 下模板仅作构建素材）：
- `paper-workspace/04-analysis/scripts/01_clean_and_prepare_master.do`：全量数据导入、真实性核查、变量构造与标准化、缩尾处理，导出表 1–3 描述统计与共线性诊断。
- `paper-workspace/04-analysis/scripts/02_empirical_analysis_master.do`：基于 `reghdfe` / `ivreghdfe` 执行基准回归及扩展实证检验，导出表 4 至表 N 论文宽表（可另附绘图脚本）。

默认技术口径：高维固定效应采用 `reghdfe`、工具变量采用 `ivreghdfe`、机制检验默认江艇（2022）两步法、调节效应默认四列递进设定。

## 5. 执行约束与职责边界

**强制执行规范**：
- 结构化数据分析前须核查变量存在性、类型、缺失、异常值、重复值、样本筛选及面板唯一性；
- 二元、有序及多分类非线性模型须报告边际效应或预测概率，不得仅报告原始系数；
- 回归表在系数下方括号内报告 t/z 统计值；标准误类型、聚类层级与权重注明于表注、正文或日志，不嵌入系数单元格；
- 描述统计、系数、边际效应、t/z 值及比例默认保留 3 位小数，样本量与频数保留整数；
- 回归表默认导出 CSV，内容按论文宽表排版（表题、模型编号列、因变量列名、系数行、括号内 t/z 行、固定效应「是/否」行、观测值行、中文注释行）；HTML/TeX/DOCX 仅作辅助格式；
- 宽表中逐行保留控制变量，固定效应用中文行名汇总为「是/否」，样本量行统一标注「观测值」，R² 类指标仅在适用模型保留；
- 文档与模板不得硬编码特定项目变量名；正式导出表格、图轴与报告使用可发表展示名（优先读取 `variable-dictionary.csv` 的 `display_name`、数据标签或清洗后变量名）；
- 访谈、田野笔记与开放题文本在进入模型阅读或 LLM 辅助编码前必须完成去标识化，不得读取或展示真实身份映射表；
- 质性分析须保留编码本、编码—原文摘录映射、分析备忘录与信度复核记录；
- 混合方法须输出定量发现与质性主题的整合矩阵（joint display），不得简单并列罗列；
- `ml` 模式须写明折分方案、随机种子、超参搜索空间与预算；预处理仅在训练折内拟合，测试集仅使用一次；
- `ml` 因果估计结果须与基准 OLS 并表呈现，并注明正交化对象与交叉拟合折数；折间波动过大时仅报告区间；
- `ml` 异质性结果须同时报告 GATES 分位组效应、BLP 检验与重叠诊断，缺少重叠诊断不得给出个体层面政策建议。

**职责边界**：
- 本模块负责常规清洗与论文分析数据构建，不承接复杂原始数据库的整体重构；
- 高级贝叶斯、SEM、深度学习（CNN/RNN/BERT 微调）、图像识别及网络分析仅作可选扩展，不纳入核心可执行流程（表格数据正则化、树集成、因果 ML 与异质性政策效应归入 `ml` 核心流程，见 `phases/07-ml-and-causal-ml.md`）；
- 严禁虚构变量、访谈摘录、统计指标与显著性。

## 6. 模板与命令执行协议

优先复用 [templates/README.md](modules/analysis/templates/README.md) 中拆分的三语言模板库：

| 流程 | 模板路径 | 用途 |
|---|---|---|
| 初始化 | `templates/01-init/` | 创建 `04-analysis` 输出结构与初始化报告 |
| 清洗描述 | `templates/02-clean-describe/` | 读取数据、清洗、变量字典、样本流失表与描述统计 |
| 回归执行 | `templates/03-regression/README.md` | 9 个可执行子流程（dispatch、主回归、非线性、面板、因果、机制/异质性、稳健性、空间计量 `08-spatial/`、导出） |
| 机器学习与因果 ML | `templates/07-ml/` | 4 个子流程（监督学习、PDS/DML/IV 选择、CATE/GATES/BLP、ML 宽表与方法说明；语言覆盖差异见 `templates/07-ml/README.md`） |
| 质性分析 | `templates/04-qual/` | 去标识化、编码本、编码数据、备忘录与信度报告 |
| 混合方法 | `templates/05-mixed/` | joint display 与整合解释 |
| 导出门控 | `templates/06-export/` | 交付前检查、声称边界与产物追溯 |

生产执行时将对应脚本复制或改写至 `paper-workspace/04-analysis/scripts/` 后运行（统一支持 `--data`、`--plan`、`--dict`、`--out-root`、`--run-log`、`--slug`、`--tasks` 命令行参数）。

**Stata（`statamcp`）执行细节**：
1. 生产逻辑写入 `.do` 文件，调用 `stata_run_file` 并明确传入 `file_path`、`working_dir` 与 `timeout`（默认 600 秒，复杂任务调至 1800 秒以上）；
2. 环境探测或单行测试使用 `stata_run_selection`，不得替代 `.do` 文件执行生产逻辑；
3. 并行子任务为各任务分配独立 `session_id`，使用 `stata_session(action=list/destroy)` 管理残留会话；
4. 每次调用的返回输出、报错信号（如 `r(...)`）与产物路径须即时写入 `run-log-[date].md`。

R 与 Python 同样须以完整脚本文件执行：

```bash
Rscript "path/to/analysis.R"
python3 "path/to/analysis.py"
```

## 7. 交付汇报清单

1. 已生成及已运行的脚本路径；
2. 主要表格、图形、质性编码产物与分析报告路径；
3. 关键模型设定或质性编码决策；
4. `post-bash` 审计与交付前检查的通过及未通过项；
5. 哪些结论源于真实脚本执行，哪些因环境、许可、数据或依赖受阻而不得声称；
6. 移交 `write` 的可用正文表述、表图占位与结果声称边界（统计参数入表或附录，正文不堆砌行内参数）；
7. `ml` 模式额外交付：`tables/ml-run-manifest.csv`（各表产出状态与未产出原因）、`reports/ml-methods-note.md`（方法说明草稿）及未执行清单阻断说明（未列入清单的表格数字严禁进入正文）。
