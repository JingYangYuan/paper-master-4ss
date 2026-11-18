#!/usr/bin/env python3
"""因果识别诊断钩子（Python，纯标准库实现）。列名与 causal_diagnostics.do / .R 严格一致。

设计原则
--------
1. **零第三方依赖**：只用 csv / math / random / argparse，任何环境可跑（与 Stata 版同属 base-only）。
2. 不重估主模型：只补「识别设计」的读数（五个 F、OLS-2SLS、AR、LTZ 阈值、RD 回退）。
3. 缺变量、缺数据、缺列一律写 SKIP 行并以 0 退出，不阻断主流程。
4. 需要第三方包才能算的量（Bacon 分解、rdrobust 三行、honestdid）写 SKIP 并说明替代路径。

输出（`--out` 下的 `tables/`）
------------------------------
first_stage_five_f.csv : model,F_standard,F_robust,F_cluster,F_bootstrap,F_effective,N,N_cluster,
                         ols_coef,ols_se,iv_coef,iv_se,ratio,ar_ci_lo,ar_ci_hi,ar_bounded,
                         main_ci_type,mu_star_reduced_form
bacon_decomp.csv       : term,weight,estimate,note
rdd_three_rows.csv     : row,coef,se,p,ci_lo,ci_hi,report_use,bw_selector,h,kernel,p_order,density_p,note
diagnostics-skips.csv  : block,reason,detail

用法
----
python3 causal_diagnostics.py --data <csv> --out paper-workspace/04-analysis \
    --y outcome --endog endog_x --iv "z z2" --controls "ability year" --cluster region \
    --running running --cutoff 0 --treat treated --reps 200
"""

from __future__ import annotations

import argparse
import csv
import math
import random
import sys
from pathlib import Path

FS_HEADER = ["model", "F_standard", "F_robust", "F_cluster", "F_bootstrap", "F_effective",
             "N", "N_cluster", "ols_coef", "ols_se", "iv_coef", "iv_se", "ratio",
             "ar_ci_lo", "ar_ci_hi", "ar_bounded", "main_ci_type", "mu_star_reduced_form"]
BACON_HEADER = ["term", "weight", "estimate", "note"]
RDD_HEADER = ["row", "coef", "se", "p", "ci_lo", "ci_hi", "report_use", "bw_selector",
              "h", "kernel", "p_order", "density_p", "note"]


# --------------------------------------------------------------------------- 线性代数（纯标准库）
def mat_t(a):
    return [list(row) for row in zip(*a)]


def mat_mul(a, b):
    bt = mat_t(b)
    return [[sum(x * y for x, y in zip(row, col)) for col in bt] for row in a]


def mat_vec(a, v):
    return [sum(x * y for x, y in zip(row, v)) for row in a]


def solve(a, b):
    """Gauss–Jordan with partial pivoting；a 为方阵，b 为同维列向量或矩阵（多列）。"""
    n = len(a)
    b_is_matrix = bool(b) and isinstance(b[0], list)
    m = len(b[0]) if b_is_matrix else 1
    aug = [list(a[i]) + (list(b[i]) if b_is_matrix else [b[i]]) for i in range(n)]
    for col in range(n):
        piv = max(range(col, n), key=lambda r: abs(aug[r][col]))
        if abs(aug[piv][col]) < 1e-12:
            raise ZeroDivisionError("singular matrix")
        aug[col], aug[piv] = aug[piv], aug[col]
        pv = aug[col][col]
        aug[col] = [x / pv for x in aug[col]]
        for r in range(n):
            if r != col and abs(aug[r][col]) > 0:
                f = aug[r][col]
                aug[r] = [x - f * y for x, y in zip(aug[r], aug[col])]
    if b_is_matrix:
        return [row[n:] for row in aug]
    return [row[n] for row in aug]


def inverse(a):
    n = len(a)
    eye = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    return solve(a, eye)


def quad(b, v):
    return sum(bi * vij * bj for bi, row in zip(b, v) for bj, vij in zip(b, row) if vij)


