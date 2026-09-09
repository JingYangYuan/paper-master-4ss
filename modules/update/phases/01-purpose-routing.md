# Phase 01: 更新目的路由

## 顾问派发闸门

读取材料线索后，必须派发 `modules/update/agents/purpose-routing-consultant.md`，复核 `discipline-knowledge`、`writing-paradigm`、`method-protocol`、`workflow-protocol`、`tooling-template`、`self-update` 或 `mixed` 路由。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/purpose-routing-consultant.md`，并初始化 `agent-synthesis-update-[YYYY-MM-DD].md`。

## 目标

判断输入材料要补充的是学科知识、写作范式、方法协议、流程协议、工具模板、update 自身，还是多类混合。路由结果决定后续抽取字段、是否需要文献补强、目标模块和风险门控。

## 输入线索

| 线索 | Purpose |
|---|---|
| 理论、概念、机制、变量、测量、实证证据、学科争议 | `discipline-knowledge` |
| 引言、文献综述、方法叙事、发现组织、理论对话、结论写法、投稿回应 | `writing-paradigm` |
| 定量模型、质性编码、混合方法、检索策略、引用体例、报告规范 | `method-protocol` |
| 模块入口、phase 顺序、agent 职责、质量门控、输出协议、交接规则 | `workflow-protocol` |
| 脚本、代码模板、Word 模板、命令参数、工具运行日志、页面选择器 | `tooling-template` |
| update 模块自身的 schema、target registry、phase、agent、rubric | `self-update` |
| 同时包含多类内容 | `mixed` |

## 执行步骤

1. 读取用户提供的路径、题名、摘要、目录或材料前 200 行。
2. 提取关键词：学科、理论、方法、章节写作、目标期刊、材料类型、工具命令、目标模块、是否涉及 update 自身。
3. 输出 `purpose-routing` 表：

| Segment | Evidence | Purpose | Target hint | Confidence | Needs enrichment | Next phase |
|---|---|---|---|---|---|---|

4. 若为 `mixed`，拆成多个候选流。每个流必须有独立 `Purpose`、证据片段和后续 phase。
5. 若出现 `self-update` 线索，必须标记 `self-update: true`，后续强制进入 Phase 05 双重审核。

## 文献补强规则

- `discipline-knowledge`：默认需要 Phase 03 文献补强。
- `method-protocol`：涉及方法规范、报告标准或文献策略时需要 Phase 03。
- `writing-paradigm`：若来源是课程材料或研究笔记，建议补强；若只是本地写作习惯，标记证据等级较低。
- `workflow-protocol`、`tooling-template`、`self-update`：不以文献补强为主，重点进入 Phase 04/05 做目标和风险门控。

## 停止条件

若无法判断目的，生成一个简短问题让用户说明希望补充哪类候选：学科知识、写作范式、方法协议、流程协议、工具模板或 update 自身。
