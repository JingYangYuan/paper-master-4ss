#!/usr/bin/env python3
"""Causal ML: post-double-selection (PDS), partially linear DML, and Lasso instrument picking.

Tasks (--tasks 里任选，留空则全跑):
  pds-controls      PDS Lasso 挑控制变量（Belloni-Chernozhukov-Hansen 2014）
  dml-plr           部分线性 DML（Chernozhukov et al. 2018），交叉拟合 + 聚类稳健标准误
  iv-lasso          Lasso 挑工具变量，再做 2SLS，报第一阶段 F

纪律（见 phases/07-ml-and-causal-ml.md §5）：
  - 交叉拟合一折一系数，全折汇总报点估计与折间波动；只报一次拟合的 DML 等于没做。
  - 每次估计都必须与「同一控制集下的基准 OLS/2SLS」并表，差异要解释。
  - 控制集由 Lasso 选出，不等于外生性成立；PDS 只解决过拟合偏差（C28、C30）。
  - 缺依赖、缺角色就写阻断，不写占位数字。
"""

from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path


def _load_common():
    for parent in Path(__file__).resolve().parents:
        shared = parent / "_shared"
        if shared.exists():
            sys.path.insert(0, str(shared))
            import python_common  # type: ignore

            return python_common
    raise RuntimeError("Cannot locate templates/_shared/python_common.py")


common = _load_common()

TASKS = ["pds-controls", "dml-plr", "iv-lasso"]


def _features(df, roles):
    return common.unique_existing(list(roles.controls), df.columns)


def _design(df, columns):
    import pandas as pd

    x = df[columns].copy()
    cat = [c for c in columns if x[c].dtype.kind not in "ifu"]
    if cat:
        x = pd.get_dummies(x, columns=cat, drop_first=True, dtype=float)
    return x.apply(lambda s: pd.to_numeric(s, errors="coerce")).fillna(0.0)


def _folds(df, roles, k: int, seed: int):
    """交叉拟合折号：有 id 按个体分组，避免同一个体跨折；否则按行分组。"""
    import numpy as np

    if roles.id and roles.id in df.columns:
        units = df[roles.id].astype(str).to_numpy()
        uniq = np.unique(units)
        rng = np.random.default_rng(seed)
        assigned = {u: i % k for i, u in enumerate(rng.permutation(uniq))}
        return np.array([assigned[u] for u in units])
    rng = np.random.default_rng(seed)
    return rng.integers(0, k, len(df))


def _lasso_select(x, y, seed: int, alpha_grid=None):
    """返回被选中的列名；cv 用 5 折，惩罚参数由 CV 定。"""
    import numpy as np
    from sklearn.linear_model import LassoCV

    model = LassoCV(cv=5, random_state=seed, max_iter=20000)
    model.fit(x.to_numpy(), np.asarray(y, dtype=float))
    mask = np.abs(model.coef_) > 1e-10
    return list(np.array(x.columns)[mask]), float(model.alpha_)


def _ols(df, y: str, regressors: list, cluster: str | None, weights: str | None = None):
    import statsmodels.api as sm

    data = df.dropna(subset=[y])
    x = sm.add_constant(_design(data, regressors), has_constant="add")
    fit = sm.OLS(data[y].astype(float), x)
    if cluster and cluster in data.columns:
        fit = fit.fit(cov_type="cluster", cov_kwds={"groups": data[cluster]})
    else:
        fit = fit.fit(cov_type="HC1")
    return fit, data


def task_pds(df, roles, args, out):
    controls = _features(df, roles)
    if not controls:
        raise RuntimeError("pds-controls: 没有候选控制变量（--dict 的 control 角色为空）")
    data = df.dropna(subset=[roles.y, roles.x])
    x = _design(data, controls)
    sel_y, a_y = _lasso_select(x, data[roles.y].astype(float), args.seed)
    sel_x, a_x = _lasso_select(x, data[roles.x].astype(float), args.seed)
    union = sorted(set(sel_y) | set(sel_x))

    rows = []
    for label, regs in [("基准：全部候选控制变量", controls), ("PDS：并集控制集", union)]:
        fit, sample = _ols(data, roles.y, [roles.x] + regs, roles.cluster)
        coef = fit.params.get(roles.x)
        se = fit.bse.get(roles.x)
        rows.append({
            "模型": label, "处理变量系数": f"{coef:.3f}", "标准误": f"{se:.3f}",
            "t 值": f"{coef / se:.3f}" if se else "n/a",
            "p 值": f"{fit.pvalues.get(roles.x):.3f}",
            "控制变量数": len(regs), "观测值": int(fit.nobs),
            "聚类层级": roles.cluster or "HC1",
        })
    common.write_csv(common.task_table(out, "ml-causal-estimates", "pds-controls"), rows,
                     list(rows[0].keys()))
    common.write_csv(
        common.task_table(out, "ml-pds-selected-variables", "pds-controls"),
        [{"variable": v, "selected_by": "Y 方程" if v in sel_y else "", "pred_X": "是" if v in sel_x else "",
          "in_union": "是" if v in union else "否"} for v in controls],
        ["variable", "selected_by", "pred_X", "in_union"],
    )
    return {"表": ["tables/ml-causal-estimates.csv", "tables/ml-pds-selected-variables.csv"],
            "摘要": f"候选控制 {len(controls)} 个；Y 方程选中 {len(sel_y)} 个；X 方程选中 {len(sel_x)} 个；"
                    f"并集 {len(union)} 个；α_Y={a_y:.4g}，α_X={a_x:.4g}。"}


