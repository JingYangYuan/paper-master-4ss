#!/usr/bin/env python3
"""Supervised ML: regularized selection, prediction, and unsupervised structure tasks.

Tasks (--tasks 里任选，留空则全跑):
  regularized         L1/L2/弹性网筛变量，报选中清单与系数路径
  predict-regression  连续因变量的样本外预测性能
  predict-binary      二分类的样本外性能、校准与置换重要性
  structure           PCA 降维与 K-means 聚类（造指标、造分组）

纪律（见 phases/07-ml-and-causal-ml.md §6 执行门槛）：
  - 预处理一律在折内拟合：Pipeline 套在 cross_validate / fit 内部完成。
  - 面板或分组数据按个体切分，不按行随机切；时间序列按时间点切。
  - 测试集只评估一次，调参在训练折内做。
  - 只报实际跑出的数；跑不动就写阻断，不写占位结果。
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

TASKS = ["regularized", "predict-regression", "predict-binary", "structure"]


def _feature_columns(df, roles):
    wanted = [roles.x] + list(roles.controls) + [roles.heterogeneity, roles.moderator]
    return common.unique_existing(wanted, df.columns)


def _split(df, roles, seed: float, test_size: float = 0.3):
    from sklearn.model_selection import GroupShuffleSplit, train_test_split

    if roles.id and roles.id in df.columns:
        splitter = GroupShuffleSplit(n_splits=1, test_size=test_size, random_state=int(seed))
        train_idx, test_idx = next(splitter.split(df, groups=df[roles.id]))
        return df.iloc[train_idx], df.iloc[test_idx], f"按 {roles.id} 分组切分（GroupShuffleSplit）"
    if roles.time and roles.time in df.columns:
        ordered = df.sort_values(roles.time)
        cut = int(len(ordered) * (1 - test_size))
        return ordered.iloc[:cut], ordered.iloc[cut:], f"按 {roles.time} 时间前后切分（不回望未来）"
    train, test = train_test_split(df, test_size=test_size, random_state=int(seed))
    return train, test, "按行随机切分（截面数据）"


def _pipeline(model, numeric: list[str], categorical: list[str]):
    from sklearn.compose import ColumnTransformer
    from sklearn.impute import SimpleImputer
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import OneHotEncoder, StandardScaler

    pre = ColumnTransformer(
        [
            ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
            ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")),
                              ("oh", OneHotEncoder(handle_unknown="ignore", sparse_output=False))]), categorical),
        ],
        remainder="drop",
    )
    return Pipeline([("pre", pre), ("model", model)])


def _column_kinds(df, features: list[str]):
    """按 dtype 分数值与分类列。

    数值列（含 0/1 哑变量）一律当数值，不展开成 one-hot：与 Stata 模板的
    `global C "x2 x3 …"` 口径一致，也不会把 0/1 处理变量拆成 treatment_0/
    treatment_1 两个列名（这种列名在正文和表里都无法解释）。
    """
    import pandas as pd

    numeric, categorical = [], []
    for col in features:
        kind = df[col].dtype.kind
        if kind in "ifu" and not pd.api.types.is_bool_dtype(df[col]):
            numeric.append(col)
        else:
            categorical.append(col)
    return numeric, categorical


def _fmt(value):
    try:
        return f"{float(value):.3f}"
    except (TypeError, ValueError):
        return str(value)


def task_regularized(df, roles, args, numeric, categorical, out, task: str):
    """L1/L2/弹性网：报选中变量、系数与人手设定的控制集的差异。"""
    import numpy as np
    from sklearn.linear_model import ElasticNetCV, LogisticRegressionCV

    features = _feature_columns(df, roles)
    y = roles.y
    if not features or y not in df.columns:
        raise RuntimeError("regularized: 缺少角色变量，先补 variable-discovery-pack")
    tau = df.dropna(subset=[y])
    rows, selected = [], []

    if roles.outcome_bin and roles.outcome_bin == y:
        model = LogisticRegressionCV(penalty="l1", solver="saga", cv=5, max_iter=5000,
                                     scoring="roc_auc", random_state=args.seed)
        kind = "L1 逻辑回归"
    else:
        model = ElasticNetCV(l1_ratio=[0.1, 0.5, 0.9, 1.0], cv=5, max_iter=10000,
                             random_state=args.seed)
        kind = "弹性网（含 Lasso 端点）"

    pipe = _pipeline(model, numeric, categorical)
    x = tau[features]
    yv = tau[y].astype(float if kind != "L1 逻辑回归" else int)
    pipe.fit(x, yv)

    fitted = pipe.named_steps["model"]
    names = pipe.named_steps["pre"].get_feature_names_out()
    coefs = np.ravel(fitted.coef_)
    for name, coef in zip(names, coefs):
        clean = str(name).split("__", 1)[-1]
        keep = abs(coef) > 1e-8
        selected.append({"variable": clean, "coefficient": _fmt(coef), "selected": "是" if keep else "否",
                         "model": kind})
    rows.append({
        "模型": kind,
        "惩罚参数": _fmt(getattr(fitted, "alpha_", "n/a")),
        "l1_ratio": _fmt(getattr(fitted, "l1_ratio_", "n/a")) if hasattr(fitted, "l1_ratio_") else "1.0",
        "候选特征数": len(features),
        "选中特征数": sum(1 for r in selected if r["selected"] == "是"),
        "样本量": len(tau),
    })
    common.write_csv(common.task_table(out, "ml-selected-variables", task), selected,
                     ["variable", "coefficient", "selected", "model"])
    common.write_csv(common.task_table(out, "ml-regularization-path", task), rows, list(rows[0].keys()))
    return {"表": ["tables/ml-selected-variables.csv", "tables/ml-regularization-path.csv"],
            "摘要": f"{kind}，候选 {len(features)} 个特征，选中 {rows[0]['选中特征数']} 个。"}


def task_predict(df, roles, args, numeric, categorical, out, task: str):
    """回归／二分类预测：基准线性模型 + 2 个 ML 候选，报样本外指标与校准。"""
    import numpy as np
    from sklearn.ensemble import HistGradientBoostingClassifier, HistGradientBoostingRegressor
    from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
    from sklearn.inspection import permutation_importance
    from sklearn.linear_model import LinearRegression, LogisticRegression
    from sklearn.metrics import (accuracy_score, brier_score_loss, mean_absolute_error,
                                 mean_squared_error, r2_score, roc_auc_score)

    features = _feature_columns(df, roles)
    y = roles.y
    # 二分类任务优先用 role=outcome_bin 的列；否则退回主因变量再做取值检查
    if task == "predict-binary" and getattr(roles, "outcome_bin", None):
        y = roles.outcome_bin
    if not features or y not in df.columns:
        raise RuntimeError(f"{task}: 缺少角色变量")
    if task == "predict-binary" and df[y].nunique(dropna=True) > 2:
        raise RuntimeError(f"{task}: 因变量 {y} 取值 {df[y].nunique(dropna=True)} 类，不是二分类任务")
    data = df.dropna(subset=[y])
    train, test, split_note = _split(data, roles, args.seed)
    numeric, categorical = _column_kinds(data, features)

    if task == "predict-binary":
        y_train = train[y].astype(int)
        y_test = test[y].astype(int)
        models = {
            "基准 Logit（MLE）": LogisticRegression(C=1e6, max_iter=5000),
            "随机森林": RandomForestClassifier(n_estimators=300, min_samples_leaf=5,
                                              random_state=int(args.seed), n_jobs=-1),
            "梯度提升（HistGB）": HistGradientBoostingClassifier(random_state=int(args.seed)),
        }
    else:
        y_train = train[y].astype(float)
        y_test = test[y].astype(float)
        models = {
            "基准 OLS": LinearRegression(),
            "随机森林": RandomForestRegressor(n_estimators=300, min_samples_leaf=5,
                                             random_state=int(args.seed), n_jobs=-1),
            "梯度提升（HistGB）": HistGradientBoostingRegressor(random_state=int(args.seed)),
        }

    perf, calib, imp, fitted_models = [], [], [], {}
    for name, model in models.items():
        pipe = _pipeline(model, numeric, categorical)
        pipe.fit(train[features], y_train)
        fitted_models[name] = pipe
        pred_train = pipe.predict(train[features])
        pred_test = pipe.predict(test[features])
        if task == "predict-binary":
            prob = pipe.predict_proba(test[features])[:, 1]
            perf.append({
                "模型": name, "样本外 AUC": _fmt(roc_auc_score(y_test, prob)),
                "样本外 Brier": _fmt(brier_score_loss(y_test, prob)),
                "样本外准确率": _fmt(accuracy_score(y_test, (prob >= 0.5).astype(int))),
                "训练集准确率": _fmt(accuracy_score(y_train, pipe.predict(train[features]))),
                "训练样本": len(train), "测试样本": len(test),
            })
            from sklearn.calibration import calibration_curve
            frac_pos, mean_pred = calibration_curve(y_test, prob, n_bins=10, strategy="quantile")
            for i, (mp, fp) in enumerate(zip(mean_pred, frac_pos), start=1):
                calib.append({"模型": name, "分箱": i, "平均预测概率": _fmt(mp), "实际正例比例": _fmt(fp)})
        else:
            perf.append({
                "模型": name,
                "样本外 RMSE": _fmt(np.sqrt(mean_squared_error(y_test, pred_test))),
                "样本外 MAE": _fmt(mean_absolute_error(y_test, pred_test)),
                "样本外 R2": _fmt(r2_score(y_test, pred_test)),
                "训练集 R2": _fmt(r2_score(y_train, pred_train)),
                "训练样本": len(train), "测试样本": len(test),
            })

    best_pipe = fitted_models["梯度提升（HistGB）"]
    perm = permutation_importance(best_pipe, test[features], y_test, n_repeats=5,
                                  random_state=int(args.seed), scoring=None)
    for name, mean, sd in zip(features, perm.importances_mean, perm.importances_std):
        imp.append({"variable": name, "置换重要性均值": _fmt(mean), "标准差": _fmt(sd)})
    imp.sort(key=lambda r: -float(r["置换重要性均值"]))

    common.write_csv(common.task_table(out, "ml-model-performance", task), perf, list(perf[0].keys()))
    if calib:
        common.write_csv(common.task_table(out, "ml-calibration", task), calib, list(calib[0].keys()))
    common.write_csv(common.task_table(out, "ml-variable-importance", task), imp, list(imp[0].keys()))
    return {
        "表": [f"tables/ml-model-performance.csv"] + (["tables/ml-calibration.csv"] if calib else [])
              + ["tables/ml-variable-importance.csv"],
        "摘要": f"{task}：折分方式＝{split_note}；特征 {len(features)} 个；候选模型 {len(models)} 个。",
        "注意": "置换重要性衡量模型依赖，不是因果贡献；对外声称请按 C30 写边界。",
    }


def task_structure(df, roles, args, numeric, categorical, out):
    """PCA 与 K-means：造综合指标、造分组，报到残差方差与解稳定性。"""
    import numpy as np
    from sklearn.cluster import KMeans
    from sklearn.decomposition import PCA
    from sklearn.metrics import silhouette_score

    features = common.unique_existing(list(roles.controls) + [roles.x], df.columns)
    if len(features) < 2:
        raise RuntimeError("structure: 候选特征少于 2 个，无法降维或聚类")
    numeric, categorical = _column_kinds(df, features)
    pipe = _pipeline(PCA(n_components=min(5, len(features))), numeric, categorical)
    x = df[features].dropna()
    pipe.fit(x)
    pre = pipe.named_steps["pre"].transform(x)
    pca = PCA(n_components=min(5, pre.shape[1])).fit(pre)
    rows = [{"主成分": f"PC{i+1}", "解释方差比例": _fmt(v), "累计解释方差": _fmt(c)}
            for i, (v, c) in enumerate(zip(pca.explained_variance_ratio_,
                                          np.cumsum(pca.explained_variance_ratio_)))]
    common.write_csv(common.task_table(out, "ml-structure-pca", "structure"), rows, list(rows[0].keys()))

    cluster_rows = []
    best = None
    n_sil = min(len(pre), 3000)  # 轮廓系数是 O(n^2)，大样本上抽样子集计算
    for k in (2, 3, 4, 5):
        if len(pre) <= k:
            continue
        km = KMeans(n_clusters=k, n_init=10, random_state=int(args.seed)).fit(pre)
        sil = (silhouette_score(pre[:n_sil], km.labels_[:n_sil]) if k < n_sil else float("nan"))
        cluster_rows.append({"解数K": k, "组内平方和": _fmt(km.inertia_), "轮廓系数": _fmt(sil),
                             "最小组占比": _fmt(np.bincount(km.labels_).min() / len(pre))})
        if best is None or sil > float(best["轮廓系数"]):
            best = cluster_rows[-1]
    common.write_csv(common.task_table(out, "ml-structure-cluster", "structure"), cluster_rows,
                     list(cluster_rows[0].keys()))
    return {"表": ["tables/ml-structure-pca.csv", "tables/ml-structure-cluster.csv"],
            "摘要": f"PCA 前两主成分累计解释 {rows[min(1, len(rows)-1)]['累计解释方差']}；"
                    f"K 解按轮廓系数选 {best['解数K'] if best else 'n/a'}。"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Supervised ML templates (paper-analysis-4ss / 07-ml)")
    common.add_common_args(parser)
    parser.add_argument("--seed", type=float, default=20261024, help="随机种子")
    parser.add_argument("--test-size", type=float, default=0.3, help="测试集比例")
    args = parser.parse_args()

    out = common.paths(args.out_root)
    if not args.data or not Path(args.data).exists():
        msg = f"缺少分析数据：{args.data!r}；先跑 02-clean-describe 产出 analysis-data.csv"
        common.write_markdown(out["reports"] / f"ml-blocked-01-supervised-{date.today()}.md",
                              "ML 执行阻断：01-supervised", {"阻断原因": msg})
        print(msg, file=sys.stderr)
        return 1

    df = common.load_data(args.data)
    roles = common.infer_roles(df, getattr(args, "dict_path", None))
    numeric, categorical = _column_kinds(df, _feature_columns(df, roles))
    results, done = {}, []

    dispatch = [
        ("regularized", lambda: task_regularized(df, roles, args, numeric, categorical, out, "regularized")),
        ("predict-regression", lambda: task_predict(df, roles, args, numeric, categorical, out, "predict-regression")),
        ("predict-binary", lambda: task_predict(df, roles, args, numeric, categorical, out, "predict-binary")),
        ("structure", lambda: task_structure(df, roles, args, numeric, categorical, out)),
    ]
    for name, fn in dispatch:
        if not common.task_enabled(args, name):
            continue
        try:
            results[name] = fn()
            done.append(name)
        except Exception as exc:  # noqa: BLE001 — 阻断要落盘，不让进程静默失败
            results[name] = {"阻断": f"{type(exc).__name__}: {exc}"}

    # 任务级副本合并成主表：不合并的后果是后跑的任务默默盖掉前一个任务的结果
    merged = [common.merge_task_tables(out, base) for base in (
        "ml-selected-variables", "ml-regularization-path", "ml-model-performance",
        "ml-calibration", "ml-variable-importance", "ml-structure-pca", "ml-structure-cluster",
    )]
    merged = [p.name for p in merged if p is not None]

    sections = {"运行口径": f"数据 `{args.data}`；种子 {args.seed:g}；测试集比例 {args.test_size:g}；"
                            f"实际执行任务 {', '.join(done) or '无'}。",
                "任务级表与主表": ("任务级副本：tables/ml-<表名>-<任务>.csv；"
                                    f"本次合并出的主表：{', '.join(merged) or '无'}。"
                                    "主表列取各任务的并集，首列为来源任务，空单元表示该任务未产此字段。")}
    for name in TASKS:
        if name in results:
            item = results[name]
            sections[name] = ("\n".join(f"- {k}：{v}" for k, v in item.items())
                              if isinstance(item, dict) else str(item))
    sections["可声称边界"] = ("预测性能支持对样本外预测能力的陈述；变量重要性与选中变量清单不支持因果解释。"
                              "因果结论须走 02-causal-ml 并满足其识别假设（C30）。")
    common.write_markdown(out["reports"] / f"ml-run-01-supervised-{date.today()}.md",
                          "ML 执行摘要：01-supervised", sections)
    print(f"[07-ml/01-supervised] 完成：{', '.join(done) or '无任务'}；报告见 "
          f"{out['reports'] / f'ml-run-01-supervised-{date.today()}.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
