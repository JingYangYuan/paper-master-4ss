#!/usr/bin/env python3
"""Executable helpers for Paper Analysis 4SS templates.

The helpers are deliberately conservative: they run real cleaning, summaries,
models, tables, and figures when the required variables and packages exist; if
not, callers should log a concrete blocker instead of fabricating results.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Any, Iterable


DEFAULT_OUT_ROOT = Path("paper-workspace/04-analysis")
SPECIAL_MISSING = {-9, -8, -7, -99, -999}


@dataclass
class Roles:
    y: str = "outcome"
    x: str = "treatment"
    controls: list[str] = field(default_factory=list)
    fe: list[str] = field(default_factory=list)
    cluster: str | None = None
    weight: str | None = None
    id: str | None = None
    time: str | None = None
    treat: str | None = None
    post: str | None = None
    gvar: str | None = None
    event: str | None = None
    endog: str | None = None
    instrument: str | None = None
    running: str | None = None
    cutoff: float = 0.0
    mediator: str | None = None
    moderator: str | None = None
    heterogeneity: str | None = None
    threshold: str | None = None
    lat: str | None = None
    lon: str | None = None
    outcome_bin: str | None = None
    outcome_ord: str | None = None
    outcome_multi: str | None = None
    outcome_count: str | None = None
    prop_outcome: str | None = None
    duration: str | None = None
    event_flag: str | None = None


def add_common_args(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument("--data", default=None, help="Path to analysis data.")
    parser.add_argument("--plan", default=None, help="Path to analysis-execution-plan markdown.")
    parser.add_argument("--dict", dest="dict_path", default=None, help="Path to variable-dictionary.csv.")
    parser.add_argument("--out-root", default=str(DEFAULT_OUT_ROOT), help="Output root.")
    parser.add_argument("--run-log", default=None, help="Run log path.")
    parser.add_argument("--slug", default="analysis", help="Project slug.")
    parser.add_argument("--tasks", default="", help="Comma-separated task list.")
    return parser


def paths(out_root: str | Path) -> dict[str, Path]:
    root = Path(out_root)
    out = {
        "root": root,
        "data": root / "data",
        "scripts": root / "scripts",
        "tables": root / "tables",
        "figures": root / "figures",
        "reports": root / "reports",
        "qual": root / "qual",
    }
    for value in out.values():
        value.mkdir(parents=True, exist_ok=True)
    for sub in ["codebooks", "coded-data", "memos", "anonymized", "reliability"]:
        (out["qual"] / sub).mkdir(parents=True, exist_ok=True)
    return out


def run_log_path(args) -> Path:
    if getattr(args, "run_log", None):
        return Path(args.run_log)
    return Path(args.out_root) / "reports" / f"run-log-{date.today().isoformat()}.md"


def write_csv(path: str | Path, rows: list[dict[str, object]], fieldnames: list[str] | None = None) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if fieldnames is None:
        fieldnames = []
        for row in rows:
            for key in row:
                if key not in fieldnames:
                    fieldnames.append(key)
        fieldnames = fieldnames or ["note"]
    with path.open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return path


def write_json(path: str | Path, payload: object) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def write_markdown(path: str | Path, title: str, sections: dict[str, str]) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    body = [f"# {title}", ""]
    for heading, text in sections.items():
        body.extend([f"## {heading}", str(text).strip() or "无", ""])
    path.write_text("\n".join(body), encoding="utf-8")
    return path


def find_latest_report(out_root: str | Path, prefix: str) -> Path | None:
    reports = Path(out_root) / "reports"
    matches = sorted(reports.glob(f"{prefix}*.md"))
    return matches[-1] if matches else None


def task_enabled(args, name: str) -> bool:
    raw = getattr(args, "tasks", "") or ""
    if not raw:
        return True
    return name in {x.strip() for x in raw.split(",") if x.strip()}


def read_csv_dicts(path: str | Path | None) -> list[dict[str, str]]:
    if not path or not Path(path).exists():
        return []
    with Path(path).open(newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def load_data(path: str | Path):
    import pandas as pd

    p = Path(path)
    ext = p.suffix.lower()
    if ext in {".csv", ".txt"}:
        return pd.read_csv(p)
    if ext == ".tsv":
        return pd.read_csv(p, sep="\t")
    if ext in {".xlsx", ".xls"}:
        return pd.read_excel(p)
    if ext == ".dta":
        return pd.read_stata(p)
    if ext == ".sav":
        return pd.read_spss(p)
    if ext == ".parquet":
        return pd.read_parquet(p)
    if ext in {".pkl", ".pickle"}:
        return pd.read_pickle(p)
    raise ValueError(f"Unsupported data file type: {p.suffix}")


def clean_column_names(df):
    out = df.copy()
    out.columns = [
        re.sub(r"_+", "_", re.sub(r"[^0-9A-Za-z_]+", "_", str(c).strip().lower())).strip("_")
        for c in out.columns
    ]
    return out


def clean_data(df, special_missing: Iterable[float] = SPECIAL_MISSING, winsor_pct: tuple[float, float] = (0.01, 0.99)):
    import numpy as np

    out = clean_column_names(df)
    for col in out.select_dtypes(include="object").columns:
        out[col] = out[col].astype(str).str.strip().replace({"": np.nan, "nan": np.nan, "None": np.nan})
    num_cols = out.select_dtypes(include="number").columns
    out[num_cols] = out[num_cols].replace(list(special_missing), np.nan)
    for col in num_cols:
        nonmiss = out[col].dropna()
        if nonmiss.nunique() > 8:
            lo, hi = nonmiss.quantile(winsor_pct[0]), nonmiss.quantile(winsor_pct[1])
            out[col] = out[col].clip(lo, hi)
    return out.drop_duplicates()


def save_analysis_data(df, out_root: str | Path) -> Path:
    path = Path(out_root) / "data" / "analysis-data.csv"
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    return path


def display_name_map(dict_path: str | Path | None) -> dict[str, str]:
    mapping = {}
    for row in read_csv_dicts(dict_path):
        raw = row.get("clean_name") or row.get("raw_name") or row.get("variable")
        display = row.get("display_name") or row.get("label") or raw
        if raw:
            mapping[raw] = display
    return mapping


def display_name(term: str, mapping: dict[str, str] | None = None) -> str:
    mapping = mapping or {}
    term = str(term)
    if term in mapping:
        return mapping[term]
    cleaned = re.sub(r"^C\(([^)]+)\).*$", r"\1", term)
    cleaned = re.sub(r"\[.*$", "", cleaned)
    cleaned = re.sub(r":.*$", "", cleaned)
    return mapping.get(cleaned, "常数" if cleaned.lower() in {"intercept", "const"} else cleaned)


def infer_roles(df, dict_path: str | Path | None = None) -> Roles:
    cols = list(df.columns)
    role_rows = read_csv_dicts(dict_path)
    roles: dict[str, list[str]] = {}
    for row in role_rows:
        var = row.get("clean_name") or row.get("raw_name") or row.get("variable")
        role = (row.get("role") or row.get("variable_role") or "").lower()
        if var and role:
            roles.setdefault(role, []).append(var)

    def first(role: str, candidates: list[str], default: str | None = None):
        for key, vals in roles.items():
            if role in key and vals:
                return vals[0]
        for c in candidates:
            if c in cols:
                return c
        return default

    y = first("y", ["outcome", "y", "dependent", "depvar"], cols[0] if cols else "outcome") or "outcome"
    x = first("x", ["treatment", "x", "main_x", "independent"], cols[1] if len(cols) > 1 else "treatment") or "treatment"
    controls = roles.get("control") or [c for c in ["age", "gender", "education", "income"] if c in cols]
    fe = roles.get("fe") or [c for c in ["region", "province", "city", "county", "year"] if c in cols and c not in {x, y}]
    cluster = first("cluster", ["region", "province", "city", "county", "pid", "id"])
    return Roles(
        y=y,
        x=x,
        controls=[c for c in controls if c in cols and c not in {y, x}],
        fe=[c for c in fe if c in cols and c not in {y, x}],
        cluster=cluster if cluster in cols else None,
        weight=first("weight", ["weight", "sample_weight"]),
        id=first("id", ["pid", "id", "unit"]),
        time=first("time", ["year", "time", "wave"]),
        treat=first("treat", ["treated", "treat", "treatment"]),
        post=first("post", ["post", "after"]),
        gvar=first("gvar", ["first_treat_year", "gvar"]),
        event=first("event", ["rel_year", "event_time"]),
        endog=first("endog", ["endog_x", "endogenous"]),
        instrument=first("instrument", ["instrument_z", "iv", "instrument"]),
        running=first("running", ["running_score", "running"]),
        mediator=first("mediator", ["mediator", "mechanism"]),
        moderator=first("moderator", ["moderator"]),
        heterogeneity=first("heterogeneity", ["group", "subgroup", "heterogeneity"]),
        threshold=first("threshold", ["threshold"]),
        lat=first("lat", ["lat", "latitude"]),
        lon=first("lon", ["lon", "longitude"]),
        outcome_bin=("outcome_bin" if "outcome_bin" in cols else None),
        outcome_ord=("outcome_ord" if "outcome_ord" in cols else None),
        outcome_multi=("outcome_multi" if "outcome_multi" in cols else None),
        outcome_count=("outcome_count" if "outcome_count" in cols else None),
        prop_outcome=("prop_outcome" if "prop_outcome" in cols else None),
        duration=("duration" if "duration" in cols else None),
        event_flag=("event" if "event" in cols else None),
    )


def write_variable_dictionary(df, roles: Roles, source_file: str | Path, out_root: str | Path) -> Path:
    role_map: dict[str, list[str]] = {
        "Y": [roles.y],
        "X": [roles.x],
        "control": roles.controls,
        "fe": roles.fe,
        "cluster": [roles.cluster] if roles.cluster else [],
        "weight": [roles.weight] if roles.weight else [],
        "id": [roles.id] if roles.id else [],
        "time": [roles.time] if roles.time else [],
        "mediator": [roles.mediator] if roles.mediator else [],
        "moderator": [roles.moderator] if roles.moderator else [],
        "instrument": [roles.instrument] if roles.instrument else [],
        "treatment": [roles.treat] if roles.treat else [],
        "post": [roles.post] if roles.post else [],
        "running": [roles.running] if roles.running else [],
    }
    reverse = {v: k for k, vals in role_map.items() for v in vals}
    rows = []
    for col in df.columns:
        rows.append(
            {
                "raw_name": col,
                "clean_name": col,
                "display_name": col,
                "role": reverse.get(col, ""),
                "dtype": str(df[col].dtype),
                "missing": int(df[col].isna().sum()),
                "source_file": str(source_file),
            }
        )
    return write_csv(Path(out_root) / "data" / "variable-dictionary.csv", rows)


def sample_flow(df, roles: Roles, out_root: str | Path) -> tuple[Any, Path]:
    required = [roles.y, roles.x, *roles.controls]
    required = [v for v in required if v and v in df.columns]
    before = len(df)
    filtered = df.dropna(subset=required) if required else df.copy()
    rows = [
        {"step": "raw", "rule": "原始数据", "n_before": before, "n_after": before, "dropped": 0, "reason": "载入原始数据"},
        {
            "step": "analysis_sample",
            "rule": "删除 Y/X/control 缺失",
            "n_before": before,
            "n_after": len(filtered),
            "dropped": before - len(filtered),
            "reason": ", ".join(required),
        },
    ]
    path = write_csv(Path(out_root) / "tables" / "sample-flow.csv", rows)
    return filtered, path


def describe_data(df, variables: list[str], out_root: str | Path, file_name: str = "table1-descriptives.csv") -> Path:
    import pandas as pd

    rows = []
    for var in [v for v in variables if v in df.columns]:
        s = pd.to_numeric(df[var], errors="coerce")
        if s.notna().any():
            rows.append(
                {
                    "variable": var,
                    "N": int(s.notna().sum()),
                    "mean": round(float(s.mean()), 3),
                    "sd": round(float(s.std()), 3) if s.notna().sum() > 1 else "",
                    "min": round(float(s.min()), 3),
                    "max": round(float(s.max()), 3),
                }
            )
        else:
            rows.append({"variable": var, "N": int(df[var].notna().sum()), "mean": "", "sd": "", "min": "", "max": ""})
    return write_csv(Path(out_root) / "tables" / file_name, rows)


def correlation_table(df, variables: list[str], out_root: str | Path) -> Path | None:
    vars_ = [v for v in variables if v in df.columns]
    if len(vars_) < 2:
        return None
    corr = df[vars_].apply(lambda s: s.astype("category").cat.codes if s.dtype == "object" else s).corr(numeric_only=True)
    path = Path(out_root) / "tables" / "table1c-correlation.csv"
    path.parent.mkdir(parents=True, exist_ok=True)
    corr.round(3).to_csv(path, encoding="utf-8-sig")
    return path


def basic_figures(df, roles: Roles, out_root: str | Path) -> list[Path]:
    outputs: list[Path] = []
    try:
        import matplotlib.pyplot as plt
    except Exception:
        return outputs
    fig_dir = Path(out_root) / "figures"
    if roles.y in df.columns:
        fig, ax = plt.subplots()
        df[roles.y].dropna().hist(ax=ax, bins=30)
        ax.set_title(display_name(roles.y))
        p = fig_dir / f"dist-{roles.y}.png"
        fig.savefig(p, dpi=200, bbox_inches="tight")
        plt.close(fig)
        outputs.append(p)
    if roles.y in df.columns and roles.x in df.columns:
        fig, ax = plt.subplots()
        ax.scatter(df[roles.x], df[roles.y], alpha=0.5)
        ax.set_xlabel(display_name(roles.x))
        ax.set_ylabel(display_name(roles.y))
        p = fig_dir / f"scatter-{roles.y}-{roles.x}.png"
        fig.savefig(p, dpi=200, bbox_inches="tight")
        plt.close(fig)
        outputs.append(p)
    return outputs


def formula_rhs(variables: list[str]) -> str:
    return " + ".join(v for v in variables if v) or "1"


def unique_existing(names: Iterable[str | None], columns: Iterable[str]) -> list[str]:
    cols = set(columns)
    out: list[str] = []
    for name in names:
        if name and name in cols and name not in out:
            out.append(name)
    return out


def fe_terms(fe: list[str]) -> list[str]:
    return [f"C({v})" for v in fe if v]


def model_formula(y: str, x: str, controls: list[str] | None = None, fe: list[str] | None = None) -> str:
    rhs = [x, *(controls or []), *fe_terms(fe or [])]
    return f"{y} ~ {formula_rhs(rhs)}"


def _fit_result(model, cluster_values=None):
    if cluster_values is not None:
        return model.fit(cov_type="cluster", cov_kwds={"groups": cluster_values})
    return model.fit(cov_type="HC1")


def run_ols(df, y: str, x: str, controls: list[str] | None = None, fe: list[str] | None = None, cluster: str | None = None):
    import statsmodels.formula.api as smf

    variables = unique_existing([y, x, *(controls or []), *(fe or []), cluster], df.columns)
    data = df[variables].dropna()
    fml = model_formula(y, x, controls, fe)
    model = smf.ols(fml, data=data)
    return _fit_result(model, data[cluster] if cluster and cluster in data.columns else None)


def run_logit(df, y: str, x: str, controls: list[str] | None = None, fe: list[str] | None = None, cluster: str | None = None):
    import statsmodels.formula.api as smf

    data = df[unique_existing([y, x, *(controls or []), *(fe or []), cluster], df.columns)].dropna()
    return _fit_result(smf.logit(model_formula(y, x, controls, fe), data=data), data[cluster] if cluster and cluster in data.columns else None)


def run_probit(df, y: str, x: str, controls: list[str] | None = None, fe: list[str] | None = None, cluster: str | None = None):
    import statsmodels.formula.api as smf

    data = df[unique_existing([y, x, *(controls or []), *(fe or []), cluster], df.columns)].dropna()
    return _fit_result(smf.probit(model_formula(y, x, controls, fe), data=data), data[cluster] if cluster and cluster in data.columns else None)


def run_poisson(df, y: str, x: str, controls: list[str] | None = None, fe: list[str] | None = None):
    import statsmodels.api as sm
    import statsmodels.formula.api as smf

    data = df[unique_existing([y, x, *(controls or []), *(fe or [])], df.columns)].dropna()
    return smf.glm(model_formula(y, x, controls, fe), data=data, family=sm.families.Poisson()).fit()


def run_panel_fe(df, roles: Roles):
    return run_ols(df, roles.y, roles.x, roles.controls, [v for v in [roles.id, roles.time] if v], roles.cluster or roles.id)


def run_iv_2sls(df, roles: Roles):
    if not roles.endog or not roles.instrument:
        raise ValueError("IV requires endog and instrument roles")
    try:
        from linearmodels.iv import IV2SLS

        variables = [roles.y, roles.endog, roles.instrument, *roles.controls]
        data = df[[v for v in variables if v in df.columns]].dropna()
        exog = data[roles.controls] if roles.controls else None
        return IV2SLS(data[roles.y], exog, data[roles.endog], data[roles.instrument]).fit(cov_type="robust")
    except Exception:
        first = run_ols(df, roles.endog, roles.instrument, roles.controls, [], roles.cluster)
        temp = df.copy()
        temp["_endog_hat"] = first.predict()
        second = run_ols(temp.dropna(subset=["_endog_hat"]), roles.y, "_endog_hat", roles.controls, [], roles.cluster)
        second._pa_first_stage = first  # type: ignore[attr-defined]
        return second


def run_twfe_did(df, roles: Roles):
    if not roles.treat or not roles.post:
        raise ValueError("DID requires treat and post roles")
    temp = df.copy()
    temp["_did"] = temp[roles.treat] * temp[roles.post]
    controls = [*roles.controls, roles.treat, roles.post]
    return run_ols(temp, roles.y, "_did", controls, [v for v in [roles.id, roles.time] if v], roles.cluster or roles.id)


def run_parametric_rdd(df, roles: Roles, bandwidth: float | None = None):
    if not roles.running:
        raise ValueError("RDD requires running role")
    temp = df.copy()
    temp["_running_centered"] = temp[roles.running] - roles.cutoff
    if bandwidth is None:
        bandwidth = float(temp["_running_centered"].std() or temp["_running_centered"].abs().max())
    temp = temp[temp["_running_centered"].abs() <= bandwidth].copy()
    temp["_above_cutoff"] = (temp["_running_centered"] >= 0).astype(int)
    temp["_rdd_interaction"] = temp["_above_cutoff"] * temp["_running_centered"]
    return run_ols(temp, roles.y, "_above_cutoff", [*roles.controls, "_running_centered", "_rdd_interaction"], [], roles.cluster)


def run_ipw_ate(df, roles: Roles):
    if not roles.treat:
        raise ValueError("IPW requires treatment role")
    import statsmodels.formula.api as smf

    data = df[[v for v in [roles.y, roles.treat, *roles.controls] if v in df.columns]].dropna()
    ps = smf.logit(f"{roles.treat} ~ {formula_rhs(roles.controls)}", data=data).fit(disp=False).predict(data).clip(0.01, 0.99)
    weights = data[roles.treat] / ps + (1 - data[roles.treat]) / (1 - ps)
    return smf.wls(f"{roles.y} ~ {roles.treat}", data=data, weights=weights).fit(cov_type="HC1")


def run_mediation(df, roles: Roles, reps: int = 500) -> dict[str, Any]:
    """江艇（2022）两步法：第一步 X→Y，第二步 X→M。

    不得把机制/中介变量 M 放进 Y 的回归方程（坏控制变量偏误）。
    间接效应仅作为补充证据，用 bootstrap 单独计算并命名为 indirect_boot。
    """
    if not roles.mediator:
        raise ValueError("Mediation requires mediator role")
    import numpy as np

    total = run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
    path_a = run_ols(df, roles.mediator, roles.x, roles.controls, roles.fe, roles.cluster)

    data = df[[v for v in [roles.y, roles.mediator, roles.x, *roles.controls] if v in df.columns]].dropna()
    rng = np.random.default_rng(20240601)
    est = np.empty(reps, dtype=float)
    n = len(data)
    for i in range(reps):
        idx = rng.integers(0, n, n)
        b = data.iloc[idx]
        a = _coef_of(run_ols(b, roles.mediator, roles.x, roles.controls, None, None), roles.x)
        bcoef = _coef_of(run_ols(b, roles.y, roles.mediator, [roles.x, *roles.controls], None, None), roles.mediator)
        est[i] = np.nan if (a is None or bcoef is None) else a * bcoef
    est = est[~np.isnan(est)]
    indirect = {
        "estimate": float(np.mean(est)) if est.size else float("nan"),
        "ci_low": float(np.quantile(est, 0.025)) if est.size else float("nan"),
        "ci_high": float(np.quantile(est, 0.975)) if est.size else float("nan"),
        "reps": int(est.size),
    }
    return {"total": total, "path_a": path_a, "indirect_boot": indirect}


def _coef_of(model, term: str):
    params = getattr(model, "params", None)
    if params is None or term not in params:
        return None
    return float(params[term])


# ---- 02 nonlinear 新增估计量（Python 不提供 Tobit / Heckman / 面板选择） ----
def run_ologit(df, y: str, x: str, controls: list[str] | None = None, cluster: str | None = None):
    import statsmodels.miscmodels.ordinal_model as om

    data = df[[v for v in [y, x, *(controls or []), cluster] if v and v in df.columns]].dropna()
    mod = om.OrderedModel(data[y], data[[x, *(controls or [])]].astype(float), distr="logit").fit(disp=False)
    return _pm_result(mod, "OrderedModel", data, cluster)


def run_oprobit(df, y: str, x: str, controls: list[str] | None = None, cluster: str | None = None):
    import statsmodels.miscmodels.ordinal_model as om

    data = df[[v for v in [y, x, *(controls or []), cluster] if v and v in df.columns]].dropna()
    mod = om.OrderedModel(data[y], data[[x, *(controls or [])]].astype(float), distr="probit").fit(disp=False)
    return _pm_result(mod, "OrderedModel", data, cluster)


def run_mlogit(df, y: str, x: str, controls: list[str] | None = None, cluster: str | None = None):
    import statsmodels.api as sm

    data = df[[v for v in [y, x, *(controls or []), cluster] if v and v in df.columns]].dropna()
    endog = data[y].astype("category").cat.codes
    exog = sm.add_constant(data[[x, *(controls or [])]].astype(float))
    mod = sm.MNLogit(endog, exog).fit(disp=False)
    return _pm_result(mod, "MNLogit", data, cluster)


def run_nbreg(df, y: str, x: str, controls: list[str] | None = None, cluster: str | None = None):
    import statsmodels.api as sm

    data = df[[v for v in [y, x, *(controls or []), cluster] if v and v in df.columns]].dropna()
    mod = sm.NegativeBinomial(data[y], sm.add_constant(data[[x, *(controls or [])]].astype(float))).fit(disp=False)
    return _pm_result(mod, "NegativeBinomial", data, cluster)


def run_fracreg(df, y: str, x: str, controls: list[str] | None = None, cluster: str | None = None):
    import statsmodels.api as sm

    data = df[[v for v in [y, x, *(controls or []), cluster] if v and v in df.columns]].dropna()
    mod = sm.GLM(data[y], sm.add_constant(data[[x, *(controls or [])]].astype(float)),
                 family=sm.families.Binomial()).fit()
    result = _pm_result(mod, "GLM-Binomial", data, cluster)
    try:
        result.get_margeff = mod.get_margeff  # type: ignore[attr-defined]
    except Exception:
        pass
    return result


def run_duration(df, y: str, x: str, controls: list[str] | None = None, event: str | None = None):
    from lifelines import CoxPHFitter, WeibullAFTFitter

    cols = [y, x, *(controls or [])] + ([event] if event else [])
    data = df[[v for v in cols if v and v in df.columns]].dropna()
    if event and event in data.columns:
        fitter = CoxPHFitter().fit(data, duration_col=y, event_col=event)
    else:
        fitter = WeibullAFTFitter().fit(data, duration_col=y)
    return _PMResult(fitter)


def _pm_result(mod, kind: str, data, cluster: str | None):
    return _PMResult(mod, kind=kind, cluster=cluster, data=data)


class _PMResult:
    """轻量包装：让 statsmodels / lifelines 结果能走同一套导出与取数路径。"""

    def __init__(self, inner, kind: str = "", cluster: str | None = None, data=None):
        self.inner = inner
        self.kind = kind
        self.cluster = cluster
        self.data = data

    @staticmethod
    def _flat(value):
        """把 numpy/pandas/字典/linearmodels 结果统一压成 {名称: 标量}。"""
        import numpy as np

        if value is None:
            return {}
        if hasattr(value, "to_dict") and not isinstance(value, (dict,)):
            value = value.to_dict()
        if isinstance(value, dict):
            out = {}
            for k, v in value.items():
                if isinstance(v, dict):
                    for k2, v2 in v.items():
                        try:
                            out[str(k2)] = float(v2)
                        except Exception:
                            continue
                else:
                    try:
                        out[str(k)] = float(v)
                    except Exception:
                        continue
            return out
        try:
            arr = np.asarray(value, dtype=float).ravel()
        except Exception:
            return {}
        names = getattr(value, "index", None)
        if names is not None:
            return {str(n): float(a) for n, a in zip(list(names), arr)}
        names = getattr(value, "name", None)
        if names is not None:
            return {str(names): float(arr[0])}
        return {str(i): float(a) for i, a in enumerate(arr)}

    @property
    def params(self):
        return self._flat(getattr(self.inner, "params", None))

    @property
    def pvalues(self):
        v = getattr(self.inner, "pvalues", None)
        if v is None:
            v = getattr(self.inner, "pvalues_", None)
        return self._flat(v)

    @property
    def tvalues(self):
        for attr in ("tvalues", "zvalues", "tstats", "zstats"):
            v = getattr(self.inner, attr, None)
            if v is not None:
                return self._flat(v)
        return {}

    @property
    def nobs(self):
        for attr in ("nobs", "n"):
            v = getattr(self.inner, attr, None)
            if callable(v):
                try:
                    v = v()
                except Exception:
                    continue
            if v is not None:
                try:
                    return int(v)
                except Exception:
                    continue
        d = getattr(self.inner, "_n_examples", None)
        return int(d) if d is not None else 0

    def summary(self):
        return getattr(self.inner, "summary", lambda: str(self.inner))()


# ---- 03 panel 新增估计量 ----
def run_panel_fe_py(df, roles: Roles):
    """linearmodels PanelOLS：个体 + 时间效应，聚类稳健标准误。"""
    from linearmodels.panel import PanelOLS

    cols = [roles.y, roles.x, *roles.controls, roles.id, roles.time]
    if roles.cluster:
        cols.append(roles.cluster)
    data = df[[v for v in cols if v and v in df.columns]].dropna()
    data = data.set_index([roles.id, roles.time])
    y = data[roles.y]
    x = data[[roles.x, *roles.controls]]
    mod = PanelOLS(y, x, entity_effects=True, time_effects=True)
    if roles.cluster and roles.cluster in data.columns:
        res = mod.fit(cov_type="clustered", clusters=data[roles.cluster])
    else:
        res = mod.fit(cov_type="clustered", cluster_entity=True)
    return _PMResult(res, "PanelOLS", cluster=roles.cluster)


def run_panel_long_py(df, roles: Roles):
    """长面板（N 小 T 大）：PanelOLS + Driscoll-Kraay（kernel）标准误。"""
    from linearmodels.panel import PanelOLS

    cols = [roles.y, roles.x, *roles.controls, roles.id, roles.time]
    data = df[[v for v in cols if v and v in df.columns]].dropna()
    data = data.set_index([roles.id, roles.time])
    mod = PanelOLS(data[roles.y], data[[roles.x, *roles.controls]], entity_effects=True)
    res = mod.fit(cov_type="kernel", kernel="bartlett", bandwidth=2)
    return _PMResult(res, "PanelOLS-DK")


def run_pgmm(df, roles: Roles):
    """动态面板 GMM：pydynpd。"""
    import pydynpd

    data = df[[v for v in [roles.y, roles.x, *roles.controls, roles.id, roles.time] if v and v in df.columns]].dropna()
    data = data.rename(columns={roles.id: "id", roles.time: "year"})
    cmd = f"{roles.y} L1.{roles.y} {' '.join(roles.x if isinstance(roles.x, str) else [roles.x])}"
    for c in roles.controls:
        cmd += f" {c}"
    mod = pydynpd.pydynpd(cmd, data, "id year")
    res = mod.estimate()
    return mod


def run_xtiv_py(df, roles: Roles):
    """面板 IV：linearmodels IV2SLS + 个体/时间虚拟变量吸收的等价实现（within 变换）。"""
    from linearmodels.iv import IV2SLS

    if not roles.endog or not roles.instrument:
        raise ValueError("panel IV requires endog and instrument")
    cols = [roles.y, roles.endog, roles.instrument, *roles.controls]
    data = df[[v for v in cols if v in df.columns]].dropna()
    exog = data[roles.controls] if roles.controls else None
    res = IV2SLS(data[roles.y], exog, data[roles.endog], data[roles.instrument]).fit(cov_type="robust")
    return _PMResult(res, "IV2SLS")


def run_panel_nl_py(df, roles: Roles):
    """面板非线性：pyfixest::feglm。"""
    import pyfixest as pf

    controls = " + ".join(roles.controls)
    fml = f"{roles.y} ~ {roles.x}" + (f" + {controls}" if controls else "") + f" | {roles.id}"
    return pf.feglm(fml, data=df, family="logit")


# ---- 04 causal 新增估计量 ----
def run_iv(df, roles: Roles):
    return run_iv_2sls(df, roles)


def run_event_study_py(df, roles: Roles):
    """事件研究：pyfixest + sunab（不依赖 pydynpd/statsmodels）。"""
    import pyfixest as pf

    gvar = roles.gvar or roles.treat
    if not gvar:
        raise ValueError("event study requires gvar")
    fml = f"{roles.y} ~ sunab({gvar}, {roles.time}) | {roles.id} + {roles.time}"
    return pf.feols(fml, data=df, vcov={"CRV1": roles.id} if roles.id else "hetero")


def run_cs_did_py(df, roles: Roles):
    """Callaway-Sant'Anna：differences::att_gt。"""
    from differences import ATTgt

    gvar = roles.gvar or roles.treat
    mod = ATTgt(data=df, cohort_column=gvar, time_column=roles.time, id_column=roles.id,
                outcome_column=roles.y, control_group="never_treated")
    return mod.fit()


