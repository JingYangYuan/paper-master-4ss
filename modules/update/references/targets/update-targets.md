# Update Targets

## 模块边界

update 模块负责生成待审核更新包。self-update 候选可以指向 update 自身协议、schema、agent 和目标注册，但不得允许 update 自动修改自身或绕过 `pending` 审核。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `self-update` | `modules/update/SKILL.md` | update 总入口、目的分类、工作流和硬规则 | high |
| `self-update` | `modules/update/phases/*.md` | 目的路由、抽取、补强、目标路由、风险门控、审核包 | high |
| `self-update` | `modules/update/agents/*.md` | update 顾问职责、参考库回查、输出格式 | high |
| `self-update` | `modules/update/references/update-schema.md` | 候选 schema、字段、类型 | high |
| `self-update` | `modules/update/references/review-rubric.md` | 审核门槛、风险等级、决策状态 | high |
| `self-update` | `modules/update/references/source-types.md` | 来源类型、抽取重点、风险 | high |
| `self-update` | `modules/update/references/target-registry.md` 和 `targets/*.md` | 目标注册表和模块目标规则 | high |

## 双重审核

所有 self-update 候选必须包含：

1. `target-routing-consultant` 对目标模块、目标面、目标文件和建议位置的复核。
2. `review-gate-consultant` 对 pending 状态、风险等级、兼容影响和验证方式的复核。
3. `self-update: true` 字段。
4. 人工验证方式，至少包括静态一致性检查和一次模拟路由场景。

## 禁止事项

- 不得生成自动应用自身修改的命令。
- 不得把 self-update 状态写成 `accepted`。
- 不得删除 pending 审核链路。
- 不得把 `scripts/` 或外部执行逻辑作为 self-update 的默认目标。
