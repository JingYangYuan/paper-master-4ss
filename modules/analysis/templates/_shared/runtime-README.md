# 运行库快照：为什么不随包分发、如何获取

本 skill 曾经在 `templates/_shared/r-lib/` 与 `templates/_shared/stata-ado/` 随包分发两份第三方编译快照（合计约 494 MB）。2026-10 起不再随主仓分发，原因有二：

1. **平台限制**：R 快照的 `.so`/`.dylib` 与 Stata 快照的 `.plugin` 都是编译产物，只在构建平台（R 4.6.x + macOS arm64）可直接加载；在 Windows/Linux 上是零价值的死重。
2. **覆盖缺口**：R 快照实际缺失模板硬依赖（`readxl` 等，见 `r-ecosystem-setup.md` §3 实测清单），"开箱即用"的承诺从未真正兑现；且快照约 82% 的字节（C/C++ 头文件、帮助文档）不参与运行。

## 三种获取方式（与各 ecosystem 文档一致）

| 方式 | 适用 | 入口 |
|------|------|------|
| ① 官方源在线安装（默认） | 联网环境，全平台 | R：`install.packages()`（Windows 走 CRAN `win.binary`，macOS 可用 PPM 二进制）；Stata：`ssc install`，包清单见 [stata-packages.txt](stata-packages.txt) |
| ② 锁文件复现 | 论文复现、版本可追溯 | R：`renv::snapshot()`/`renv::restore()`；Stata：按 `stata-packages.txt` 逐包 `ssc install` |
| ③ Release 资产（离线兜底） | 断网环境 | runtime 仓库 Release 下载 `r-lib-4.6-macos-arm64.zip` 与 `stata-ado-plus-<date>.zip`，解压到 `<skill>/runtime/`；加载方式见 `r-ecosystem-setup.md` §3.5 与 `stata-ecosystem-setup.md` §4.1 |

方式 ① 与 ② 不涉及第三方二进制再分发，也是许可上最干净的选择。方式 ③ 仍是再分发，见下方许可说明。

## 平台约束（方式 ③ 必读）

- R 快照：仅 R 4.6.x + macOS arm64 可直接加载；不含 recommended 包（`MASS`/`nnet`/`survival` 等）；不含 `spdep`/`spatialreg`/`splm`（R 空间计量由 `r_common.R` 的 base R 实现承载）。
- Stata 快照：`.plugin` 平台相关，解压时排除 `.plugin`，加载失败的命令对该包 `ssc install <pkg>, replace` 重装。
- 已用方式 ①/② 装好依赖的环境不要再加载快照目录，避免版本混用。

## 许可与再分发

快照收录的是第三方作者的 R 包（GPL-2/GPL-3/MIT 等各异）与 Stata 社区包（SSC/GitHub 源），版权归各作者所有；不含 Stata 官方 base ado（商业软件，不可再分发）。Release 资产以"便于复现分析环境"为目的再分发，使用前请自行确认各包许可；如需严格合规，请改用方式 ①/②。

## 维护（刷新快照，作者机操作）

```bash
# R：刷新 site-library 后重新打包（剔除不参与运行的字节）
rsync -a --delete "<R site-library>/" "runtime-staging/r-lib/4.6/"
# 打包前剔除 include/ 与 help/html/doc/Meta/（约 82% 字节），见 make_runtime_assets 脚本

# Stata：刷新 ado/plus
rsync -a --delete "<用户 ado>/plus/" "runtime-staging/stata-ado/plus/"
# 复核整树一致性
diff -r --brief "<用户 ado>/plus" "runtime-staging/stata-ado/plus"
```

刷新后更新 Release 资产并同步本文件的体积/包数声明（声明值必须来自 `du`/`find | wc -l` 实测，不得沿用旧数）。