def run_rd_py(df, roles: Roles, cutoff: float = 0.0, bandwidth: float | None = None):
    from rdrobust import rdrobust

    out = rdrobust(y=df[roles.y], x=df[roles.running], c=cutoff, h=bandwidth)
    return out


def run_psm_py(df, roles: Roles):
    """倾向得分最近邻匹配（statsmodels logit + sklearn NearestNeighbors）。"""
    import numpy as np
    import statsmodels.api as sm
    from sklearn.neighbors import NearestNeighbors

    data = df[[v for v in [roles.y, roles.treat, *roles.controls] if v in df.columns]].dropna()
    ps = sm.Logit(data[roles.treat], sm.add_constant(data[roles.controls].astype(float))).fit(disp=False)
    p = ps.predict(sm.add_constant(data[roles.controls].astype(float)))
    treated = data[data[roles.treat] == 1]
    control = data[data[roles.treat] == 0]
    if len(control) == 0 or len(treated) == 0:
        raise ValueError("PSM requires both treated and control units")
    nn = NearestNeighbors(n_neighbors=1).fit(p.loc[control.index].to_numpy().reshape(-1, 1))
    idx = nn.kneighbors(p.loc[treated.index].to_numpy().reshape(-1, 1), return_distance=False).ravel()
    matched_control = control.iloc[idx]
    att = float(np.mean(treated[roles.y].to_numpy() - matched_control[roles.y].to_numpy()))
    return {"att": att, "n_treated": int(len(treated)), "n_control_matched": int(len(matched_control)),
            "ps_model": ps, "matched": matched_control}


