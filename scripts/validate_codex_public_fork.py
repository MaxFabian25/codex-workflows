#!/usr/bin/env python3

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent

REQUIRED_PATHS = [
    ".codex-plugin/plugin.json",
    "README.md",
    ".codex/INSTALL.md",
    "docs/README.codex.md",
    "SECURITY.md",
    "package.json",
]

REMOVED_PATHS = [
    ".claude-plugin",
    ".cursor-plugin",
    ".opencode",
    "hooks",
    "docs/README.opencode.md",
    "GEMINI.md",
    "gemini-extension.json",
]

FORBIDDEN_SCAN_TARGETS = [
    "README.md",
    ".codex/INSTALL.md",
    "docs/README.codex.md",
    ".github/ISSUE_TEMPLATE/config.yml",
    "CODE_OF_CONDUCT.md",
    "CHANGELOG.md",
    "RELEASE-NOTES.md",
    "SECURITY.md",
    "package.json",
    ".codex-plugin/plugin.json",
    "skills/using-superpowers/SKILL.md",
    "skills/using-superpowers/references/codex-tools.md",
    "skills/writing-skills/SKILL.md",
]

FORBIDDEN_SNIPPETS = [
    "https://github.com/obra/superpowers",
    "https://github.com/obra/superpowers-marketplace",
    "https://claude.com/plugins/superpowers",
    "discord.gg/Jd8Vphy9jq",
    "github.com/sponsors/obra",
    "/Users/maxibon",
    "maxfa-",
    ".worktrees/",
    "~/.claude/skills",
    "~/.config/opencode",
    "CLAUDE_PLUGIN_ROOT",
    "OpenCode",
    "Gemini CLI",
]

EXPECTED_MANIFEST_FIELDS = {
    "name": "superpowers-codex",
    "skills": "./skills/",
    "repository": "https://github.com/MaxFabian25/superpowers",
    "homepage": "https://github.com/MaxFabian25/superpowers",
    "license": "MIT",
}

REQUIRED_INTERFACE_FIELDS = [
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
    "capabilities",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def validate_required_paths() -> list[str]:
    issues: list[str] = []
    for rel_path in REQUIRED_PATHS:
        if not (ROOT / rel_path).exists():
            issues.append(f"Missing required path: {rel_path}")
    return issues


def validate_removed_paths() -> list[str]:
    issues: list[str] = []
    for rel_path in REMOVED_PATHS:
        if (ROOT / rel_path).exists():
            issues.append(f"Removed path still exists: {rel_path}")
    return issues


def validate_forbidden_snippets() -> list[str]:
    issues: list[str] = []
    for rel_path in FORBIDDEN_SCAN_TARGETS:
        path = ROOT / rel_path
        if not path.exists():
            continue
        text = read_text(path)
        for snippet in FORBIDDEN_SNIPPETS:
            if snippet in text:
                issues.append(f"{rel_path} contains forbidden snippet: {snippet}")
    return issues


def is_non_empty(value: object) -> bool:
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, list):
        return any(isinstance(item, str) and item.strip() for item in value)
    return value is not None


def validate_manifest() -> list[str]:
    issues: list[str] = []
    manifest_path = ROOT / ".codex-plugin/plugin.json"
    if not manifest_path.exists():
        return issues

    try:
        manifest = json.loads(read_text(manifest_path))
    except json.JSONDecodeError as exc:
        return [f".codex-plugin/plugin.json is invalid JSON: {exc.msg}"]

    for field, expected_value in EXPECTED_MANIFEST_FIELDS.items():
        actual_value = manifest.get(field)
        if actual_value != expected_value:
            issues.append(
                f".codex-plugin/plugin.json field `{field}` must be `{expected_value}` but found `{actual_value}`"
            )

    interface = manifest.get("interface")
    if not isinstance(interface, dict):
        issues.append(".codex-plugin/plugin.json field `interface` must be an object")
        return issues

    for field in REQUIRED_INTERFACE_FIELDS:
        if not is_non_empty(interface.get(field)):
            issues.append(f".codex-plugin/plugin.json interface field `{field}` must be non-empty")

    return issues


def main() -> int:
    issues = [
        *validate_required_paths(),
        *validate_removed_paths(),
        *validate_forbidden_snippets(),
        *validate_manifest(),
    ]

    if issues:
        print("FAIL: codex public fork validator")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("PASS: codex public fork validator")
    return 0


if __name__ == "__main__":
    sys.exit(main())
