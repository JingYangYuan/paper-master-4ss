# 07 机器学习模板：四个可执行子流程

`07-ml` 与 `phases/07-ml-and-causal-ml.md` 一一对应。只把 `ml-analysis-plan-[date].md` 点到的子流程复制进 `paper-workspace/04-analysis/scripts/07-ml/`，再按下列顺序跑：

1. `01-supervised`：弹性网／Lasso 正则化与选择路径、样本外预测（回归或分类，含校准）、无监督结构（PCA 载荷、聚类稳定性）。
2. `02-causal-ml`：post-double-selection 控制集、双重机器学习（PLR）交叉拟合、工具变量筛选与第一阶段诊断。每个因果任务都必须在基准 OLS 旁报告 ML 估计。
3. `03-heterogeneity`：CATE 分布、GATES 分组、BLP 检验、重叠诊断。
4. `04-ml-export`：`ml-wide-table.csv`、`ml-not-run-list.csv`、`ml-methods-note.md`，以及各子流程清单。

`04-ml-export` 必须在 01–03 之后跑；01–03 之间可并行。前三个子流程各有 Python、R、Stata 三份模板，第四个只有 Python 与 R（只读 CSV，Stata 侧用任一种跑）。模板只产出它真正产出过的产物；执行命令、退出码、stdout/stderr 由 Agent 记进 `run-log-[date].md`。

## 表的口径

同一子流程被多个 `--tasks` 调用时会向同名表写入。模板因此先写任务级副本 `tables/<表名>-<任务>.csv`，再把副本合并成主表 `tables/<表名>.csv`，首列记 `任务`。`04-ml-export` 优先读主表，读不到时回落到任务级副本。后跑的任务不得静默覆盖前一个任务的结果。

例外：Stata 侧 01 直接写主表、不写任务级副本（`01-supervised` 一台机器一次只跑一组任务时不必分副本）；02 的 `ml-crossfit-folds.csv` 由 Stata 直接写主表并带 `任务` 列。

## 各语言的方法覆盖差异

| 方法 | Stata | R | Python |
|---|---|---|---|
| 弹性网／Lasso／岭回归、选择路径 | 提供（官方 `lasso`/`elasticnet`） | 提供（`glmnet`） | 提供（`scikit-learn`） |
| OLS／logit／probit／Poisson 的等价基准 | 提供 | 提供（`lm`、`glm`） | 提供（`statsmodels`） |
| 树集成（随机森林、梯度提升）、置换重要性 | **不提供**；`rforest`/`cforest` 属社区包，模板不依赖。`predict-regression` 的候选模型为基准 OLS／Lasso／弹性网，置换重要性同此，报告须写明 | 视 `ranger`/`xgboost`/`gbm` 而定，未装则阻断并给安装指引 | 提供（`scikit-learn`，历史梯度提升为额外依赖） |
| PCA、K-means、聚类稳定性 | 提供（`pca`、`cluster`） | 提供（`prcomp`、`kmeans`） | 提供（`scikit-learn`） |
| PDS（post-double-selection） | 提供（手写 `lasso linear` 跑 Y、X 两方程后取并集；**不等价**于 `pdslasso` 的 post-double-selection 推断，报告摘要行注明） | 提供（`hdm::rlasso` 手工实现 Y/X 两方程） | 提供（`sklearn` 的 LassoCV 两方程） |
| DML（partially linear model） | 提供（手写交叉拟合 + `lasso linear` nuisance，按 `$ID` 分组分折；不依赖 `ddml`） | 提供（手工交叉拟合 + `glmnet`/`ranger` nuisance） | 提供（手工交叉拟合 + `scikit-learn` nuisance） |
| 挑工具变量（Lasso 选 IV） | 提供（官方 `lasso` 选 IV + `ivregress`） | 提供（`glmnet` 选 IV + `AER::ivreg`） | 提供（`sklearn` 选 IV + `linearmodels`） |
| 因果森林（CATE + honest 区间） | **不提供**；只给 GATES 与 BLP 的手工实现 | 视 `grf` 而定，未装则阻断 | 以 T-learner／S-learner 近似并注明非 honest 森林 |
| SHAP 归因 | **不提供** | 视 `shap`/`fastshap` 而定 | 视 `shap` 而定（默认不装） |

