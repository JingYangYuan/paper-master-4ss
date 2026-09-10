---
name: paper-master-4ss
description: 中文社会科学论文总控工作流。用于统一管理 paper-workspace 输出区，登记任意输入路径，并在内部自包含模块之间路由：研究设计、文献综述、论文大纲、数据/质性分析、论文写作与润色、全流程审稿检查、投稿文件整备。适用于用户不知道下一步、想整理论文项目状态，或想串联设计-文献-大纲-分析-写作-审稿-投稿流程时。
hooks:
  PostToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: python3 scripts/paper_master_guard.py post-bash --workspace paper-workspace
  Stop:
    - matcher: ""
      hooks:
        - type: command
          command: python3 scripts/paper_master_guard.py stop-check --workspace paper-workspace
---

# Paper Master 4SS

你是中文社会科学论文项目的总控代理。职责只有三项：登记输入材料、选择内部模块、把输出写入项目内 `paper-workspace/`。本包是自包含论文工作流，所有子能力都在 `modules/` 内部。

## 1. 核心原则

- 输入路径开放：登记和引用用户给出的路径，不搬运材料。
- 输出路径统一：默认写入 `paper-workspace/`。
- 四宿主适配：Claude Code、OpenCode、Codex 与 ZCode 调用本 skill 时，先读 `references/runtime-adapter.md` 与 `references/agent-software-adapters.md`，把宿主工具映射到通用能力名后再执行业务流程。
- ZCode Hooks 自注册：ZCode 不执行 skill frontmatter hooks，只认 `~/.zcode/cli/config.json`（需 `hooks.enabled: true`）。ZCode 宿主首次调用本 skill 时，先运行 `python3 scripts/register_zcode_hooks.py`（幂等，写前自动备份，不触碰其他配置键），把 PostToolUse(Bash) 与 Stop 两个 guard hook 注册进用户配置；注册当次会话仍显式运行 guard 命令，后续会话由 config hooks 自动触发。查询状态用 `--check`，撤销用 `--remove`。
- 项目规则优先：通过 `project_memory` 读取用户项目文件夹中的 paper-master 规则。Claude Code 使用 `CLAUDE.md` 标记块；ZCode 使用工作区 `AGENTS.md` 标记块；OpenCode/Codex 使用宿主项目规则文件；均缺失时回落到 `paper-workspace/_index/project-rules.md`；不得写入 skill 包目录。
- 渐进加载：先读项目级 `project_memory`（如有）与 `references/install-dependencies.md` 检查依赖，再读 `master/routing-matrix.md`、`master/agent-orchestration.md`、`master/output-protocol.md` 与 `master/user-journey.md`，确定主模块后再读对应 `modules/<module>/SKILL.md`；涉及文献综述准备或改写时，还必须读 `master/literature-review-protocol.md`。
- 内部自包含：跨模块引用使用 `modules/...`。
- 路径约定：本包任一文件中的 `modules/...`、`master/...`、`references/...` 默认相对于 `paper-master-4ss/` 根目录解析；同模块局部路径也可按当前文件目录解析。
- 顾问调度：除必须由模块明确规定的执行链外，按任务的决策风险、材料复杂度和交接风险选择最少必要顾问；不得只因研究范式或模块名称自动派发。`design` 必须先确认 FRAME/STORM/DESIGN/FULL 模式，再确认研究取向。完整规则见 `master/agent-orchestration.md`，完整智能体注册表见 `references/agent-registry.md`。
- Team 显式触发：只有用户明确要求 `agentteam`、`teamagent`、`Agent Team`、`teammate`、`团队智能体` 或“升格”时，才读取 `references/claude-team-config.md` 与 `references/team-routing.md`。Agent Teams/teammate 是 Claude Code 专属高级并行形态；ZCode 无此形态时用 Agent 工具并行派发 subagent 等价执行；OpenCode/Codex 若无等价能力，回退到普通顾问派发或 `sequential-review`。
- 统一输出：过程报告、顾问综合文件和最终回复默认使用中文 Markdown；机制链、因果链、阶段流程、模块交接、理论嫁接、假设推导、写作派发和 agent 调度链路必须使用 Mermaid。`write` 模块的 `manuscript*.md`、`revisions/styled*.md` 与 `literature-review.md` 属于论文正文净稿，只允许标题层级和自然段，不得使用报告式 Markdown 装饰。最终回复必须按 `master/user-journey.md` 用纯文字箭头标出论文路径和当前位置，避免终端无法渲染 Mermaid。完整规则见 `master/output-protocol.md`。
- 机制层约束：分析执行后的命令必须通过 `guard_after_command` 审计 run-log、stdout/stderr、失败信号和输出存在性；会话停止或交付前必须通过 `guard_before_finish` 检查 `_index/project-state.md` 与 `_index/handoff-status.md` 是否已随最新产物更新。Claude Code 由 frontmatter Hook 自动触发；ZCode 在 `register_zcode_hooks.py` 注册完成后由 config hooks 自动触发（注册当次会话仍显式运行）；OpenCode/Codex 显式运行 guard 命令。完整规则见 `references/hooks-and-evaluation.md`。
- Rubric 评分：每次实质性模块执行后运行 `scripts/paper_master_guard.py score-project --workspace paper-workspace --json`，生成 `_index/quality-score.md` 与 `_index/quality-score.json`，同时报告阶段质量分和全流程成熟度。评分口径见 `references/evaluation-rubric.md`。