def run_ipw_py(df, roles: Roles):
    """IPW/AIPW：statsmodels 倾向得分 + sklearn 加权回归。"""
    import numpy as np
    import statsmodels.api as sm

    data = df[[v for v in [roles.y, roles.treat, *roles.controls] if v in df.columns]].dropna()
    ps = sm.Logit(data[roles.treat], sm.add_constant(data[roles.controls].astype(float))).fit(disp=False)
    p = np.clip(ps.predict(sm.add_constant(data[roles.controls].astype(float))), 0.01, 0.99)
    w = data[roles.treat] / p + (1 - data[roles.treat]) / (1 - p)
    res = sm.WLS(data[roles.y], sm.add_constant(data[[roles.treat]]), weights=w).fit(cov_type="HC1")
    return _PMResult(res, "WLS-IPW")


def run_scm_py(df, roles: Roles):
    """合成控制：pysyncon。"""
    from pysyncon import Dataprep, Synth

    unit = "pid" if "pid" in df.columns else roles.id
    treated_unit = int(df[unit].iloc[0])
    dataprep = Dataprep(
        foo=df,
        predictors=roles.controls,
        predictors_op="mean",
        time_predictors_prior=sorted(df[roles.time].unique())[:3],
        special_predictors=None,
        dependent=roles.y,
        unit_variable=unit,
        time_variable=roles.time,
        treatment_identifier=treated_unit,
        controls_identifier=[u for u in df[unit].unique() if u != treated_unit],
        time_optimize_ssr=sorted(df[roles.time].unique())[:3],
        time_plot=sorted(df[roles.time].unique()),
    )
    synth = Synth()
    synth.fit(dataprep)
    return {"loss": float(synth.loss(verbose=False)) if hasattr(synth, "loss") else None, "synth": synth}


