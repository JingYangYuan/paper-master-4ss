#!/usr/bin/env python3
"""Prepare a Word reference docx while preserving its template formatting."""

from __future__ import annotations

import argparse
import re
import shutil
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.text import WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt
from lxml import etree


HEADING_STYLES = ("Title", "Heading 1", "Heading 2", "Heading 3", "标题 1", "标题 2", "标题 3")
LEVEL_ONE_HEADING_STYLES = {"Heading 1", "标题 1"}
SECONDARY_HEADING_STYLES = ("Heading 2", "标题 2")
TERTIARY_HEADING_STYLE_NAMES = ("Heading 3", "标题 3")
TERTIARY_HEADING_STYLES = {"Heading 3", "标题 3"}
LABEL_AND_CAPTION_STYLES = (
    "作者",
    "摘要",
    "关键词",
    "英文摘要",
    "英文关键词",
    "Abstract",
    "Keywords",
    "Caption",
    "图片",
)
LEADING_SPACE_RE = re.compile(r"^[\s\u3000\xa0]+")
CHINESE_TERTIARY_HEADING_RE = re.compile(r"^[（(]\s*[一二三四五六七八九十]+\s*[）)]")
ARABIC_BODY_HEADING_RE = re.compile(r"^(?:[（(]\s*)?\d{1,2}\s*(?:[.．、）)]|\s+[^\d])")
LABEL_STYLE_RULES = (
    (re.compile(r"^(摘要|内容提要)\s*[:：]"), ("摘要",)),
    (re.compile(r"^关键词\s*[:：]"), ("关键词",)),
    (re.compile(r"^Abstract\b\s*[:：.]?", re.IGNORECASE), ("英文摘要", "Abstract")),
    (re.compile(r"^Keywords?\b\s*[:：.]?", re.IGNORECASE), ("英文关键词", "Keywords")),
    (re.compile(r"^(作者|作者单位|作者简介|联系方式|基金项目|资助项目|通讯作者)\s*[:：]"), ("作者",)),
    (re.compile(r"^(Author|Corresponding author|Contact|Funding)\b\s*[:：]?", re.IGNORECASE), ("作者",)),
)
CAPTION_RE = re.compile(r"^(图|表)\s*[0-9０-９一二三四五六七八九十]+")
WORD_XML_PARTS = (
    "word/document.xml",
    "word/header",
    "word/footer",
    "word/footnotes.xml",
    "word/endnotes.xml",
)
W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def style_or_none(doc: Document, name: str):
    try:
        return doc.styles[name]
    except KeyError:
        return None


def first_existing_style(doc: Document, names: tuple[str, ...]):
    for name in names:
        style = style_or_none(doc, name)
        if style is not None:
            return style
    return None


def clear_paragraph_indent(paragraph) -> None:
    paragraph.paragraph_format.first_line_indent = Cm(0)
    paragraph.paragraph_format.left_indent = Cm(0)
    force_zero_indent_xml(paragraph._p.get_or_add_pPr())


def reset_paragraph_direct_layout(paragraph) -> None:
    paragraph.paragraph_format.first_line_indent = None
    paragraph.paragraph_format.left_indent = None
    paragraph.paragraph_format.alignment = None
    ppr = paragraph._p.pPr
    if ppr is None:
        return
    for tag in ("w:ind", "w:jc", "w:pageBreakBefore", "w:keepNext", "w:keepLines"):
        for element in ppr.xpath(f"./{tag}"):
            parent = element.getparent()
            if parent is not None:
                parent.remove(element)


def force_zero_indent_xml(ppr) -> None:
    """Force both twip-based and character-based Word indentation to zero."""
    ind = ppr.find(qn("w:ind"))
    if ind is None:
        ind = OxmlElement("w:ind")
        ppr.append(ind)
    for attr in ("w:left", "w:start", "w:firstLine", "w:firstLineChars"):
        ind.set(qn(attr), "0")
    for attr in ("w:hanging", "w:hangingChars"):
        ind.attrib.pop(qn(attr), None)


def clear_style_indent(style) -> None:
    style.paragraph_format.first_line_indent = Cm(0)
    style.paragraph_format.left_indent = Cm(0)
    force_zero_indent_xml(style._element.get_or_add_pPr())


def clear_paragraph_page_controls(paragraph) -> None:
    pf = paragraph.paragraph_format
    pf.page_break_before = False
    pf.keep_with_next = False
    pf.keep_together = False
    for tag in ("w:pageBreakBefore", "w:keepNext", "w:keepLines"):
        for element in paragraph._element.xpath(f".//{tag}"):
            parent = element.getparent()
            if parent is not None:
                parent.remove(element)