三语言的 DML 不可能逐位一致：nuisance 学习器不同（Stata 交叉拟合学习器、R 的 `glmnet`/`ranger`、Python 的 `HistGradientBoosting`），标准误口径也不同。论文正文若并列不同语言的结果，必须在表注写明学习器与 VCE；**不得**为对齐数值而更换聚类口径或改用样本内拟合。

缺装依赖的安装口径：Stata 包清单见 `templates/_shared/stata-packages.txt`，Stata 生态见 `references/stata-ecosystem-setup.md`；R 见 `references/r-ecosystem-setup.md`；Python 见 `references/python-ecosystem-setup.md`。

## 实测状态

2026-10-28 在本机用一份 1 200 × 19 的合成面板（`pid`、`year`、`outcome`、`outcome_bin`、`treatment`、`group`、`x1`–`x10`、`instrument_z1`–`z3`）逐语言跑过：

| 语言 | 已跑通 | 本机约束 |
|---|---|---|
| Python 3.12 + scikit-learn 1.5.1 + statsmodels 0.14.2 + linearmodels 6.1 | 四个子流程全部任务（`iv-lasso` 需显式传 `--iv-candidates`，否则写阻断） | 无 |
| R 4.5.3 + glmnet + fixest | 四个子流程全部任务 | 未装 `ranger`/`grf`/`xgboost`/`gbm`，树模型与因果森林按设计阻断并给安装指引 |
| Stata 18 MP | 01、02、03 | 树模型不提供（见上表）；`03-heterogeneity` 以 GATES/BLP 手写实现替代因果森林；**`04-ml-export` 无 Stata 模板**，导出只读 CSV，直接用 Python 或 R 版跑 |

三处已核实并写死的口径差异：

1. **主表列序**：Python 与 Stata 的 `ml-model-performance.csv`、`ml-causal-estimates.csv` 列序一致（首列 `任务`）；`01-supervised` 的任务级副本只由 Python／R 写，Stata 直接写主表。跨语言拼表时以变量名为准，不按列位置。
2. **变量口径**：数值列一律不进 one-hot，0/1 处理变量在三种语言里都保持单列（Python 早前会拆成 `treatment_0`/`treatment_1`，已改）。二元变量（0/1 结局、政策虚拟变量）以「取值数恰为 2」判定，不看变量名。
3. **工作根**：三个 `.do` 都按 `PROJECT_ROOT` 环境变量 → 已设的 `${PROJECT_ROOT}` global → 当前工作目录的顺序解析，并在 `cd` 失败时打印 rc 后继续；这比参考模板里 `fileexists()` 的单行写法稳健（`fileexists` 只认文件，不认目录）。

## 执行

```bash
# Python
python3 templates/07-ml/01-supervised/supervised_ml.py --data data.csv --dict variable-dictionary.csv \
  --out-root paper-workspace/04-analysis --tasks regularized,predict-regression

# R
Rscript templates/07-ml/02-causal-ml/causal_ml.R --data data.csv --dict variable-dictionary.csv \
  --out-root paper-workspace/04-analysis --tasks pds-controls,dml-plr
```

```text
# statamcp —— stata_run_file(
#   file_path="paper-workspace/04-analysis/scripts/07-ml/02-causal-ml/causal_ml.do",
#   working_dir="paper-workspace/04-analysis",
#   timeout=1800)
```

Stata 侧只用官方命令（`lasso`、`elasticnet`、`pca`、`cluster`、`ivregress`、`bootstrap`、Mata 手写循环），**不依赖** `pdslasso`、`ddml`、`rforest` 这三个社区包：缺包不影响执行，但上面覆盖表已如实写明哪些方法因此改了口径。

模板不做运行时条件跳过：不适用于本数据的任务块，改写时直接删掉；变量、依赖或数据结构不满足时直接报错并记入 `ml-not-run-list.csv`。未执行的任务不得出现在结果表里，也不得以占位数字进入正文。
