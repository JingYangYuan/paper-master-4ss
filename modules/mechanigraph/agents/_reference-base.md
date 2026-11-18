---
base-id: mechanigraph-2026.10.24
module: mechanigraph
---

# mechanigraph 模块参考库回查底座

本文件是 `mechanigraph` 模块 2 个顾问角色的唯一参考回查源。各顾问卡仅保留指针行 `参考库回查: base=mechanigraph-2026.10.24; tier=…; 判据=…; 缺口=…`。

## B1 核心摘录（≤1200 字，主流程注入用）

学术机制图绘制分两步执行：先确定拓扑构型，再执行几何坐标计算与 SVG 编码。

构型选择依据文本内在因果结构而非主观审美，8 类经典学术拓扑对应关系为：流水线（时序演化）、纵向层级（宏观—中观—微观）、双系统对偶（政府—市场、正式—非正式等对偶交互）、网络协同（多主体网状互动）、闭环回路（正负反馈与再生产）、矩阵四象限（双维交叉分类）、阶梯演化（多阶段跃迁）与齿轮啮合（多要素协同驱动）。应先提取因果实体（起点、中介、调节/边界、产出、反馈），再匹配构型并核定画布预算。

画布规格按实体规模与文本宽度选定：`900×600`（标准）、`1320×720`（大型三元综合）、`1200×650`（宽幅时序）或 `900×1000`（纵向深层），严禁先绘图后挤压空间。

矢量排版硬规范：纯白底（`#ffffff`/`none`）、纯黑字与黑线（`#000000`）、零灰色填充；核心强调项用黑体 20–24px（`font-weight="normal"`），次级说明用加粗仿宋 14–16px，英文数字用 Times New Roman/Arial；`viewBox` 与数值 `width`/`height` 1:1 绑定，禁用百分比；卡片内边距 12–20px，相邻卡片间距 20–45px，外框留白 ≥35px，回路净空 ≥35px，斜线标注净空 ≥25px；单向连线仅用 `marker-end`，双向关系用平行双线；XML 注释内禁用双连字符 `--`。

图内严禁出现主标题、作者标注或数据来源，此类信息留由正文图注承担。

交付前须完成「生成 SVG -> 无头渲染 PNG -> 逐项视觉自检 -> 坐标修正重渲染 -> 输出 SVG + PNG + metadata.json」完整闭环。

## B2 判据条目

C01 因果实体提取完整：驱动起点/自变量、核心中介、调节/边界条件、产出/因变量与反馈路径五要素齐备（`references/layout_catalog.md`）。

C02 构型匹配准确：8 类拓扑（Pipeline / Hierarchy / Dual-System / Network / Loop / Matrix / Steps / Gear）与文本因果结构相符，并阐明理论适配逻辑（`references/drawing_patterns_reference.md`）。

C03 备选构型说明：列明至少一个被排除的备选构型及排除原因。

C04 画布预算合理：依据实体数量与文本长度预设画布规格与主轴布局（`references/design_system.md` §2）。

C05 纯黑白配色规范：严格白底黑字黑线，零彩色、零灰底、零反白。

C06 字阶与字体栈规范：核心项黑体 20–24px 不加粗；次级项加粗仿宋 14–16px；英文数字 Times New Roman/Arial。

C07 视口绑定规范：`viewBox` 与数值型 `width`/`height` 同时声明，禁用百分比尺寸。

C08 间隙与净空标准：卡片内边距 12–20px、相邻卡片 20–45px、外框留白 ≥35px、回路净空 ≥35px、斜线标注净空 ≥25px（`references/design_system.md` §4–§5）。

C09 连线与箭头规范：仅使用 `marker-end`，禁用 `marker-start`；双向关系采用平行双线。

C10 图内无标题与注释：不出现主标题（「图X XXX机制图」）、「作者自制」或「数据来源」。

C11 XML 语法安全：SVG 注释中无连续双连字符 `--`。

C12 几何居中对称：坐标经居中计算，四向留白对称。

C13 无穿透与无蹭线：连线不穿过文字或标题徽标，斜线/曲线上方标注不蹭线。

C14 渲染自检闭环：运行 `scripts/render_svg.py` 导出 PNG 并按清单逐项审查，发现瑕疵须修改坐标并重渲染直至通过。

C15 交付物齐全：输出 SVG、PNG 与 `metadata.json`（含构型分类、核心实体、画布尺寸、字体声明与自检结果）。

C16 风格选项准备：出图前向用户提供构型流派、外围大框样式与分箱连线风格三项确认。

C17 职责边界遵守：不在图内写正文解释、不替代正文排版、不虚构因果链条。

C18 可追溯要求：判断指向具体参考规范或渲染结果；缺失标「待核验」。

## B3 角色附加项

| 标准名 | 判据条目 | 附加参考 | 派活档位 |
|---|---|---|---|
| `paper-mechanigraph-topology-consultant` | C01 C02 C03 C04 C16 C17 C18 | `references/drawing_patterns_reference.md`、`references/layout_catalog.md`、`references/design_system.md` §2 | T1（单图复刻走 L0） |
| `paper-mechanigraph-svg-designer` | C05 C06 C07 C08 C09 C10 C11 C12 C13 C14 C15 C17 | `references/design_system.md`、`references/drawing_patterns_reference.md`、`resources/academic_defs.svg`、`scripts/render_svg.py` | T2（writer） |

L1 默认单点角色：`paper-mechanigraph-topology-consultant`（确保拓扑构型准确；单图快速复刻可走 L0 由主流程完成）。
