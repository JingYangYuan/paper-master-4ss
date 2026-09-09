# Design Targets

## 模块边界

design 模块负责选题、理论框架、跨学科头脑风暴和研究设计蓝图。候选更新不得直接生成正文、数据结果或投稿文件。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/design/frame/theory-frameworks-*.md` | 理论、概念、机制、测量、争议、适用场景 | low |
| `knowledge-reference` | `modules/design/references/*.md` | 研究设计方法、方法路由、识别策略、质性/定量参考 | low |
| `workflow-protocol` | `modules/design/phases/*.md` | FRAME/STORM/DESIGN/FULL 流程、质量门控 | medium |
| `workflow-protocol` | `modules/design/agents/*.md` | 理论、方法、领域、期刊适配、致命审查顾问职责 | medium |
| `workflow-protocol` | `modules/design/SKILL.md` | 入口路由、模式确认、输出协议 | medium |
| `tooling-template` | `modules/design/scripts/frame_locator.py` | 框架检索逻辑、输出字段、命令参数 | high |

## 路由提示

- 学科理论条目优先进入对应 `frame/theory-frameworks-*.md`。
- 研究设计、识别策略、方法选择优先进入 `references/`。
- 需要改变执行顺序或门控规则时，目标面为 `workflow-protocol`。
- 涉及 `frame_locator.py` 的候选必须给出人工运行命令和预期字段。
