#!/usr/bin/env python3
"""Heterogeneous policy effects: honest T-learner CATE, GATES, BLP, overlap diagnostics.

做法与依据（references/ml-causal-ml-methods.md §11）：
  T-learner（Künzel et al. 2019）分处理组／控制组各训练一个结果模型，CATE = mu1(x) - mu0(x)。
  GATES（Chernozhukov et al. 2018）：按 CATE 分位组估组平均效应，回答"对哪一群有效"。
  BLP：把 CATE 当回归量检验异质性信号是否真实存在。
  以上三项都在「样本外折」（honest split）上算，训练折只用来拟合 nuisance 模型。

纪律：
  - 没有重叠就没有个体政策建议；倾向得分贴边或叶节点样本过小的组只能报"不可识别"。
  - CATE 是模型输出，不是个体真实效应；结论停在组间差异（C29、C30）。
  - 跑不动、缺角色就写阻断，不写占位数字。
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


def _design(df, columns):
    import pandas as pd

    x = df[columns].copy()
    cat = [c for c in columns if x[c].dtype.kind not in "ifu"]
    if cat:
        x = pd.get_dummies(x, columns=cat, drop_first=True, dtype=float)
    return x.apply(lambda s: pd.to_numeric(s, errors="coerce")).fillna(0.0)


def _split_half(df, roles, seed):
    """按个体（有 id）或按行（无 id）一分为二：一半拟合 nuisance，一半做诚实评估。"""
    import numpy as np

    if roles.id and roles.id in df.columns:
        uniq = np.unique(df[roles.id].astype(str).to_numpy())
        rng = np.random.default_rng(seed)
        picked = set(rng.permutation(uniq)[: len(uniq) // 2])
        mask = df[roles.id].astype(str).isin(picked).to_numpy()
        return df[mask], df[~mask], f"按 {roles.id} 分组对半切（honest split）"
    rng = np.random.default_rng(seed)
    mask = rng.random(len(df)) < 0.5
    return df[mask], df[~mask], "按行随机对半切（honest split）"


def _nuisance_learner(seed):
    from sklearn.ensemble import HistGradientBoostingRegressor

    return HistGradientBoostingRegressor(random_state=seed)


def _pick_cjk_font():
    """找得到中文字体就用中文标签，找不到返回 None 由调用方退回英文。"""
    try:
        from matplotlib import font_manager
    except Exception:  # noqa: BLE001
        return None
    installed = {f.name for f in font_manager.fontManager.ttflist}
    for name in ("Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Source Han Sans SC", "WenQuanYi Zen Hei"):
        if name in installed:
            return name
    return None


def run(args) -> int:
    import numpy as np
    import pandas as pd
    import statsmodels.api as sm

    out = common.paths(args.out_root)
    if not args.data or not Path(args.data).exists():
        msg = f"缺少分析数据：{args.data!r}"
        common.write_markdown(out["reports"] / f"ml-blocked-03-heterogeneity-{date.today()}.md",
                              "ML 执行阻断：03-heterogeneity", {"阻断原因": msg})
        print(msg, file=sys.stderr)
        return 1

    df = common.load_data(args.data)
    roles = common.infer_roles(df, getattr(args, "dict_path", None))
    treat = roles.x
    y = roles.y
    if not treat or not y or treat not in df.columns or y not in df.columns:
        raise SystemExit("03-heterogeneity: 缺处理变量或因变量角色，先补变量发现包")

    covariates = common.unique_existing(list(roles.controls) + [roles.heterogeneity, roles.moderator],
                                       df.columns)
    data = df.dropna(subset=[y, treat]).reset_index(drop=True)
    fit_df, eval_df, split_note = _split_half(data, roles, args.seed)
    x_fit = _design(fit_df, covariates)
    x_eval = _design(eval_df, covariates)

    # T-learner：处理组与控制组各一个结果模型
    t = fit_df[treat].astype(int).to_numpy()
    mu1 = _nuisance_learner(args.seed).fit(x_fit[t == 1], fit_df[y].astype(float)[t == 1])
    mu0 = _nuisance_learner(args.seed).fit(x_fit[t == 0], fit_df[y].astype(float)[t == 0])
    cate = mu1.predict(x_eval) - mu0.predict(x_eval)

    eval_out = pd.DataFrame({
        "unit_index": eval_df.index.to_numpy(),
        "treatment": eval_df[treat].astype(int).to_numpy(),
        "outcome": eval_df[y].astype(float).to_numpy(),
        "cate": np.asarray(cate, dtype=float),
    })
    if roles.id and roles.id in eval_df.columns:
        eval_out.insert(0, roles.id, eval_df[roles.id].to_numpy())
    common.write_csv(out["tables"] / "ml-cate.csv", eval_out.round(4).to_dict("records"),
                     list(eval_out.columns))

    # 重叠诊断：倾向得分分布
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import roc_auc_score

    ps_model = LogisticRegression(C=1e6, max_iter=5000).fit(x_fit, t)
    ps_eval = ps_model.predict_proba(x_eval)[:, 1]
    extreme = float(np.mean((ps_eval < 0.05) | (ps_eval > 0.95)))
    overlap = [{
        "指标": "倾向得分 AUC", "值": f"{roc_auc_score(eval_df[treat].astype(int), ps_eval):.3f}",
        "解读": "接近 1 说明处理组与对照组可比性差",
    }, {
        "指标": "贴边比例（e<0.05 或 e>0.95）", "值": f"{extreme:.3f}",
        "解读": "超过 0.10 时个体层面的 CATE 不可用于政策建议",
    }, {
        "指标": "CATE 均值", "值": f"{float(np.mean(cate)):.3f}", "解读": "样本外折的平均处理效应近似",
    }, {
        "指标": "CATE 标准差", "值": f"{float(np.std(cate, ddof=1)):.3f}", "解读": "异质性的原始尺度",
    }, {
        "指标": "CATE 最小值／最大值", "值": f"{float(np.min(cate)):.3f} / {float(np.max(cate)):.3f}",
        "解读": "极值常来自外推，需对照重叠诊断阅读",
    }]
    common.write_csv(out["tables"] / "ml-overlap.csv", overlap, list(overlap[0].keys()))

    try:  # 重叠图：没有 matplotlib 也不阻断主结果
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        # 有中文字体用中文，没有就用英文标签（缺字形只会告警不会报错）
        cjk = _pick_cjk_font()
        if cjk:
            plt.rcParams["font.sans-serif"] = [cjk, "DejaVu Sans"]
            plt.rcParams["axes.unicode_minus"] = False
            t1, t0, xl, yl, ti = "处理组", "对照组", "倾向得分（训练折拟合、样本外折预测）", "频数", "重叠诊断"
        else:
            t1, t0, xl, yl, ti = "Treated", "Control", "Propensity score (fit in training fold)", "Count", "Overlap"
        fig, ax = plt.subplots(figsize=(6.4, 4.2), dpi=300)
        ax.hist(np.asarray(ps_eval)[eval_out["treatment"].to_numpy() == 1], bins=30, alpha=0.6, label=t1)
        ax.hist(np.asarray(ps_eval)[eval_out["treatment"].to_numpy() == 0], bins=30, alpha=0.6, label=t0)
        ax.set_xlabel(xl)
        ax.set_ylabel(yl)
        ax.set_title(ti)
        ax.legend(frameon=False)
        fig.tight_layout()
        fig.savefig(out["figures"] / "ml-overlap.png")
        plt.close(fig)
        figure_note = "figures/ml-overlap.png"
    except Exception as exc:  # noqa: BLE001
        figure_note = f"未出图（{type(exc).__name__}: {exc}）"

    # GATES：按 CATE 分位组估组平均效应
    n_groups = args.gates_groups
    quantile = pd.qcut(pd.Series(cate).rank(method="first"), n_groups, labels=False)
    gates_rows = []
    des = pd.DataFrame({"y": eval_out["outcome"].to_numpy(), "t": eval_out["treatment"].to_numpy()})
    for g in range(n_groups):
        des[f"g{g}"] = (quantile == g).astype(int).to_numpy()
        des[f"tg{g}"] = des[f"g{g}"] * des["t"]
    fit = sm.OLS(des["y"], sm.add_constant(des[[f"tg{g}" for g in range(n_groups)]
                                              + [f"g{g}" for g in range(1, n_groups)]])).fit(cov_type="HC1")
    for g in range(n_groups):
        coef = fit.params.get(f"tg{g}")
        se = fit.bse.get(f"tg{g}")
        gates_rows.append({
            "GATES 组": f"第 {g + 1} 组（CATE 分位 {g + 1}/{n_groups}）",
            "组平均处理效应": f"{coef:.3f}", "标准误": f"{se:.3f}",
            "p 值": f"{fit.pvalues.get(f'tg{g}'):.3f}",
            "组样本": int((quantile == g).sum()),
            "CATE 均值": f"{float(np.mean(cate[quantile == g])):.3f}",
        })
    common.write_csv(out["tables"] / "ml-gates.csv", gates_rows, list(gates_rows[0].keys()))

    # BLP：CATE 的异质性信号是否真实存在
    centered = cate - np.mean(cate)
    blp = pd.DataFrame({"y": eval_out["outcome"].to_numpy(), "t": eval_out["treatment"].to_numpy(),
                        "s": centered, "ts": eval_out["treatment"].to_numpy() * centered})
    blp_fit = sm.OLS(blp["y"], sm.add_constant(blp[["t", "s", "ts"]])).fit(cov_type="HC1")
    blp_rows = [{
        "项": "处理×CATE（异质性信号）", "系数": f"{blp_fit.params['ts']:.3f}",
        "标准误": f"{blp_fit.bse['ts']:.3f}", "p 值": f"{blp_fit.pvalues['ts']:.3f}",
        "解读": "显著为正说明 CATE 排序在样本外仍有解释力；不显著则不得声称异质性",
    }, {
        "项": "处理项（ATE 基准）", "系数": f"{blp_fit.params['t']:.3f}",
        "标准误": f"{blp_fit.bse['t']:.3f}", "p 值": f"{blp_fit.pvalues['t']:.3f}",
        "解读": "可与 GATES 加权平均对照",
    }]
    common.write_csv(out["tables"] / "ml-blp-test.csv", blp_rows, list(blp_rows[0].keys()))

    sections = {
        "运行口径": f"数据 `{args.data}`；折分方式＝{split_note}；GATES 组数 {n_groups}；种子 {args.seed}。"
                    f"协变量 {len(covariates)} 个；训练折 {len(fit_df)}，样本外折 {len(eval_df)}。",
        "CATE": f"均值 {float(np.mean(cate)):.3f}，标准差 {float(np.std(cate, ddof=1)):.3f}；"
                f"明细 tables/ml-cate.csv。",
        "GATES": "；".join(f"{r['GATES 组']}={r['组平均处理效应']}" for r in gates_rows) + "。",
        "BLP": f"处理×CATE 系数 {blp_fit.params['ts']:.3f}（p={blp_fit.pvalues['ts']:.3f}）。",
        "重叠诊断": f"贴边比例 {extreme:.3f}；{figure_note}。",
        "可声称边界": ("可声称：不同特征群体的平均效应存在差异（GATES），且该差异在样本外可复现（BLP 显著）。"
                      "不可声称：某个个体的效应等于其 CATE；重叠不足时不可给出个体政策建议（C29、C30）。"),
    }
    common.write_markdown(out["reports"] / f"ml-run-03-heterogeneity-{date.today()}.md",
                          "ML 执行摘要：03-heterogeneity", sections)
    print(f"[07-ml/03-heterogeneity] 完成：GATES {n_groups} 组；BLP p={blp_fit.pvalues['ts']:.3f}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Heterogeneous effects templates (paper-analysis-4ss / 07-ml)")
    common.add_common_args(parser)
    parser.add_argument("--seed", type=int, default=20261024)
    parser.add_argument("--gates-groups", dest="gates_groups", type=int, default=5)
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
