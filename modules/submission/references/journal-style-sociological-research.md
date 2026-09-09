# 社会学研究范式投稿样式说明

本文件用于 `paper-submission-4ss` 的内置模板和格式检查。

## 来源层级

| 层级 | 来源 | 用途 |
|---|---|---|
| 官方要求 | 《社会学研究》征稿要求，https://www.shxyjzz.cn/tongzhigonggao/2020/0831/325.html | 投稿要素、参考文献标准、稿件基本信息 |
| 参照来源 | 《社会》投稿指南，https://www.society.shu.edu.cn/CN/column/column35.shtml | 中文社会学期刊夹注与参考文献细化体例 |
| 参照来源 | 中国社会科学杂志社投稿须知，https://sscp.cssn.cn/tzgg/202502/t20250227_5849425.shtml | 社科期刊通用投稿伦理、原创性和格式意识 |
| 内置模板来源 | `/Users/yjy/年会征文-元景阳.docx` | `templates/sociological-research-default.docx` 的 Word 版式、样式和页脚页码格式 |

## 必检要素

`check_docx_format.py --style sociological-research` 必须检查：

- 标题。
- 作者姓名与单位信息。
- 中文摘要或内容提要。
- 英文摘要。
- 中文关键词。
- 英文关键词。
- 正文主体。
- 注释或脚注。
- 参考文献。
- 作者简介。
- 联系方式。

缺少上述项目时，在 `format-check-report.md` 中标记为 `FAIL` 或 `WARN`。

## 参考文献

《社会学研究》公开要求中说明参考文献按 GB/T 7714 执行。本模块默认将 `sociological-research` 的文后参考文献目标体例设为 GB/T 7714，并允许中文社会学常见作者-年份夹注作为正文引用形式。

## Word 版式边界

版式检查以 `templates/sociological-research-default.docx` 为默认样式。该模板从 `/Users/yjy/年会征文-元景阳.docx` 抽取格式，生成时已移除样本文档正文、表格、图片和文后参考文献内容。

- 页面：A4 纵向；上、下页边距 2.54 cm，左、右页边距 3.00 cm。
- 页脚：保留样本文档的居中页码字段格式。
- 正文 `Normal`：Times New Roman，10.5 pt；两端对齐；首行缩进约 0.74 cm；段后 5 pt。
- 主标题 `Heading 1` / `标题 1`：Times New Roman，22 pt；居中；单倍行距；无首行缩进、无字符首行缩进。
- 作者行 `作者`：Times New Roman，12 pt；居中；无首行缩进。
- 摘要、关键词、中英文摘要关键词 `摘要` / `关键词` / `英文摘要` / `英文关键词`：Times New Roman，9 pt；无首行缩进；英文标签可加粗。
- 其余标题 `Heading 2` / `标题 2`：Arial，12 pt；居中；单倍行距；段前 26 pt、段后 5 pt；导出投稿稿默认移除标题自动分页设置。
- 二级节标题 `Heading 3`：Arial，加粗；左对齐；段前 15.6 pt。
- 图题/图注 `图片`：居中；单倍行距；段前 5 pt；与后续段落保持同页。
- 参考文献 `参考文献`：悬挂缩进约 1.06 cm，沿用样本文档的 Zotero/GB 类参考文献排版设置。

默认导出清洗规则：

- Markdown 文件开头的 YAML frontmatter 不进入 Word。
- 独立成行的 Markdown 分割线 `---`、`***`、`___` 不进入 Word；表格分隔行和代码块内容不在此规则内。
- 所有 `Heading`/`标题` 样式的段落首行缩进必须为 0，不得继承正文 Normal 的首行缩进。
- 主标题使用 `Heading 1` / `标题 1`；主标题之后的非三级标题统一使用 `Heading 2` / `标题 2`，`（一）...`、`（二）...` 这类中文三级标题保留 `Heading 3` / `标题 3`，`1. ...`、`1、...`、`（1）...` 这类数字小标题使用正文 `Normal`，不得保留 `Title` 或后续 `Heading 1`。
- `Heading 1/2/3` 不得保留 `pageBreakBefore`、`keepNext` 或 `keepLines` 等标题自动分页控制。
- `摘要：`、`关键词：`、`Abstract`、`Keywords`、作者信息、基金项目、图题和表题等标签段落首行缩进必须为 0，不得继承正文 Normal 的两格缩进，也不得保留文本本身的前导空格或全角空格。
- 若导出的题名或标题出现首行缩进两格、约 0.74 cm，视为格式失败，必须重新运行导出清洗。

若用户上传目标期刊 Word 模板，用户模板优先，内置模板只作为兜底。

## 报告写法

格式报告必须区分：

- `官方要求`：直接来自《社会学研究》公开投稿要求。
- `参照来源`：来自《社会》或其他社科期刊投稿说明。
- `内置模板建议`：从 `/Users/yjy/年会征文-元景阳.docx` 抽取并清空内容后的默认 Word 版式。
