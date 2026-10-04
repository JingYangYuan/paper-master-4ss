# 随包分发的 Stata 社区 ado 包（`plus/`）

本目录是**本地 `ado/plus` 的完整快照**（2503 个文件 / 83 MB），按 Stata 的 ado 库原目录结构存放，
用于让 `03-regression` 的 Stata 模板**开箱即用**，无需再逐个 `ssc install`。

## 内容

| 类别 | 数量 | 说明 |
|---|---|---|
| `.ado` | 1186 | 命令实现 |
| `.sthlp` / `.hlp` | 660 / 350 | 帮助文件 |
| `.mlib` / `.mata` | 65 / 59 | Mata 库与源码（如 `moremata`、`gtools`） |
| `.plugin` | 25 | **平台相关编译插件**（macOS / Linux / Windows 三平台各一份） |
| `.mo` / `.dlg` / `.scheme` / `.trk` | 33 / 39 / 49 / 6 | Mata 编译缓存、对话框、配色方案、Stata 包跟踪文件 |

## 用法

把本目录加入 `adopath` 即可（不覆盖用户自己的 `ado/plus`）：

```stata
adopath + "<skill 根目录>/modules/analysis/templates/_shared/stata-ado/plus"
```

在 `paper-workspace` 项目脚本中，推荐写成可复现的一行：

```stata
* 依 analysis-execution-plan 决定是否需要随包 ado；不需要时删除本行
adopath + "$SKILL_ROOT/modules/analysis/templates/_shared/stata-ado/plus"
```

若目标环境已用 `ssc install` 装好依赖，**不要**加载本目录，避免版本混用；两种方式二选一。

## 平台与插件注意

- `.plugin` 是编译产物，**只在对应平台可用**。本快照取自 macOS arm64 环境，实际生效的是
  `gtools_macosx_v3.plugin`、`synthopt.plugin` 等；Linux / Windows 需用各自平台的同名插件。
- 若某插件加载失败，报错形如 `Could not load plugin: .../xxx.plugin`，此时对**该命令**重新安装即可：
  ```stata
  ssc install gtools, replace      // reghdfe / ppmlhdfe 依赖
  ssc install synth, replace       // 修复 synthopt.plugin 平台错配
  ```
- `honestdid` 依赖 `honestosqp` / `honestecos` 插件，验收命令为 `honestdid _plugin_check`。

## 许可与再分发

本目录收录的是**第三方作者**发布的 Stata 社区包（SSC / GitHub 源），版权归各作者所有，
**不含** Stata 官方 base ado（那部分属商业软件，不可再分发）。
本仓库以「便于复现分析环境」为目的做本地快照，再分发前请自行确认各包许可；
如需严格的许可合规，请改用 `references/stata-ecosystem-setup.md` 的 `ssc install` 清单方式。

## 维护

刷新快照（例如新装了包之后）：

```bash
rsync -a --delete "<用户 ado>/plus/" \
  "paper-master-4ss/modules/analysis/templates/_shared/stata-ado/plus/"
```

刷新后请复核整树一致性：

```bash
diff -r --brief "<用户 ado>/plus" "paper-master-4ss/modules/analysis/templates/_shared/stata-ado/plus"
```
