# Phase 02：社会科学候选条目抽取

## 顾问派发门控

抽取候选前须派发 `modules/update/agents/extraction-consultant.md`（须读取 `modules/update/references/source-types.md`、`modules/update/references/update-schema.md` 及本阶段文件）。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/extraction-consultant.md`。

## 目标

将输入材料拆解为可审核、可路由、可验证的结构化候选条目，完整保留来源路径、证据等级、适用边界与风险提示。

## 来源定级与抽取模板

依据 `modules/update/references/source-types.md` 评估来源类型与可信度，提取可迁移结构而非整段摘要复制：

- **学科知识**：概念定义、理论谱系、核心主张、机制链条、边界条件、操作化与测量、代表文献与证据、争议与竞争理论、适用场景；
- **写作范式**：适用章节/环节、写作功能、论证动作、材料组织、段落/结构模板、常见失败、交付门槛、可迁移示例；
- **方法协议**：适用方法/场景、前置条件、操作步骤、诊断/门槛、报告规范、常见失败、验证材料；
- **流程协议**：影响入口或阶段、现有流程问题、建议流程、顾问影响、输出协议影响、跨模块影响、兼容性风险；
- **工具模板**：目标脚本或模板、建议行为、输入/输出样例、人工验证命令、失败处理/回滚提示、依赖与兼容性风险；
- **`self-update`**：目标 `update` 文件、自更新理由、保留 `pending` 审核说明、目标路由与审核门控双重复核要求、静态一致性验证方式。

## 输出格式

在 `paper-workspace/07-update/evidence/` 保存来源摘录并分配稳定 `Candidate ID`供后续引用：

```markdown
# Source Extraction

## Source
- Path / URL:
- Source type:
- Evidence level:
- Extracted by:

## Candidate Items

| Candidate ID | Purpose | Source segment | Candidate title | Evidence level | Risk hint | Needs enrichment |
|---|---|---|---|---|---|---|
```

## 禁止事项

- 不得整篇原文照搬充当候选；
- 不得将单一案例经验直接上升为通用强制规则；
- 不得将尚未实现的脚本变更表述为已完成功能；
- 不得将 `self-update` 候选标记为可自动合并。