# ---- 06 robustness 新增估计量 ----
def run_wild_boot_py(df, roles: Roles, reps: int = 9999):
    """Wild cluster bootstrap：wildboottest。"""
    import wildboottest

    return wildboottest.WildBootTest(
        data=df, y=roles.y, x=[roles.x, *roles.controls],
        cluster=roles.cluster, B=reps, param=roles.x,
    ).fit()


def run_multiplicity_py(pvalues, method: str = "holm"):
    from statsmodels.stats.multitest import multipletests

    return multipletests(pvalues, method=method)[1]


# ---- 08 spatial 新增估计量（spreg / libpysal，不依赖 geopandas） ----
def run_spatial_py(df, roles: Roles, model: str = "lag"):
    """截面空间回归：libpysal 权重 + spreg ML_Lag/ML_Error。"""
    import numpy as np
    from libpysal.weights import KNN
    from spreg import ML_Error, ML_Lag

    unit = "pid" if "pid" in df.columns else roles.id
    cross = df.drop_duplicates(subset=[unit]).dropna(subset=[roles.y, roles.x, *roles.controls, roles.lat, roles.lon])
    coords = cross[[roles.lon, roles.lat]].to_numpy(dtype=float)
    w = KNN.from_array(coords, k=5)
    w.transform = "r"
    y = cross[roles.y].to_numpy(dtype=float).reshape(-1, 1)
    x = cross[[roles.x, *roles.controls]].to_numpy(dtype=float)
    mod = ML_Lag(y, x, w=w) if model == "lag" else ML_Error(y, x, w=w)
    return {"model": mod, "weights": w, "coef": np.asarray(mod.betas).ravel(),
            "z": np.asarray(mod.z_stat), "n": int(mod.n)}


