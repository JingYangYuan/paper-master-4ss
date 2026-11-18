# Phase 01：更新目的路由

## 顾问派发门控

读取材料线索后，须派发 `modules/update/agents/extraction-consultant.md` 复核更新目的分类（`discipline-knowledge`、`writing-paradigm`、`method-protocol`、`workflow-protocol`、`tooling-template`、`self-update` 或 `mixed`）。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/extraction-consultant.md`，并初始化 `agent-synthesis-update-[YYYY-MM-DD].md`。

## 目标

确定输入材料待补充的知识或协议类别，从而决定后续抽取字段、是否需要文献补强、目标模块与风险门控等级。

## 目的分类线索

| 材料内容特征 | Purpose |
|---|---|
| 理论、概念、机制、变量、测量、实证证据与学科争议 | `discipline-knowledge` |
| 引言、综述、方法叙事、发现组织、理论对话、结论与审稿回应写法 | `writing-paradigm` |
| 定量模型、质性编码、混合方法、检索策略、引用体例与报告规范 | `method-protocol` |
| 模块入口、阶段顺序、顾问职责、交付检查、输出与交接协议 | `workflow-protocol` |
| 脚本、代码模板、Word 模板、命令参数、运行日志与页面选择器 | `tooling-template` |
| `update` 模块自身的 schema、目标注册表、阶段、顾问与审核规范 | `self-update` |
| 同时涵盖多类内容 | `mixed` |

## 执行步骤

1. 读取输入文件路径、题名、摘要、目录或前 200 行内容；
2. 提取学科、理论、方法、写作环节、目标期刊、工具命令、目标模块与是否涉及 `update` 自身等线索；
3. 输出 `purpose-routing` 路由表（`Segment`、`Evidence`、`Purpose`、`Target hint`、`Confidence`、`Needs enrichment`、`Next phase`）；
4. 若为 `mixed`，拆分为多个独立候选流（各有独立 `Purpose`、证据片段与后续阶段）；
5. 涉及 `self-update` 时必须标注 `self-update: true`，并在 Phase 05 执行双重审核。

## 文献补强触发规则

- `discipline-knowledge`：默认需要 Phase 03 文献补强；
- `method-protocol`：涉及方法规范、报告标准或文献策略时需要 Phase 03；
- `writing-paradigm`：来源为课程材料或笔记时建议补强；若仅为个人写作习惯，标注较低证据等级；
- `workflow-protocol`、`tooling-template`、`self-update`：不以文献补强为主，重点进入 Phase 04/05 核查目标与兼容风险。

## 中止条件

无法依据材料判定更新目的时，暂停推进并向用户提问确认具体拟更新的类别。
