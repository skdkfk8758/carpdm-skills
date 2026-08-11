#!/usr/bin/env python3
"""Validate a human-readable Linear issue body."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


SCHEMAS = {
    "feature": {
        "required": {"목적", "작업 내용", "완료 조건"},
        "optional": {"범위 밖", "참고"},
    },
    "bug": {
        "required": {"문제", "재현 방법", "기대 결과", "완료 조건"},
        "optional": {"범위 밖", "참고"},
    },
    "research": {
        "required": {"확인할 질문", "조사 범위", "완료 조건"},
        "optional": {"결과물", "범위 밖", "참고"},
    },
}

FORBIDDEN_PATTERNS = {
    "recommended section": re.compile(r"(?m)^##\s+추천\s*$"),
    "next-work section": re.compile(r"(?m)^##\s+다음 작업\s*$"),
    "kickoff prompt": re.compile(r"시작\s*프롬프트"),
    "AUTO/HUMAN marker": re.compile(r"\[(?:AUTO|HUMAN)\]"),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", help="Markdown file; omit to read stdin")
    parser.add_argument("--kind", choices=sorted(SCHEMAS), default="feature")
    parser.add_argument("--max-chars", type=int, default=1600)
    return parser.parse_args()


def load_text(path: str | None) -> str:
    if path:
        return Path(path).read_text(encoding="utf-8")
    return sys.stdin.read()


def validate(text: str, kind: str, max_chars: int) -> list[str]:
    errors: list[str] = []
    headings = re.findall(r"(?m)^##\s+(.+?)\s*$", text)
    heading_set = set(headings)
    schema = SCHEMAS[kind]
    allowed = schema["required"] | schema["optional"]

    missing = schema["required"] - heading_set
    unexpected = heading_set - allowed
    duplicate = {heading for heading in heading_set if headings.count(heading) > 1}

    if missing:
        errors.append(f"missing required headings: {', '.join(sorted(missing))}")
    if unexpected:
        errors.append(f"unexpected headings: {', '.join(sorted(unexpected))}")
    if duplicate:
        errors.append(f"duplicate headings: {', '.join(sorted(duplicate))}")

    for label, pattern in FORBIDDEN_PATTERNS.items():
        if pattern.search(text):
            errors.append(f"forbidden content: {label}")

    if len(text.strip()) > max_chars:
        errors.append(f"body is {len(text.strip())} characters; maximum is {max_chars}")

    completion_match = re.search(
        r"(?ms)^##\s+완료 조건\s*$\n(.*?)(?=^##\s+|\Z)", text
    )
    if completion_match:
        checkbox_count = len(
            re.findall(r"(?m)^\s*-\s*\[[ xX]\]\s+\S", completion_match.group(1))
        )
        if not 2 <= checkbox_count <= 6:
            errors.append("완료 조건 must contain 2 to 6 checkboxes")

    return errors


def main() -> int:
    args = parse_args()
    try:
        text = load_text(args.path)
    except OSError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    errors = validate(text, args.kind, args.max_chars)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {args.kind} issue body is valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

