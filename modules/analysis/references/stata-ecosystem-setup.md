# Stata 执行通道与依赖安装

本文件供 `modules/analysis/` 在需要运行 Stata 脚本时按需读取。Stata 统一经 **statamcp（软件 Stata MCP 服务）** 执行，覆盖安装配置、通道验收、调用规范、包源、社区包和常见故障。

---

## 1. 安装与配置 statamcp

Stata 本体为商业软件（要求 Stata 17+），需自行购买并安装；MCP 服务经 statamcp 桥接。安装与配置以仓库 README 为权威来源：<https://github.com/JingYangYuan/stata-mcp>。

一键部署（Windows，PowerShell）：

```bash
git clone https://github.com/JingYangYuan/stata-mcp.git
cd stata-mcp
powershell -ExecutionPolicy Bypass -File deploy.ps1
# 默认 Stata 路径取环境变量或常见安装位置；其他位置/端口显式指定：
powershell -ExecutionPolicy Bypass -File deploy.ps1 -StataPath "<Stata 安装目录>" -Port 4001
```

部署脚本完成三件事：安装 VS Code 扩展 DeepEcon.stata-mcp 并预构建其 Python venv（VS Code 仅安装期需要，运行时不需要）；把 `mcp.servers["stata-mcp"] → http://localhost:<port>/mcp-streamable`（默认端口 4001）写入宿主的用户级配置文件（位置以宿主文档为准）；注册 SessionStart hook（`stata-mcp-start.ps1` 探测 `http://localhost:4001/health`，服务未运行则自动拉起）。脚本幂等可重复运行，`uv` 缺失时自动安装。

其他平台或手动配置：按仓库 README 对应章节把同一 MCP 端点注册进软件 `mcp.servers["stata-mcp"]`，重启会话后按 §2 验收；验收不通过时不得运行任何 Stata 分析，只能记录阻断。

---

## 2. statamcp 验收与调用规范

### 2.1 验收（写入 run-log）

1. `stata_session`（action=list）：确认 MCP 可达；记录 `default` 会话状态、`multi_session_enabled` 与可用会话数。
2. `stata_run_selection`（selection=`display 1+1`）：返回 `2` 即通道就绪。

两步均通过后，在 `run-log-[date].md` 记录"Stata 通道：statamcp 已验收"。

### 2.2 调用规范

| 工具 | 用途 | 关键参数 |
|---|---|---|
| `stata_run_file` | 执行 `.do` 文件（生产逻辑唯一入口） | `file_path`（脚本路径）、`working_dir`（`.do` 内相对路径的基准目录，通常为脚本所在目录或 `paper-workspace/04-analysis`）、`timeout`（默认 600 秒，重回归/Bootstrap 显式调大，如 1800）、`session_id`（并行子流程各用独立 ID） |
| `stata_run_selection` | 环境探测与单点验证（如 `display 1+1`） | `selection`、`working_dir`、`timeout`、`session_id`；不得替代生产 `.do` |
| `stata_session` | 会话管理 | action=list 查看状态；action=destroy 清理残留会话后续跑 |

并行子流程（主回归、稳健性、机制检验等互不依赖的任务）为每个任务指定独立 `session_id`；同一 `session_id` 内的调用串行执行。`.do` 文件保存为 UTF-8，路径使用相对 `working_dir` 的相对路径或绝对路径，避免依赖调用方当前目录。

每次调用的返回输出、失败信号（Stata `r(...)`、报错文本）和产物路径写入 `run-log-[date].md`。

---

## 3. 包源配置（SSC 镜像）

```stata
* 保持默认
net set ado https://fmwww.bc.edu/repec/bocode/
```

---

## 4. 关键依赖安装（社区包）

包清单的唯一事实源是 [stata-packages.txt](../templates/_shared/stata-packages.txt)（每行一个包名，`#` 为注释；`github:` 行走 `net install`）。在 Stata 中循环安装：

