# Phase 05：混合方法整合

## 0. 顾问派发门控

进入混合方法整合前，须派发或复用 `modules/analysis/agents/qual-mixed-consultant.md`，复核定量发现与质性主题的整合逻辑、案例选择、编码变量化与 `joint display` 呈现，并将意见写入 `agent-synthesis-analysis-[YYYY-MM-DD].md` 后生成整合矩阵。

## 1. 混合研究设计类型

| 设计类型 | 整合用途 |
|---|---|
| `QUANT -> qual` | 先通过定量回归识别经验模式，再选取典型/偏离案例用质性材料解释机制 |
| `qual -> QUANT` | 先通过质性材料提炼构念或测量维度，再以定量数据检验推广性 |
| `convergent` | 定量与质性并行实施，通过整合矩阵比较收敛、互补与分歧 |
| `embedded` | 将一种分析路径嵌套于另一主导设计中提供辅助证据 |

## 2. `QUANT -> qual` 案例选择逻辑

依据定量回归结果与残差分布选取质性案例（输出案例选择表：`case_id`、选择理由、对应定量结果、拟解释机制）：
- **典型案例**：回归残差接近 `0`，用于验证主路径机制；
- **偏离案例**：残差绝对值较大，用于发现遗漏机制或反例条件；
- **极端案例**：核心解释变量 `X` 或因变量 `Y` 处于极大/极小值；
- **异质性案例**：覆盖不同群体、区域或时期。

## 3. `qual -> QUANT` 编码变量化

将质性编码转化为定量分析变量（二元出现指示、频次计数、强度等级 `无/弱/中/强`、主题组合类型），均须保存「编码—变量映射表」，并写明信息压缩损失与外推边界。

## 4. Joint Display 整合矩阵

| 定量发现 | 质性主题 / 证据 | 整合关系 | 综合解释 |
|---|---|---|---|
| `X` 与 `Y` 显著正相关 | 受访者阐明 `X` 触发 `M` 进而影响 `Y` | 收敛 | 传导机制获双向支持 |
| `Z` 系数不显著 | 访谈材料中 `Z` 极少作为核心动因出现 | 收敛 | `Z` 非主导解释路径 |
| `W` 呈负相关 | 访谈称 `W` 具有正向作用 | 分歧 | 须核查测量口径差异或特定情境边界 |

整合关系限定标注：`收敛`、`互补`、`扩展`、`分歧`。

## 5. 混合整合写作约束

- 不得以少数质性引文充当统计代表性证据，亦不得以回归显著性直接替代质性机制过程证明；
- 段落须阐明两类证据如何相互校准、限定或补充；
- 出现分歧发现时如实保留并讨论成因，严禁隐匿或强行调和。

## 6. 脚本执行门槛与输出文件

生成 `joint display`、案例选择表或编码变量化脚本后须立即执行（Stata 经 `statamcp` 的 `stata_run_file`），并记入 `run-log-[date].md`：

```bash
python3 "paper-workspace/04-analysis/scripts/mixed-methods.py"
# 或
Rscript "paper-workspace/04-analysis/scripts/mixed-methods.R"
```

未执行成功前不得声称已完成整合。标准输出路径：
- `paper-workspace/04-analysis/tables/joint-display-[slug]-[date].csv` / `.docx`
- `paper-workspace/04-analysis/qual/coded-data/code-to-variable-map-[slug]-[date].csv`
- `paper-workspace/04-analysis/reports/mixed-methods-results-[slug]-[date].md`