def task_dml_plr(df, roles, args, out):
    import numpy as np
    from sklearn.ensemble import HistGradientBoostingRegressor
    from sklearn.linear_model import LassoCV

    controls = _features(df, roles)
    if not controls:
        raise RuntimeError("dml-plr: 没有候选控制变量")
    data = df.dropna(subset=[roles.y, roles.x]).reset_index(drop=True)
    x = _design(data, controls)
    y = data[roles.y].astype(float).to_numpy()
    d = data[roles.x].astype(float).to_numpy()
    fold = _folds(data, roles, args.folds, args.seed)

    def learner():
        if args.learner == "lasso":
            return LassoCV(cv=5, random_state=args.seed, max_iter=20000)
        return HistGradientBoostingRegressor(random_state=args.seed)

    y_res = np.zeros_like(y)
    d_res = np.zeros_like(d)
    per_fold = []
    from sklearn.linear_model import LinearRegression

    for k in range(args.folds):
        train, test = fold != k, fold == k
        if test.sum() == 0 or train.sum() == 0:
            continue
        my = learner().fit(x[train], y[train])
        md = learner().fit(x[train], d[train])
        y_res[test] = y[test] - my.predict(x[test])
        d_res[test] = d[test] - md.predict(x[test])
        beta_fold = LinearRegression().fit(d_res[test].reshape(-1, 1), y_res[test]).coef_[0]
        per_fold.append({"折": k + 1, "折系数": f"{beta_fold:.3f}", "折样本": int(test.sum())})

    import statsmodels.api as sm

    fit = sm.OLS(y_res, sm.add_constant(d_res)).fit(cov_type="HC1")
    theta, se = float(fit.params[1]), float(fit.bse[1])
    base, _ = _ols(data, roles.y, [roles.x] + controls, roles.cluster)
    rows = [
        {"模型": "基准 OLS（全部控制）", "处理变量系数": f"{base.params.get(roles.x):.3f}",
         "标准误": f"{base.bse.get(roles.x):.3f}", "观测值": int(base.nobs),
         "备注": f"控制变量 {len(controls)} 个"},
        {"模型": f"DML-PLR（{args.learner}，{args.folds} 折交叉拟合）", "处理变量系数": f"{theta:.3f}",
         "标准误": f"{se:.3f}", "观测值": int(fit.nobs),
         "备注": "Neyman 正交 + 交叉拟合；标准误 HC1"},
    ]
    common.write_csv(common.task_table(out, "ml-causal-estimates", "dml-plr"), rows,
                     list(rows[0].keys()))
    common.write_csv(common.task_table(out, "ml-crossfit-folds", "dml-plr"), per_fold,
                     list(per_fold[0].keys()))
    return {
        "表": ["tables/ml-causal-estimates.csv", "tables/ml-crossfit-folds.csv"],
        "摘要": f"DML 点估计 {theta:.3f}（HC1 标准误 {se:.3f}），基准 OLS {base.params.get(roles.x):.3f}；"
                f"折间系数范围 {min(float(r['折系数']) for r in per_fold):.3f}–"
                f"{max(float(r['折系数']) for r in per_fold):.3f}。",
        "注意": "两列差异若无机制解释，不得写成「ML 校正了内生性」（C30）。",
    }


