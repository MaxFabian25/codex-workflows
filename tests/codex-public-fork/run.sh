#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

prepare_fixture() {
  local fixture_root="$1"

  if [[ -e "$fixture_root/scripts/validate_codex_public_fork.py" ]]; then
    return 0
  fi

  mkdir -p \
    "$fixture_root/scripts" \
    "$fixture_root/.codex-plugin" \
    "$fixture_root/.codex" \
    "$fixture_root/docs" \
    "$fixture_root/skills/sample" \
    "$fixture_root/contract" \
    "$fixture_root/_shared/validators" \
    "$fixture_root/tests/codex-public-fork"

  cp "$ROOT/scripts/validate_codex_public_fork.py" "$fixture_root/scripts/validate_codex_public_fork.py"

  cat >"$fixture_root/README.md" <<'EOF'
Codex-only package README.
EOF
  cat >"$fixture_root/.codex/INSTALL.md" <<'EOF'
Install docs for Codex users.
EOF
  cat >"$fixture_root/docs/README.codex.md" <<'EOF'
Codex docs surface.
EOF
  cat >"$fixture_root/SECURITY.md" <<'EOF'
Security policy.
EOF
  cat >"$fixture_root/LICENSE" <<'EOF'
MIT
EOF
  cat >"$fixture_root/CHANGELOG.md" <<'EOF'
Changelog.
EOF
  cat >"$fixture_root/RELEASE-NOTES.md" <<'EOF'
Release notes.
EOF
  cat >"$fixture_root/contract/process-family.md" <<'EOF'
Process family contract.
EOF
  cat >"$fixture_root/contract/package-standards.md" <<'EOF'
Package standards contract.
EOF
  cat >"$fixture_root/_shared/validators/validate_skill_library.py" <<'EOF'
#!/usr/bin/env python3
print("fixture validator placeholder")
EOF
  chmod +x "$fixture_root/_shared/validators/validate_skill_library.py"
  cat >"$fixture_root/tests/codex-public-fork/run.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF
  chmod +x "$fixture_root/tests/codex-public-fork/run.sh"
  cat >"$fixture_root/skills/sample/SKILL.md" <<'EOF'
# Sample skill
EOF
  cat >"$fixture_root/.codex-plugin/plugin.json" <<'EOF'
{
  "name": "superpowers-codex",
  "version": "5.0.6",
  "description": "Codex-only workflow and skills library forked from obra/superpowers.",
  "author": {
    "name": "Max Fabian",
    "url": "https://github.com/MaxFabian25"
  },
  "homepage": "https://github.com/MaxFabian25/superpowers",
  "repository": "https://github.com/MaxFabian25/superpowers",
  "license": "MIT",
  "keywords": [
    "codex",
    "plugin",
    "skills",
    "workflow"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Superpowers for Codex",
    "shortDescription": "Codex-only workflow and skill library",
    "longDescription": "A Codex-specific fork of obra/superpowers focused on design, planning, execution, debugging, and review workflows.",
    "developerName": "Max Fabian",
    "category": "Developer Tools",
    "capabilities": [
      "Interactive",
      "Write"
    ]
  }
}
EOF
  cat >"$fixture_root/package.json" <<'EOF'
{
  "name": "superpowers-codex",
  "version": "5.0.6",
  "description": "Codex-only workflow and skills library, forked from obra/superpowers.",
  "type": "module",
  "license": "MIT",
  "repository": "https://github.com/MaxFabian25/superpowers",
  "homepage": "https://github.com/MaxFabian25/superpowers",
  "bugs": {
    "url": "https://github.com/MaxFabian25/superpowers"
  },
  "files": [
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
    "docs/README.codex.md"
  ],
  "scripts": {
    "validate:public-fork": "bash tests/codex-public-fork/run.sh",
    "validate:process-family": "python3 _shared/validators/validate_skill_library.py --root . --family process"
  }
}
EOF

  (
    cd "$fixture_root"
    true
  )
}

run_fixture_validator() {
  local fixture_root="$1"

  (
    cd "$fixture_root"
    python3 scripts/validate_codex_public_fork.py
  )
}

expect_fixture_passes() {
  local fixture_root="$1"
  prepare_fixture "$fixture_root"
  if ! output="$(run_fixture_validator "$fixture_root" 2>&1)"; then
    printf 'Expected validator to pass, but it failed:\n%s\n' "$output" >&2
    return 1
  fi
}

expect_fixture_fails_with() {
  local fixture_root="$1"
  local expected_fragment="$2"

  prepare_fixture "$fixture_root"
  if output="$(run_fixture_validator "$fixture_root" 2>&1)"; then
    printf 'Expected validator to fail, but it passed.\n' >&2
    return 1
  fi

  if [[ "$output" != *"$expected_fragment"* ]]; then
    printf 'Expected validator output to contain %q, but saw:\n%s\n' "$expected_fragment" "$output" >&2
    return 1
  fi
}

run_self_tests() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  expect_fixture_passes "$tmpdir/base"

  mkdir -p "$tmpdir/release-surface/skills/private"
  cat >"$tmpdir/release-surface/skills/private/notes.md" <<'EOF'
This published file still mentions Gemini CLI.
EOF
  expect_fixture_fails_with "$tmpdir/release-surface" "skills/private/notes.md contains forbidden snippet: Gemini CLI"

  expect_fixture_passes "$tmpdir/package-contract"
  python3 - <<'PY' "$tmpdir/package-contract/package.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["version"] = "0.0.1"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with "$tmpdir/package-contract" 'package.json field `version` must be `5.0.6`'

  expect_fixture_passes "$tmpdir/broken-symlink"
  ln -s missing-target "$tmpdir/broken-symlink/.claude-plugin"
  expect_fixture_fails_with "$tmpdir/broken-symlink" "Removed path still exists: .claude-plugin"

  echo "PASS: codex public fork self-tests"
}

if [[ "${1:-}" == "self-test" ]]; then
  run_self_tests
  exit 0
fi

cd "$ROOT"

run_self_tests

python3 scripts/validate_codex_public_fork.py
python3 _shared/validators/validate_skill_library.py --root "$ROOT" --family process
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'

echo "PASS: codex public fork validation bundle"
