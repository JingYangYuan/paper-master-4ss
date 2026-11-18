# Analysis Targets

## 模块边界

analysis 模块负责数据清洗、描述统计、模型执行、质性编码、混合方法和论文级结果呈现。候选更新不得伪造统计结果，也不得绕过 CLI 执行要求。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/analysis/references/quantitative-model-router.md` | 模型选择、诊断阈值、标准误、面板/空间路由 | low |
| `knowledge-reference` | `modules/analysis/references/quantitative-reporting-standards.md` | 表格、图形、数值格式、结果段落模板 | low |
| `knowledge-reference` | `modules/analysis/references/qualitative-*.md` | 质性设计、资料收集、编码、质量保证、混合整合 | low |
| `knowledge-reference` | `modules/analysis/references/*-ecosystem-setup.md` | Python/R/Stata 依赖、镜像、验收命令 | low |
| `knowledge-reference` | `modules/analysis/references/*-protocol.md` | 单一识别设计的完整流程协议（适用场景、前置条件、步骤、诊断门槛、报告规范、退出判据）；一份文件只写一种设计 | low |
| `knowledge-reference` | `modules/analysis/references/advanced-method-catalog.md` | 方法目录（族别、method_id、语言、估计目标、代表文献线索）；只作识别线索，不作推荐 | low |
| `workflow-protocol` | `modules/analysis/phases/*.md` | 初始化、清洗、回归、质性、混合、导出门控 | medium |
| `workflow-protocol` | `modules/analysis/agents/*.md` | 变量、识别、代码撰写、稳健性、报告顾问职责 | medium |
| `workflow-protocol` | `modules/analysis/MODULE.md` | 模式路由、语言选择、执行边界 | medium |
| `tooling-template` | `modules/analysis/templates/README.md`、`modules/analysis/templates/_shared/*`、`modules/analysis/templates/01-init/*`、`02-clean-describe/*`、`03-regression/*/*`、`04-qual/*`、`05-mixed/*`、`06-export/*` | 按流程与子流程拆分的 Stata/R/Python 模板库；回归模板必须落到具体子流程 | high |

## 路由提示

- 计量模型和诊断规则优先进入 `quantitative-model-router.md`。
- 识别设计的**流程**（该按什么顺序做、什么时候该放弃）进 `references/*-protocol.md`；**估计量选择与诊断阈值**仍进 `quantitative-model-router.md`，不得把两者混在一份文件里。
- `*-protocol.md` 的命名遵循 `<方法族>-<阶段数或动作数>-protocol.md`（例：`did-nine-step-protocol.md`、`rdd-four-stage-protocol.md`）；方法目录类文件用 `advanced-method-catalog.md`，不套 `*-protocol.md` 后缀。
- 报告格式和结果写作优先进入 `quantitative-reporting-standards.md`。
- 质性方法补充优先进入对应 `qualitative-*.md`。
- 模板候选必须提供运行命令、依赖条件、示例输入、预期输出文件和 `run-log` 记录方式。
- high-risk template 候选必须指明具体流程或子流程目录；例如 `templates/03-regression/04-causal/`、`templates/03-regression/05-mechanism-heterogeneity/`，不得只写 `templates/*`。
- `03-regression` 候选不得重新合并为单个长脚本；必须保持 `00-plan-dispatch` 到 `07-regression-export` 的拆分结构。
