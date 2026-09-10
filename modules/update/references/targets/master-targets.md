# Master Targets

## 模块边界

master 不是 `modules/` 下的业务模块，而是总控路由与编排面。候选更新可指向路由矩阵、顾问编排、交接清单、用户路径、智能体注册表和包根入口，但不得指向 `scripts/`，也不得把 `output-contract` 文件改入本清单。

update 只能在 `paper-workspace/07-update/` 生成待审核候选，禁止直接修改这些文件。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `master-routing` | `master/routing-matrix.md` | 用户意图消歧、主模块选择 | medium |
| `master-routing` | `master/agent-orchestration.md` | 顾问派发强度与跨模块默认链路 | medium |
| `master-routing` | `master/handoff-checklists.md` | 阶段交接清单 | medium |
| `master-routing` | `master/user-journey.md` | 用户层论文路径图 | medium |
| `master-routing` | `references/agent-registry.md` | 跨模块并行触发矩阵与路径说明 | medium |
| `master-routing` | 包根 `SKILL.md` | 总控入口与模块边界表 | medium |

## 禁止事项

- 不得指向 `scripts/`。
- 不得把 `master/output-protocol.md`、`master/workspace-contract.md`、`master/literature-review-protocol.md` 改入本表；它们属于 `output-contract`。
- 不得自动应用候选。
