---
base-id: analysis-2026.10.24
module: analysis
---

# analysis 模块参考库回查底座

本文件是 `analysis` 模块 8 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=analysis-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

数据分析各环节须逐项核查三件事：变量口径是否准确、模型设定是否匹配研究问题、统计结果是否源于真实执行。

清洗阶段须先产出 `variable-discovery-pack`，包含字段清单（数据字段、标签、codebook、问卷或变量字典溯源）、19 类角色映射（Y/X/control/fe/cluster/weight/id/time/mechanism/mediator/moderator/heterogeneity/threshold/nonlinear/instrument/treatment/post/running/cutoff）及质量预判（特殊缺失码、异常值、单位混乱、反向题、小样本分类、面板唯一性与样本流失）。三段缺一不得批准最终清洗脚本。

模型选择依据因变量类型与研究设计（截面、面板、重复截面、政策冲击、选择偏差、空间依赖）确定，并与标准误及聚类层级保持口径一致；面板模型在 FE/RE/混合 OLS 间结合 Hausman 检验与理论依据裁决，动态面板采用 GMM。

机制检验默认采用江艇（2022）两步法；调节效应报告主效应完整且仅交乘项中心化的四列递进结果；含时间固定效应时须排除全国宏观时变变量；高维固定效应采用 `reghdfe` 类命令。内生性须先判定来源（遗漏变量、测量误差、联立、样本选择）再匹配识别策略，不得由工具变量倒推内生性。

稳健性检验针对具体识别或测量威胁设计，不作无目的堆表；平行趋势、第一阶段 F 值、弱工具变量、操纵检验、平衡性、Hausman 与聚类标准误属于必做诊断。

代码写手不持有阻断权，仅输出「代码片段 + 合并位置 + 命令行执行指令」供主流程拼接执行；变量或数据结构缺失时须输出阻断与退回任务，严禁编写占位代码。

结果呈现默认导出 CSV 论文宽表并采用 `display_name` 展示名；未执行或失败的模型仅记入限制与阻断说明，所有统计结论均须可追溯至真实运行日志。

## B2 判据条目

C01 因变量类型决定模型族：连续/二分/多分类/计数/截断/受限因变量分别对应 OLS/Logit-Probit/Mlogit-Ordered/Poisson-负二项/Tobit/Heckman（`references/quantitative-model-router.md` §2）。

C02 研究设计路由：截面、面板、重复截面、政策冲击、选择偏差与空间依赖场景严格区分（§3）。

C03 标准误与聚类层级：聚类层级与固定效应层级口径一致，避免层级错配（§4）。

C04 表格顺序与诊断阈值：主表顺序与诊断阈值按 §5/§6 执行，未达标项须写明诊断结论。

C05 变量清单可追溯：候选变量可追溯至数据字段、标签、codebook、问卷条目或既有变量字典，标明同名异义、反向题与单位口径问题。

C06 角色映射完整性：19 类角色逐项落位，标出一变量多用、因果倒置与后处理变量风险。

C07 数据质量预判：识别特殊缺失码、异常值、单位混乱、反向题与分类小样本风险，量化缺失处理与样本流失。

C08 面板与样本口径：核查 ID/时间唯一性、重复记录、面板平衡性、筛选顺序与权重可用性，评估筛选偏差。

C09 内生性判断框架：先判来源（遗漏变量/测量误差/联立/样本选择）再定识别策略（§7），不倒推设定。

C10 面板模型选择：FE/RE/混合 OLS 依据 Hausman 与理论理由裁决，动态面板采用 GMM 并说明工具变量有效性（§8）。

C11 机制与调节规范：机制默认江艇（2022）两步法；调节报告主效应齐全且仅交乘项中心化的四列递进；时间固定效应下排除全国宏观变量；高维固定效应采用标准命令（§11）。

C12 稳健性针对性：每项稳健性检验对应具体威胁，异质性分组具备理论依据，不堆砌表格（`quantitative-reporting-standards.md` §5）。

C13 代码可执行性：输出「代码片段 + 合并位置 + CLI 执行命令」，可被主流程拼入单一脚本执行；按 `task_id` 选用三语言模板。

C14 阻断与退回：缺变量、数据结构或算法支持时输出阻断说明与退回任务，不得静默跳过或写占位代码。

C15 结果报告格式：默认导出 CSV 论文宽表（模型编号行、因变量行、系数行、括号内 t/z 行、固定效应「是/否」行、观测值行、中文注释行），逐行保留控制变量，R² 类指标按模型适用性输出。

C16 可发表展示名：建立变量显示名映射，CSV、图轴与报告使用 `display_name`、数据标签或清洗后变量名，不硬编码特定项目变量。

C17 真实执行追溯：未执行或失败的模型只进限制与阻断段，正文引用表图均须可追溯至命令行执行记录。

