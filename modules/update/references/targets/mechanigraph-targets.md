# Mechanigraph Targets

## 模块边界

mechanigraph 模块负责社科学术机制图（理论机制图、分析框架图、因果演化模型、政策网络、治理体系）的纯矢量 SVG 自动化生成、构型匹配、复刻与无头渲染自检修复。核心产物统一交付至 `paper-workspace/figures/`。候选更新不得破坏纯黑白白底、大字号无加粗黑体与加粗仿宋字阶、无图表主标题与边角注释等核心出版级不可逾越红线。

## 可更新目标

| Target surface | Target files | 适用候选 | Risk tier |
|---|---|---|---|
| `knowledge-reference` | `modules/mechanigraph/references/drawing_patterns_reference.md` | 8 大构型几何样板参数、因果图示映射规则、代码模板 | low |
| `knowledge-reference` | `modules/mechanigraph/references/design_system.md` | 间隙留白规范、画布动态预算、防蹭线曲线公式、坐标系统 | low |
| `knowledge-reference` | `modules/mechanigraph/references/layout_catalog.md` | 期刊经典拓扑实证案例库、分类标准 | low |
| `knowledge-reference` | `modules/mechanigraph/resources/academic_defs.svg` | SVG 箭头 marker 定义、标准学术图形元组件 | low |
| `knowledge-reference` | `modules/mechanigraph/examples/*.svg` | CSSCI/SSCI 期刊出版级标准样例 SVG | low |
| `workflow-protocol` | `modules/mechanigraph/SKILL.md` | 入口规范、风格询问交互、16 大制图红线、自检闭环 | medium |
| `workflow-protocol` | `modules/mechanigraph/agents/*.md` | `topology-consultant` 与 `svg-designer` 职责与核查清单 | medium |
| `tooling-template` | `modules/mechanigraph/scripts/render_svg.py` | 跨平台无头 Chrome CLI / Selenium 渲染与截图逻辑 | high |
| `tooling-template` | `modules/mechanigraph/scripts/generate_mechanism.py` | 基础拓扑构型代码生成器与参数接口 | high |
| `tooling-template` | `modules/mechanigraph/scripts/batch_process_images.py` | 原图批量解析与视觉复刻执行脚本 | high |
| `tooling-template` | `modules/mechanigraph/scripts/extract_layouts.py` | 多模态拓扑聚类提取脚本 | high |

## 路由提示

- 新增学术机制图拓扑构型、代码模版或微调规范优先进入 `references/drawing_patterns_reference.md`。
- 几何布局计算、文字安全走廊公式或间距标准更新进入 `references/design_system.md`。
- 涉及前置询问偏好流程（`ask_user`）或自检审查闭环协议的变更，目标面标为 `workflow-protocol`。
- 涉及渲染器（`render_svg.py`）或生成器（`generate_mechanism.py`）的脚本更新必须给出跨平台（macOS/Linux/Windows）测试用例和预期视觉效果，目标面标为 `tooling-template`。
