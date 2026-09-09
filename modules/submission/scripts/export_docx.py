#!/usr/bin/env python3
"""Export a Markdown manuscript to Word using pandoc and a reference docx."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from sanitize_reference_docx import inspect_docx_structure, sanitize_docx, structure_issues


STYLE_TEMPLATES = {
    "sociological-research": "sociological-research-default.docx",
}


def module_root() -> Path:
    return Path(__file__).resolve().parents[1]


def resolve_reference_doc(style: str, reference_doc: str | None) -> Path:
    if reference_doc:
        path = Path(reference_doc).expanduser().resolve()
        if not path.exists():
            raise SystemExit(f"reference doc not found: {path}")
        if path.suffix.lower() != ".docx":
            raise SystemExit(f"reference doc must be a .docx file: {path}")
        return path

    template_name = STYLE_TEMPLATES[style]
    path = module_root() / "templates" / template_name
    if not path.exists():
        raise SystemExit(f"built-in template not found: {path}")
    return path


def report_reference_issues(label: str, reference_doc: Path) -> list[str]:
    issues = structure_issues(inspect_docx_structure(reference_doc))
    if issues:
        print(f"{label}: " + "; ".join(issues), file=sys.stderr)
    return issues


THEMATIC_BREAK_RE = re.compile(r"^\s{0,3}([-*_])(?:\s*\1){2,}\s*$")
FENCE_RE = re.compile(r"^\s{0,3}(```+|~~~+)")


def strip_markdown_export_artifacts(text: str) -> tuple[str, list[str]]:
    """Remove Markdown metadata and visual separators that should not enter Word."""
    lines = text.splitlines()
    changes: list[str] = []

    first_content = next((i for i, line in enumerate(lines) if line.strip()), None)
    if first_content is not None and lines[first_content].strip() == "---":
        for end in range(first_content + 1, len(lines)):
            if lines[end].strip() in {"---", "..."}:
                del lines[first_content : end + 1]
                changes.append("removed YAML frontmatter block")
                break

    cleaned: list[str] = []
    in_fence = False
    fence_marker = ""
    removed_breaks = 0
    for line in lines:
        fence_match = FENCE_RE.match(line)
        if fence_match:
            marker = fence_match.group(1)
            if not in_fence:
                in_fence = True
                fence_marker = marker[:3]
            elif marker.startswith(fence_marker):
                in_fence = False
                fence_marker = ""
            cleaned.append(line)
            continue
        if not in_fence and THEMATIC_BREAK_RE.match(line):
            removed_breaks += 1
            continue
        cleaned.append(line)
    if removed_breaks:
        changes.append(f"removed {removed_breaks} Markdown thematic break line(s)")

    return "\n".join(cleaned).strip() + "\n", changes


def prepare_markdown_source(manuscript: Path) -> tuple[Path, list[str]]:
    text = manuscript.read_text(encoding="utf-8-sig")
    cleaned, changes = strip_markdown_export_artifacts(text)
    if not changes:
        return manuscript, []
    tmp = tempfile.NamedTemporaryFile("w", suffix=manuscript.suffix or ".md", delete=False, encoding="utf-8")
    with tmp:
        tmp.write(cleaned)
    return Path(tmp.name), changes


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export Markdown to docx with a submission reference template."
    )
    parser.add_argument("manuscript", help="Path to manuscript.md")
    parser.add_argument(
        "--style",
        choices=sorted(STYLE_TEMPLATES),
        default="sociological-research",
        help="Built-in style to use when --reference-doc is not supplied.",
    )
    parser.add_argument(
        "--reference-doc",
        help="User-provided Word reference template. Overrides --style.",
    )
    parser.add_argument(
        "--out",
        default="paper-workspace/06-submission/submission.docx",
        help="Output docx path.",
    )
    parser.add_argument(
        "--toc",
        action="store_true",
        help="Ask pandoc to include a table of contents.",
    )
    args = parser.parse_args()

    pandoc = shutil.which("pandoc")
    if not pandoc:
        raise SystemExit(
            "pandoc is required. See modules/submission/references/install-dependencies.md"
        )

    manuscript = Path(args.manuscript).expanduser().resolve()
    if not manuscript.exists():
        raise SystemExit(f"manuscript not found: {manuscript}")
    if manuscript.suffix.lower() not in {".md", ".markdown", ".txt"}:
        raise SystemExit(f"manuscript should be Markdown/text: {manuscript}")

    out = Path(args.out).expanduser()
    if not out.is_absolute():
        out = (Path.cwd() / out).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    reference_doc = resolve_reference_doc(args.style, args.reference_doc)
    report_reference_issues("reference-doc precheck", reference_doc)
    tmp_ref = tempfile.NamedTemporaryFile(suffix=".docx", delete=False)
    tmp_ref.close()
    prepared_reference = Path(tmp_ref.name)
    shutil.copy2(reference_doc, prepared_reference)
    sanitize_docx(
        prepared_reference,
        strip_artifacts=not args.reference_doc,
        remove_heading_page_breaks=True,
    )
    prepared_manuscript = manuscript
    try:
        remaining_reference_issues = report_reference_issues("reference-doc postcheck", prepared_reference)
        if not args.reference_doc and remaining_reference_issues:
            raise SystemExit("built-in reference template still has structural artifacts; aborting export")

        prepared_manuscript, markdown_changes = prepare_markdown_source(manuscript)
        for change in markdown_changes:
            print(f"markdown preprocess: {change}", file=sys.stderr)

        cmd = [
            pandoc,
            str(prepared_manuscript),
            "-o",
            str(out),
            f"--reference-doc={prepared_reference}",
            "--from=markdown+footnotes+citations",
        ]
        if args.toc:
            cmd.append("--toc")

        result = subprocess.run(cmd, text=True, capture_output=True)
        if result.returncode != 0:
            sys.stderr.write(result.stderr)
            return result.returncode

        sanitize_docx(out, remove_heading_page_breaks=True)
        output_issues = report_reference_issues("output docx check", out)
        page_break_issues = [issue for issue in output_issues if "style page breaks" in issue]
        if page_break_issues:
            raise SystemExit("exported docx still has heading style page breaks; aborting")
        print(f"exported: {out}")
        print(f"style: {args.style}")
        if args.reference_doc:
            print("reference-doc: user-provided")
        return 0
    finally:
        if prepared_manuscript != manuscript:
            prepared_manuscript.unlink(missing_ok=True)
        prepared_reference.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
