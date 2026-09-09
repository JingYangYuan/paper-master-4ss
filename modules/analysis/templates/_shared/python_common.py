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


def log_run(args, step: str, status: str, outputs: Iterable[str] = (), note: str = "") -> None:
    p = run_log_path(args)
    p.parent.mkdir(parents=True, exist_ok=True)
    if not p.exists():
        p.write_text("# Analysis Run Log\n\n| Date | Step | Status | Outputs | Note |\n|---|---|---|---|---|\n", encoding="utf-8")
    output_text = "<br>".join(str(x) for x in outputs) if outputs else "-"
    with p.open("a", encoding="utf-8") as fh:
        fh.write(f"| {date.today().isoformat()} | {step} | {status} | {output_text} | {note or '-'} |\n")


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


def run_mediation_baron_kenny(df, roles: Roles) -> dict[str, Any]:
    if not roles.mediator:
        raise ValueError("Mediation requires mediator role")
    return {
        "total": run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster),
        "path_a": run_ols(df, roles.mediator, roles.x, roles.controls, roles.fe, roles.cluster),
        "path_b": run_ols(df, roles.y, roles.mediator, [roles.x, *roles.controls], roles.fe, roles.cluster),
    }


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
