# Phase 04：目标面路由

## 顾问派发门控

目标面路由前须派发 `modules/update/agents/target-routing-consultant.md`，读取 `modules/update/references/target-registry.md` 与对应 `modules/update/references/targets/<module>-targets.md`。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/target-routing-consultant.md` 并同步至 `agent-synthesis-update-[YYYY-MM-DD].md`。涉及 `self-update` 时须标注 `self-update: true` 并送入 Phase 05 双重审核。

## 目标

将候选条目精确映射至 `paper-master-4ss` 内的目标模块、目标面、目标文件与建议插入位置（仅生成候选路由表与拟修改文本，不修改任何核心文件）。

## 目标面分类

| Target surface | 覆盖范围 | 典型目标位置 | 默认风险 |
|---|---|---|---|
| `knowledge-reference` | 理论、方法、写作、投稿等知识条目 | `references/`、`resources/`、`chapters/`、`frame/` | `low` |
| `workflow-protocol` | 模块入口、阶段流程、顾问职责与检查门控 | `MODULE.md`、`phases/`、`agents/` | `medium` |
| `tooling-template` | 脚本、代码模板、Word 模板与执行命令 | `scripts/`、`templates/` | `high` |
| `self-update` | `update` 模块自身协议、顾问、schema 与 rubric | `modules/update/**` | `high` |
| `master-routing` | 总控路由、交接、用户路径与跨模块矩阵 | `master/routing-matrix.md` 等 | `medium` |

## 执行步骤

1. 读取 `target-registry.md` 核对更新目的与目标模块对应关系；
2. 目的为 `self-update` 时仅读取 `targets/update-targets.md`；非 `self-update` 时按需读取 1–2 个最相关的 `targets/*.md`（不一次全量加载）；
3. 输出目标路由表（字段：`Candidate ID`、`Purpose`、`Target module`、`Target surface`、`Target file`、`Suggested location`、`Risk tier`、`Self-update`、`Required validation`）；
4. 为每条候选在 `paper-workspace/07-update/proposed-diffs/<surface>/` 下指定拟插入草案文件名；
5. 跨多个目标模块的候选条目须拆分为独立候选项，分别标明证据、目标与风险。

## 模块路由原则

- **顺序**：先定模块，再定目标面，最后定目标文件；
- **`design`**：学科理论、概念、机制与测量进 `design/frame/` 或 `design/references/`；
- **`write` vs. `check`**：写作范式与章节技法进 `write/chapters/` 或 `write/resources/`；审稿核查、反模式检验与退回规则进 `modules/check/`；
- **总控层**：路由、交接与路径图进 `master-routing`；
- **`lit` / `outline` / `analysis` / `submission`**：按各自 `references/`、`phases/`、`templates/`、`scripts/` 归位；
- **`update` 自身**：仅允许路由至 `targets/update-targets.md` 列明的目标文件。

## 草案目录与命名

```text
paper-workspace/07-update/proposed-diffs/
├── knowledge/
├── workflow/
├── agents/
├── templates/
├── scripts/
└── self-update/
```

文件名格式：`[target-module]-[target-surface]-[slug]-[date].md`。所有草案文件必须标注 `Review status: pending`。

## 阻断与回退条件

- 无法匹配目标模块：退回 Phase 01 重新定目的；
- 找不到合法目标文件：生成 `target-unknown` 候选并请求人工指定；
- 指向 `scripts/`、`templates/`、`agents/`、`phases/` 或 `MODULE.md` 却缺失 `Required validation`：暂不进入 Phase 06，先在 Phase 05 补齐验证方式。
