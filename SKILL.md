---
name: paper-master-4ss
description: 中文社会科学论文总控工作流。用于统一管理 paper-workspace 输出区，登记任意输入路径，并在内部自包含模块之间路由：研究设计、文献综述、论文大纲、数据/质性分析、学术机制图、论文写作与润色、全流程审稿检查、投稿文件整备。适用于用户不知道下一步、想整理论文项目状态，或想串联设计-文献-大纲-分析-机制图-写作-审稿-投稿流程时。
---

# Paper Master 4SS

本技能包负责论文项目的输入登记、阶段路由、产物归档与状态校验。学术观点与研究结论由研究者决定，本包确保各阶段产物路径统一、引用可回溯、交接有记录。

## 1. 核心规则

### 1.1 输入与输出路径

- **输入开放**：用户提供的材料保持原路径，仅登记到 `paper-workspace/_index/input-registry.md`，不移动、重命名或复制原文件。
- **输出集中**：所有阶段产物统一写入项目根目录下的 `paper-workspace/`（目录结构见 `master/workspace-contract.md`）。
- **包内引用**：`modules/...`、`master/...`、`references/...` 均相对于本技能包根目录解析；模块内部引用也可相对于当前文件所在目录解析。

### 1.2 运行环境适配

- 本包不绑定特定运行环境，也不维护固定软件名单。
- 每次会话启动时，按 `references/runtime-adapter.md` §5 探测当前可用能力（读写文件、全文检索、命令执行、联网检索、网页抓取、可见浏览器控制、选项提问、子代理派发、并行执行等），结果写入 `paper-workspace/_index/runtime-capabilities.md`。
- 协议文本使用 `references/runtime-adapter.md` §1 定义的通用能力名；`references/agent-software-adapters.md` 仅作工具形态与 hook 配置格式的对照参考。能力缺失时按对应回退方案执行，并在日志或回复中明确说明，不得虚构执行结果。
- 如需自动触发审计脚本，可执行 `python3 scripts/register_host_hooks.py --detect` 查看候选配置，通过 `--setup` 生成 `.paper-master/host-profile.json` 并注册（`--print` 预览、`--check` 查询、`--remove` 撤销，规则见 `references/hooks-and-evaluation.md`）。若无法确认本次会话 hook 已实际生效，仍须手动执行审计命令。

### 1.3 项目规则优先级

- 执行前先检查项目根目录是否存在本包的规则标记块（`<!-- paper-master-4ss:start -->` 至 `<!-- paper-master-4ss:end -->`）。若存在，读取并仅维护该标记块内部。
- 仅在确认项目内不存在任何规则文件时，回退使用 `paper-workspace/_index/project-rules.md`。
- 不得向本技能包目录写入项目规则，也不得为未确认使用的运行环境新建专用规则文件（维护规范见 `references/project-rules-writing-layer.md`）。

### 1.4 按需加载顺序

1. 读取项目规则（如存在）；
2. 读取 `references/install-dependencies.md` 检查目标模块依赖（缺依赖则停止并提示安装）；
3. 读取 `master/routing-matrix.md`、`master/agent-orchestration.md`、`master/output-protocol.md`、`master/user-journey.md` 确定主模块与协作规范；
4. 读取目标模块入口 `modules/<module>/MODULE.md`；涉及文献综述成稿或改写时，同时读取 `master/literature-review-protocol.md`。

### 1.5 顾问（子代理）派发规则

- **按风险按需派发**：依据当前步骤的决策风险、材料复杂度和交接跨度决定是否派发及派发数量，不得因研究类型或模块名称套用固定名单。档位划分（L0 不派发 / L1 单顾问 / L2 串联复核）见 `master/agent-orchestration.md` §1.6。
- **结果等待门槛**：派发顾问后，须等待其返回实质结果或确认失败，方可继续后续步骤。
- **能力缺失回退**：运行环境不支持子代理或并行执行时，按同一角色清单顺序复核，并在汇总中标注 `sequential-review` 及缺失能力；轻量任务跳过顾问时，须记录 `agent-skip` 及原因。
- **`design` 模块前置确认**：须先确认工作模式（FRAME / STORM / DESIGN / FULL），再确认研究取向。
- **回查声明**：顾问输出须包含一行 `参考库回查:`（注明参考文件、级别 T0/T1/T2、判据条目及缺口）；缺失该行视为输出无效。分级规则见 `references/agent-registry.md` §2。
- **标准命名**：32 个顾问的标准名以 `references/agent-registry.md` 为准；简称仅作阅读简写，不得作为执行标识。

