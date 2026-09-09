# submission module 安装说明

本模块用于 Markdown 转 Word、Word 格式检查、投稿清单生成和参考文献体例整理。执行转换或检查前必须完成依赖验收。

## 安装模式

| 模式 | 适用场景 | 必需依赖 |
|---|---|---|
| 仅格式说明 | 只生成投稿检查建议，不导出 Word | Python 3 |
| Markdown 转 Word | 生成 `submission.docx` | Python 3 + pandoc |
| Word 格式检查 | 对 docx 做样式和结构检查 | Python 3 + python-docx + lxml |
| 完整投稿包 | 导出 Word、检查格式、整理引用 | Python 3 + pandoc + python-docx + lxml |

## 强制依赖

```bash
python3 --version
pandoc --version
python3 - <<'PY'
import importlib.util
for name in ["docx", "lxml"]:
    print(name, "OK" if importlib.util.find_spec(name) else "MISSING")
PY
```

合格状态：

- `python3` 可执行。
- `pandoc` 可执行。
- `docx` 显示 `OK`。
- `lxml` 显示 `OK`。

## 安装建议

macOS 推荐：

```bash
brew install pandoc
python3 -m pip install --user python-docx lxml
```

如当前 Python 不允许 `--user` 安装，可使用虚拟环境：

```bash
python3 -m venv .venv-submission
. .venv-submission/bin/activate
python -m pip install python-docx lxml
```

## 内置文件检查

```bash
test -f modules/submission/SKILL.md
test -f modules/submission/scripts/export_docx.py
test -f modules/submission/scripts/check_docx_format.py
test -f modules/submission/scripts/sanitize_reference_docx.py
test -f modules/submission/scripts/check_citations.py
test -f modules/submission/references/citation-rules.md
test -f modules/submission/references/journal-style-sociological-research.md
test -f modules/submission/templates/sociological-research-default.docx
```

## 失败处理

- 缺少 `pandoc`：不得执行 Markdown 转 Word；可以只输出参考文献或格式缺口说明。
- 缺少 `python-docx` 或 `lxml`：不得执行 Word 格式检查；可以先完成 Markdown 导出。
- 用户提供的 `--reference-doc` 不存在或不是 `.docx`：停止导出并提示用户更换模板。
- 内置模板缺失：停止导出，先修复 `modules/submission/templates/`。

## 验收命令

```bash
python3 modules/submission/scripts/export_docx.py --help
python3 modules/submission/scripts/check_docx_format.py --help
python3 modules/submission/scripts/sanitize_reference_docx.py --help
python3 modules/submission/scripts/check_citations.py --help
```

验收通过后，才能正式生成 `paper-workspace/06-submission/submission.docx` 与 `format-check-report.md`。