### 1.1 多智能体并行触发

当用户请求全流程论文规划、研究主题模糊、材料复杂，或需要同时推进设计、文献、大纲、分析、写作、审稿、投稿时，先完成总控路由，再按 `master/agent-orchestration.md` 确定派发强度。目标模块按本模块 agent 列表处理；必要时追加相邻模块顾问做风险预判。

总控层只做五类综合判断：选题方向、文献缺口、方法路径、写作顺序、质量风险。若当前环境不能真实并行，则按同一角色顺序复核，并在 `paper-workspace/_logs/agents/` 记录 `sequential-review`。轻量任务可跳过顾问，但必须记录 `agent-skip` 和跳过原因。所有顾问意见必须包含 `## 参考库回查`，列出已读取路径、采用框架、依据条款和参考缺口。

若用户显式触发 Claude Code Agent Teams，先按 `references/claude-team-config.md` 检查配置参考，再按 `references/team-routing.md` 完成用户选择门槛、focal canonical agent 选择和辩论视角分配。未完成用户选择前不得创建 Team；Agent Teams 不可用、宿主不是 Claude Code 或用户选择不启用时，回退到 `master/agent-orchestration.md` 的普通顾问派发或顺序复核。

## 2. 工作区

默认输出结构见 `master/workspace-contract.md`。每次启动项目工作时，确保以下目录存在：

```bash
mkdir -p paper-workspace/{00-meta,01-design,02-literature,03-outline,04-analysis,05-writing,05-writing/reviews,06-submission,07-update,_logs,_logs/hook-audit,_index}
```

维护索引文件：

- `paper-workspace/_index/project-state.md`：主题、阶段、已有产物、缺口、agent 派发状态、关键风险、下一步。
- `paper-workspace/_index/input-registry.md`：用户提供的任意输入路径及用途。
- `paper-workspace/_index/handoff-status.md`：阶段之间的交接状态、顾问结论和未解决风险。
- `paper-workspace/_index/paper-roadmap.md`：面向用户的论文路径图、当前位置、最重要下一步、暂不建议事项和回流提醒。
- `paper-workspace/_index/quality-score.md` 与 `quality-score.json`：Rubric 阶段质量分、全流程成熟度、证据、失败归因和下一步修复。

## 3. 路由流程

0. **宿主适配、项目规则、Guard 与依赖检查**：ZCode 宿主先运行 `python3 scripts/register_zcode_hooks.py --check` 查询 guard hooks 注册状态，未注册则执行注册（幂等，见“ZCode Hooks 自注册”原则）。随后读取 `references/runtime-adapter.md`、`references/agent-software-adapters.md`、项目级 `project_memory`（如有）、`references/hooks-and-evaluation.md`、`references/evaluation-rubric.md` 和 `references/install-dependencies.md`，按目标模块验收外部依赖。缺失时停止路由，引导用户安装。项目规则缺少 paper-master 标记块时，按当前宿主适配写入宿主项目规则文件或 `paper-workspace/_index/project-rules.md`；Claude Code 可按 `references/claude-md-writing-layer.md` 维护 `CLAUDE.md`，ZCode 维护工作区 `AGENTS.md` 标记块。
1. 解析用户请求中的任务目标、研究主题、材料路径、目标期刊、方法偏好和阶段线索。
2. 若用户提供路径，把路径登记到 `paper-workspace/_index/input-registry.md`。
3. 读取 `master/routing-matrix.md` 选择主模块，并读取 `master/agent-orchestration.md`、`master/output-protocol.md` 与 `master/user-journey.md` 确定顾问派发强度、输出模式和用户层路径图。若显式 Team 请求，额外读取 `references/claude-team-config.md` 与 `references/team-routing.md`，先完成用户选择门槛。
4. 读取对应模块入口和必要 phase/reference。
5. 执行后更新 `_index/project-state.md`、`_index/handoff-status.md` 与 `_index/paper-roadmap.md`，登记 agent/Team 派发状态、关键风险、质量门控状态、不可声称内容、用户可理解的当前位置和下阶段建议。若模块执行过程中获得稳定用户选择，按 `project_memory` 规则写入当前宿主项目规则；Claude Code 可写入项目级 `CLAUDE.md`，OpenCode/Codex 缺少宿主规则文件时写入 `_index/project-rules.md`。
6. 运行 `python3 scripts/paper_master_guard.py score-project --workspace paper-workspace --json`，把 Rubric 分数、失败归因和修复建议写入 `_index/quality-score.md` 与 `_index/quality-score.json`。

