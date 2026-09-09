# Review Rubric

每个候选更新都必须保持 `pending`，由研究者人工判断。update 模块不得自动合并、不得输出 `accepted` 状态的候选包。

## 风险等级

| Risk tier | 目标面 | 审核要求 |
|---|---|---|
| low | `knowledge-reference` | 来源、证据、目标、边界和语言风格清楚 |
| medium | `workflow-protocol` | 额外说明兼容影响、agent/phase 影响、跨模块交接 |
| high | `tooling-template`, `self-update` | 额外提供人工验证命令、失败风险、回滚提示和双重审核（self-update） |

## 必查项

| 项目 | 通过标准 |
|---|---|
| 来源清楚 | 有路径、题名、作者、URL 或材料说明 |
| 证据充分 | 学科知识和方法协议经过文献或方法手册补充；写作范式有可迁移依据 |
| 目标正确 | 指向 `target-registry.md` 和 `targets/*.md` 中允许的模块、目标面和文件 |
| 边界明确 | 标出适用学科、论文类型、期刊范式、方法边界或执行环境 |
| 风险可见 | 标出争议、过时、证据薄弱、执行失败或兼容风险 |
| 表述可合并 | 语言风格与目标模块一致，不是原文摘抄 |
| 兼容性明确 | medium/high 候选说明对入口、phase、agent、模板或脚本的影响 |
| 验证方式明确 | high 候选包含人工验证命令、样例或检查清单 |
| 自更新安全 | self-update 候选包含双重审核，且不跳过 pending 状态 |

## 决策状态

- `pending`：待审核。update 模块只能生成此状态。
- `accepted`：研究者人工审核后可合并。
- `revise`：需要改写、补证据、改目标或补验证。
- `rejected`：不进入核心模块。

## 阻断规则

- 候选内容试图直接修改核心文件。
- 候选状态不是 `pending`。
- high 风险候选没有 `Required validation`。
- self-update 候选没有双重审核记录。
- 目标文件不在 `target-registry.md` 或模块 target 文件允许范围内。
