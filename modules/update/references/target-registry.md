# Target Registry

本注册表定义 `paper-master-4ss` 全包候选更新的目标模块、目标面、风险等级和模块级参考文件。update 模块只能生成待审核候选包，不得直接修改任何目标文件。

## 目标面

| Target surface | 目录或文件 | 风险等级 | 说明 |
|---|---|---|---|
| `knowledge-reference` | `frame/`, `chapters/`, `references/`, `resources/`, `examples/` | low | 知识条目、写作范式、方法协议、格式规范、范文说明 |
| `workflow-protocol` | `SKILL.md`, `phases/`, `agents/` | medium | 入口规则、phase 流程、agent 职责和质量门控 |
| `output-contract` | `master/output-protocol.md`, `master/workspace-contract.md`, `master/literature-review-protocol.md`, `modules/outline/references/output-formats.md`, `modules/write/SKILL.md`, `modules/write/scripts/assemble_drafts.py` | high | 段落级大纲、正文净稿、综述净稿落点和投稿前置稿的跨模块输出契约 |
| `tooling-template` | `scripts/`, `templates/` | high | 可执行脚本、代码模板、Word 模板、命令协议 |
| `self-update` | `modules/update/**` | high | update 模块自身协议、schema、agent、目标注册和审核门控 |

## 模块目标表

| Target module | 目标参考 | 可用目的 | 默认目标面 | 备注 |
|---|---|---|---|---|
| design | `modules/update/references/targets/design-targets.md` | `discipline-knowledge`, `method-protocol`, `workflow-protocol` | `knowledge-reference` | 理论框架、研究设计、方法路由 |
| lit | `modules/update/references/targets/lit-targets.md` | `method-protocol`, `workflow-protocol`, `tooling-template` | `knowledge-reference` | 检索、CNKI/Scholar、综述与假设推导 |
| outline | `modules/update/references/targets/outline-targets.md` | `writing-paradigm`, `workflow-protocol` | `knowledge-reference` | 大纲模板、证据映射、质量检查 |
| analysis | `modules/update/references/targets/analysis-targets.md` | `method-protocol`, `tooling-template`, `workflow-protocol` | `knowledge-reference` | 量化、质性、混合方法、三语言模板 |
| write | `modules/update/references/targets/write-targets.md` | `writing-paradigm`, `workflow-protocol`, `tooling-template` | `knowledge-reference` | 章节标准、范文、写作扫描与路由 |
| submission | `modules/update/references/targets/submission-targets.md` | `method-protocol`, `workflow-protocol`, `tooling-template` | `knowledge-reference` | 投稿样式、引用规则、Word 导出 |
| update | `modules/update/references/targets/update-targets.md` | `self-update` | `self-update` | update 自身更新，必须双重审核 |

## 路由规则

1. 先依据 Phase 01 的 `Purpose` 选择候选模块，再读取对应目标参考。
2. 单个候选最多指向一个主目标文件；若需要多个文件，拆分为多个候选。
3. `scripts/`、`templates/`、`agents/`、`phases/`、`SKILL.md` 默认不得低于 medium 风险。
4. `self-update` 只能路由到 `update-targets.md` 列出的文件。
5. 任何目标文件不存在时，候选状态保持 `pending`，并标记 `target-unknown`。
6. 任何候选更新不得把 `outline` 的段落级写作蓝图回退为章节级大纲，也不得把 `write` 的正文净稿回退为普通 Markdown 报告格式；涉及这些规则时目标面必须标为 `output-contract`，风险等级不得低于 high。
