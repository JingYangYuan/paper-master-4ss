# 随包分发的 R 包库快照（`r-lib/4.6`）

本目录是**本地 R `site-library` 的完整快照**（179 个包 / 21871 个文件 / 495 MB），
按 R 的版本目录布局存放（`r-lib/<R 大版本>.<小版本>/`），用于让 `03-regression` 的 R 模板
**免 `install.packages`** 直接运行。

## 快照来源

| 项 | 值 |
|---|---|
| R 版本 | `4.6.0 (2026-04-24)` |
| 平台 | `aarch64-apple-darwin25.4.0`（macOS arm64） |
| 包数 | 179 |
| 体积 | 495 MB |

## 用法

在项目脚本开头把它加进 `.libPaths()`（**追加**，不覆盖用户自己的库）：

```r
.libPaths(c(
  "<skill 根目录>/modules/analysis/templates/_shared/r-lib/4.6",
  .libPaths()
))
```

或按项目需要写成可复现的一行：

```r
# 依 analysis-execution-plan 决定是否需要随包 R 库；不需要时删除本段
skill_lib <- file.path(Sys.getenv("SKILL_ROOT"), "modules/analysis/templates/_shared/r-lib/4.6")
if (dir.exists(skill_lib)) .libPaths(c(skill_lib, .libPaths()))
```

**两种方式二选一**：已用 `install.packages` 装好依赖的环境**不要**再加载本目录，避免版本混用。

## 平台与版本约束（重要）

- 快照里的 `.so` / `.dylib` 是**编译产物**，只在 **R 4.6.x + macOS arm64** 上可直接加载。
- 其它 R 版本或其它平台（Linux / Windows / macOS x86_64）**不能**直接用本快照，
  请改用 `references/r-ecosystem-setup.md` 的 `install.packages` 清单方式。
- 若 R 版本不同但想尝试复用纯 R 包（无编译产物的包），可只加 `.libPaths()` 而跳过含 `.so` 的包；
  不建议这么做，版本错配的报错通常难以定位。

## 覆盖范围

模板实际依赖的包（`AER`、`censReg`、`sampleSelection`、`plm`、`fixest`、`did`、`MatchIt`、
`WeightIt`、`cobalt`、`Synth`、`sensemakr`、`quantreg`、`lmtest`、`sandwich`、`car`、`rdrobust`、
`marginaleffects`、`fwildclusterboot`、`robomit` 等）**全部在内**。

**不在内**（属 R 随附包，随 R 本体安装，不属 `site-library`）：
`MASS`、`nnet`、`survival`、`boot`、`Matrix`、`stats` 等 recommended/base 包。

**已知缺失**：`spdep`、`spatialreg`、`splm` 未收录——它们的依赖链 `sf` → GDAL 在本机无法满足
（见 `references/r-ecosystem-setup.md`）。R 模板的空间计量因此由 `_shared/r_common.R` 的
**base R 线性代数实现**承载，不依赖这三个包。

## 许可与再分发

本目录收录的是**第三方作者**发布的 CRAN 包，版权归各作者所有（GPL-2/GPL-3/MIT 等各有不同），
**不含** R 本体及其 recommended 包。
本仓库以「便于复现分析环境」为目的做本地快照，再分发前请自行确认各包许可；
如需严格的许可合规，请改用 `references/r-ecosystem-setup.md` 的 `install.packages` 清单方式。

## 维护

刷新快照（例如新装了包之后）：

```bash
R_LIB="$(Rscript -e 'cat(.libPaths()[1])')"
rsync -a --delete --exclude='.DS_Store' "$R_LIB/" \
  "paper-master-4ss/modules/analysis/templates/_shared/r-lib/4.6/"
```

刷新后请复核一致性（注意：文件数上万，`shasum` 直接传参会超出 `ARG_MAX`，用 `-exec … +` 分批）：

```bash
diff -r --brief "$R_LIB" "<快照目录>" | grep -v '\.DS_Store'
```