def run_spatial_panel_py(df, roles: Roles, model: str = "lag"):
    """面板空间回归：spreg Panel_FE_Lag / Panel_FE_Error。"""
    import numpy as np
    from libpysal.weights import KNN
    from spreg import Panel_FE_Error, Panel_FE_Lag

    cross = df.drop_duplicates(subset=[roles.id])
    coords = cross[[roles.lon, roles.lat]].to_numpy(dtype=float)
    w = KNN.from_array(coords, k=5)
    w.transform = "r"
    data = df.dropna(subset=[roles.y, roles.x, *roles.controls, roles.time]).sort_values([roles.id, roles.time])
    y = data[roles.y].to_numpy(dtype=float).reshape(-1, 1)
    x = data[[roles.x, *roles.controls]].to_numpy(dtype=float)
    t = data[roles.time].to_numpy()
    mod = Panel_FE_Lag(y, x, w=w, t=t) if model == "lag" else Panel_FE_Error(y, x, w=w, t=t)
    return {"model": mod, "weights": w, "coef": np.asarray(mod.betas).ravel(), "n": int(mod.n)}


def run_moran_py(df, roles: Roles):
    """全局 Moran's I：libpysal + esda。"""
    from esda.moran import Moran
    from libpysal.weights import KNN

    unit = "pid" if "pid" in df.columns else roles.id
    cross = df.drop_duplicates(subset=[unit]).dropna(subset=[roles.y, roles.lat, roles.lon])
    w = KNN.from_array(cross[[roles.lon, roles.lat]].to_numpy(dtype=float), k=5)
    w.transform = "r"
    mo = Moran(cross[roles.y].to_numpy(dtype=float), w)
    return {"moran": mo, "weights": w, "I": float(mo.I), "p": float(mo.p_sim)}