def clear_style_page_controls(style) -> None:
    pf = style.paragraph_format
    pf.page_break_before = False
    pf.keep_with_next = False
    pf.keep_together = False
    for tag in ("w:pageBreakBefore", "w:keepNext", "w:keepLines"):
        for element in style._element.xpath(f".//{tag}"):
            parent = element.getparent()
            if parent is not None:
                parent.remove(element)


def strip_leading_text_space(paragraph) -> bool:
    """Remove real leading spaces before labels/headings, not just paragraph indent."""
    changed = False
    for run in paragraph.runs:
        if not run.text:
            continue
        new_text = LEADING_SPACE_RE.sub("", run.text)
        if new_text != run.text:
            run.text = new_text
            changed = True
        if run.text:
            break
    return changed


def sanitize_styles(
    doc: Document,
    normalize_legacy_defaults: bool = False,
    remove_heading_page_breaks: bool = False,
) -> list[str]:
    changes: list[str] = []

    if normalize_legacy_defaults:
        normal = style_or_none(doc, "Normal")
        if normal is not None:
            normal.font.name = "Times New Roman"
            normal.font.size = Pt(10.5)
            normal.paragraph_format.first_line_indent = Cm(0.74)
            normal.paragraph_format.space_before = Pt(0)
            normal.paragraph_format.space_after = Pt(0)
            normal.paragraph_format.line_spacing = 1.5
            changes.append("normalized Normal style")

    for style_name in HEADING_STYLES:
        style = style_or_none(doc, style_name)
        if style is None:
            continue
        pf = style.paragraph_format
        if pf.first_line_indent:
            changes.append(f"cleared first_line_indent from {style_name}")
        clear_style_indent(style)
        if style_name in LEVEL_ONE_HEADING_STYLES:
            pf.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if remove_heading_page_breaks:
            if pf.page_break_before:
                changes.append(f"removed page_break_before from {style_name}")
            clear_style_page_controls(style)

    for style_name in LABEL_AND_CAPTION_STYLES:
        style = style_or_none(doc, style_name)
        if style is None:
            continue
        clear_style_indent(style)
        if remove_heading_page_breaks:
            clear_style_page_controls(style)

    if normalize_legacy_defaults:
        ref_style = style_or_none(doc, "参考文献")
        if ref_style is not None:
            ref_pf = ref_style.paragraph_format
            ref_pf.left_indent = Cm(0.74)
            ref_pf.first_line_indent = Cm(-0.74)
            ref_pf.space_before = Pt(0)
            ref_pf.space_after = Pt(0)
            ref_pf.line_spacing_rule = WD_LINE_SPACING.SINGLE
            changes.append("normalized reference style")

    return changes


def label_style_names(text: str) -> tuple[str, ...]:
    for pattern, style_names in LABEL_STYLE_RULES:
        if pattern.search(text):
            return style_names
    if CAPTION_RE.search(text):
        return ("图片", "Caption")
    return ()


def is_chinese_tertiary_heading(text: str) -> bool:
    return bool(CHINESE_TERTIARY_HEADING_RE.search(text.strip()))


def is_arabic_body_heading(text: str) -> bool:
    return bool(ARABIC_BODY_HEADING_RE.search(text.strip()))