def task_iv_lasso(df, roles, args, out):
    import pandas as pd
    import statsmodels.api as sm
    from linearmodels.iv import IV2SLS

    if not roles.instrument:
        raise RuntimeError("iv-lasso: 缺 instrument 角色，先补变量发现包")
    if args.iv_candidates:
        candidates = [c.strip() for c in args.iv_candidates.split(",") if c.strip()]
    else:
        candidates = [c for c in df.columns
                      if c.startswith(str(roles.instrument)) or c == roles.instrument]
    candidates = [c for c in candidates if c in df.columns and c not in {roles.y, roles.x, roles.cluster}]
    if not candidates:
        raise RuntimeError("iv-lasso: 找不到工具变量候选；用 --iv-candidates 显式指定")
    data = df.dropna(subset=[roles.y, roles.x]).reset_index(drop=True)
    z = _design(data, candidates)
    d = data[roles.x].astype(float)
    sel, alpha = _lasso_select(z, d, args.seed)
    if not sel:
        raise RuntimeError("iv-lasso: 第一阶段的 Lasso 未选中任何工具变量候选")

    controls = _features(df, roles)
    exog = _design(data, controls) if controls else pd.DataFrame(index=data.index)
    exog = sm.add_constant(exog, has_constant="add")
    endog = pd.DataFrame({roles.x: d}, index=data.index)
    instr = z[sel].reset_index(drop=True)
    y = data[roles.y].astype(float)
    fit = IV2SLS(y, exog, endog, instr).fit(cov_type="robust")
    coef = float(fit.params[roles.x])
    se = float(fit.std_errors[roles.x])
    first = sm.OLS(d, sm.add_constant(instr)).fit(cov_type="HC1")
    rows = [{
        "模型": "2SLS（Lasso 挑 IV）", "处理变量系数": f"{coef:.3f}", "标准误": f"{se:.3f}",
        "第一阶段 F": f"{float(first.fvalue):.3f}", "选中工具变量数": len(sel), "观测值": int(fit.nobs),
        "备注": f"选中：{', '.join(sel[:8])}{' …' if len(sel) > 8 else ''}；α={alpha:.4g}",
    }]
    common.write_csv(common.task_table(out, "ml-causal-estimates", "iv-lasso"), rows,
                     list(rows[0].keys()))
    return {"表": ["tables/ml-causal-estimates.csv"],
            "摘要": f"选中 {len(sel)} 个工具变量候选，第一阶段 F={float(first.fvalue):.3f}；"
                    f"2SLS 点估计 {coef:.3f}（稳健标准误 {se:.3f}）。",
            "注意": "第一阶段 F 不达标时退回 03-regression/04-causal，不用 ML 硬凑工具变量。"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Causal ML templates (paper-analysis-4ss / 07-ml)")
    common.add_common_args(parser)
    parser.add_argument("--seed", type=int, default=20261024)
    parser.add_argument("--folds", type=int, default=5, help="交叉拟合折数")
    parser.add_argument("--learner", default="histgb", choices=["histgb", "lasso"],
                        help="DML 的 nuisance 学习器")
    parser.add_argument("--iv-candidates", dest="iv_candidates", default="",
                        help="逗号分隔的工具变量候选列名；留空则按 instrument 名前缀匹配")
    args = parser.parse_args()

    out = common.paths(args.out_root)
    if not args.data or not Path(args.data).exists():
        msg = f"缺少分析数据：{args.data!r}"
        common.write_markdown(out["reports"] / f"ml-blocked-02-causal-ml-{date.today()}.md",
                              "ML 执行阻断：02-causal-ml", {"阻断原因": msg})
        print(msg, file=sys.stderr)
        return 1

    df = common.load_data(args.data)
    roles = common.infer_roles(df, getattr(args, "dict_path", None))
    dispatch = [
        ("pds-controls", lambda: task_pds(df, roles, args, out)),
        ("dml-plr", lambda: task_dml_plr(df, roles, args, out)),
        ("iv-lasso", lambda: task_iv_lasso(df, roles, args, out)),
    ]
    results, done = {}, []
    for name, fn in dispatch:
        if not common.task_enabled(args, name):
            continue
        try:
            results[name] = fn()
            done.append(name)
        except Exception as exc:  # noqa: BLE001
            results[name] = {"阻断": f"{type(exc).__name__}: {exc}"}

    # 任务级副本合并成主表；单独跑一个任务时主表就是该任务的结果，不会被其他任务盖掉
    merged = [common.merge_task_tables(out, base) for base in (
        "ml-causal-estimates", "ml-crossfit-folds", "ml-pds-selected-variables",
    )]
    merged = [p.name for p in merged if p is not None]

    sections = {"运行口径": f"数据 `{args.data}`；折数 {args.folds}；nuisance 学习器 {args.learner}；"
                            f"实际执行 {', '.join(done) or '无'}。",
                "任务级表与主表": (f"本次合并出的主表：{', '.join(merged) or '无'}；"
                                    "各任务副本另存为 tables/ml-<表名>-<任务>.csv。")}
    for name in TASKS:
        if name in results:
            item = results[name]
            sections[name] = "\n".join(f"- {k}：{v}" for k, v in item.items())
    sections["识别前提"] = ("PDS 与 DML 都只在给定识别假设下成立：控制集须满足条件外生性，"
                          "DML 只处理高维控制带来的正则化偏误，不解决遗漏变量。")
    common.write_markdown(out["reports"] / f"ml-run-02-causal-ml-{date.today()}.md",
                          "ML 执行摘要：02-causal-ml", sections)
    print(f"[07-ml/02-causal-ml] 完成：{', '.join(done) or '无任务'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
