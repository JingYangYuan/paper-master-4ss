# Analysis Templates

本目录按 `modules/analysis/phases/` 的执行流程组织真实可执行的三语言模板。模板是项目脚本的源材料：实际执行时，把相关脚本复制或改写到 `paper-workspace/04-analysis/scripts/`，再用 `python3`、`Rscript` 运行；Stata 统一经 statamcp 的 `stata_run_file` 执行。

## 目录

| 流程 | 目录 | 产物 |
|---|---|---|
| 初始化与路由 | `01-init/` | 目录、run-log、候选数据、CLI 检查 |
| 清洗与描述 | `02-clean-describe/` | `analysis-data.*`、`variable-dictionary.csv`、`sample-flow.csv`、`table1-descriptives.csv` |
| 回归与扩展 | `03-regression/` | dispatch、模型决策、主回归、非线性、面板、因果、机制、稳健性、汇总导出 |
| 质性分析 | `04-qual/` | 匿名化文本、分段数据、编码本、编码表、信度记录 |
| 混合方法 | `05-mixed/` | 读取真实定量表和质性编码表，生成 joint display |
| 导出门控 | `06-export/` | `script-index.md`、结果报告、质量门控清单 |

## 统一接口

Python/R 脚本采用“配置块 + CLI 参数覆盖”：

```bash
python3 templates/02-clean-describe/cleaning.py --data data.csv --out-root paper-workspace/04-analysis
Rscript templates/03-regression/01-main-models/main_models.R --data data.csv --out-root paper-workspace/04-analysis
```

Stata 脚本使用文件顶部宏配置，并保留等价参数说明；生产执行使用 `.do` 文件：

```text
# statamcp —— stata_run_file(
#   file_path="paper-workspace/04-analysis/scripts/03-regression/01-main-models/main_models.do",
#   working_dir=<.do 相对路径基准目录>, timeout=按需)
```

所有脚本必须追加 `paper-workspace/04-analysis/reports/run-log-[date].md`，并且只能声称本脚本实际生成的产物。高级方法在变量、依赖或软件许可不足时写阻断，不写空表冒充结果。