def sanitize_document_paragraphs(doc: Document, remove_page_breaks: bool = False) -> list[str]:
    changes: list[str] = []
    main_title_style = first_existing_style(doc, ("Heading 1", "标题 1"))
    secondary_heading_style = first_existing_style(doc, SECONDARY_HEADING_STYLES)
    tertiary_heading_style = first_existing_style(doc, TERTIARY_HEADING_STYLE_NAMES)
    normal_style = style_or_none(doc, "Normal")
    converted_main_title = False
    for paragraph in doc.paragraphs:
        text = paragraph.text.strip()
        pf = paragraph.paragraph_format
        style_name = paragraph.style.name if paragraph.style else ""

        if text and style_name in HEADING_STYLES:
            if not converted_main_title:
                if main_title_style is not None and style_name not in LEVEL_ONE_HEADING_STYLES:
                    paragraph.style = main_title_style
                    style_name = paragraph.style.name if paragraph.style else style_name
                    changes.append("converted first heading paragraph to Heading 1")
                converted_main_title = True
            elif is_arabic_body_heading(text) and normal_style is not None:
                paragraph.style = normal_style
                style_name = paragraph.style.name if paragraph.style else style_name
                changes.append("converted Arabic numbered heading paragraph to Normal")
                if strip_leading_text_space(paragraph):
                    changes.append("stripped leading spaces from Arabic numbered paragraph")
                reset_paragraph_direct_layout(paragraph)
                continue
            elif is_chinese_tertiary_heading(text) and tertiary_heading_style is not None:
                if style_name not in TERTIARY_HEADING_STYLES:
                    paragraph.style = tertiary_heading_style
                    style_name = paragraph.style.name if paragraph.style else style_name
                    changes.append("converted Chinese tertiary heading paragraph to Heading 3")
            elif (
                secondary_heading_style is not None
                and style_name not in SECONDARY_HEADING_STYLES
                and style_name not in TERTIARY_HEADING_STYLES
            ):
                paragraph.style = secondary_heading_style
                style_name = paragraph.style.name if paragraph.style else style_name
                changes.append("converted non-title heading paragraph to Heading 2")
            clear_paragraph_indent(paragraph)
            if strip_leading_text_space(paragraph):
                changes.append(f"stripped leading spaces from heading paragraph: {style_name}")
            if remove_page_breaks:
                clear_paragraph_page_controls(paragraph)

        if style_name in HEADING_STYLES or style_name.startswith("Heading"):
            if pf.first_line_indent:
                changes.append(f"cleared heading paragraph first_line_indent: {style_name}")
            clear_paragraph_indent(paragraph)
            if style_name in LEVEL_ONE_HEADING_STYLES:
                pf.alignment = WD_ALIGN_PARAGRAPH.CENTER
            if strip_leading_text_space(paragraph):
                changes.append(f"stripped leading spaces from heading paragraph: {style_name}")
        if remove_page_breaks and pf.page_break_before:
            clear_paragraph_page_controls(paragraph)
            changes.append("removed paragraph page_break_before")
        if remove_page_breaks and paragraph.style and paragraph.style.name.startswith("Heading"):
            clear_paragraph_page_controls(paragraph)

        matched_style_names = label_style_names(text)
        if matched_style_names:
            style = first_existing_style(doc, matched_style_names)
            if style is not None and (paragraph.style is None or paragraph.style.name != style.name):
                paragraph.style = style
                changes.append(f"applied {style.name} style to label/caption paragraph")
            if strip_leading_text_space(paragraph):
                changes.append("stripped leading spaces from label/caption paragraph")
            clear_paragraph_indent(paragraph)
            if remove_page_breaks:
                clear_paragraph_page_controls(paragraph)
    return changes


def _is_word_content_xml(name: str) -> bool:
    return name.endswith(".xml") and any(name == part or name.startswith(part) for part in WORD_XML_PARTS)


def _remove_xpath_nodes(root, xpath: str, namespaces: dict[str, str]) -> int:
    removed = 0
    for element in root.xpath(xpath, namespaces=namespaces):
        parent = element.getparent()
        if parent is not None:
            parent.remove(element)
            removed += 1
    return removed


def strip_content_artifacts(path: Path) -> list[str]:
    """Remove residual visual/content objects from a reference docx package."""
    changes: list[str] = []
    tmp = Path(tempfile.NamedTemporaryFile(suffix=".docx", delete=False).name)
    with ZipFile(path, "r") as zin, ZipFile(tmp, "w", ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            name = item.filename
            if name.startswith("word/media/"):
                changes.append(f"removed media file {name}")
                continue

            data = zin.read(name)
            if _is_word_content_xml(name):
                try:
                    root = etree.fromstring(data)
                except etree.XMLSyntaxError:
                    zout.writestr(item, data)
                    continue
                removed = 0
                removed += _remove_xpath_nodes(root, ".//w:tbl", {"w": W_NS})
                removed += _remove_xpath_nodes(root, ".//w:drawing", {"w": W_NS})
                removed += _remove_xpath_nodes(root, ".//w:pict", {"w": W_NS})
                removed += _remove_xpath_nodes(root, ".//w:object", {"w": W_NS})
                if removed:
                    changes.append(f"removed {removed} content artifact(s) from {name}")
                    data = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)

            if name.endswith(".rels"):
                try:
                    root = etree.fromstring(data)
                except etree.XMLSyntaxError:
                    zout.writestr(item, data)
                    continue
                removed = 0
                for rel in list(root):
                    rel_type = rel.get("Type", "")
                    target = rel.get("Target", "")
                    if rel_type.endswith("/image") or target.startswith("media/"):
                        root.remove(rel)
                        removed += 1
                if removed:
                    changes.append(f"removed {removed} image relationship(s) from {name}")
                    data = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)

            zout.writestr(item, data)
    shutil.move(str(tmp), str(path))
    return changes


