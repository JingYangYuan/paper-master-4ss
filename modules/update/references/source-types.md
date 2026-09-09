# Source Types

| 来源类型 | 抽取重点 | 适用候选 | 风险 |
|---|---|---|---|
| 学术专著 | 理论谱系、概念体系、机制链条、范式分歧 | `discipline-knowledge`, `method-protocol` | 可能缺少最新实证证据 |
| 教材 | 基础概念、范式分类、教学型结构 | `discipline-knowledge`, `writing-paradigm`, `method-protocol` | 可能过度简化或滞后 |
| 期刊论文 | 研究空白、方法、测量、证据、边界条件 | `discipline-knowledge`, `method-protocol` | 单篇证据不可直接泛化 |
| 综述论文 | 理论地图、争议、累积发现、未来方向 | `discipline-knowledge`, `method-protocol` | 需核查综述覆盖范围 |
| 课程材料 | 写作流程、教学模板、操作步骤 | `writing-paradigm`, `workflow-protocol` | 证据等级较低 |
| 研究笔记 | 本地经验、项目知识、写作技法、流程问题 | `writing-paradigm`, `workflow-protocol`, `self-update` | 必须标记为待核验 |
| 方法手册 | 操作协议、质量门槛、反模式、报告规范 | `method-protocol`, `tooling-template` | 需确认适用学科与论文类型 |
| 工具日志 | 命令、错误、运行环境、脚本输出、页面状态 | `tooling-template`, `workflow-protocol` | 需要人工复现和验证 |
| 模板样本 | Word 模板、代码模板、范文片段、格式样例 | `tooling-template`, `writing-paradigm` | 可能依赖特定项目或格式 |

优先保留可迁移结构，不保留普通摘要。任何涉及脚本、模板或 self-update 的来源都必须附验证方式。
