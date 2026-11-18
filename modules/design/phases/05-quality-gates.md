# Phase 05：交付前检查与输出规范

本文件定义 `design` 模块的五层检查门控（Layer 0–4）、文件命名与过程日志规范。门控检查依据已确认的 `research_orientation` 分别验收：非实证路径不要求变量、统计功效或回归模型，其「可操作性」体现为材料可追溯与论证可辩护；未选路径不扣分。

```text
Layer 0（路由与取向锁定） -> Layer 1（FRAME 质量） -> Layer 2（STORM 质量） -> Layer 3（DESIGN 质量） -> Layer 4（整体交付门控）
```

---

## Layer 0：路由与前置确认（入口门控）

检查时机：学科路由完成后、读取阶段文件前。

| 编号 | 检查项 | 验收标准 | 阻断条件 |
|---|---|---|---|
| L0-1 | 模式与取向锁定 | 已确认 `mode-lock` 与 `research_orientation`（混合取向须写明主次关系） | 未确认时仅做澄清，禁止生成正式报告 |
| L0-2 | 关键词与框架匹配 | 关键词经 `frame_locator.py` 匹配到对应框架与 `read_ranges` | 匹配异常时请用户确认或指定学科 |
| L0-3 | 多学科互补性 | 跨学科组合优先低冗余互补学科（如社会学+经济学优于公共管理+政治学） | 高冗余组合须调整或说明理由 |
| L0-4 | 路由记录可追溯 | 过程日志完整记录检索词、得分与实际读取行号 | 缺失时补齐日志 |

---

## Layer 1：FRAME 模式质量

检查时机：FRAME 报告生成后。

| 编号 | 检查项 | 验收标准 | 是否阻断 |
|---|---|---|---|
| L1-1 | 行号区间读取 | 已按 `frame_locator.py` 的 `read_ranges` 读取条目并记录扩展行号 | 否 |
| L1-2 | 理论定位规模 | 理论定位矩阵包含 ≥ 5 个候选理论（< 3 个阻断） | 是（< 3） |
| L1-3 | 五维评估完整 | 每个理论均含匹配度、解释潜力、机制/论证映射与边界条件 | 否 |
| L1-4 | 空白依据与覆盖 | 空白清单引用框架信息，覆盖 ≥ 2 类空白（按取向含概念/谱系/规范或语境空白） | 否 |
| L1-5 | 方向可追溯 | 推荐研究方向均能追溯至具体理论条目 | 是（无追溯） |

---

## Layer 2：STORM 模式质量

检查时机：STORM 报告生成后。

| 编号 | 检查项 | 验收标准 | 是否阻断 |
|---|---|---|---|
| L2-1 | 学科覆盖度 | 交叉扫描覆盖 ≥ 2 个学科 | 是 |
| L2-2 | 扫描维度 | 四维交叉扫描至少完成两类 | 否 |
| L2-3 | 嫁接策略与评估 | 每个嫁接方案注明策略类型，且有创新性与取向适配的可行性评估 | 是 |
| L2-4 | 候选 RQ 覆盖 | 15–20 个候选 RQs 覆盖 ≥ 4 种生成策略，要素完整 | 是 |
| L2-5 | 风险驱动复核 | 按实际风险选派顾问并写入 `agent-synthesis`（或记录 `sequential-review`/`agent-skip`） | 否 |
| L2-6 | `FATAL FLAW` 清理 | 已识别致命缺陷并将命中项移出 Top 10 | 是 |
| L2-7 | Top 10 完整性 | Top 10 RQs 均含理论嫁接来源、核心分析要素与预期贡献 | 是 |

**`FATAL FLAW` 判定条件（满足任一项即剔除）**：
1. **逻辑矛盾**：前提与拟检验/论证的结论互相矛盾；
2. **同义反复**：结论已包含在前提定义中（如套套逻辑）；
3. **不可检验 / 不可论证**：实证核心概念缺乏可操作路径，或理论/规范命题缺乏可争辩依据与文本/原则支撑；
4. **材料不存在**：所需数据或核心文本档案在可预见范围内无法获取；
5. **伦理不可行**：研究设计违反学术与受试者伦理；
6. **纯表面类比**：跨学科嫁接仅有比喻（「A 类似于 B」）而无实质传导机制或概念关联。