### 1.6 多席位辩论（可选）

`multi_seat_debate` 为可选能力（同一角色多席位互辩）。运行环境支持且用户明确选择时方可使用；不支持或未启用时，按普通顾问派发或顺序复核处理，不单独增加环境探测步骤。

### 1.7 输出格式规范

- **过程与沟通文件**：报告、顾问意见、综合文档与最终回复使用中文 Markdown。
- **图示使用**：涉及机制链、因果链、阶段流程、模块交接、理论嫁接、假设推导、写作派活或顾问调度时，绘制 Mermaid 流程图并附 2–4 句中文说明。
- **论文正文净稿**：`manuscript*.md`、`revisions/styled*.md`、`literature-review.md` 正文区仅保留标题层级和自然段，严禁出现加粗、表格、列表、代码块、Mermaid 图、任务信息、待补证据或超出结论边界的表述。
- **终端回复导航**：最终回复使用纯文本箭头标示论文路径与当前位置（详见 `master/output-protocol.md`）。

### 1.8 执行审计与质量评分

无论运行环境是否配置自动 hook，以下三项检查均须执行并如实记录（未执行须写明未执行，不得默认通过）：

- **命令后审计**：执行分析命令后，核对 run-log、stdout/stderr 路径、报错信号及登记输出文件是否存在。手动命令：`python3 scripts/paper_master_guard.py post-bash --workspace paper-workspace`（阻断模式加 `--strict`）。
- **交付前检查**：模块交付或会话结束前，核对 `_index/project-state.md` 与 `_index/handoff-status.md` 是否已同步至最新产物。手动命令：`python3 scripts/paper_master_guard.py stop-check --workspace paper-workspace`。
- **项目评分**：实质性执行完一个模块后，运行 `python3 scripts/paper_master_guard.py score-project --workspace paper-workspace --json`，生成 `_index/quality-score.md` 与 `_index/quality-score.json`（评分口径见 `references/evaluation-rubric.md`）。

## 2. 工作区初始化

目录与产物约定见 `master/workspace-contract.md`。项目首次启用时确保以下目录存在：

```bash
mkdir -p paper-workspace/{00-meta,01-design,02-literature,03-outline,04-analysis,05-writing,05-writing/reviews,06-submission,07-update,figures,_logs,_logs/hook-audit,_index}
```

`_index/` 目录下各索引文件用途：

- `project-state.md`：研究主题、当前阶段、已有产物、待补缺口、顾问状态、关键风险与下一步。
- `input-registry.md`：外部输入材料路径、类型、用途及状态登记。
- `handoff-status.md`：跨阶段交接清单、已采纳结论与未解决风险。
- `paper-roadmap.md`：面向研究者的全流程路径图、当前位置、下一步建议、暂缓事项与退回提示。
- `quality-score.md` / `quality-score.json`：阶段得分、全流程成熟度、失败归因与修复建议。
- `runtime-capabilities.md`：当前会话的能力探测结果、工具映射与缺失清单。
- `project-rules.md`：项目根目录无适用规则文件时的项目规则存储位置。
- `agent-registry.md`：顾问路径索引（同步自 `references/agent-registry.md`）。

## 3. 标准执行流程

