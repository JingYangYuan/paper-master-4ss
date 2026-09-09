# MinerU PDF → Markdown（lit 模块内置，自包含）

> 2026-09-05 由 mineru-pdf2md skill 合并入本模块：脚本 `modules/lit/scripts/mineru/pdf2md.py` 与 Token 配置 `modules/lit/scripts/mineru/.env.kie` 均为模块内部资产，lit 流程**不得引用外部 skill 路径**。

## 用途

文献综述的 Top-N 全文化（phase-1-search.md Step 10）：把下载的 PDF 批量转为带本地图片的 Markdown，供全文读取与综述写作。

## 模式

| 模式 | Token | 上限 | 适用 |
|---|---|---|---|
| 精准解析 v4（默认） | 是（`.env.kie` 内 JWT） | ≤200MB / ≤200页 / 批量50 | 常规论文 |
| 长文档切块 `--split-long` | 是 | 每块≤200页 | 教材/年鉴/超长报告 |
| Agent 轻量 `--agent` | 否（IP 限频） | ≤10MB / ≤20页 / 单文件 | Token 失效兜底 |

## 执行

```bash
# 项目注册表模式：每篇写入 fulltext/<paper_id>/document.md，并回写解析状态
python3 modules/lit/scripts/mineru/pdf2md.py \
  paper-workspace/02-literature/papers \
  --output paper-workspace/02-literature/fulltext \
  --registry paper-workspace/02-literature/paper-registry.csv

# 单文件超限（报 "pages exceeds limit" 时）
python3 modules/lit/scripts/mineru/pdf2md.py <PDF目录> --split-long --output <输出目录>

# Token 失效且文件 ≤10MB/≤20页 时
python3 modules/lit/scripts/mineru/pdf2md.py <单文件.pdf> --agent --output <输出目录>
```

- Token 来源优先级：`--token` 参数 → 目标目录/父目录 `.env.kie` → `~/.config/mineru/.env.kie` 等用户级 → `modules/lit/scripts/mineru/.env.kie`。
- Token 是 JWT（`eyJ` 开头），在 mineru.net 注册获取；格式：`MINERU_PIPELINE_ID=<jwt>`。
- 注册表模式输出结构：`<输出目录>/<paper_id>/document.md` + `<paper_id>/images/<论文名>/*`，MD 内为相对路径，可直接渲染。未使用注册表时保留旧的单目录输出行为。

## 质量与迭代规则

1. 转换后抽查 2–3 篇：正文是否完整、公式/表格是否乱码、图片是否本地化；失败文件换 `--agent` 或重试一次，仍失败由解析器写回 paper-registry.csv 的 parse_status 和 notes。
2. 知网 PDF 若为 CAJ 伪装（`%PDF` 魔数校验已在下载器拦截），不送 MinerU。
3. 转换结果统计（成功/失败/图片数）追加进搜索日志；是否可用于写作以注册表的 parse_status 和 review-evidence.csv 的证据定位为准。
4. 经验迭代：本文件的执行坑（超限阈值、失败兜底、抽查标准）每次实跑后回写。