def run_interaction(df, roles: Roles):
    if not roles.moderator:
        raise ValueError("Interaction requires moderator role")
    temp = df.copy()
    temp["_interaction"] = temp[roles.x] * temp[roles.moderator]
    return run_ols(temp, roles.y, "_interaction", [roles.x, roles.moderator, *roles.controls], roles.fe, roles.cluster)


def run_group_models(df, roles: Roles) -> dict[str, Any]:
    if not roles.heterogeneity or roles.heterogeneity not in df.columns:
        raise ValueError("Heterogeneity requires grouping role")
    out = {}
    for value, part in df.groupby(roles.heterogeneity):
        if len(part) > max(8, len(roles.controls) + 3):
            out[f"{roles.heterogeneity}={value}"] = run_ols(part, roles.y, roles.x, roles.controls, roles.fe, roles.cluster if roles.cluster in part.columns else None)
    return out


def run_robustness(df, roles: Roles) -> dict[str, Any]:
    out = {"baseline_hc1": run_ols(df, roles.y, roles.x, roles.controls, roles.fe, None)}
    if roles.cluster:
        out["clustered"] = run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
    if roles.fe:
        out["no_fe"] = run_ols(df, roles.y, roles.x, roles.controls, [], roles.cluster)
    if roles.controls:
        out["no_controls"] = run_ols(df, roles.y, roles.x, [], roles.fe, roles.cluster)
    return out


