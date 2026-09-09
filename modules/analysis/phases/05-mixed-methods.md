# Phase 05: 混合方法整合

## 0. 顾问派发闸门

进入混合方法整合前，必须派发或复用 `modules/analysis/agents/qual-mixed-consultant.md`，复核定量发现与质性主题的整合逻辑、案例选择、编码变量化和 joint display 呈现。意见必须写入 `agent-synthesis-analysis-[YYYY-MM-DD].md` 后再生成整合矩阵。

## 1. 设计类型

| 类型 | 用法 |
|---|---|
| QUANT -> qual | 回归结果发现模式，质性材料解释机制 |
| qual -> QUANT | 质性材料生成构念，定量数据检验推广性 |
| convergent | 定量与质性并行，比较收敛和分歧 |
| embedded | 一个方法嵌入另一个设计中 |

## 2. QUANT -> qual

从回归结果选择案例：

- 典型案例：残差接近 0，用于确认机制。
- 偏离案例：残差绝对值大，用于发现遗漏机制。
- 极端案例：Y 或 X 最高/最低。
- 异质性案例：不同群体、地区、时期。

输出案例选择表：case_id、选择理由、对应定量结果、拟解释机制。

## 3. qual -> QUANT

把编码转变量：

- 二元变量：某编码是否出现。
- 计数变量：某编码出现次数。
- 强度变量：无/弱/中/强。
- 类型变量：根据主题组合形成类型。

所有转换必须保留编码到变量的映射表，说明信息损失和解释边界。

## 4. Joint Display

输出整合矩阵：

| 定量发现 | 质性主题/证据 | 关系 | 综合解释 |
|---|---|---|---|
| X 与 Y 正相关 | 受访者描述 X 如何促进 Y | 收敛 | 机制得到支持 |
| Z 不显著 | Z 很少被提及 | 收敛 | Z 可能不是关键解释 |
| W 负相关 | 访谈称 W 有帮助 | 分歧 | 可能存在测量或情境差异 |

关系可写：收敛、互补、扩展、分歧。

## 5. 写作规则

- 不把质性引文当作统计代表性证据。
- 不把回归显著性当作机制证明。
- 混合方法段落必须解释两类证据如何相互校准。
- 分歧发现要保留，不强行调和。

## 5.1 整合脚本执行门槛

生成 joint display、案例选择表或编码变量化脚本后，必须立即实际执行（涉及 Stata 时走 statamcp 的 `stata_run_file`）：

```bash
python3 "paper-workspace/04-analysis/scripts/mixed-methods.py"
# 或
Rscript "paper-workspace/04-analysis/scripts/mixed-methods.R"
```

执行结果写入 `paper-workspace/04-analysis/reports/run-log-[date].md`，记录命令、退出码、stdout/stderr 路径、joint display、code-to-variable map 和整合报告。未执行成功时，不得声称定量与质性结果已经完成整合。

## 6. 输出文件

- `tables/joint-display-[slug]-[date].csv/.docx`
- `qual/coded-data/code-to-variable-map-[slug]-[date].csv`
- `reports/mixed-methods-results-[slug]-[date].md`