# --------------------------------------------------------------------------- 统计工具
def ols(y, X):
    """返回 (beta, resid, XtX_inv, XtX)。X 含常数列。"""
    Xt = mat_t(X)
    XtX = mat_mul(Xt, X)
    Xty = mat_vec(Xt, y)
    XtX_inv = inverse(XtX)
    beta = mat_vec(XtX_inv, Xty)
    resid = [yi - sum(b * x for b, x in zip(beta, row)) for yi, row in zip(y, X)]
    return beta, resid, XtX_inv, XtX


def se_classic(resid, XtX_inv, k):
    n = len(resid)
    sigma2 = sum(r * r for r in resid) / max(1, n - k)
    return [math.sqrt(max(0.0, sigma2 * XtX_inv[j][j])) for j in range(len(XtX_inv))]


def meat_robust(X, resid):
    """sum_i x_i x_i' u_i^2"""
    k = len(X[0])
    M = [[0.0] * k for _ in range(k)]
    for row, u in zip(X, resid):
        u2 = u * u
        for i in range(k):
            rix = row[i] * u2
            for j in range(k):
                M[i][j] += rix * row[j]
    return M


def meat_cluster(X, resid, groups):
    """sum_g (sum_{i in g} x_i u_i)(...)'"""
    k = len(X[0])
    acc = {}
    for row, u, g in zip(X, resid, groups):
        s = acc.setdefault(g, [0.0] * k)
        for i in range(k):
            s[i] += row[i] * u
    M = [[0.0] * k for _ in range(k)]
    for s in acc.values():
        for i in range(k):
            for j in range(k):
                M[i][j] += s[i] * s[j]
    return M, len(acc)


def vcov_sandwich(XtX_inv, meat, adj=1.0):
    k = len(XtX_inv)
    V = [[0.0] * k for _ in range(k)]
    tmp = mat_mul(XtX_inv, meat)
    tmp = mat_mul(tmp, XtX_inv)
    for i in range(k):
        for j in range(k):
            V[i][j] = tmp[i][j] * adj
    return V


def wald(b, V, k=None):
    """b' V^{-1} b / k"""
    k = k or len(b)
    try:
        Vinv = inverse(V)
    except ZeroDivisionError:
        return float("nan")
    return quad(b, Vinv) / k


def p_norm(z):
    return 2 * (1 - 0.5 * (1 + math.erf(abs(z) / math.sqrt(2))))


def p_chi2(stat, k):
    if k == 1:
        return p_norm(math.sqrt(max(stat, 0.0)))
    z = ((stat / k) ** (1 / 3) - (1 - 2 / (9 * k))) / math.sqrt(2 / (9 * k))
    return p_norm(z)


def write_csv(path: Path, header: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in header})


def load_csv(path: Path) -> dict[str, list]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        cols: dict[str, list] = {name: [] for name in (reader.fieldnames or [])}
        for row in reader:
            for name in cols:
                raw = row.get(name, "")
                try:
                    cols[name].append(float(raw))
                except (TypeError, ValueError):
                    cols[name].append(raw)
    return cols


def col_float(cols, name):
    return [float(v) for v in cols[name]]


