#!/usr/bin/env python3
"""Validate ExecPlan structural requirements and evidence blocks."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


REQUIRED_HEADINGS = [
    "## Progress",
    "## Surprises & Discoveries",
    "## Decision Log",
    "## Outcomes & Retrospective",
    "## Purpose / Big Picture",
    "## Context and Orientation",
    "## Plan of Work",
    "## Concrete Steps",
    "## Validation and Acceptance",
    "## Idempotence and Recovery",
    "## Artifacts and Notes",
    "## Interfaces and Dependencies",
]

EVIDENCE_FIELDS = [
    "Command:",
    "Working directory:",
    "Expected result:",
    "Observed result:",
    "Exit status:",
    "Timestamp (UTC):",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate ExecPlan files.")
    parser.add_argument("plan_file", help="ExecPlan markdown file to validate")
    parser.add_argument("--strict-evidence", action="store_true", help="Require complete evidence blocks")
    parser.add_argument("--json", action="store_true", dest="as_json", help="Emit machine-readable output")
    return parser.parse_args()


def validate_text(text: str) -> list[str]:
    issues: list[str] = []

    for heading in REQUIRED_HEADINGS:
        if heading not in text:
            issues.append(f"Missing required heading: {heading}")

    if "```" in text:
        issues.append("Nested triple-backtick fences are not allowed in ExecPlan content")

    if "## Progress" in text and "- [" not in text:
        issues.append("Progress section must include checkbox items")

    return issues


def validate_evidence(text: str) -> list[str]:
    issues: list[str] = []
    blocks = re.findall(
        r"(?:^|\n)(?:[ \t]*Command:.*?)(?=\n\s*\n|\Z)",
        text,
        flags=re.DOTALL | re.MULTILINE,
    )

    if not blocks:
        return ["No evidence block found"]

    for index, block in enumerate(blocks, start=1):
        for field in EVIDENCE_FIELDS:
            if field not in block:
                issues.append(f"Evidence block {index} missing field: {field}")

    return issues


def main() -> int:
    args = parse_args()
    text = Path(args.plan_file).read_text(encoding="utf-8")

    issues = validate_text(text)
    if args.strict_evidence:
        issues.extend(validate_evidence(text))

    if args.as_json:
        print(json.dumps({"ok": not issues, "issues": issues}, indent=2))
    elif issues:
        for issue in issues:
            print(issue)
    else:
        print("ExecPlan validation passed")

    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