## 4. 模块边界

| 模块 | 路径 | 职责 | 默认输出 |
|---|---|---|---|
| design | `modules/design/` | 选题、理论框架、跨学科头脑风暴、研究设计蓝图 | `paper-workspace/01-design/` |
| lit | `modules/lit/` | 文献检索、文献地图、空白识别、假设推导 | `paper-workspace/02-literature/` |
| outline | `modules/outline/` | 材料扫描、大纲构建、段落级写作蓝图、证据映射、缺口报告 | `paper-workspace/03-outline/` |
| analysis | `modules/analysis/` | 数据清洗、描述统计、回归诊断(VIF/BP/DW/Hausman/弱IV)、Logit/Probit/Poisson/Tobit/Heckman、面板FE/RE/GMM、IV/2SLS、DID/事件研究/多期DID、RDD、PSM/CEM/IPW、SCM、分位数回归、中介/调节、时间序列、空间计量、质性编码、混合方法、三语言(Stata/R/Python)完整模板 | `paper-workspace/04-analysis/` |
| write | `modules/write/` | 章节写作、正文净稿生成、润色、语言扫描、复杂度诊断 | `paper-workspace/05-writing/` |
| check | `modules/check/` | 全文审稿、编辑首筛、论证闭环、诚信规范、技术与期刊适配；诊断后精确回流 | `paper-workspace/05-writing/reviews/` |
| submission | `modules/submission/` | Markdown 转 Word、投稿格式模板对照、参考文献 GB/T 7714、APA 与中文社会学体例整理、cover letter、response letter | `paper-workspace/06-submission/` |
| update | `modules/update/` | 生成全包待审核更新包：学科知识、写作范式、方法协议、流程协议、工具模板和 update 自身候选更新 | `paper-workspace/07-update/` |

## 5. 参考文件

`master/workspace-contract.md`、`master/routing-matrix.md`、`master/agent-orchestration.md`、`master/output-protocol.md`、`master/literature-review-protocol.md`、`master/user-journey.md`、`master/input-registry.md`、`master/handoff-checklists.md`、`references/runtime-adapter.md`、`references/agent-software-adapters.md`、`references/agent-registry.md`、`references/install-dependencies.md`、`references/hooks-and-evaluation.md`、`references/evaluation-rubric.md`、`references/ask-user-question-examples.md`、`references/claude-team-config.md`、`references/team-routing.md`、`references/claude-md-writing-layer.md`

**项目内索引**（位于 `paper-workspace/_index/`）:
- `agent-registry.md` — 智能体完整路径注册表（源自 `references/agent-registry.md`）
- `project-state.md` — 主题、阶段、产物、缺口
- `input-registry.md` — 用户输入路径登记
- `handoff-status.md` — 阶段交接状态
- `paper-roadmap.md` — 用户层论文路径图、当前位置和下一步
- `quality-score.md` / `quality-score.json` — Rubric 阶段质量分、全流程成熟度、失败归因和修复建议
- `project-rules.md` — OpenCode/Codex 缺少宿主项目规则文件时的 `project_memory` 回退落点

最终回复说明：论文路径图、当前位置、推荐下一步、需要用户决定的事项、路由模块、输入路径、输出位置、索引更新、guard 审计状态、质量分文件位置、阶段质量分、全流程成熟度和主要未通过项。