def inspect_docx_structure(path: Path) -> dict[str, int]:
    doc = Document(str(path))
    with ZipFile(path) as archive:
        names = archive.namelist()
        styles_xml = archive.read("word/styles.xml").decode("utf-8", errors="ignore")
        document_xml = archive.read("word/document.xml").decode("utf-8", errors="ignore")
        xml_parts = []
        for name in names:
            if _is_word_content_xml(name):
                xml_parts.append(archive.read(name).decode("utf-8", errors="ignore"))
    nonempty_paragraphs = sum(1 for paragraph in doc.paragraphs if paragraph.text.strip())
    empty_run = 0
    max_empty_run = 0
    for paragraph in doc.paragraphs:
        if paragraph.text.strip():
            empty_run = 0
        else:
            empty_run += 1
            max_empty_run = max(max_empty_run, empty_run)
    joined_xml = "\n".join(xml_parts)
    return {
        "paragraphs": len(doc.paragraphs),
        "nonempty_paragraphs": nonempty_paragraphs,
        "max_empty_paragraph_run": max_empty_run,
        "tables": len(doc.tables) + document_xml.count("<w:tbl"),
        "inline_shapes": len(doc.inline_shapes),
        "media_files": sum(1 for name in names if name.startswith("word/media/")),
        "drawings": document_xml.count("<w:drawing")
        + document_xml.count("<w:pict")
        + document_xml.count("<w:object"),
        "style_page_breaks": styles_xml.count("w:pageBreakBefore"),
        "explicit_page_breaks": joined_xml.count('w:type="page"') + joined_xml.count("w:pageBreakBefore"),
    }


def structure_issues(summary: dict[str, int]) -> list[str]:
    issues: list[str] = []
    if summary["tables"]:
        issues.append(f"table artifacts: {summary['tables']}")
    if summary["media_files"] or summary["drawings"] or summary["inline_shapes"]:
        issues.append(
            "image/drawing artifacts: "
            f"{summary['media_files']} media, {summary['drawings']} drawings, {summary['inline_shapes']} inline"
        )
    if summary["max_empty_paragraph_run"] > 8:
        issues.append(f"long empty paragraph run: {summary['max_empty_paragraph_run']}")
    if summary["style_page_breaks"]:
        issues.append(f"style page breaks: {summary['style_page_breaks']}")
    return issues


def sanitize_docx(
    path: Path,
    out: Path | None = None,
    strip_artifacts: bool = False,
    normalize_legacy_defaults: bool = False,
    remove_heading_page_breaks: bool = False,
) -> list[str]:
    doc = Document(str(path))
    changes = sanitize_styles(
        doc,
        normalize_legacy_defaults=normalize_legacy_defaults,
        remove_heading_page_breaks=remove_heading_page_breaks,
    )
    changes.extend(sanitize_document_paragraphs(doc, remove_page_breaks=remove_heading_page_breaks))
    target = out or path
    doc.save(str(target))
    if strip_artifacts:
        changes.extend(strip_content_artifacts(target))
    return changes


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove automatic page breaks from a Word template/docx.")
    parser.add_argument("docx", help="Input docx path")
    parser.add_argument("--out", help="Optional output docx path. Defaults to in-place.")
    parser.add_argument(
        "--strip-content-artifacts",
        action="store_true",
        help="Remove residual tables, drawings, and image package relationships from a reference template.",
    )
    parser.add_argument(
        "--normalize-legacy-defaults",
        action="store_true",
        help="Apply the old built-in Times New Roman/10.5pt body defaults.",
    )
    parser.add_argument(
        "--remove-heading-page-breaks",
        action="store_true",
        help="Remove heading style and paragraph page-break controls.",
    )
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="Print a compact structure inspection after sanitizing.",
    )
    args = parser.parse_args()

    path = Path(args.docx).expanduser().resolve()
    if not path.exists():
        raise SystemExit(f"docx not found: {path}")
    out = Path(args.out).expanduser().resolve() if args.out else None
    changes = sanitize_docx(
        path,
        out,
        strip_artifacts=args.strip_content_artifacts,
        normalize_legacy_defaults=args.normalize_legacy_defaults,
        remove_heading_page_breaks=args.remove_heading_page_breaks,
    )
    print(f"sanitized: {out or path}")
    for change in changes:
        print(f"- {change}")
    if args.inspect:
        summary = inspect_docx_structure(out or path)
        for key, value in summary.items():
            print(f"{key}: {value}")
        issues = structure_issues(summary)
        if issues:
            print("issues: " + "; ".join(issues))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