```stata
* 默认通道：SSC 官方源（需联网）
foreach p of global PKGS {   // PKGS 由 stata-packages.txt 读入或手工填入
    ssc install `p', replace
}
* GitHub 源包（如 scpi）：
net install scpi, from("https://raw.githubusercontent.com/nppackages/scpi/main/stata") replace
```

手工逐包安装时，直接按 `stata-packages.txt` 每行执行 `ssc install <pkg>, replace`。

**依赖差异与构建前置**（实测）：

- `moremata` 是 Mata 函数库而不是 ado 命令，`which moremata` 必然失败；用依赖它的 `kmatch` 实际估计成功作为功能验收标准。
- `synth` 的 `synthopt.plugin` 是平台相关的编译插件：装成 Windows PE 或 x86_64 版本会在 macOS arm64 上报 `Could not load plugin`。`ssc install synth, replace` 可重新拉到 universal Mach-O 版本。
- `honestdid` 依赖编译插件，验收用 `honestdid _plugin_check`（加载 `honestosqp`/`honestecos` 插件成功即通过）。
- `07-ml` 的三个 ML 社区包各有坑，装完必须验收，不能看 `ssc install` 返回成功就算过：
  - `lasso`、`elasticnet`、`ivregress`、`pca`、`cluster` 是 Stata 16+ 自带，**不需要**安装；`version 16` 以下的 Stata 直接阻断。
  - `pdslasso` 依赖 `lassopack`，`ssc install pdslasso` 不会自动装它；验收用 `which lassopack`。
  - `ddml` 先在 SSC 找，找不到再走 GitHub（`net install ddml, from("https://raw.githubusercontent.com/aahrens1/ddml/main") replace`）；验收用 `help ddml` 能打开且 `ddml` 不报 unrecognized command。
  - `rforest` 只给回归森林（Breiman 口径），预测与置换重要性可用；因果森林没有等价实现，`03-heterogeneity` 不给个体 CATE。
- 装不上就阻断并在 `reports/ml-blocked-<子流程>-<date>.md` 写安装指引，不得用 `regress` 手写循环冒充 lasso 或 DML。

社区包在 statamcp 会话内安装一次即可（用 `stata_run_selection` 运行安装命令），后续所有会话共享同一 ado 路径。

---

## 4.1 离线安装（Release 资产）

无法联网时，从 runtime 仓库的 Release 下载 `stata-ado-plus-<date>.zip`，解压到 `<skill>/runtime/ado/plus`（解压时排除 `.plugin`——平台相关二进制，误装报 `Could not load plugin`），然后：

```stata
adopath + "<skill>/runtime/ado/plus"
```

验收：`which reghdfe` 返回路径；`honestdid _plugin_check` 加载插件成功（该命令需联网装 honestdid，离线时以 `which reghdfe` 为准）。

获取方式总览与维护流程见 [runtime-README.md](../templates/_shared/runtime-README.md)。

---

## 5. 故障排除

| 症状 | 原因 | 解决 |
|------|------|------|
| `stata_session`（action=list）不可达 | statamcp 服务未部署或未运行 | 按 §1 安装/配置；确认健康端点（默认 `http://localhost:4001/health`）可达、SessionStart hook 已注册后重启会话 |
| `stata_run_selection` 返回报错或超时 | 会话被长任务占满或已失效 | `stata_session`（action=list）查状态；残留会话 action=destroy 后重试验收 |
| 并行任务相互等待 | 多个调用共用同一 `session_id` | 互不依赖的子流程改用独立 `session_id`（受 `max_sessions` 限制） |
| `stata_run_file` 输出 `file not found` | `file_path` 或 `.do` 内相对路径基准不符 | 核对 `file_path` 与 `working_dir`；`.do` 内路径改绝对路径或与 `working_dir` 一致 |
| Stata `r(...)` 错误码 | 脚本级错误（变量缺失、语法、包缺失） | 按返回文本定位；社区包缺失先按 §4 安装 |
| 输出乱码 | 编码问题 | `.do` 文件保存为 UTF-8；Stata 18+ 默认支持 Unicode |
| 服务日志排查 | 部署或运行异常 | 查看仓库 README 指引的日志位置（如 `%TEMP%\stata-mcp-standalone.log`） |

---

## 6. 其他语言

- Python 环境：[python-ecosystem-setup.md](python-ecosystem-setup.md)
- R 环境：[r-ecosystem-setup.md](r-ecosystem-setup.md)
