<!-- merged from paper-master-4ss update package 2026-11-15；来源：update 候选 C009；元数据转录自第三方应用 _index.json，只作识别线索，不作推荐 -->

# 高级方法目录（20 族 139 条）

本文件是 `quantitative-model-router.md` §12 的附件：只列可识别的方法条目（method_id / 包 / 语言 / 估计目标 / 代表文献 / 一句话用途）。分流规则写在 §12；每条方法进入论文正文前，其估计目标与关键假设必须回到对应协议核对。`—` 表示源字段缺失，未凭空填补。

**引用纪律**：本文件只作识别线索。139 条代表文献已做存在性核验（Crossref），结果见 `paper-workspace/07-update/evidence/method-catalog-verification-2026-11-15.md`：118 条命中，19 条短引文/包文档，1 条源字段为空（`rdd`）。**任何一条进入论文正文前必须自行核验**；未命中项一律按「待核验」处理。

## 附录：方法目录（20 族 139 条）

| 族 | 方法数 | 代表方法 | 估计目标 | 语言 |
|---|---|---|---|---|
| 聚束 Bunching | 2 | `bunching`, `bunching_py` | behavioral (compensated/structural) earnings elasticity — a structural parameter, NOT ATT/ATE/LATE/CATE; elast | python, r |
| 因果发现 | 4 | `abn`, `baycn`, `caugi`, `causal_validation` | DAG (conditional dependency structure); Posterior edge-state probabilities (edge direction / edge absence) of  | python, r |
| 协变量调整 | 3 | `matchit`, `weightit`, `matching` | ATE (default) / ATT / ATC / ATO / ATM / ATOS depending on method= — estimand= must be passed explicitly, and t | r |
| 双重差分 DiD | 31 | `azcausal`, `bacondecomp_r`, `badcontrols`, `causalpy`… | ATE (design-based; coincides with ATT under random timing); ATET; ATT | R, python, r, r|stata, stata |
| DSGE-VAR | 2 | `dsge_var`, `irf_matching` | DSGE structural parameters chosen to minimize a weighted distance between model-implied and empirically estima | matlab |
| 动态处理方案 DTR | 1 | `pydtr` | optimal_dynamic_treatment_regime | python |
| 异质性处理效应 HTE | 20 | `bartcause`, `bartcs`, `cate_stata`, `causaldt`… | ATE / ATT / ATC (population, sample, conditional); individual ICATE; ATE / CATE / IATE / GATE / GATES; BLP(bet | R, python, r, stata |
| 推断与标准误 | 5 | `binsreg`, `clubsandwich`, `ri2`, `sandwich`… | ATE (sharp-null hypothesis test; no CI/SE returned); Conditional expectation function E[y|x] (or a quantile /  | r, r, stata, python |
| 干扰与溢出 | 4 | `inferference`, `netchain`, `networkcausaltree`, `tnet` | Allocation-indexed population-average potential-outcome contrasts under partial interference: direct DE(alpha) | ['r'], python, r |
| 工具变量 IV | 21 | `rendo`, `shiftsharese`, `steiniv`, `bartik_weight`… | ACE, P(Y|do(X)), CRR; ATE / ATET / ATEC (recursive bivariate probit); ATE|ATT|ATU|LATE|GenLATE|PRTE (MTE-weigh | python, r, r|stata, stata |
| 局部投影 | 1 | `localprojections` | impulse response function / dynamic causal effect / ATT (LP-DiD) | python|r|stata |
| 缺失数据 | 2 | `missing_data_field_guide`, `regsensitivity` | breakdown points for the OLS coefficient beta_long (explain-away and sign-change), identified sets under bound | r|python|stata, stata |
| 功效分析 | 1 | `powerupr` | MDES / statistical power / MRSS (design-phase planning) | R |
| 断点回归 RD | 12 | `nprobust`, `qte_rd`, `ratest`, `rdcqr`… | Fisher sharp null (test) / within-window ATE (point) / LATE (fuzzy); Hypothesis-test decisions (not point esti | python|r|stata, r, r|python|stata, stata |
| 结构方程 SEM | 7 | `blavaan`, `lavaan`, `openmx`, `plssem`… | Auxiliary quantities for lavaan models (measurement-invariance test statistics, reliability/AVE, corrected fit | python, r, r|stata, stata |
| 移动份额 Shift-Share | 1 | `shifthypothesis` | constant structural effect beta (post-selection) | r|stata |
| 合成控制 | 4 | `discos_stata`, `gsynth`, `mlsynth`, `scpi` | ATT; ATT on the treated unit (random individual/unit-level effect, PI not CI); Distributional ATT (counterfact | python, r, r|python|stata, stata |
| 靶向最大似然 TMLE | 7 | `ltmle`, `npcausal`, `origami`, `pytmle`… | ATE (also EY1/EY0, ATT, ATC, RR, OR, CDE, MSM parameters); ATE|ATT|LATE|IV-bounds|dose-response|incremental-in | R, python, r |
| 增益模型 Uplift | 4 | `scikit_uplift`, `tools4uplift`, `uplift_modeling`, `upliftml` | CATE; uplift (CATE for binary outcome) | python, r |
| 向量自回归 VAR | 7 | `bsvars`, `bvar`, `statsmodels_var`, `svars`… | Posterior distribution of reduced-form VAR coefficients and covariance, and the derived impulse responses, for | matlab, python, r, stata |

合计 **139** 个方法条目，覆盖 20 个方法族。


### 聚束 Bunching（2）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `bunching` | bunching | r | elasticity of taxable income (bunching a | Saez (2010) doi:10.1257/pol.2.3.180; Kle | bunching: Estimate the elasticity of taxable/reported income from excess mass ("bunching") at tax kinks and no |
| `bunching_py` | bunching-python (Python port of R  | python | behavioral (compensated/structural) earn | Saez (2010); Kleven and Waseem (2013) | Bunching estimation of behavioral elasticities (bunching-py, a Python port of the R `bunching` package by Mavr |

### 因果发现（4）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `abn` | abn | r | DAG (conditional dependency structure) | Kratzer et al. (2023) | abn (Additive Bayesian Networks) for structure / causal discovery in R: learns a directed acyclic graph (DAG)  |
| `baycn` | baycn | r | Posterior edge-state probabilities (edge | Martin & Fu (2023) | baycn performs approximate Bayesian inference of the edge states of a directed acyclic graph (DAG): its primar |
| `caugi` | caugi | r | covariate-adjustment identification (gra | Richardson & Spirtes (2002); Meek (1995) | caugi is an R toolkit (S7 front-end + Rust/extendr backend) for building and reasoning about causal graphs — D |
| `causal_validation` | causal-validation | python | falsification p-value / treatment-effect | Abadie, Diamond & Hainmueller (2010); Le | Simulate synthetic panel data with known ground-truth treatment effects and validate synthetic-control / DID e |

### 协变量调整（3）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `matchit` | MatchIt (R) | r | ATT / ATC / ATE (method-dependent; estim | Ho, D. E., Imai, K., King, G., & Stuart, | Six matching engines (nearest, exact, coarsened exact matching, subclassification, optimal, optimal full) that |
| `weightit` | WeightIt (R) | r | ATE (default) / ATT / ATC / ATO / ATM /  | Greifer, N. (2026). WeightIt: Weighting  | Inverse probability weighting and balancing-weight methods (GLM propensity-score weighting, entropy balancing, |
| `matching` | Matching (R) | r | ATT (default) / ATE / ATC — same default | Sekhon, J. S. (2011). Multivariate and P | Bias-corrected multivariate and propensity-score matching via Match(), plus genetic matching via GenMatch() (D |

### 双重差分 DiD（31）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `azcausal` | azcausal | python | ATT | Arkhangelsky, D., Athey, S., Hirshberg,  | Skill for Amazon's azcausal Python package: large-scale causal inference with DID, SDID, FSDID, ASDID, SNN, an |
| `bacondecomp_r` | bacondecomp | r | VWATT | Goodman-Bacon (2021) | Goodman-Bacon Decomposition: diagnostic tool that decomposes two-way fixed effects difference-in-differences e |
| `badcontrols` | badcontrols | r | ATT(g,t), event study ATT(e), overall AT | Caetano, C., Callaway, B., Payne, S., an | Difference-in-differences when conditional parallel trends requires covariates that are themselves affected by |
| `causalpy` | causalpy | python | ATT | Abadie et al. (2010), Arkhangelsky et al | CausalPy is a Python package offering 12 causal inference estimators (DID, SC, RDD, IV, etc.) with dual PyMC/s |
| `cic` | cic-hybrid | r/stata | QTE (quantile), ATT (mean) | Athey and Imbens (2006) | Changes-in-Changes (CIC) estimation for staggered adoption designs: implements Athey & Imbens (2006) quantile  |
| `condpt_covariates` | twfeweights + ptetools | r | ATT, ATT(g,t) (plus TWFE alpha as a weig | Caetano, C. and Callaway, B. (2026). Dif | Diagnoses hidden linearity bias in TWFE regressions with covariates (differencing out the unit fixed effect al |
| `contdid` | contdid | r | ATT(d)/ACRT(d) | Callaway and Goodman-Bacon (2024) | Callaway-Goodman-Bacon-Sant'Anna Difference-in-Differences with Continuous Treatment: estimates level treatmen |
| `did` | did | r | ATT(g,t) | Callaway and Sant'Anna (2021) | Callaway and Sant'Anna (2021) group-time average treatment effects for staggered difference-in-differences: es |
| `didforbigdata` | DiDforBigData | r | ATT | Setzler, DiDforBigData Theory vignette;  | Memory-efficient staggered difference-in-differences for very large panels: estimates the cohort-event average |
| `didregress` | didregress | stata | ATT/ATET | Sant'Anna, P. H. C., & Zhao, J. (2020).  | Stata's built-in Difference-in-Differences command for causal inference: estimates the Average Treatment Effec |
| `diff_diff` | diff-diff | python | ATT / ATT(g,t) / event-study ATT_es(e) | Callaway & Sant'Anna (2021); de Chaisema | diff-diff is a pure-Python DiD library (sklearn-like API, ~23 estimators): 2x2 DiD, Callaway-Sant'Anna ATT(g,t |
| `drdid` | DRDID | r | ATT | Sant'Anna, P. H. C. and Zhao, J. (2020). | Doubly robust difference-in-differences (DiD) estimators for the ATT in the canonical 2x2 design, implementing |
| `etwfe` | etwfe | r | ATT | Wooldridge (2021, 2023) | Extended Two-Way Fixed Effects (ETWFE): heterogeneity-robust difference-in-differences for staggered treatment |
| `eventstudyinteract` | eventstudyinteract v0.1 | stata | CATT_{e,l} grid and convex cohort-share  | Sun, L. & Abraham, S. (2021), Journal of | Sun & Abraham (2021) Interaction-Weighted event-study estimator for staggered DiD: estimates cohort-specific d |
| `eventstudyr` | eventstudyr 1.2.0 | R | dynamic cumulative policy-effect path de | Freyaldenhoven, Hansen, Perez Perez & Sh | Linear panel event-study estimation and visualization with the eventstudyr R package: estimates the dynamic cu |
| `fect` | fect | r | ATT | Liu, Wang & Xu (2024) AJPS | fect (Fixed Effects Counterfactual Estimators): A practical R package for panel DID that estimates ATT using a |
| `fetwfe` | fetwfe | r | ATT | Faletto (2025) arXiv:2312.05985 | Fused Extended Two-Way Fixed Effects (FETWFE) for difference-in-differences with staggered adoptions: estimate |
| `fixest` | fixest | r | ATT (sunab); conditional-mean regression | Bergé (2018); Sun and Abraham (2021) | fixest: fast estimation of linear (feols), GLM (feglm/fepois), maximum-likelihood (femlm/fenegbin/feNmlm) and  |
| `flci` | HonestDiD | r | theta = l' tau_post (partially identifie | Rambachan and Roth (2023) | Honest DiD sensitivity analysis for violations of parallel trends (Rambachan & Roth 2023): robust, partially i |
| `flexpaneldid` | flexpaneldid | stata | ATT | Dettmann, Giebler & Weyh (2020) | flexpaneldid: flexible panel difference-in-differences (DID) toolbox for treatments with individually varying  |
| `honestdid` | HonestDiD | R | Partially identified linear functional θ | Rambachan & Roth (2023), Review of Econo | HonestDiD: Credible inference for difference-in-differences under relaxed parallel trends. Implements sensitiv |
| `jwdid` | jwdid v2.201 (Fernando Rios-Avila) | stata | ATT(g,t) (cohort-time ATT) and margins-b | Wooldridge (2021, SSRN 3906345); Nagenga | Wooldridge (2021) Extended Two-Way Fixed Effects (ETWFE) / Two-Way Mundlak estimator for staggered difference- |
| `panelmatch` | PanelMatch | r | ATT/ATC/ART/ATE | Imai, Kim & Wang (2023, AJPS, DOI 10.111 | Matching Methods for Causal Inference with Time-Series Cross-Sectional Data (PanelMatch): estimates average tr |
| `panelview` | panelView | r | N/A (pre-estimation diagnostics; serves  | Mou, Liu and Xu (2023) | panelView: pre-estimation visualization and diagnostics for causal panel analysis — plots treatment status, mi |
| `pretrends` | pretrends | r | diagnostic (pretest power & conditional  | Roth (2022) | pretrends (Roth 2022): power analysis and post-pretest distortion diagnostics for pre-trends tests in differen |
| `sdid` | synthdid (R 0.0.9) / sdid (Stata a | r/stata | ATT | Arkhangelsky, Athey, Hirshberg, Imbens & | Synthetic Difference-in-Differences (SDID): a weighted two-way fixed-effects estimator of the ATT that combine |
| `stackedev` | stackedev | stata | Cengiz-style stacked event-study coeffic | No companion methods paper. Empirical or | Stata command for Cengiz-style stacked event studies under staggered treatment adoption: builds one sub-experi |
| `staggered` | staggered (v1.2.3) | r | ATE (design-based; coincides with ATT un | Roth and Sant'Anna (2023) | Efficient estimation for staggered rollout designs (Roth & Sant'Anna 2023): design-based plug-in efficient est |
| `sunab` | fixest::sunab (R) / eventstudyinte | r/stata | CATT building blocks; IW aggregates nu_g | Sun and Abraham (2021), Journal of Econo | Sun & Abraham (2021) interaction-weighted (IW) event-study estimator for staggered difference-in-differences:  |
| `twowayfeweights` | TwoWayFEWeights | r/stata | ATT (diagnostic reference only; not esti | de Chaisemartin & D'Haultfœuille (2020,  | Estimation of the weights attached to Two-Way Fixed Effects regressions. Decomposes the TWFE coefficient into  |
| `xtdidregress` | didregress/xtdidregress (didregres | stata | ATET | StataCorp [CAUSAL] didregress manual; Do | Stata built-in command family (Stata 17+) for difference-in-differences (DID) and triple-differences (DDD) est |

### DSGE-VAR（2）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `dsge_var` | Dynare 6.0 (dsge_var / dsge_varlag | matlab | VAR coefficients and DSGE structural par | Del Negro, M., & Schorfheide, F. (2004). | DSGE-VAR (Del Negro & Schorfheide 2004) estimates a vector autoregression whose prior is generated by a struct |
| `irf_matching` | Dynare (IRF matching) | matlab | DSGE structural parameters chosen to min | Christiano, L. J., Eichenbaum, M., & Eva | Impulse-response matching (IRF matching) is a limited-information, minimum-distance estimator for the deep par |

### 动态处理方案 DTR（1）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `pydtr` | pydtr | python | optimal_dynamic_treatment_regime | Wang et al. (2025); Song et al. (2015) | pydtr IqLearnReg: estimate the optimal Dynamic Treatment Regime (DTR) via Iterative Q-Learning — backward-indu |

### 异质性处理效应 HTE（20）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `bartcause` | bartCause | r | ATE / ATT / ATC (population, sample, con | Hill (2011); Chipman, George & McCulloch | Causal inference with Bayesian Additive Regression Trees (BART): flexible, nonparametric estimation of average |
| `bartcs` | bartcs | r | SATE | Kim, Tec and Zigler (2023) | bartcs: Bayesian Additive Regression Trees for Confounder Selection — jointly selects confounders and estimate |
| `cate_stata` | cate | stata | ATE / CATE / IATE / GATE / GATES | Semenova and Chernozhukov (2021); Cherno | Stata 19 `cate` command suite for heterogeneous treatment-effect estimation under unconfoundedness: estimates  |
| `causaldt` | causalDT | R | Subgroup ATE tau^(g) = E[Y(1) - Y(0) / G | Huang, Tang & Kenney (2025), arXiv:2502. | Estimate and interpret heterogeneous treatment effects with Causal Distillation Trees (CDT): a flexible "teach |
| `causalforest` | causalForest | r | CATE | Athey & Imbens (2016); Wager & Athey (20 | causalForest (v0.9.0, Athey-Kong-Wager 2015, built on rpart): causal trees and forests for heterogeneous treat |
| `causalml` | causalml | python | CATE / ITE / ATE / uplift / LATE (compli | Chen et al. (arXiv:2002.11631); per-esti | causalml (Uber): a multi-estimator Python toolkit for uplift modeling and heterogeneous treatment effect (HTE  |
| `causalwins` | causalWins | r | tau_star (individual-level causal win pr | Even & Josse (2025), arXiv:2501.16933 | causalWins: causal Win Ratio / Net Benefit / Win Proportion for hierarchical (prioritized) outcomes, estimatin |
| `cre` | CRE | r | CATE (ATE + rule-specific AATE) | Bargagli-Stoffi, Cadei, Lee & Dominici ( | Causal Rule Ensemble (CRE) for interpretable discovery and inference of heterogeneous treatment effects: a two |
| `evalhte` | evalHTE | r | GATE | Li and Imai (2023) | evalHTE evaluates heterogeneous treatment effects (HTE) in randomized experiments: grouped average treatment e |
| `fast_causal_shap` | fast-causal-shap | python | Causal SHAP feature attribution (per-ins | Ng, Wang, Liu and Fan (2025) | Causal SHAP feature attribution (Ng et al., 2025) implemented in the fast-causal-shap package: decomposes a fi |
| `findit` | FindIt | r | CATE / ATE (SVM-Het) ; AME / AMIE (Causa | Imai & Ratkovic (2013) ; Egami & Imai (2 | FindIt (R) is a hybrid causal-inference package that bundles TWO independent heterogeneous-treatment-effect me |
| `genericml` | GenericML | r | BLP(beta_1, beta_2) / GATES(gamma_k) / C | Chernozhukov, Demirer, Duflo and Fernánd | GenericML: Generic Machine Learning inference on heterogeneous treatment effects in randomized experiments. Es |
| `grf` | grf | r | CATE (+ conditional mean, conditional LA | Athey, Tibshirani and Wager (2019) | grf (Generalized Random Forests): a forest-based toolkit for non-parametric heterogeneous treatment effect est |
| `grf_py` | skgrf | python | CATE τ(x), conditional LATE τ(x), condit | Athey, Tibshirani & Wager (2019), "Gener | Generalized Random Forests in Python via `skgrf` (scikit-generalized-random-forests): a Cython binding to the  |
| `maq` | maq | r | Q(B) — multi-armed Qini curve (policy va | Sverdrup, Wu, Athey, Wager (2025) | Multi-Armed Qini Curves (maq): estimates Q(B), the expected ATE-denominated gain of the budget-constrained opt |
| `metalearners` | metalearners | python | CATE | Kuenzel, Sekhon, Bickel and Yu (2019); N | metalearners (QuantCo): estimates Conditional Average Treatment Effects (CATE) from observational or experimen |
| `opl_stata` | opl | stata | CATE | Cerulli (2025) | opl (Optimal Policy Learning, Cerulli): a 13-command Stata suite that turns estimated treatment effects into w |
| `policytree` | policytree | r | best-in-class (depth-k tree) max-welfare | Zhou, Athey & Wager (2023); Athey & Wage | policytree: policy learning via doubly-robust empirical welfare maximization (EWM) over shallow decision trees |
| `root` | ROOT | r | TATE / WTATE (Target / Weighted Target A | Parikh et al. (2025) | ROOT (Rashomon Set of Optimal Trees) learns an interpretable binary weight function w(X) in {0,1} — a sparse d |
| `stochtree` | stochtree | r | E[f(x)] (regression) / CATE tau(x) (caus | He & Hahn (2023) JASA; Hahn, Murray & Ca | stochtree: stochastic tree ensembles (BART, XBART grow-from-root acceleration, Bayesian Causal Forest, and clo |

### 推断与标准误（5）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `binsreg` | binsreg (R 2.2 / Stata 2.2 / Pytho | r, stata, py | Conditional expectation function E[y/x]  | Cattaneo, Crump, Farrell & Feng (2024, A | binsreg supplies the inference half of a binned scatter: a defensible bin count (binsregselect), pointwise int |
| `clubsandwich` | clubSandwich | r | Var(beta-hat) — sampling variance of the | Pustejovsky and Tipton (2018); Tipton an | clubSandwich (R) computes cluster-robust "sandwich" variance-covariance estimators with small-sample correctio |
| `ri2` | ri2 | r | ATE (sharp-null hypothesis test; no CI/S | Gerber & Green (2012, ISBN 978-039397995 | ri2 (Randomization Inference) for randomized experiments: computes exact, distribution-free p-values for a SHA |
| `sandwich` | sandwich | r | VAR[theta-hat] (sampling covariance matr | Zeileis (2004, 2006); Zeileis, Koll & Gr | sandwich (R) computes robust/heteroscedasticity-, autocorrelation-, and cluster-consistent covariance matrix e |
| `wildrwolf` | wildrwolf | r | FWER-adjusted p-values (multiple-hypothe | Clarke, Romano & Wolf (2020) [Stata blue | wildrwolf (v0.7.0, R): fast Romano–Wolf family-wise-error-rate (FWER) correction of p-values across many simul |

### 干扰与溢出（4）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `inferference` | inferference | r | Allocation-indexed population-average po | Saul & Hudgens (2017), J Stat Softw 82(2 | inferference estimates population-average CAUSAL EFFECTS UNDER PARTIAL (TWO-STAGE) INTERFERENCE using group-le |
| `netchain` | netchain | r | P(Y(a)=y) — counterfactual collective/jo | Ogburn, Shpitser & Lee (2018) | netchain fits a conditional log-linear chain-graph model by MLE and runs a Gibbs g-formula to estimate causal  |
| `networkcausaltree` | NetworkCausalTree | ['r'] | leaf-specific CACE (CATE under clustered | Bargagli-Stoffi et al. (2025). Heterogen | WHAT: Discovers and estimates heterogeneous treatment AND spillover effects under Clustered Network Interferen |
| `tnet` | TNet | python | dose-response psi(t,z); AME; ASE; ATE | Chen, Cai, Yang, Qiao, Yan, Li and Hao ( | TNet: doubly robust causal effect estimation under networked interference via targeted (TMLE-style) learning.  |

### 工具变量 IV（21）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `rendo` | REndo | r | Structural coefficient(s) on the endogen | Gui, Meierer, Algesheimer & Schilter (20 | Fit linear models with endogenous regressors WITHOUT external instruments via six internal-instrument (IIV) es |
| `shiftsharese` | ShiftShareSE | r | Shift-share (Bartik) regression coeffici | Adao, Kolesar and Morales (2019) | Exposure-robust AKM/AKM0 standard errors and confidence intervals for shift-share (Bartik) regressions and IV. |
| `steiniv` | SteinIV | r | Structural coefficient beta in y = X*bet | Hansen (2017), Econometric Reviews | Semi-parametric Stein-like (SPS) shrinkage IV combining OLS, TSLS and JIVE for the structural coefficient beta |
| `bartik_weight` | bartik.weight | r/stata | diagnostic (Rotemberg weights) over an I | Goldsmith-Pinkham, Sorkin & Swift (2020) | Rotemberg-weight decomposition of the Bartik/shift-share IV estimate into per-industry just-identified IV esti |
| `bpbounds` | bpbounds | r | ACE, P(Y/do(X)), CRR | Balke & Pearl (1997); Palmer et al. (201 | Balke-Pearl nonparametric sharp bounds for the average causal effect under a binary instrumental-variable mode |
| `budgetivr` | budgetIVr | r | Partial identification set (bounds) on c | Penn et al. (2025), AISTATS 2025 | Partial identification of causal effects from summary statistics with mostly-invalid instruments under a budge |
| `drlate` | drlate | r | LATE (compliers) and LATT (treated compl | Sloczynski, Uysal & Wooldridge (2022, ar | Doubly robust estimation of LATE and LATT with a binary instrument, plus an Abadie-kappa weighting menu. |
| `econml` | econml | python | CATE/LATE/ITT/optimal-policy | Chernozhukov et al. (2018); Syrgkanis et | Heterogeneous treatment-effect toolkit (>30 estimators incl. IV+ML) estimating CATE/LATE with ML nuisances and |
| `estimatr` | estimatr | r | LATE (iv_robust 2SLS coefficient; ATE /  | No founding 2SLS paper ships with estima | Fast design-based estimators for R; primary estimator iv_robust runs 2SLS with HC2/CR2 robust standard errors. |
| `fejiv` | fejiv | r | structural coefficient delta_0 (LATE-typ | Chao, Swanson & Woutersen (2023) | Fixed-effect jackknife IV (FEJIV) that stays consistent under many weak instruments where 2SLS is biased. |
| `iv_sensemakr` | iv.sensemakr | r | Local Average Treatment Effect (LATE) vi | Cinelli & Hazlett (2025), Biometrika 112 | Omitted-variable-bias sensitivity analysis (robustness values, bias-adjusted bounds) for just-identified IV es |
| `ivdiag` | ivDiag | r | LATE | Lal, Lockhart, Xu & Zu (2024) | Weak-instrument diagnostics toolkit for 2SLS/LATE: first-stage F variants, Anderson-Rubin, effective F, tF, lo |
| `ivdml` | IVDML | r | structural partially-linear IV coefficie | Scheidegger, Guo & Buhlmann (2025) | Double machine learning with instruments and heterogeneity: learns an optimal instrument (mlIV) for the partia |
| `ivmodel` | ivmodel | r | structural IV effect beta (constant/homo | Kang et al. (2021) | Inference and sensitivity for the linear IV model with one endogenous variable: k-class estimation, AR/CLR wea |
| `ivmte` | ivmte | r | ATE/ATT/ATU/LATE/GenLATE/PRTE (MTE-weigh | Mogstad, Santos & Torgovitsky (2018) | Marginal treatment effect (MTE) extrapolation and partial identification of a chosen target parameter for bina |
| `ivreg` | ivreg | r | structural linear-IV coefficient (LATE u | none (package: Fox, Kleiber & Zeileis 20 | Instrumental-variables regression by 2SLS (plus robust 2SM/2SMM) with weak-IV, Wu-Hausman and Sargan diagnosti |
| `ivreghdfe` | ivreghdfe | stata | structural IV coefficient (within/partia | Baum, Schaffer & Stillman (2007) - ivreg | IV/2SLS/LIML/GMM2S with high-dimensional fixed effects absorbed via reghdfe, joined to the ivreg2 diagnostic s |
| `linearmodels` | linearmodels | python | structural coefficient beta on endogenou | Hansen (1982); Newey & Smith (2004); Whi | linearmodels IV module: IV2SLS/IVLIML/IVGMM/IVGMMCUE and AbsorbingLS with robust covariance and a full IV diag |
| `propertee` | propertee | r | SATE (primary; also ETT/ETC, overlap-wei | arXiv:2406.10473 (Wang & Hansen 2024); a | Design-based direct-adjustment (standardization) framework for RCTs, observational studies and regression disc |
| `rbiprobit` | rbiprobit | stata | ATE / ATET / ATEC (recursive bivariate p | Coban (2021) Stata Conference; Greene (2 | Fits the Gaussian recursive bivariate probit model in Stata for a binary outcome with an endogenous binary tre |
| `ssaggregate` | ssaggregate | r | none (aggregation/instrument constructio | Borusyak, Hull and Jaravel (2022) | Exposure-weighted aggregation of location-level data into shock-level aggregates for shift-share (Bartik) IV d |

### 局部投影（1）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `localprojections` | localprojections-suahjl (0.2.1) /  | python/r/sta | impulse response function / dynamic caus | Jordà (2005); Jordà & Taylor (2024); Gon | Local Projections (LP) impulse-response and dynamic-causal-effect estimation for time-series and panel data, p |

### 缺失数据（2）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `missing_data_field_guide` | none (method/practice guide) | r/python/sta | varies by entry — the guide's discipline | Gietner, B. (2026). A Field Guide to Mis | Routing guide over twenty-two recurring 'the data you need isn't there' problems (P01-P22): for each, the avai |
| `regsensitivity` | regsensitivity (Stata) | stata | breakdown points for the OLS coefficient | Masten, M. A. and Poirier, A. (2026). Th | Explain-away vs sign-change breakdown points for Oster's delta: the sign-change point is provably at most 1 wi |

### 功效分析（1）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `powerupr` | PowerUpR | R | MDES / statistical power / MRSS (design- | Dong & Maynard (2013), JREE 6(1):24-67 | Statistical power, minimum detectable effect size (MDES), and minimum required sample size (MRSS) analysis for |

### 断点回归 RD（12）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `nprobust` | nprobust | python/r/sta | Nonparametric conditional mean m(x)=E[Y/ | Calonico, S., Cattaneo, M. D. & Farrell, | General-purpose nonparametric kernel estimation with robust bias-corrected (RBC) inference: kernel density est |
| `qte_rd` | QTE.RD | r | delta(tau/z) — conditional QTE at the cu | Qu, Z. and Yoon, J. (2025). QTE.RD: An R | Local-linear quantile treatment effect (QTE) estimation under the SHARP regression discontinuity design, follo |
| `ratest` | RATest | r | Hypothesis-test decisions (not point est | Canay, I. A. & Kamat, V. (2018). Approxi | RATest 0.1.10: Randomization & Permutation Tests for RDD covariate balance, k-sample tests, and distributional |
| `rdcqr` | rdcqr | r | Sharp: local ATE at the cutoff, tau_SRD  | Huang, X. & Zhan, Z. (2022). Local Compo | Estimate the local treatment effect at a regression-discontinuity (RD) cutoff using local composite quantile r |
| `rdd` | — | — | — | — | Use this skill for regression discontinuity design (RDD) analysis in R with the archived CRAN package `rdd` v0 |
| `rddensity_r` | rddensity | r | density discontinuity f(c+) - f(c-) at a | Cattaneo, Jansson, and Ma (2020) | rddensity (R): manipulation / sorting testing in regression discontinuity designs via local-polynomial density |
| `rddensity_stata` | rddensity | stata | density-discontinuity f(c+) - f(c-) | Cattaneo, Jansson and Ma (2020, JASA) | rddensity is the Stata implementation of the Cattaneo-Jansson-Ma (2020) local polynomial density estimator for |
| `rddtools` | rddtools | r | Sharp: local ATE at the cutpoint, tau_SR | Imbens & Lemieux (2008); Imbens & Kalyan | End-to-end Regression Discontinuity Design (RDD) workflow in R with the rddtools package (v2.0.2, Stigler & Qu |
| `rdhte` | — | r/python/sta | — | Calonico, Cattaneo, Farrell, Palomba & T | Multi-language toolkit (R / Python / Stata) for estimating and conducting inference on treatment effect hetero |
| `rdlocrand` | rdlocrand | r | Fisher sharp null (test) / within-window | Cattaneo, Frandsen & Titiunik (2015); Ca | rdlocrand: local-randomization inference for regression discontinuity (RD) designs. Treats the RD score inside |
| `rdmulti` | rdmulti | r/python/sta | cutoff-specific / pooled / weighted RD e | Cattaneo, Titiunik & Vazquez-Bare (2020, | rdmulti: RD designs with multiple cutoffs (rdmc) or multiple scores (rdms), plus multi-cutoff RD plots (rdmcpl |
| `rdpower` | rdpower | r | RD power / required sample size / minimu | Cattaneo, Titiunik and Vazquez-Bare (201 | rdpower: Power, sample-size, and minimum-detectable-effect (MDE) calculations for regression-discontinuity (RD |

### 结构方程 SEM（7）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `blavaan` | blavaan | r | Posterior distributions of SEM measureme | Merkle, E. C., & Rosseel, Y. (2018). bla | blavaan (R) fits Bayesian structural equation models — Bayesian CFA, full SEM with latent regressions, and lat |
| `lavaan` | lavaan | r | Measurement and structural parameters (f | Rosseel, Y. (2012). lavaan: An R Package | lavaan (R) fits latent-variable structural equation models — CFA, full SEM with latent regressions and indirec |
| `openmx` | OpenMx | r | SEM parameters under user-specified matr | Neale, M. C., Hunter, M. D., Pritikin, J | OpenMx (R) is a fully programmable structural equation modeling engine in which models are built either from p |
| `plssem` | seminr (R) / plssem (Stata) | r/stata | Composite-based path coefficients and ou | Venturini, S., & Mehmetoglu, M. (2019).  | Partial Least Squares Structural Equation Modeling (PLS-SEM) via seminr (R) and plssem (Stata). Estimates comp |
| `sem_stata` | sem/gsem (Stata built-in) | stata | Measurement and structural parameters of | StataCorp. Stata Structural Equation Mod | Stata's built-in sem and gsem commands fit structural equation models by maximum likelihood. sem fits linear S |
| `semopy` | semopy | python | SEM measurement and structural parameter | Igolkina, A. A., & Meshcheryakov, G. (20 | semopy (Python) is the main full structural-equation-modeling package in Python. It fits measurement + structu |
| `semtools` | semTools | r | Auxiliary quantities for lavaan models ( | Jorgensen, T. D., Pornprasertmanit, S.,  | semTools (R) is the standard companion package to lavaan. It does not fit a new kind of model — it computes au |

### 移动份额 Shift-Share（1）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `shifthypothesis` | shifthypothesis | r/stata | constant structural effect beta (post-se | Apfel (2024); Apfel & Liang (2024) | shifthypothesis: hypothesis testing and invalid-instrument selection for shift-share (Bartik) IV designs — dec |

### 合成控制（4）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `discos_stata` | disco (DiSCos_stata) | stata | Distributional ATT (counterfactual distr | Gunsilius (2023); Gunsilius and Van Dijc | Distributional Synthetic Controls (DiSCo) for causal inference in Stata: estimates the counterfactual *distrib |
| `gsynth` | gsynth | r | ATT | Xu (2017) | gsynth: Generalized Synthetic Control for panel/TSCS causal inference. Imputes treated-unit counterfactuals wi |
| `mlsynth` | mlsynth | python | ATT | multiple (see References) | mlsynth is a hybrid synthetic-control / difference-in-differences / experimental-design toolbox: it unifies 58 |
| `scpi` | scpi (R 4.0.1) / scpi_pkg (Python  | r/python/sta | ATT on the treated unit (random individu | Cattaneo, Feng & Titiunik (2021, JASA);  | scpi: Synthetic Control with prediction intervals and uncertainty quantification. Estimates the treatment effe |

### 靶向最大似然 TMLE（7）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `ltmle` | ltmle | r | Intervention-specific mean E_0(Y_d) / AT | Lendle, Schwab, Petersen, van der Laan ( | ltmle: Longitudinal Targeted Maximum Likelihood Estimation — doubly robust, semiparametric-efficient estimatio |
| `npcausal` | npcausal | r | ATE/ATT/LATE/IV-bounds/dose-response/inc | Kennedy et al. (2015, 2017, 2019, 2020,  | npcausal (Edward H. Kennedy) is a nonparametric / doubly-robust causal inference toolkit for R. It estimates i |
| `origami` | origami | r | cross_validated_risk / oracle_selector | Coyle and Hejazi (2018) | origami: a generalized cross-validation FRAMEWORK for R — it does not estimate a fixed parameter; it maps an a |
| `pytmle` | pytmle | python | counterfactual absolute risk (CIF) / eve | Guski, Aborageh & Fröhlich (2025), PyTML | pytmle — Targeted Maximum Likelihood Estimation (TMLE) for causal inference with survival and competing-risks  |
| `sherlock` | sherlock | R | CATE/GATE per segment; threshold set T;  | Hejazi, Zheng & Anand (2021), arXiv:2111 | Causal machine learning for population segment discovery with the R package sherlock 0.2.0 (Netflix): doubly r |
| `tmle` | tmle | r | ATE (also EY1/EY0, ATT, ATC, RR, OR, CDE | Gruber and van der Laan (2012) | Targeted Maximum Likelihood Estimation for causal inference: two-stage, doubly robust, semiparametric-efficien |
| `txshift` | txshift | r | counterfactual mean under additive shift | Díaz & van der Laan (2012); Hejazi et al | txshift (R) — TMLE and one-step estimation of the counterfactual mean of an outcome under an additive modified |

### 增益模型 Uplift（4）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `scikit_uplift` | scikit-uplift | python | CATE | Jaskowski and Jaroszewicz (2012); Lo (20 | scikit-uplift (sklift) is a Python toolkit for uplift modeling / heterogeneous treatment effect (HTE) estimati |
| `tools4uplift` | tools4uplift | r | uplift (CATE for binary outcome) | Belbahri, Murua, Gandouet & Partovi Nia  | Uplift modeling / heterogeneous treatment effect targeting in R with the tools4uplift package: estimates the i |
| `uplift_modeling` | scikit-uplift | python | CATE | Jaskowski and Jaroszewicz (2012); Lo (20 | scikit-uplift (import `sklift`) meta-model uplift toolkit: estimates the Conditional Average Treatment Effect  |
| `upliftml` | upliftml | python | CATE | Künzel et al. (2019); Nie & Wager (2021) | UpliftML (Booking.com) heterogeneous treatment effect / uplift modelling toolkit: estimates the Conditional Av |

### 向量自回归 VAR（7）

| method_id | 包 | 语言 | 估计目标 | 代表文献 | 一句话用途 |
|---|---|---|---|---|---|
| `bsvars` | bsvars | r | Posterior distribution of the structural | Wozniak, T. bsvars: Bayesian Estimation  | bsvars (R) performs fast Bayesian estimation of Structural Vector Autoregressions via a Gibbs sampler written  |
| `bvar` | BVAR | r | Posterior distribution of reduced-form V | Kuschnig, N., & Vashold, L. (2021). BVAR | BVAR (R) estimates hierarchical Bayesian vector autoregressions with a conjugate Normal-Inverse-Wishart Minnes |
| `statsmodels_var` | statsmodels (tsa.vector_ar) | python | Reduced-form VAR/VECM coefficients and,  | Seabold, S., & Perktold, J. (2010). stat | statsmodels.tsa.vector_ar is the Python-native VAR toolchain — it estimates reduced-form VAR(p) models by equa |
| `svars` | svars | r | Structural impact matrix B and the resul | Lange, A., Dalheimer, B., Herwartz, H.,  | svars (R) identifies structural VAR models from the statistical properties of the reduced-form residuals inste |
| `var_stata` | var/svar/vec (Stata built-in) | stata | Reduced-form VAR/VECM coefficients and,  | StataCorp. Stata Time-Series Reference M | Stata's built-in time-series command family — `var`, `varbasic`, `svar`, `vec` — estimates reduced-form VARs b |
| `var_toolbox` | VAR-Toolbox (v4.0) | matlab | Reduced-form VAR coefficients and struct | Cesa-Bianchi, A. VAR Toolbox. https://gi | VAR-Toolbox (Ambrogio Cesa-Bianchi, MATLAB/Octave) estimates reduced-form VARs by equation-by-equation OLS and |
| `vars` | vars | r | Reduced-form VAR coefficients and, after | Pfaff, B. (2008). VAR, SVAR and SVEC Mod | vars (R, Bernhard Pfaff) estimates reduced-form VAR models by equation-wise OLS and turns them into structural |

---