---

## Layer 3：DESIGN 模式质量

检查时机：DESIGN 报告生成后。

| 编号 | 检查项 | 验收标准 | 是否阻断 |
|---|---|---|---|
| L3-1 | 元数据完整 | 报告首部写明 `research_orientation` 与 `analysis_required` | 是 |
| L3-2 | 锚点清晰 | 理论框架、机制/论证链与核心要素结构明确 | 是 |
| L3-3 | 路径化设计验收 | 实证：操作化、识别策略匹配与功效论证齐备；概念：论题/概念账本/反驳齐备；规范：前提/标准/冲突/反例齐备；阐释：文本/语境/竞争诠释齐备；混合：整合关系明确 | 是 |
| L3-4 | 七项对齐检查 | 理论—方法七项对齐全部为「通过」或「需调整」 | 是（存在「不通过」） |
| L3-5 | 稳健性或竞争回应 | 实证设计覆盖 ≥ 4 类威胁；非实证设计回应最强反例或竞争诠释 | 否 |

---

## Layer 4：整体交付门控（出口门控）

检查时机：任何模式最终交付前。四项标准均须满足，任一项不通过须返回对应阶段修正：
1. **跨学科/理论连接具实质内容**：非表面类比，具备具体机制链或概念整合路径；
2. **全链路逻辑自洽**：源理论 -> 嫁接命题 -> RQ -> 研究设计完整可追溯；
3. **取向化可执行性**：实证设计可检验，理论/规范/阐释设计材料可追溯且论证可辩护；
4. **交付文件与记录完整**：报告文件、过程日志与顾问综合（或 `agent-skip` 记录）均已落盘。

---

## 输出文件与日志规范

### 报告命名与路径

```text
paper-workspace/01-design/
├── frame-report-[discipline]-[slug]-[YYYY-MM-DD].md
├── storm-report-[slug]-[YYYY-MM-DD].md
├── design-report-[slug]-[YYYY-MM-DD].md
└── full-report-[slug]-[YYYY-MM-DD].md
```

`slug` 为研究主题英文简写（≤ 20 字符、小写、连字符分隔）；日期格式 `YYYY-MM-DD`。

### 各模式必含章节（缺失即阻断）

- **FRAME**：研究主题与学科定位、理论定位矩阵（≥ 5 行）、研究空白清单（≥ 5 行）；
- **STORM**：交叉扫描矩阵、理论嫁接方案（≥ 3 个）、评估共识与 `FATAL FLAW` 处理、精炼后 Top 10 RQs；
- **DESIGN**：`research_orientation` 与 `analysis_required` 元数据、操作化/概念与材料方案、模型或论证设定、七项对齐检查；
- **FULL**：上述三部分完整内容 + 执行路线与下游交接说明。

### 过程日志格式（`paper-workspace/_logs/process-log-design-[YYYY-MM-DD].md`）

```markdown
# Process Log: design
- **Date**: YYYY-MM-DD
- **Arguments**: [raw arguments]
- **Mode**: [frame|storm|design|full]
- **Research Orientation**: [research_orientation]
- **Analysis Required**: [true|false]
- **Disciplines**: [matched disciplines]
- **Target Journal**: [if specified]

## Steps
| # | Timestamp | Step | Action | Output | Status |
|---|---|---|---|---|---|

## Quality Gates
| Gate | Passed | Issues |
|---|---|---|
| Layer 0: Routing | ✓ | — |
| Layer 1: FRAME | ✓ | — |
| Layer 2: STORM | ✓ | — |
| Layer 3: DESIGN | ✓ | — |
| Layer 4: Overall | ✓ | — |

## Summary
- **Mode / Orientation**: ...
- **Advisors**: [selected roles or agent-skip reason]
- **Outputs**: [list of output files]
```
