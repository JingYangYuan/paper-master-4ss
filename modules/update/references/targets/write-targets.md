# Write Targets

## 模块边界

write 模块负责正文写作、润色、章节标准、范文截取、写作扫描和复杂度诊断。候选更新不得替代投稿格式检查，也不得生成未来源化的论文事实。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/write/chapters/ch*.md` | 章节标准、论证动作、写作反模式、质量门槛 | low |
| `knowledge-reference` | `modules/write/resources/*.md` | 路由规则、风格子路由、术语表、技法、速查表 | low |
| `knowledge-reference` | `modules/write/examples/*.md` | 范文结构、提示词模板、示例片段 | low |
| `workflow-protocol` | `modules/write/agents/*.md` | 写作规划、草稿、论证、材料、风格、章节复核顾问职责 | medium |
| `workflow-protocol` | `modules/write/SKILL.md` | 写作流水线、扫描循环、约束规则 | medium |
| `tooling-template` | `modules/write/scripts/*.py` | 方法路由器、范文截取器、扫描器、复杂度分析器 | high |

## 路由提示

- 章节写法和论文七要素优先进入 `chapters/`。
- 跨章节风格、术语和路由规则优先进入 `resources/`。
- 示例性材料只进入 `examples/`，不得作为强制规范。
- 脚本候选必须给出命令行参数、样本文本和预期报告。
