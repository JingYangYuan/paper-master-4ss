#!/usr/bin/env python3
"""Locate likely design frame files via AI-keyword full-text search.

This script expects AI-generated keywords (--keywords) and searches ALL
frame/*.md files for relevance. No hardcoded discipline keywords — routing
is driven entirely by AI-extracted terms matched against frame content.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


# Minimal mapping: discipline-key → Chinese label (no keywords).
_FRAME_META: dict[str, str] = {
    "sociological": "社会学",
    "public-admin": "公共管理",
    "psychology": "心理学",
    "communication": "传播学",
    "economics": "经济学",
    "education": "教育学",
    "political-science": "政治学",
    "international-politics": "国际政治",
    "contemporary-china": "当代中国研究",
    "philosophy": "哲学",
    "methodology": "方法论",
    "marxism": "马克思主义",
    "party-history": "党史党建",
    "law": "法学",
    "xinsixiang": "新时代思想",
}


@dataclass
class ReadRange:
    title: str
    start: int
    end: int
    score: int
    matched_terms: list[str]


@dataclass
class Candidate:
    key: str
    label: str
    path: Path
    score: float
    ai_keyword_hits: list[str]
    ranges: list[ReadRange]


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _stem_to_discipline(stem: str) -> tuple[str | None, str]:
    """Map a frame filename stem to (discipline_key, chinese_label)."""
    for key, label in _FRAME_META.items():
        if key in stem:
            return key, label
    return None, stem


def split_terms(text: str) -> list[str]:
    """Split a keyword / topic string into individual search terms."""
    return [t for t in re.split(r"[\s,，、;；:：/]+", text) if t]


def count_hits(text: str, terms: list[str]) -> list[str]:
    """Return which *terms* appear anywhere in *text* (case-insensitive)."""
    lowered = text.lower()
    return [kw for kw in terms if kw.lower() in lowered]


def extract_headings(text: str) -> list[tuple[str, int]]:
    """Return (heading_title, 1-based_line_number) for every '## ' line."""
    headings: list[tuple[str, int]] = []
    for i, line in enumerate(text.splitlines(), start=1):
        if line.startswith("## "):
            headings.append((line[3:].strip(), i))
    return headings


def score_ranges(query: str, text: str, headings: list[tuple[str, int]]) -> list[ReadRange]:
    """Score each '## '-delimited section by how well it matches the query terms."""
    lines = text.splitlines()
    topic_terms = split_terms(query)
    scored: list[ReadRange] = []

    for idx, (heading, line_no) in enumerate(headings):
        start_idx = line_no - 1
        next_heading_idx = headings[idx + 1][1] - 1 if idx + 1 < len(headings) else len(lines)
        end_idx = min(next_heading_idx, start_idx + 120)
        section = "\n".join(lines[start_idx:end_idx])

        matched_terms = [t for t in topic_terms if t.lower() in section.lower()]
        score = (
            sum(3 for t in matched_terms if t.lower() in heading.lower())
            + sum(section.lower().count(t.lower()) for t in matched_terms)
        )

        if score > 0:
            scored.append(ReadRange(
                title=heading,
                start=line_no,
                end=end_idx,
                score=score,
                matched_terms=matched_terms,
            ))

    scored.sort(key=lambda r: (r.score, len(r.matched_terms)), reverse=True)

    if scored:
        return scored[:8]

    # No section matched any term → return first 5 headings as fallback
    return [
        ReadRange(
            title=heading,
            start=line_no,
            end=min(
                headings[idx + 1][1] - 1 if idx + 1 < len(headings) else len(lines),
                line_no + 119,
            ),
            score=0,
            matched_terms=[],
        )
        for idx, (heading, line_no) in enumerate(headings[:5])
    ]


# ---------------------------------------------------------------------------
# core
# ---------------------------------------------------------------------------

def locate(topic: str, keywords: str, preferred: str | None, top: int) -> list[Candidate]:
    """Full-text search ALL frame/*.md files with AI keywords; return top-N."""
    root = Path(__file__).resolve().parents[1]
    frame_dir = root / "frame"

    ai_terms = split_terms(keywords) if keywords else split_terms(topic)
    candidates: list[Candidate] = []

    for md_path in sorted(frame_dir.glob("*.md")):
        disc_key, label = _stem_to_discipline(md_path.stem)

        if preferred and disc_key and preferred not in {disc_key, label}:
            continue

        text = md_path.read_text(encoding="utf-8", errors="ignore")
        headings = extract_headings(text)

        # ── full-text scoring ──
        ai_hits = count_hits(text, ai_terms)          # which AI terms appear in the file
        ranges = score_ranges(keywords or topic, text, headings)

        score = len(ai_hits) * 3 + sum(r.score for r in ranges[:5]) * 0.3

        candidates.append(Candidate(
            key=disc_key or md_path.stem,
            label=label,
            path=md_path,
            score=score,
            ai_keyword_hits=ai_hits,
            ranges=ranges,
        ))

    candidates.sort(key=lambda c: c.score, reverse=True)
    return candidates[:top]


# ---------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------

def as_markdown(topic: str, keywords: str, candidates: list[Candidate]) -> str:
    lines = [
        "# Frame Locator Result",
        "",
        f"- 研究主题: {topic}",
        f"- AI 提取关键词: {keywords or topic}",
        f"- 检索范围: frame/ 全部 {len(_FRAME_META)} 个学科框架文件",
        f"- 候选 frame 数: {len(candidates)}",
        "",
        "| Rank | 候选 frame | 相关度分数 | AI 关键词命中 | 建议精读行号区间 |",
        "|---:|---|---:|---|---|",
    ]
    for rank, c in enumerate(candidates, start=1):
        hits = "、".join(dict.fromkeys(c.ai_keyword_hits)) or "无直接命中"
        rel_path = c.path.relative_to(Path(__file__).resolve().parents[1])
        ranges = "；".join(
            f"{r.title} (`{rel_path}:L{r.start}-L{r.end}`; 命中: {'、'.join(r.matched_terms) or '无'})"
            for r in c.ranges[:5]
        ) or "无候选区间，需人工确认 frame 文件"
        lines.append(f"| {rank} | `{rel_path}` ({c.label}) | {c.score:.1f} | {hits} | {ranges} |")

    if not candidates or candidates[0].score < 3:
        lines.extend([
            "",
            "## 不确定性提示",
            "- 最高分低于阈值，必须要求用户确认学科或扩大到 2-3 个候选 frame。",
        ])
    else:
        lines.extend([
            "",
            "## 不确定性提示",
            "- 该结果只用于初步定位；最终框架选择必须按建议精读行号区间读取候选 frame 内容，并由 design agents 复核。",
        ])
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="AI-keyword full-text search across design frame files.")
    parser.add_argument("--topic", required=True, help="Original research topic.")
    parser.add_argument(
        "--keywords",
        required=True,
        help="AI-extracted routing keywords (3-8 terms, space/comma separated). Required — the script no longer uses hardcoded discipline keywords.",
    )
    parser.add_argument("--discipline", help="Optional discipline key or Chinese label to restrict search.")
    parser.add_argument("--top", type=int, default=3, help="Number of candidates to return (1-14).")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of Markdown.")
    args = parser.parse_args()

    candidates = locate(args.topic, args.keywords, args.discipline, max(1, min(args.top, 14)))

    if args.json:
        payload = [
            {
                "discipline": c.key,
                "label": c.label,
                "frame": str(c.path.relative_to(Path(__file__).resolve().parents[1])),
                "score": round(c.score, 2),
                "topic": args.topic,
                "ai_keywords": args.keywords,
                "ai_keyword_hits": c.ai_keyword_hits,
                "read_ranges": [
                    {
                        "title": r.title,
                        "start": r.start,
                        "end": r.end,
                        "score": r.score,
                        "matched_terms": r.matched_terms,
                    }
                    for r in c.ranges
                ],
            }
            for c in candidates
        ]
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(as_markdown(args.topic, args.keywords, candidates), end="")


if __name__ == "__main__":
    main()