def _model_params(model) -> dict[str, float]:
    params = getattr(model, "params", None)
    if params is None:
        return {}
    return {str(k): float(v) for k, v in params.items()}


def _model_stat(model, term: str) -> float | None:
    for attr in ("tvalues", "zstats"):
        values = getattr(model, attr, None)
        if values is not None and term in values:
            try:
                return float(values[term])
            except Exception:
                return None
    return None


def _model_pvalue(model, term: str) -> float | None:
    values = getattr(model, "pvalues", None)
    if values is not None and term in values:
        try:
            return float(values[term])
        except Exception:
            return None
    return None


def stars(p: float | None) -> str:
    if p is None or math.isnan(p):
        return ""
    return "***" if p < 0.001 else "**" if p < 0.01 else "*" if p < 0.05 else ""


def model_n(model) -> str:
    for attr in ("nobs",):
        if hasattr(model, attr):
            try:
                return str(int(getattr(model, attr)))
            except Exception:
                pass
    return ""


def model_r2(model) -> str:
    for attr in ("rsquared", "prsquared"):
        if hasattr(model, attr):
            try:
                return f"{float(getattr(model, attr)):.3f}"
            except Exception:
                pass
    return ""


def export_regression_table(
    models: dict[str, Any] | list[Any],
    path: str | Path,
    controls: list[str] | None = None,
    fe: list[str] | None = None,
    cluster: str | None = None,
    title: str = "Regression Table",
) -> Path:
    if not isinstance(models, dict):
        models = {f"({i + 1})": m for i, m in enumerate(models)}
    terms: list[str] = []
    for model in models.values():
        for term in _model_params(model):
            if term not in terms and not term.startswith("C(") and term.lower() not in {"intercept", "const"}:
                terms.append(term)
    rows: list[list[str]] = [[title, *["" for _ in models]], ["变量", *models.keys()]]
    for term in terms:
        coef_row = [display_name(term)]
        stat_row = [""]
        for model in models.values():
            params = _model_params(model)
            if term in params:
                p = _model_pvalue(model, term)
                coef_row.append(f"{params[term]:.3f}{stars(p)}")
                stat = _model_stat(model, term)
                stat_row.append(f"({stat:.3f})" if stat is not None else "")
            else:
                coef_row.append("-")
                stat_row.append("-")
        rows.extend([coef_row, stat_row])
    for ctrl in controls or []:
        if ctrl not in terms:
            rows.extend([[display_name(ctrl), *["控制变量" for _ in models]], ["", *["" for _ in models]]])
    for fe_var in fe or []:
        rows.append([f"{display_name(fe_var)}固定", *["是" for _ in models]])
    rows.append(["观测值", *[model_n(m) for m in models.values()]])
    r2_values = [model_r2(m) for m in models.values()]
    if any(r2_values):
        rows.append(["R²/Pseudo R²", *r2_values])
    note = "注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t/z 统计值。"
    if cluster:
        note += f" 标准误按 {cluster} 聚类。"
    rows.append([note, *["" for _ in models]])
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as fh:
        csv.writer(fh).writerows(rows)
    return path