0. **环境与规则检查**：按 `references/runtime-adapter.md` §5 探测运行能力并写入 `_index/runtime-capabilities.md`。如需自动审计，执行 `python3 scripts/register_host_hooks.py --check` 确认注册状态。读取项目规则（若缺失，按 `references/project-rules-writing-layer.md` 写入已有规则文件标记块或 `_index/project-rules.md`）。读取 `references/install-dependencies.md`，若目标模块缺少必需依赖则终止推进并提示安装。
1. **需求解析**：提取任务目标、研究主题、输入路径、目标期刊、方法偏好及阶段线索。
2. **输入登记**：若用户提供了文件或目录路径，立即登记至 `paper-workspace/_index/input-registry.md`。
3. **模块路由**：依据 `master/routing-matrix.md` 确定主模块；结合 `master/agent-orchestration.md`、`master/output-protocol.md` 与 `master/user-journey.md` 确定顾问档位、输出规范与路径图。
4. **模块执行**：读取目标模块 `MODULE.md` 及对应阶段与参考文件并执行任务。
5. **索引与规则更新**：更新 `_index/project-state.md`、`handoff-status.md`、`paper-roadmap.md`。若本轮确认了稳定的长期选择，同步写入项目规则标记块或 `_index/project-rules.md`。
6. **质量评分**：运行 `python3 scripts/paper_master_guard.py score-project --workspace paper-workspace --json`，更新质量分文件。

## 4. 模块职责边界

| 模块 | 路径 | 职责范围 | 默认输出目录 |
|---|---|---|---|
| design | `modules/design/` | 选题、理论框架定位、跨学科头脑风暴、研究设计蓝图 | `paper-workspace/01-design/` |
| lit | `modules/lit/` | 文献检索、文献地图、空白识别、假设推导 | `paper-workspace/02-literature/` |
| outline | `modules/outline/` | 材料扫描、大纲构建、段落级写作蓝图、证据映射、缺口报告 | `paper-workspace/03-outline/` |
| analysis | `modules/analysis/` | 数据清洗、描述与诊断、基础回归、因果识别、面板与时序、机器学习与因果 ML、质性与混合方法（Stata/R/Python 模板） | `paper-workspace/04-analysis/` |
| write | `modules/write/` | 章节写作、正文净稿生成、润色、语言扫描与复杂度诊断 | `paper-workspace/05-writing/` |
| check | `modules/check/` | 全文审稿、编辑首筛、论证闭环、诚信规范、技术与期刊适配、问题退回 | `paper-workspace/05-writing/reviews/` |
| submission | `modules/submission/` | Markdown 转 Word、模板与格式核对、参考文献体例整理、投稿信与回复信 | `paper-workspace/06-submission/` |
| update | `modules/update/` | 生成待人工审核的更新包（理论框架、写作范式、方法协议、流程协议、工具模板及自更新） | `paper-workspace/07-update/` |
| mechanigraph | `modules/mechanigraph/` | 纯矢量社科机制图生成、8 类经典拓扑匹配、原图复刻与无头渲染视觉自检 | `paper-workspace/figures/` |

`analysis` 模块包含的方法族明细见 `master/routing-matrix.md`。

## 5. 参考文件索引

- **协议层（`master/`）**：`workspace-contract.md`、`routing-matrix.md`、`agent-orchestration.md`、`output-protocol.md`、`literature-review-protocol.md`、`user-journey.md`、`handoff-checklists.md`。
- **治理层（`references/`）**：`runtime-adapter.md`、`agent-software-adapters.md`、`agent-registry.md`、`agent-prompt-blocks.md`、`install-dependencies.md`、`hooks-and-evaluation.md`、`evaluation-rubric.md`、`user-question-examples.md`、`project-rules-writing-layer.md`。

## 6. 交付汇报清单

每次任务结束回复时，须明确报告以下十项：
1. 纯文本论文路径图
2. 当前所处阶段与本轮完成事项
3. 推荐下一步及原因
4. 需用户决策的事项（如有）
5. 本轮路由的主模块
6. 已登记或使用的输入路径
7. 产物的输出路径
8. 索引文件更新状态
9. 命令后及交付前审计状态（自动或手动执行情况）
10. 质量分文件路径、当前阶段分（`stage_score`）、全流程成熟度（`maturity_score`）及主要未通过项
