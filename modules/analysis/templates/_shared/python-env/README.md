# Python 分析环境（锁文件方式）

本目录用**锁文件 + 安装脚本**固定 Paper Analysis 4SS 的 Python 依赖，而**不是**分发 venv 快照。

## 为什么不分发 venv

| 原因 | 说明 |
|---|---|
| 不可重定位 | venv 的 `pyvenv.cfg`、`bin/*` 内含**绝对路径**，拷贝到别处即失效 |
| 平台/版本锁定 | `site-packages` 里是 `cp311-macosx_*_arm64` 编译产物，只在 Python 3.11 + macOS arm64 可用 |
| 超出 GitHub 限制 | 完整 venv 1.2 GB，其中 `_polars_runtime.abi3.so`（153 MB）与 `libllvmlite.dylib`（124 MB）**超过单文件 100 MB 上限**，直接推送会被拒 |
| 这两个文件不可删 | `numba` 被 `pandas`/`statsmodels`/`linearmodels`/`pyfixest`/`rdrobust`/`wildboottest`/`esda`/`libpysal` 依赖；`polars` 被 `statsmodels`/`differences` 依赖 |

因此 Python 侧交付**锁文件**：可复现、跨机器可用、无体积与许可负担。

## 文件

| 文件 | 用途 |
|---|---|
| `requirements-lock.txt` | `pip freeze` 全量锁定（99 个包，含精确版本） |
| `install_python_env.sh` | 建 venv → 按锁文件安装 → 自动验收 |

## 用法

```bash
bash templates/_shared/python-env/install_python_env.sh                 # 默认装到本目录下 venv/
bash templates/_shared/python-env/install_python_env.sh /tmp/pm4ss-venv # 指定目标目录
bash templates/_shared/python-env/install_python_env.sh /tmp/pm4ss-venv python3.12  # 指定解释器
```

脚本最后会跑验收（`import` 全部关键包），输出 `PY-ENV-OK <版本>` 才算成功。

安装完成后运行模板：

```bash
/tmp/pm4ss-venv/bin/python templates/03-regression/08-spatial/spatial_models.py \
  --out-root paper-workspace/04-analysis
```

## 环境基线

| 项 | 值 |
|---|---|
| Python | `3.11.15` |
| 平台 | `macOS-27.0.1-arm64` |
| 关键包 | `pyfixest 0.60.0`、`differences 0.3.0`、`linearmodels 7.0`、`statsmodels 0.15.0`、`pysyncon 1.7.0`、`spreg 1.9.0`、`pydynpd 0.2.2`、`lifelines 0.30.3`、`rdrobust 2.1.0`、`wildboottest 0.3.2`、`esda 2.9.0`、`libpysal 4.14.1` |

要求 **Python >= 3.11**（`pyfixest` / `differences` 等要求）。

## 已知生态缺口

以下方法在 Python 生态无维护实现，模板中**不提供**，请使用 Stata 或 R 模板：

- Tobit / 删失回归
- Heckman / 样本选择模型
- 面板设定选择检验（Hausman、Breusch-Pagan LM）
- Oster `psacalc` 未观测混淆敏感性分析

多重检验校正用 `statsmodels.stats.multitest`（Holm/BH），**不**等价于 Stata 的 `rwolf`/`wyoung`。

## 许可

锁文件只记录**包名与版本号**，不包含任何第三方代码，无再分发问题。
各包许可见 PyPI / 各项目仓库。
