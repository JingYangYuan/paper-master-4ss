# Check 模块目标

`paper-check-4ss` 的单一事实源是 `paper-master-4ss/modules/check/`。update 只能在 `paper-workspace/07-update/` 生成待审核候选，禁止直接修改这些文件。

| 目标面 | 可指向文件 | Purpose | 风险 |
|---|---|---|---|
| 审稿知识库 | `chapters/*.md`、`glossary.md`、`patterns.md`、`cheatsheet.md` | `writing-paradigm`、`method-protocol` | low |
| 工作流协议 | `SKILL.md`、`phases/*.md` | `workflow-protocol` | medium |
| 顾问协议 | `agents/*.md` | `workflow-protocol` | medium |

候选必须说明来源、适用边界、与10维矩阵/三档严重度/四级总体结论的兼容性、路径检查方式和人工审核动作。不得把缺证据项目从“待核验”升级为违规，不得把书中经验性建议伪装成期刊硬标准。