C18 质性与混合方法规范：文本去标识化，编码层级与主题命名紧扣摘录并回应研究问题；混合方法产出 joint display 整合矩阵（`references/qualitative-routing-design.md` §0.1、`qualitative-analysis-methods.md` §0、`qualitative-quality-integration.md`）。

C19 变量发现包准入门：无 `variable-discovery-pack` 不得批准最终清洗脚本；发现包中退回补证项未清零不得定稿。

C20 非线性与识别必做诊断：非线性模型报告 AME 或预测概率；DiD/事件研究检平行趋势，IV 检第一阶段与弱工具，RDD 检操纵与带宽，PSM 检平衡性。

C21 跨模块口径一致：`analysis-execution-plan` 变量角色与 `design`/`lit`/`outline` 保持一致，冲突须退回确认。

C22 执行可追溯要求：判断指向已读文件、`variable-dictionary.csv` 行或运行日志；缺口标注「待核验」。

C23 阶段顺序门控：结构化数据须走「变量发现 -> 清洗 -> CLI 执行」；回归与检验须走「analysis-plan -> identification -> code-writer -> CLI 执行 -> reporting/export」，不得跳步。

C24 ML 进入门槛：仅当预测/分类即研究目的、经典方法在高维强非线性下失效、或在识别框架内用 ML 修补薄弱环节时方进入 `ml` 模式（`references/ml-causal-ml-methods.md` §2、§10）。

C25 任务驱动算法选择：先界定回归预测、二/多分类、聚类降维或因果估计任务，再选模型族与损失/评估指标（§2、§4、§7）。

C26 防泄漏与折分纪律：标准化、插补、编码、特征选择与调参仅在训练折内拟合，测试集仅用一次；面板/分组按组切折，时序按时间切分（§4、§10）。

C27 样本外评估与披露：样本外指标须与训练集指标并报以检过拟合，同时披露折数、随机种子、软件版本与超参搜索空间（§4、§6、§7）。

C28 因果 ML 正交化与稳定性：PDS/DML 明确正交化对象、交叉拟合折数与折间波动，与基准 OLS 并表；折间极差过大时仅报区间（§10）。

C29 异质性与重叠诊断：CATE 落地至 GATES 分位组与 BLP 异质性检验，并附倾向得分重叠诊断；重叠不足或叶节点样本过小时禁止个体层面政策建议（§11）。

C30 预测不等于因果：样本外精度、变量重要性与 CATE 排序不构成因果证据；ML 不解决遗漏变量、联立与测量误差，须写明声称边界（§3、§10、§13）。

C31 复现资产落盘：随机种子、折分索引、搜索空间、依赖版本与计算成本均须落盘，未落盘结果不入正文（§4、§10）。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-analysis-variable-discovery-consultant` | C05 C06 C07 C08 C14 C19 C22 | `phases/02-quant-cleaning.md`、`references/quantitative-model-router.md` §1–§2、数据 codebook/问卷/变量字典 | T1 |
| `paper-analysis-variable-cleaning-consultant` | C07 C08 C14 C19 C22 | `phases/02-quant-cleaning.md`、`variable-discovery-pack`、样本流失要求 | T2（阻断清洗定稿） |
| `paper-analysis-analysis-plan-consultant` | C02 C06 C09 C21 C22 | `design`/`lit`/`outline` 产物、`variable-discovery-pack`、`phases/03-basic-regression.md` | T1 |
| `paper-analysis-identification-consultant` | C01 C02 C09 C10 C12 C20 C22 | `references/quantitative-model-router.md` §2–§4、§7–§9、§11、`analysis-execution-plan` | T2（结论进正文） |
| `paper-analysis-code-writer` | C01 C02 C03 C11 C13 C14 C20 | `references/quantitative-model-router.md`、`quantitative-reporting-standards.md`、`templates/`、`python-ecosystem-setup.md`、`r-ecosystem-setup.md`、`stata-ecosystem-setup.md` | T2（writer） |
| `paper-analysis-qual-mixed-consultant` | C18 C14 C22 | `references/qualitative-routing-design.md`（§0.1）、`qualitative-analysis-methods.md`（§0）、`qualitative-quality-integration.md` | T1 |
| `paper-analysis-reporting-consultant` | C15 C16 C17 C13 C22 | `references/quantitative-reporting-standards.md` §1–§6、`phases/06-export-and-quality-gates.md`、运行日志与 `script-index` | T2（结论进正文/投稿包） |
| `paper-analysis-ml-causal-consultant` | C24 C25 C26 C27 C28 C29 C30 C31 | `references/ml-causal-ml-methods.md`、`phases/07-ml-and-causal-ml.md`、`templates/07-ml/`、`analysis-execution-plan` | T2（结论进正文） |

L1 默认单点角色：`paper-analysis-identification-consultant`（确保基准识别策略正确，避免后续稳健性检验无效）。
