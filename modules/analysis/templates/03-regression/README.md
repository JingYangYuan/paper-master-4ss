# 03 Regression Template Subflows

`03-regression` is split into eight executable subflows. Copy only the subflows required by `analysis-execution-plan-[date].md` into `paper-workspace/04-analysis/scripts/`, then run them in this order:

1. `00-plan-dispatch`: read the plan, write `model-decision-[date].md`, and create `regression-dispatch.json/csv`.
2. `01-main-models`: Table 1, OLS/baseline models, diagnostics, and `table2-main-regression.csv`.
3. `02-nonlinear`: Logit/Probit/Poisson/Tobit/Heckman/ordered/multinomial models with marginal effects or predicted probabilities.
4. `03-panel`: FE/RE, Hausman, two-way fixed effects, dynamic GMM, panel IV, and panel diagnostics.
5. `04-causal`: IV/2SLS/GMM, DID/event study, staggered DID, RDD, PSM/CEM/IPW, and SCM.
6. `05-mechanism-heterogeneity`: mediation, mechanism, moderation, heterogeneity, threshold, interaction, grouped tests, and marginal-effect figures.
7. `06-robustness`: explicitly dispatched robustness, placebo, sensitivity, standard-error, model, sample, and variable alternatives.
8. `07-regression-export`: aggregate products into `script-index.md`, figure index, missing-product report, and `regression-results-[date].md`.

Each subflow has Python, R, and Stata templates. The templates write run-log entries and produce only the artifacts they actually create. Placeholder cells mean "not yet estimated"; they cannot be cited as statistical findings.
