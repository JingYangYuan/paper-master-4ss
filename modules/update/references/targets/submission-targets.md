# Submission Targets

## 模块边界

submission 模块负责 Markdown 到 Word、格式检查、引用整理、投稿包清单、cover letter 和 response letter。候选更新不得大规模重写正文。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/submission/references/citation-rules.md` | GB/T 7714、APA、中文社会学夹注、引用缺口规则 | low |
| `knowledge-reference` | `modules/submission/references/journal-style-sociological-research.md` | 投稿样式、版式边界、报告依据 | low |
| `knowledge-reference` | `modules/submission/references/install-dependencies.md` | pandoc、python-docx、lxml 安装与验收 | low |
| `workflow-protocol` | `modules/submission/agents/*.md` | 格式、引用、投稿包顾问职责 | medium |
| `workflow-protocol` | `modules/submission/SKILL.md` | 输入优先级、导出流程、回流规则 | medium |
| `tooling-template` | `modules/submission/scripts/*.py` | docx 导出、格式检查、引用检查、模板清理 | high |
| `tooling-template` | `modules/submission/templates/*.docx` | Word reference docx 样式资产 | high |

## 路由提示

- 引用规则优先进入 `citation-rules.md`。
- 期刊或投稿样式优先进入 `journal-style-sociological-research.md`。
- 脚本候选必须提供输入稿件样例、执行命令和预期报告路径。
- docx 模板候选只能生成说明和人工替换指引，不得自动合并二进制文件。