def columns(cols, names):
    return [[float(cols[n][i]) for n in names] for i in range(len(cols[names[0]]))]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", default=None)
    parser.add_argument("--out", default="paper-workspace/04-analysis")
    parser.add_argument("--y", default="outcome")
    parser.add_argument("--endog", default="endog_x")
    parser.add_argument("--iv", default="instrument_z")
    parser.add_argument("--controls", default="")
    parser.add_argument("--cluster", default="")
    parser.add_argument("--running", default="running")
    parser.add_argument("--cutoff", type=float, default=0.0)
    parser.add_argument("--treat", default="treated")
    parser.add_argument("--reps", type=int, default=200)
    parser.add_argument("--alpha", type=float, default=0.05)
    args = parser.parse_args()

    out = Path(args.out)
    tables = out / "tables"
    tables.mkdir(parents=True, exist_ok=True)
    skips: list[dict] = []
    controls = [c for c in str(args.controls).split() if c]
    ivs = [z for z in str(args.iv).split() if z]

    data_path = Path(args.data) if args.data else out / "data" / "analysis-data.csv"
    if not data_path.exists():
        for name, header in (("first_stage_five_f", FS_HEADER), ("bacon_decomp", BACON_HEADER),
                             ("rdd_three_rows", RDD_HEADER)):
            write_csv(tables / f"{name}.csv", header, [])
        skips.append({"block": "all", "reason": "no_data", "detail": str(data_path)})
        write_csv(tables / "diagnostics-skips.csv", ["block", "reason", "detail"], skips)
        print(f"SKIP: 数据不存在 {data_path}")
        return 0

    cols = load_csv(data_path)
    n_obs = len(cols["pid"]) if "pid" in cols else len(next(iter(cols.values())))

    # ------------------------------------------------------------------ IV
    need = [args.y, args.endog] + ivs + [c for c in controls if c]
    missing = [c for c in need if c not in cols]
    if missing:
        skips.append({"block": "iv", "reason": "missing_vars", "detail": ",".join(missing)})
        write_csv(tables / "first_stage_five_f.csv", FS_HEADER, [])
        print(f"SKIP: IV 诊断缺列 {missing}")
    else:
        y = col_float(cols, args.y)
        d = col_float(cols, args.endog)
        Zraw = columns(cols, ivs)
        W = columns(cols, controls) if controls else []
        Wc = [[1.0] + w for w in W]
        # 对控制变量残差化（FWL）
        def resid_on(v, base):
            if len(base[0]) <= 1:
                m = sum(v) / len(v)
                return [vi - m for vi in v]
            beta, *_ = ols(v, base)
            return [vi - sum(b * x for b, x in zip(beta, row)) for vi, row in zip(v, base)]

        y_t = resid_on(y, Wc)
        d_t = resid_on(d, Wc)
        Z_t = [[resid_on([r[j] for r in Zraw], Wc)[i] for j in range(len(ivs))] for i in range(n_obs)]
        # 2SLS（恰/过度识别都用 2SLS 公式：beta = (Z'd)^-1 Z'y 的投影形式）
        Zd = [[sum(Z_t[i][j] * d_t[i] for i in range(n_obs)) for j in range(len(ivs))]]
        Zy = [sum(Z_t[i][j] * y_t[i] for i in range(n_obs)) for j in range(len(ivs))]
        # pi: 首阶段 d_t ~ Z_t
        pi, resid_pi, inv_pi, _ = ols(d_t, Z_t) if len(ivs) > 1 else (
            [sum(z * dd for z, dd in zip([r[0] for r in Z_t], d_t)) / sum(r[0] ** 2 for r in Z_t)],
            [d_t[i] - (sum(z * dd for z, dd in zip([r[0] for r in Z_t], d_t)) /
                       sum(r[0] ** 2 for r in Z_t)) * Z_t[i][0] for i in range(n_obs)],
            [[1.0 / sum(r[0] ** 2 for r in Z_t)]],
            None)
        d_hat = [sum(p * z for p, z in zip(pi, row)) for row in Z_t]
        iv_b = sum(dh * yy for dh, yy in zip(d_hat, y_t)) / sum(dh * dd for dh, dd in zip(d_hat, d_t))
        u = [yy - iv_b * dd for yy, dd in zip(y_t, d_t)]
        k = len(ivs)
        s2 = sum(x * x for x in u) / max(1, n_obs - k - 1)
        iv_se = math.sqrt(s2 / sum(dh * dh for dh in d_hat))
        b_ols, r_ols, inv_ols, _ = ols(y, [[1.0] + w + [dd] for w, dd in zip(W, d)] if controls
                                       else [[1.0, dd] for dd in d])
        ols_b, ols_se = b_ols[-1], se_classic(r_ols, inv_ols, len(b_ols))[-1]

        # 五个 F
        bR = pi
        F_std = wald(bR, [[(sum(x * x for x in resid_pi) / max(1, n_obs - k)) * inv_pi[i][j]
                           for j in range(k)] for i in range(k)], k)
        meat_r = meat_robust(Z_t, resid_pi)
        V_rob = vcov_sandwich(inv_pi, meat_r)
        F_rob = wald(bR, V_rob, k)
        F_clu, ncl = None, 1
        if args.cluster and args.cluster in cols:
            groups = cols[args.cluster]
            meat_c, ncl = meat_cluster(Z_t, resid_pi, groups)
            adj = ncl / (ncl - 1) if ncl > 1 else 1.0
            V_clu = vcov_sandwich(inv_pi, meat_c, adj)
            F_clu = wald(bR, V_clu, k)
            V_for_eff = V_clu
        else:
            V_for_eff = V_rob
        # effective F（迹公式）：(pi' Q pi) / tr(V Q)，Q = Z'Z/N
        ZtZ = mat_mul(mat_t(Z_t), Z_t)
        Q = [[x / n_obs for x in row] for row in ZtZ]
        VQ = mat_mul(V_for_eff, Q)
        den = sum(VQ[i][i] for i in range(k))
        num = quad(pi, Q)
        F_eff = num / den if den > 0 else float("nan")
        # bootstrap F（仅单工具）
        F_boot = None
        if k == 1:
            rng = random.Random(20261115)
            groups = cols[args.cluster] if (args.cluster and args.cluster in cols) else list(range(n_obs))
            uniq = sorted(set(groups))
            by_group = {}
            for i, g in enumerate(groups):
                by_group.setdefault(g, []).append(i)
            t2s = []
            for _ in range(max(20, min(args.reps, 1000))):
                idx = []
                for g in (rng.choice(uniq) for _ in range(len(uniq))):
                    idx.extend(by_group[g])
                zz = [Z_t[i][0] for i in idx]
                dd = [d_t[i] for i in idx]
                szz = sum(v * v for v in zz)
                if szz <= 0:
                    continue
                b = sum(z * x for z, x in zip(zz, dd)) / szz
                r = [x - b * z for x, z in zip(dd, zz)]
                se = math.sqrt((sum(x * x for x in r) / max(1, len(idx) - 1)) / szz)
                if se > 0:
                    t2s.append((b / se) ** 2)
            F_boot = sum(t2s) / len(t2s) if t2s else None
        # AR 区间
        accepted = []
        grid = [iv_b - 6 * iv_se + i * (12 * iv_se / 80) for i in range(81)]
        for b0 in grid:
            yy = [a - b0 * b for a, b in zip(y_t, d_t)]
            if k == 1:
                zz = [r[0] for r in Z_t]
                szz = sum(v * v for v in zz)
                bb = sum(z * x for z, x in zip(zz, yy)) / szz
                rr = [x - bb * z for x, z in zip(yy, zz)]
                if args.cluster and args.cluster in cols:
                    meat_c, nc = meat_cluster([[z] for z in zz], rr, cols[args.cluster])
                    Vb = vcov_sandwich([[1 / szz]], meat_c, nc / (nc - 1) if nc > 1 else 1.0)[0][0]
                else:
                    Vb = vcov_sandwich([[1 / szz]], meat_robust([[z] for z in zz], rr))[0][0]
                if p_norm(bb / math.sqrt(Vb)) > args.alpha:
                    accepted.append(b0)
            else:
                bb, rr, invb, _ = ols(yy, Z_t)
                meat_c, nc = meat_cluster(Z_t, rr, cols[args.cluster]) if (args.cluster and args.cluster in cols) \
                    else (meat_robust(Z_t, rr), 1)
                Vb = vcov_sandwich(invb, meat_c, nc / (nc - 1) if nc > 1 else 1.0)
                stat = quad(bb, inverse(Vb)) if True else 0.0
                if p_chi2(stat, k) > args.alpha:
                    accepted.append(b0)
        ar_bounded = 1 if accepted else 0
        mu_star = None
        if k == 1:
            zz = [r[0] for r in Z_t]
            mu_star = sum(z * x for z, x in zip(zz, y_t)) / sum(v * v for v in zz)
        main_ci = "analytic"
        if F_eff == F_eff and F_eff < 23:
            main_ci = "tF_or_ar"
        if F_eff == F_eff and F_eff < 10:
            main_ci = "ar"
        if k > 1:
            skips.append({"block": "iv_bootstrap", "reason": "multi_instrument",
                          "detail": "多工具下 bootstrap F 未定义；改看 effective F 与 AR"})
        write_csv(tables / "first_stage_five_f.csv", FS_HEADER, [{
            "model": "iv_main", "F_standard": F_std, "F_robust": F_rob,
            "F_cluster": F_clu if F_clu is not None else "",
            "F_bootstrap": F_boot if F_boot is not None else "",
            "F_effective": F_eff, "N": n_obs, "N_cluster": ncl,
            "ols_coef": ols_b, "ols_se": ols_se, "iv_coef": iv_b, "iv_se": iv_se,
            "ratio": (iv_b / ols_b) if ols_b else "",
            "ar_ci_lo": min(accepted) if accepted else "", "ar_ci_hi": max(accepted) if accepted else "",
            "ar_bounded": ar_bounded, "main_ci_type": main_ci,
            "mu_star_reduced_form": mu_star if mu_star is not None else "",
        }])
        print(f"IV 诊断完成：N={n_obs} F_std={F_std:.2f} F_rob={F_rob:.2f} "
              f"F_clu={F_clu if F_clu is None else round(F_clu, 2)} F_eff={F_eff:.2f} "
              f"AR=[{min(accepted) if accepted else None}, {max(accepted) if accepted else None}]")

    # ------------------------------------------------------------------ DiD
    skips.append({"block": "did_bacon", "reason": "missing_package",
                  "detail": "bacondecomp 无 Python 等价实现；见 Stata 模板 ddetail 输出"})
    write_csv(tables / "bacon_decomp.csv", BACON_HEADER, [
        {"term": "SKIP", "note": "bacondecomp 无 Python 等价实现；见 Stata 模板 ddetail 输出"}])

    # ------------------------------------------------------------------ RDD
    if args.running not in cols or args.y not in cols:
        skips.append({"block": "rdd", "reason": "missing_vars", "detail": args.running})
        write_csv(tables / "rdd_three_rows.csv", RDD_HEADER, [{"row": "SKIP", "note": "缺 running/y"}])
    else:
        rv = col_float(cols, args.running)
        yv = col_float(cols, args.y)
        mean_rv = sum(rv) / len(rv)
        sd = math.sqrt(sum((x - mean_rv) ** 2 for x in rv) / max(1, len(rv) - 1))
        h = 0.5 * sd
        idx = [i for i, x in enumerate(rv) if abs(x - args.cutoff) <= h]
        X, Y, wt = [], [], []
        for i in idx:
            rc = rv[i] - args.cutoff
            dpos = 1.0 if rv[i] >= args.cutoff else 0.0
            w = max(0.0, 1 - abs(rc) / h) if h > 0 else 1.0
            sw = math.sqrt(w)
            X.append([sw, sw * rc, sw * dpos, sw * rc * dpos])
            Y.append(yv[i] * sw)
            wt.append(w)
        b, r, inv, _ = ols(Y, X)
        # 稳健（HC1）sandwich：与 Stata 的 vce(robust) 对齐
        V_rd = vcov_sandwich(inv, meat_robust(X, r), len(Y) / max(1, len(Y) - 4))
        jump, jump_se = b[2], math.sqrt(max(0.0, V_rd[2][2]))
        p = p_norm(jump / jump_se)
        n_l = sum(1 for i in idx if rv[i] < args.cutoff)
        n_r = len(idx) - n_l
        tot = n_l + n_r
        dens_p = None
        if tot:
            z = (n_l - tot / 2) / math.sqrt(tot * 0.25)
            dens_p = p_norm(z)
        write_csv(tables / "rdd_three_rows.csv", RDD_HEADER, [{
            "row": "conventional", "coef": jump, "se": jump_se, "p": p,
            "ci_lo": jump - 1.96 * jump_se, "ci_hi": jump + 1.96 * jump_se,
            "report_use": "fallback_conventional", "bw_selector": "manual_h", "h": h,
            "kernel": "triangular", "p_order": 1, "density_p": dens_p if dens_p is not None else "",
            "note": "Python base 回退；主报须 rdrobust 的 Robust 行"}])
        print(f"RD 回退：jump={jump:.4f} se={jump_se:.4f} h={h:.3f} 窗内左右={n_l}/{n_r}")

    write_csv(tables / "diagnostics-skips.csv", ["block", "reason", "detail"], skips)
    print(f"完成。输出目录：{tables}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
