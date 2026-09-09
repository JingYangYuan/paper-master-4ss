# Phase 02: 社会科学候选抽取

## 顾问派发闸门

候选抽取前，必须派发 `modules/update/agents/knowledge-extraction-consultant.md`。该顾问必须读取 `modules/update/references/source-types.md`、`modules/update/references/update-schema.md` 和本 phase。意见写入 `paper-workspace/_logs/agents/update-[YYYY-MM-DD]/knowledge-extraction-consultant.md`。

## 目标

将来源材料拆解为可审核、可路由、可验证的候选更新项。候选项可以是理论知识、写作范式、方法协议、流程协议、工具模板或 self-update，但都必须保留来源、证据等级、适用边界和风险。

## 来源类型

按 `modules/update/references/source-types.md` 判断来源类型和风险。不得把普通摘要直接作为候选条目；必须抽取可迁移结构。

## 抽取字段

### 学科知识

- 概念定义
- 理论谱系
- 核心主张
- 机制链条
- 边界条件
- 操作化与测量
- 代表文献与证据
- 争议与竞争理论
- 适用研究场景

### 写作范式

- 适用章节或环节
- 写作功能
- 论证动作
- 材料组织方式
- 段落或结构模板
- 常见失败模式
- 质量门槛
- 可迁移示例

### 方法协议

- 适用方法或场景
- 前置条件
- 操作步骤
- 诊断或质量门槛
- 报告规范
- 常见失败模式
- 验证材料

### 流程协议

- 影响入口或 phase
- 现有流程问题
- 建议流程
- agent 影响
- 输出协议影响
- 跨模块影响
- 兼容性风险

### 工具模板

- 目标脚本或模板
- 建议行为
- 输入样例
- 输出样例
- 人工验证命令
- 失败处理或回滚提示
- 依赖或兼容性风险

### Self-update

- 目标 update 文件
- 为什么需要自更新
- 不绕过 pending 审核的说明
- 目标路由复核要求
- 审核门控复核要求
- 模拟路由或静态一致性验证方式

## 输出

在 `paper-workspace/07-update/evidence/` 中保存来源摘要或证据摘录，在后续 proposed-diffs 中使用 `Candidate ID` 引用。

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

## 反模式

- 不得把整篇材料原样摘抄为候选。
- 不得把单个案例经验直接提升为通用规则。
- 不得把脚本变更写成已实现功能。
- 不得把 self-update 候选写成可自动合并。
