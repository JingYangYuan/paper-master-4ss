# Update Schema

所有候选更新都必须先填写统一基础字段，再按候选类型补充专属字段。update 模块只能生成 `pending` 状态。

## Unified Candidate Fields

```markdown
## [Candidate Title]

- **Candidate ID**:
- **Purpose**: discipline-knowledge / writing-paradigm / method-protocol / workflow-protocol / tooling-template / self-update
- **Target module**:
- **Target surface**: knowledge-reference / workflow-protocol / tooling-template / self-update
- **Target file**:
- **Suggested location**:
- **Risk tier**: low / medium / high
- **Review status**: pending
- **Self-update**: true / false
- **Source**:
- **Evidence level**: monograph / review / empirical article / textbook / course material / method handbook / research note / local experience
- **Compatibility impact**:
- **Required validation**:
- **Risk and limitation**:
```

## Discipline Knowledge Candidate

```markdown
## [Theory / Concept Name]

- **Purpose**: discipline-knowledge
- **Target module**: design / lit / analysis
- **Target surface**: knowledge-reference
- **Review status**: pending

- **概念定义**：
- **理论谱系**：
- **核心主张**：
- **机制链条**：
- **边界条件**：
- **操作化与测量**：
- **代表文献与证据**：
- **争议与竞争理论**：
- **适用研究场景**：
- **风险与限制**：
```

## Writing Paradigm Candidate

```markdown
## [Writing Pattern Name]

- **Purpose**: writing-paradigm
- **Target module**: write / outline / submission
- **Target surface**: knowledge-reference
- **Review status**: pending

- **适用章节或环节**：
- **写作功能**：
- **论证动作**：
- **材料组织方式**：
- **段落或结构模板**：
- **常见失败模式**：
- **质量门槛**：
- **可迁移示例**：
- **风险与限制**：
```

## Method Protocol Candidate

```markdown
## [Method / Protocol Name]

- **Purpose**: method-protocol
- **Target module**: analysis / lit / design / submission
- **Target surface**: knowledge-reference
- **Review status**: pending

- **适用方法或场景**：
- **前置条件**：
- **操作步骤**：
- **诊断或质量门槛**：
- **报告规范**：
- **常见失败模式**：
- **验证材料**：
- **风险与限制**：
```

## Workflow Protocol Candidate

```markdown
## [Workflow Change Name]

- **Purpose**: workflow-protocol
- **Target surface**: workflow-protocol
- **Risk tier**: medium
- **Review status**: pending

- **影响入口或 phase**：
- **现有流程问题**：
- **建议流程**：
- **agent 影响**：
- **输出协议影响**：
- **跨模块影响**：
- **Required validation**：
```

## Tooling Template Candidate

```markdown
## [Tool / Template Change Name]

- **Purpose**: tooling-template
- **Target surface**: tooling-template
- **Risk tier**: high
- **Review status**: pending

- **目标脚本或模板**：
- **建议行为**：
- **输入样例**：
- **输出样例**：
- **人工验证命令**：
- **失败处理或回滚提示**：
- **依赖或兼容性风险**：
```

## Self Update Candidate

```markdown
## [Update Module Change Name]

- **Purpose**: self-update
- **Target module**: update
- **Target surface**: self-update
- **Risk tier**: high
- **Review status**: pending
- **Self-update**: true

- **目标文件**：
- **建议位置**：
- **为什么需要自更新**：
- **不会绕过 pending 审核的说明**：
- **target-routing-consultant 复核摘要**：
- **review-gate-consultant 复核摘要**：
- **Required validation**：
- **风险与限制**：
```