def export_marginal_effects(models: dict[str, Any], path: str | Path, title: str = "Nonlinear Marginal Effects") -> Path:
    rows: list[list[str]] = [[title, *["" for _ in models]], ["变量", *models.keys()]]
    all_terms: list[str] = []
    effects: dict[str, dict[str, tuple[float, float | None]]] = {}
    for name, model in models.items():
        vals: dict[str, tuple[float, float | None]] = {}
        try:
            margeff = model.get_margeff(at="overall")
            frame = margeff.summary_frame()
            for term, row in frame.iterrows():
                vals[str(term)] = (float(row.iloc[0]), float(row.get("z", row.get("t", float("nan")))))
        except Exception:
            for term, val in _model_params(model).items():
                vals[term] = (val, _model_stat(model, term))
        effects[name] = vals
        for term in vals:
            if term not in all_terms:
                all_terms.append(term)
    for term in all_terms:
        coef_row = [display_name(term)]
        stat_row = [""]
        for name in models:
            if term in effects[name]:
                coef, stat = effects[name][term]
                coef_row.append(f"{coef:.3f}")
                stat_row.append(f"({stat:.3f})" if stat is not None and not math.isnan(stat) else "")
            else:
                coef_row.append("-")
                stat_row.append("-")
        rows.extend([coef_row, stat_row])
    rows.append(["注：非线性模型报告平均边际效应或预测概率；括号内为 z/t 统计值。", *["" for _ in models]])
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as fh:
        csv.writer(fh).writerows(rows)
    return path


def export_model_summary(path: str | Path, models: dict[str, Any], title: str) -> Path:
    sections = {}
    for name, model in models.items():
        try:
            sections[name] = str(model.summary())
        except Exception:
            sections[name] = str(model)
    return write_markdown(path, title, sections)


def script_index(out_root: str | Path, scripts: Iterable[str]) -> Path:
    rows = ["# Script Index", "", "| Order | Script |", "|---|---|"]
    for i, script in enumerate(scripts, 1):
        rows.append(f"| {i} | `{script}` |")
    path = Path(out_root) / "reports" / "script-index.md"
    path.write_text("\n".join(rows), encoding="utf-8")
    return path
