# 03 Regression Template Subflows

`03-regression` is split into nine executable subflows. Copy only the subflows required by `analysis-execution-plan-[date].md` into `paper-workspace/04-analysis/scripts/`, then run them in this order:

1. `00-plan-dispatch`: read the plan, write `model-decision-[date].md`, and create `regression-dispatch.json/csv`.
2. `01-main-models`: Table 1, OLS/baseline models, diagnostics, and `table2-main-regression.csv`.
3. `02-nonlinear`: Logit/Probit/Poisson/Tobit/Heckman/ordered/multinomial/count/fractional/duration models with marginal effects or predicted probabilities.
4. `03-panel`: FE/RE, Hausman, two-way fixed effects, dynamic GMM, panel IV, long-N panel, panel nonlinear models, and panel diagnostics.
5. `04-causal`: IV/2SLS/LIML/GMM, DID/event study, staggered DID, RDD, PSM/CEM/IPW/entropy balancing, and SCM.
6. `05-mechanism-heterogeneity`: mediation, mechanism, moderation, heterogeneity, group difference, threshold grid, interaction, and marginal-effect figures.
7. `06-robustness`: explicitly dispatched robustness, placebo, inference robustness, sensitivity, and standard-error, model, sample, and variable alternatives.
8. `08-spatial`: spatial weights, Moran's I, SAR/SDM cross-section and panel, and direct/indirect/total effects.
9. `07-regression-export`: aggregate products into `script-index.md`, figure index, missing-product report, and `regression-results-[date].md`.

Each subflow has Python, R, and Stata templates. The templates produce only the artifacts they actually create; execution commands, exit codes, and stdout/stderr are recorded by the agent in `run-log-[date].md`. Subflows that the plan does not require are deleted when adapting the script — templates never skip work at run time, so a missing variable or package fails loudly. Placeholder cells mean "not yet estimated"; they cannot be cited as statistical findings.

`08-spatial` keeps directory number 08 but runs **before** `07-regression-export`, because the export script aggregates all subflow products including the spatial tables.
