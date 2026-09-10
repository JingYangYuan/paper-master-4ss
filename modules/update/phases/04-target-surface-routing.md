# Phase 04: 统一目标面路由

## 顾问派发闸门

目标面路由前，必须派发 `modules/update/agents/target-routing-consultant.md`。该顾问必须读取 `modules/update/references/target-registry.md`，并按候选目标模块读取 `modules/update/references/targets/<module>-targets.md`。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/target-routing-consultant.md`，并同步进入 `agent-synthesis-update-[YYYY-MM-DD].md`。

若候选项涉及 `self-update`，还必须在本 phase 标记 `self-update: true`，并进入 Phase 05 的双重审核门。

## 目标

把候选更新项路由到 `paper-master-4ss` 包内的具体目标模块、目标面、目标文件和建议位置。目标面可以是知识库、流程协议、agent 角色、模板、脚本、入口说明或 update 自身协议，但本 phase 只生成候选目标，不修改任何核心文件。

## 输入

- Phase 01 的 `purpose-routing` 表。
- Phase 02 的候选条目或抽取结果。
- Phase 03 的文献补强结果（若适用）。
- `modules/update/references/target-registry.md`。
- 对应模块的 `modules/update/references/targets/*.md`。

## 目标面类型

| Target surface | 含义 | 典型目标 | 默认风险 |
|---|---|---|---|
| `knowledge-reference` | 理论、方法、写作、投稿等知识资产 | `references/`, `resources/`, `chapters/`, `frame/` | low |
| `workflow-protocol` | 模块入口、phase、agent 调度与质量门控 | `SKILL.md`, `phases/`, `agents/` | medium |
| `tooling-template` | 脚本、代码模板、Word 模板、执行命令 | `scripts/`, `templates/` | high |
| `self-update` | update 模块自身协议、agent、schema、rubric | `modules/update/**` | high |
| `master-routing` | 总控路由、交接、用户路径与跨模块矩阵 | `master/routing-matrix.md` 等 | medium |

## 执行步骤

1. 读取 `target-registry.md`，确认候选目的可对应的目标模块。
2. 若候选目的为 `self-update`，只读取 `targets/update-targets.md`，不得路由到其他模块。
3. 若候选目的不是 `self-update`，按候选内容读取 1-2 个最相关的 `targets/*.md`，不得一次性加载全部目标参考。
4. 输出目标路由表：

| Candidate ID | Purpose | Target module | Target surface | Target file | Suggested location | Risk tier | Self-update | Required validation |
|---|---|---|---|---|---|---|---|---|

5. 为每个候选项在 `paper-workspace/07-update/proposed-diffs/<surface>/` 下生成拟插入内容文件名建议。
6. 若单个候选项跨越多个目标模块，拆分为多个候选项，分别标记证据、目标和风险。

## 路由原则

- 先选模块，再选目标面，最后选具体文件。
- 学科理论、概念、机制、测量优先路由到 `design/frame/` 或 `design/references/`。
- 写作范式、章节技法、反模式优先路由到 `write/chapters/` 或 `write/resources/`。
- 全流程审稿、编辑首筛、论证闭环、诚信规范优先路由到 `modules/check/`。
- 写作范式若属于审稿检查/反模式/回流指令则进 check，不进 write/chapters。
- master 路由/交接/用户路径图走 `master-routing`。
- 文献检索、CNKI/Scholar、综述综合、假设推导优先路由到 `lit/references/`、`lit/phases/` 或 `lit/scripts/`。
- 大纲结构、证据映射、素材扫描优先路由到 `outline/references/` 或 `outline/phases/`。
- 量化、质性、混合方法、报告规范和分析模板优先路由到 `analysis/references/`、`analysis/templates/` 或 `analysis/phases/`。
- 投稿格式、引用规则、Word 导出和投稿包复核优先路由到 `submission/references/`、`submission/scripts/` 或 `submission/templates/`。
- update 自身规则、schema、目标注册、agent 能力和审核门控只路由到 `update-targets.md` 列出的目标。

## 输出文件命名

```text
paper-workspace/07-update/proposed-diffs/
├── knowledge/
├── workflow/
├── agents/
├── templates/
├── scripts/
└── self-update/
```

候选文件名使用：

```text
[target-module]-[target-surface]-[slug]-[date].md
```

所有候选文件必须写明 `Review status: pending`，不得写 `accepted`。

## 停止条件

- 找不到目标模块：回到 Phase 01 重新判断目的。
- 找不到目标文件：生成 `target-unknown` 候选，并要求用户或研究者人工指定。
- 候选目标为 `scripts/`、`templates/`、`agents/`、`phases/`、`SKILL.md`，但没有验证方式：不得进入 Phase 06，先进入 Phase 05 补足 `Required validation`。
