#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path


MANIFEST_BY_FAMILY = {
    "process": "_shared/validators/process_family_targets.txt",
}

REQUIRED_MANIFEST_TARGETS = {
    "process": [
        "contract/package-standards.md",
        "contract/process-family.md",
        "contract/prompt-packet.md",
        "contract/runtime-surfaces.md",
        "skills/using-superpowers/SKILL.md",
        "skills/brainstorming/SKILL.md",
        "skills/brainstorming/spec-document-reviewer-prompt.md",
        "skills/writing-plans/SKILL.md",
        "skills/writing-plans/plan-document-reviewer-prompt.md",
        "skills/using-git-worktrees/SKILL.md",
        "skills/dispatching-parallel-agents/SKILL.md",
        "skills/subagent-driven-development/SKILL.md",
        "skills/subagent-driven-development/implementer-prompt.md",
        "skills/subagent-driven-development/spec-reviewer-prompt.md",
        "skills/subagent-driven-development/code-quality-reviewer-prompt.md",
        "skills/executing-plans/SKILL.md",
        "skills/requesting-code-review/SKILL.md",
        "skills/requesting-code-review/code-reviewer.md",
        "skills/receiving-code-review/SKILL.md",
        "skills/verification-before-completion/SKILL.md",
        "skills/finishing-a-development-branch/SKILL.md",
        "skills/writing-skills/SKILL.md",
    ],
}

EXPECTED_DESCRIPTION_LINES = {
    "skills/brainstorming/SKILL.md": 'description: "Use when a request needs design exploration and explicit user approval before implementation planning."',
    "skills/writing-plans/SKILL.md": "description: Use when you have an approved spec for a multi-step task and need an implementation plan before touching code",
    "skills/using-git-worktrees/SKILL.md": "description: Use when implementation is about to start and the work needs an isolated workspace",
    "skills/dispatching-parallel-agents/SKILL.md": "description: Use when you have multiple independent investigation tasks that can run in parallel without shared write ownership",
    "skills/subagent-driven-development/SKILL.md": "description: Use when executing an implementation plan with write-owning task work in the current session",
    "skills/executing-plans/SKILL.md": "description: Use when executing a written implementation plan in a separate or sequential session with review checkpoints",
    "skills/using-superpowers/SKILL.md": "description: Use when starting a session so the agent routes through the skill system before responding",
    "skills/writing-skills/SKILL.md": "description: Use when creating or editing skills and validating that they satisfy the library contract before deployment",
}

PROMPT_TARGETS = [
    "skills/brainstorming/spec-document-reviewer-prompt.md",
    "skills/writing-plans/plan-document-reviewer-prompt.md",
    "skills/subagent-driven-development/implementer-prompt.md",
    "skills/subagent-driven-development/spec-reviewer-prompt.md",
    "skills/subagent-driven-development/code-quality-reviewer-prompt.md",
]

PROMPT_FORBIDDEN_STRINGS = [
    "Codex subagent packet (preferred v2):",
    "Task tool (general-purpose):",
    "task_name:",
    'agent_type: "reviewer"',
]

BOUNDARY_REQUIREMENTS = {
    "skills/dispatching-parallel-agents/SKILL.md": ["read-only", "write-owning"],
    "skills/subagent-driven-development/SKILL.md": ["write-owning"],
}

NO_BACKWARD_COMPAT_TARGETS = [
    "skills/requesting-code-review/SKILL.md",
    "skills/requesting-code-review/code-reviewer.md",
    "skills/receiving-code-review/SKILL.md",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate skill-library structural contracts.")
    parser.add_argument("--root", required=True, help="Repository root to validate")
    parser.add_argument(
        "--family",
        required=True,
        choices=sorted(MANIFEST_BY_FAMILY),
        help="Skill family contract to validate",
    )
    return parser.parse_args()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def read_manifest(path: Path) -> list[str]:
    return [line.strip() for line in read_text(path).splitlines() if line.strip()]


def read_frontmatter(path: Path) -> list[str] | None:
    lines = read_text(path).splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[1:index]
    return None


def find_frontmatter_line(frontmatter: list[str] | None, key: str) -> str | None:
    if frontmatter is None:
        return None
    prefix = f"{key}:"
    for line in frontmatter:
        if line.startswith(prefix):
            return line.strip()
    return None


def validate_family(root: Path, family: str) -> list[str]:
    issues: list[str] = []
    manifest_path = root / MANIFEST_BY_FAMILY[family]

    if not manifest_path.exists():
        return [f"Missing manifest: {manifest_path.relative_to(root)}"]

    entries = read_manifest(manifest_path)
    entry_set = set(entries)

    for rel_path in REQUIRED_MANIFEST_TARGETS[family]:
        if rel_path not in entry_set:
            issues.append(f"Manifest missing required target: {rel_path}")

    for rel_path in entries:
        if "/reference/" in rel_path:
            issues.append(f"Manifest entry uses forbidden /reference/ path: {rel_path}")
        if (root / rel_path).exists():
            continue
        issues.append(f"Manifest target missing from repo: {rel_path}")

    for rel_path in [entry for entry in entries if entry.endswith("/SKILL.md")]:
        target = root / rel_path
        if not target.exists():
            continue
        frontmatter = read_frontmatter(target)
        if frontmatter is None:
            issues.append(f"{rel_path} is missing SKILL.md frontmatter")
            continue
        if find_frontmatter_line(frontmatter, "name") is None:
            issues.append(f"{rel_path} frontmatter is missing name:")
        if find_frontmatter_line(frontmatter, "description") is None:
            issues.append(f"{rel_path} frontmatter is missing description:")

    for rel_path, expected_line in EXPECTED_DESCRIPTION_LINES.items():
        target = root / rel_path
        if not target.exists():
            continue
        actual_line = find_frontmatter_line(read_frontmatter(target), "description")
        if actual_line != expected_line:
            issues.append(
                f"{rel_path} description mismatch: expected `{expected_line}` but found `{actual_line or 'missing'}`"
            )

    for rel_path in PROMPT_TARGETS:
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        if "Codex subagent packet:" not in text:
            issues.append(f"{rel_path} is missing required packet caption `Codex subagent packet:`")
        for forbidden in PROMPT_FORBIDDEN_STRINGS:
            if forbidden in text:
                issues.append(f"{rel_path} contains forbidden prompt text `{forbidden}`")

    for rel_path, required_phrases in BOUNDARY_REQUIREMENTS.items():
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for phrase in required_phrases:
            if phrase not in text:
                issues.append(f"{rel_path} must mention `{phrase}`")

    for rel_path in NO_BACKWARD_COMPAT_TARGETS:
        target = root / rel_path
        if not target.exists():
            continue
        if "backward compatibility" in read_text(target):
            issues.append(f"{rel_path} contains forbidden phrase `backward compatibility`")

    for path in root.rglob(".DS_Store"):
        issues.append(f"Forbidden artifact present: {path.relative_to(root)}")
    for path in root.rglob("__pycache__"):
        if path.is_dir():
            issues.append(f"Forbidden artifact present: {path.relative_to(root)}")

    return issues


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    if not root.exists():
        raise SystemExit(f"Root does not exist: {root}")

    issues = validate_family(root, args.family)
    manifest_entries = read_manifest(root / MANIFEST_BY_FAMILY[args.family])

    if issues:
        print("FAIL")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print(f"PASS: {len(manifest_entries)} validated targets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
