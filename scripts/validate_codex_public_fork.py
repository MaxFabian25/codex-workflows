#!/usr/bin/env python3

import json
import subprocess
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

PACKAGED_SCAN_EXCLUDED_PATHS = {
    "scripts/validate_codex_public_fork.py",
    "tests/codex-public-fork/run.sh",
}

EXPECTED_PACKAGE_FIELDS = {
    "name": "superpowers-codex",
    "version": "5.0.6",
    "description": "Codex-only workflow and skills library, forked from obra/superpowers.",
    "type": "module",
    "license": "MIT",
    "repository": "https://github.com/MaxFabian25/superpowers",
    "homepage": "https://github.com/MaxFabian25/superpowers",
}

EXPECTED_PACKAGE_BUGS_URL = "https://github.com/MaxFabian25/superpowers"

EXPECTED_PACKAGE_SCRIPTS = {
    "validate:public-fork": "bash tests/codex-public-fork/run.sh",
    "validate:process-family": "python3 _shared/validators/validate_skill_library.py --root . --family process",
}

REQUIRED_PACKAGE_FILE_ENTRIES = [
    "skills",
    "contract",
    "_shared",
    "scripts",
    "tests",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "CHANGELOG.md",
    "RELEASE-NOTES.md",
    "package.json",
    ".codex-plugin/plugin.json",
    ".codex/INSTALL.md",
    "docs/README.codex.md",
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


def read_json(path: Path) -> object:
    return json.loads(read_text(path))


def validate_required_paths() -> list[str]:
    issues: list[str] = []
    for rel_path in REQUIRED_PATHS:
        if not (ROOT / rel_path).exists():
            issues.append(f"Missing required path: {rel_path}")
    return issues


def validate_removed_paths() -> list[str]:
    issues: list[str] = []
    for rel_path in REMOVED_PATHS:
        path = ROOT / rel_path
        if path.exists() or path.is_symlink():
            issues.append(f"Removed path still exists: {rel_path}")
    return issues


def read_text_if_packaged_text(path: Path) -> str | None:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        raise RuntimeError(f"Unable to read packaged file `{path.relative_to(ROOT)}`: {exc}") from exc

    if b"\0" in raw:
        return None

    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return None


def load_pack_file_list() -> tuple[list[str], list[str]]:
    command = ["npm", "pack", "--dry-run", "--json"]
    result = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        stderr = result.stderr.strip()
        stdout = result.stdout.strip()
        detail = stderr or stdout or "no output"
        return [], [f"`{' '.join(command)}` failed: {detail}"]

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return [], [f"`npm pack --dry-run --json` returned invalid JSON: {exc.msg}"]

    if not isinstance(payload, list) or not payload:
        return [], ["`npm pack --dry-run --json` returned no package entries"]

    files = payload[0].get("files")
    if not isinstance(files, list):
        return [], ["`npm pack --dry-run --json` payload is missing its `files` list"]

    issues: list[str] = []
    rel_paths: list[str] = []
    for entry in files:
        if not isinstance(entry, dict):
            issues.append("`npm pack --dry-run --json` listed a non-object file entry")
            continue
        rel_path = entry.get("path")
        if not isinstance(rel_path, str) or not rel_path:
            issues.append("`npm pack --dry-run --json` listed a file entry without a valid `path`")
            continue
        rel_paths.append(rel_path)

    return rel_paths, issues


def validate_forbidden_snippets() -> list[str]:
    rel_paths, issues = load_pack_file_list()
    if issues:
        return issues

    for rel_path in rel_paths:
        if rel_path in PACKAGED_SCAN_EXCLUDED_PATHS:
            continue

        path = ROOT / rel_path
        if not path.exists():
            issues.append(f"Packaged path is missing from the working tree: {rel_path}")
            continue

        text = read_text_if_packaged_text(path)
        if text is None:
            continue

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
        manifest = read_json(manifest_path)
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


def validate_package_contract() -> list[str]:
    package_path = ROOT / "package.json"
    if not package_path.exists():
        return []

    try:
        package = read_json(package_path)
    except json.JSONDecodeError as exc:
        return [f"package.json is invalid JSON: {exc.msg}"]

    if not isinstance(package, dict):
        return ["package.json must contain a JSON object"]

    issues: list[str] = []
    for field, expected_value in EXPECTED_PACKAGE_FIELDS.items():
        actual_value = package.get(field)
        if actual_value != expected_value:
            issues.append(f"package.json field `{field}` must be `{expected_value}` but found `{actual_value}`")

    bugs = package.get("bugs")
    if not isinstance(bugs, dict):
        issues.append("package.json field `bugs` must be an object")
    elif bugs.get("url") != EXPECTED_PACKAGE_BUGS_URL:
        issues.append(
            f"package.json field `bugs.url` must be `{EXPECTED_PACKAGE_BUGS_URL}` but found `{bugs.get('url')}`"
        )

    scripts = package.get("scripts")
    if not isinstance(scripts, dict):
        issues.append("package.json field `scripts` must be an object")
    else:
        for field, expected_value in EXPECTED_PACKAGE_SCRIPTS.items():
            actual_value = scripts.get(field)
            if actual_value != expected_value:
                issues.append(
                    f"package.json script `{field}` must be `{expected_value}` but found `{actual_value}`"
                )

    files = package.get("files")
    if not isinstance(files, list):
        issues.append("package.json field `files` must be an array")
    else:
        file_entries = {item for item in files if isinstance(item, str)}
        for required_entry in REQUIRED_PACKAGE_FILE_ENTRIES:
            if required_entry not in file_entries:
                issues.append(f"package.json `files` must include `{required_entry}`")

    return issues


def main() -> int:
    issues = [
        *validate_required_paths(),
        *validate_removed_paths(),
        *validate_package_contract(),
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
