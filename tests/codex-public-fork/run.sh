#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

join_fragments() {
  local fragment
  local output=""
  for fragment in "$@"; do
    output+="$fragment"
  done
  printf '%s' "$output"
}

forbidden_gemini_cli() {
  join_fragments "Gemini" " CLI"
}

forbidden_claude_code() {
  join_fragments "Claude" " Code"
}

forbidden_claude_md() {
  join_fragments "CLAUDE" ".md"
}

forbidden_stale_hooks_path() {
  join_fragments "~/.config/" "superpowers/hooks/"
}

forbidden_no_hook_bootstrap_wording() {
  join_fragments "does not depend on " "Codex hook bootstrap"
}

expected_release_version() {
  printf '%s' '5.0.6-codex.1'
}

append_text() {
  local target_path="$1"
  local payload="$2"

  python3 - <<'PY' "$target_path" "$payload"
from pathlib import Path
import sys

path = Path(sys.argv[1])
payload = sys.argv[2]
path.write_text(path.read_text(encoding="utf-8") + payload, encoding="utf-8")
PY
}

expected_issue() {
  local rel_path="$1"
  local snippet="$2"

  join_fragments "$rel_path" " contains forbidden snippet: " "$snippet"
}

require_path() {
  local rel_path="$1"

  if [[ ! -e "$ROOT/$rel_path" ]]; then
    printf 'Expected required path %s to exist.\n' "$rel_path" >&2
    return 1
  fi
}

require_pattern() {
  local pattern="$1"
  shift

  if ! rg -n "$pattern" "$@" >/dev/null; then
    printf 'Expected pattern %s in: %s\n' "$pattern" "$*" >&2
    return 1
  fi
}

reject_pattern() {
  local pattern="$1"
  shift

  if rg -n "$pattern" "$@" >/dev/null; then
    printf 'Forbidden pattern %s found in: %s\n' "$pattern" "$*" >&2
    return 1
  fi
}

require_fixed() {
  local needle="$1"
  shift

  if ! rg -F -n -- "$needle" "$@" >/dev/null; then
    printf 'Expected literal %s in: %s\n' "$needle" "$*" >&2
    return 1
  fi
}

reject_fixed() {
  local needle="$1"
  shift

  if rg -F -n -- "$needle" "$@" >/dev/null; then
    printf 'Forbidden literal %s found in: %s\n' "$needle" "$*" >&2
    return 1
  fi
}

prepare_fixture() {
  local fixture_root="$1"

  if [[ -e "$fixture_root/scripts/validate_codex_public_fork.py" ]]; then
    return 0
  fi

  mkdir -p \
    "$fixture_root/scripts" \
    "$fixture_root/.codex-plugin" \
    "$fixture_root/.codex" \
    "$fixture_root/.github/ISSUE_TEMPLATE" \
    "$fixture_root/docs" \
    "$fixture_root/hooks" \
    "$fixture_root/tests/cmux-superpowers" \
    "$fixture_root/skills/sample" \
    "$fixture_root/contract" \
    "$fixture_root/_shared/validators" \
    "$fixture_root/tests/codex-public-fork"

  cp "$ROOT/scripts/validate_codex_public_fork.py" "$fixture_root/scripts/validate_codex_public_fork.py"
  cp "$ROOT/scripts/install_codex_hooks.py" "$fixture_root/scripts/install_codex_hooks.py"
  cp "$ROOT/scripts/install_cmux_superpowers_launcher.py" "$fixture_root/scripts/install_cmux_superpowers_launcher.py"
  cp "$ROOT/scripts/cmux_superpowers_team.py" "$fixture_root/scripts/cmux_superpowers_team.py"
  cp "$ROOT/hooks/hooks.json" "$fixture_root/hooks/hooks.json"
  cp "$ROOT/hooks/session-start" "$fixture_root/hooks/session-start"

  cat >"$fixture_root/README.md" <<'EOF'
Install with:
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
- cmux codex install-hooks
- Set `[features].codex_hooks = true` in ~/.codex/config.toml
- cmux-superpowers doctor

Uninstall with:
- Remove the `superpowers-codex` entry from ~/.agents/plugins/marketplace.json
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py --remove
- cmux codex uninstall-hooks
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py --remove
EOF
  cat >"$fixture_root/.codex/INSTALL.md" <<'EOF'
Install with:
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
- cmux codex install-hooks
- Set `[features].codex_hooks = true` in ~/.codex/config.toml
- cmux-superpowers doctor

Uninstall with:
- Remove the `superpowers-codex` entry from ~/.agents/plugins/marketplace.json
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py --remove
- cmux codex uninstall-hooks
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py --remove
EOF
  cat >"$fixture_root/docs/README.codex.md" <<'EOF'
Install with:
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
- cmux codex install-hooks
- Set `[features].codex_hooks = true` in ~/.codex/config.toml
- cmux-superpowers doctor

Uninstall with:
- Remove the `superpowers-codex` entry from ~/.agents/plugins/marketplace.json
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py --remove
- cmux codex uninstall-hooks
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py --remove
EOF
  cat >"$fixture_root/SECURITY.md" <<'EOF'
Security policy.
EOF
  cat >"$fixture_root/CODE_OF_CONDUCT.md" <<'EOF'
Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported privately through
https://github.com/MaxFabian25/superpowers/security/advisories/new.
EOF
  cat >"$fixture_root/LICENSE" <<'EOF'
MIT
EOF
  cat >"$fixture_root/CHANGELOG.md" <<'EOF'
## 5.0.6-codex.1
EOF
  cat >"$fixture_root/RELEASE-NOTES.md" <<'EOF'
## 5.0.6-codex.1
EOF
  cat >"$fixture_root/.github/ISSUE_TEMPLATE/config.yml" <<'EOF'
blank_issues_enabled: false
contact_links:
  - name: Private security or conduct report
    url: https://github.com/MaxFabian25/superpowers/security/advisories/new
    about: Report security issues or conduct concerns privately through GitHub Security Advisories.
EOF
  cat >"$fixture_root/.github/ISSUE_TEMPLATE/bug_report.md" <<'EOF'
| Superpowers version | |
| Codex version | |
| Model | |
| OS + shell | |
EOF
  cat >"$fixture_root/.github/ISSUE_TEMPLATE/feature_request.md" <<'EOF'
## Context
Optional: Superpowers version, Codex version, model, and workflow context.
EOF
  cat >"$fixture_root/.github/PULL_REQUEST_TEMPLATE.md" <<'EOF'
| Codex version | Model | Model version/ID | OS + shell |
|---------------|-------|------------------|------------|
|               |       |                  |            |
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
  cat >"$fixture_root/tests/cmux-superpowers/install.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF
  chmod +x "$fixture_root/tests/cmux-superpowers/install.sh"
  cat >"$fixture_root/tests/cmux-superpowers/doctor.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF
  chmod +x "$fixture_root/tests/cmux-superpowers/doctor.sh"
  cat >"$fixture_root/tests/cmux-superpowers/team_smoke.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF
  chmod +x "$fixture_root/tests/cmux-superpowers/team_smoke.sh"
  cat >"$fixture_root/skills/sample/SKILL.md" <<'EOF'
# Sample skill
EOF
  cat >"$fixture_root/.codex-plugin/plugin.json" <<'EOF'
{
  "name": "superpowers-codex",
  "version": "5.0.6-codex.1",
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
  "version": "5.0.6-codex.1",
  "description": "Codex-only workflow and skills library, forked from obra/superpowers.",
  "type": "module",
  "license": "MIT",
  "repository": "https://github.com/MaxFabian25/superpowers",
  "homepage": "https://github.com/MaxFabian25/superpowers",
  "bugs": {
    "url": "https://github.com/MaxFabian25/superpowers/issues"
  },
  "files": [
    "skills",
    "contract",
    "_shared",
    "hooks",
    "scripts",
    "tests",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "CODE_OF_CONDUCT.md",
    "CHANGELOG.md",
    "RELEASE-NOTES.md",
    "package.json",
    ".codex-plugin/plugin.json",
    ".codex/INSTALL.md",
    "docs/README.codex.md"
  ],
  "scripts": {
    "validate:public-fork": "bash tests/codex-public-fork/run.sh",
    "validate:process-family": "python3 _shared/validators/validate_skill_library.py --root . --family process",
    "validate:cmux-superpowers": "bash tests/cmux-superpowers/install.sh && bash tests/cmux-superpowers/doctor.sh && bash tests/cmux-superpowers/team_smoke.sh"
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

run_fixture_hook_installer() {
  local fixture_root="$1"
  local codex_home="$2"

  (
    cd "$fixture_root"
    python3 scripts/install_codex_hooks.py --codex-home "$codex_home"
  )
}

run_fixture_hook_remover() {
  local fixture_root="$1"
  local codex_home="$2"

  (
    cd "$fixture_root"
    python3 scripts/install_codex_hooks.py --codex-home "$codex_home" --remove
  )
}

expect_fixture_hook_installer_writes_codex_hooks() {
  local fixture_root="$1"
  local codex_home="$2"

  prepare_fixture "$fixture_root"
  mkdir -p "$codex_home"
  if ! output="$(run_fixture_hook_installer "$fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook installer to succeed, but it failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

fixture_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
hooks_path = codex_home / "hooks.json"
data = json.loads(hooks_path.read_text(encoding="utf-8"))
group = data["hooks"]["SessionStart"][0]
handler = group["hooks"][0]

assert group["matcher"] == "startup|resume|clear"
assert handler["type"] == "command"
assert handler["statusMessage"] == "loading superpowers"

command = handler["command"]
expected_script = str(fixture_root / "hooks" / "session-start")
if expected_script not in command:
    raise SystemExit(f"hooks.json command does not point at {expected_script}: {command}")
PY
}

expect_fixture_hook_installer_preserves_unrelated_sessionstart_hooks() {
  local fixture_root="$1"
  local codex_home="$2"

  prepare_fixture "$fixture_root"
  mkdir -p "$codex_home"
  python3 - <<'PY' "$codex_home"
import json
import sys
from pathlib import Path

codex_home = Path(sys.argv[1])
payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": "startup|resume|clear",
                "hooks": [
                    {
                        "type": "command",
                        "command": "/tmp/another-plugin/hooks/session-start",
                        "statusMessage": "loading superpowers",
                    }
                ],
            }
        ]
    }
}
(codex_home / "hooks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

  if ! output="$(run_fixture_hook_installer "$fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook installer to preserve unrelated hooks, but install failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

fixture_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
hooks_path = codex_home / "hooks.json"
data = json.loads(hooks_path.read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 2, session_groups

commands = [group["hooks"][0]["command"] for group in session_groups]
assert "/tmp/another-plugin/hooks/session-start" in commands

expected_script = str(fixture_root / "hooks" / "session-start")
matching = [
    group
    for group in session_groups
    if expected_script in group["hooks"][0]["command"]
]
assert len(matching) == 1, session_groups
assert matching[0]["hooks"][0]["statusMessage"] == "loading superpowers"
PY

  if ! output="$(run_fixture_hook_remover "$fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook remover to preserve unrelated hooks, but remove failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$codex_home"
import json
import sys
from pathlib import Path

codex_home = Path(sys.argv[1])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 1, session_groups
handler = session_groups[0]["hooks"][0]
assert handler["command"] == "/tmp/another-plugin/hooks/session-start"
assert handler["statusMessage"] == "loading superpowers"
PY
}

expect_fixture_hook_installer_replaces_prior_superpowers_clone_path() {
  local current_fixture_root="$1"
  local prior_fixture_root="$2"
  local codex_home="$3"

  prepare_fixture "$current_fixture_root"
  prepare_fixture "$prior_fixture_root"
  mkdir -p "$codex_home"

  python3 - <<'PY' "$prior_fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

prior_fixture_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": "startup|resume|clear",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"python3 {prior_fixture_root / 'hooks' / 'session-start'}",
                        "statusMessage": "loading superpowers",
                    }
                ],
            }
        ]
    }
}
(codex_home / "hooks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

  if ! output="$(run_fixture_hook_installer "$current_fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook installer to replace a prior Superpowers clone hook, but install failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$current_fixture_root" "$prior_fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

current_fixture_root = Path(sys.argv[1])
prior_fixture_root = Path(sys.argv[2])
codex_home = Path(sys.argv[3])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 1, session_groups
command = session_groups[0]["hooks"][0]["command"]
assert str(current_fixture_root / "hooks" / "session-start") in command, command
assert str(prior_fixture_root / "hooks" / "session-start") not in command, command
PY

  if ! output="$(run_fixture_hook_remover "$current_fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook remover to remove the migrated Superpowers hook, but remove failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$codex_home"
import json
import sys
from pathlib import Path

codex_home = Path(sys.argv[1])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
assert "SessionStart" not in data["hooks"], data
PY
}

expect_fixture_hook_installer_replaces_deleted_prior_superpowers_clone_path() {
  local current_fixture_root="$1"
  local prior_fixture_root="$2"
  local codex_home="$3"

  prepare_fixture "$current_fixture_root"
  prepare_fixture "$prior_fixture_root"
  mkdir -p "$codex_home"

  python3 - <<'PY' "$prior_fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

prior_fixture_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": "startup|resume|clear",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"python3 {prior_fixture_root / 'hooks' / 'session-start'}",
                        "statusMessage": "loading superpowers",
                    }
                ],
            }
        ]
    }
}
(codex_home / "hooks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
  rm -rf "$prior_fixture_root"

  if ! output="$(run_fixture_hook_installer "$current_fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook installer to replace a deleted prior Superpowers clone hook, but install failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$current_fixture_root" "$prior_fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

current_fixture_root = Path(sys.argv[1])
prior_fixture_root = Path(sys.argv[2])
codex_home = Path(sys.argv[3])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 1, session_groups
command = session_groups[0]["hooks"][0]["command"]
assert str(current_fixture_root / "hooks" / "session-start") in command, command
assert str(prior_fixture_root / "hooks" / "session-start") not in command, command
PY
}

expect_fixture_hook_remover_removes_deleted_prior_superpowers_clone_path() {
  local current_fixture_root="$1"
  local prior_fixture_root="$2"
  local codex_home="$3"

  prepare_fixture "$current_fixture_root"
  prepare_fixture "$prior_fixture_root"
  mkdir -p "$codex_home"

  python3 - <<'PY' "$prior_fixture_root" "$codex_home"
import json
import sys
from pathlib import Path

prior_fixture_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": "startup|resume|clear",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"python3 {prior_fixture_root / 'hooks' / 'session-start'}",
                        "statusMessage": "loading superpowers",
                    }
                ],
            }
        ]
    }
}
(codex_home / "hooks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
  rm -rf "$prior_fixture_root"

  if ! output="$(run_fixture_hook_remover "$current_fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook remover to remove a deleted prior Superpowers clone hook, but remove failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$codex_home"
import json
import sys
from pathlib import Path

codex_home = Path(sys.argv[1])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
assert "SessionStart" not in data["hooks"], data
PY
}

expect_fixture_hook_installer_preserves_deleted_unrelated_missing_sessionstart_sidecar() {
  local fixture_root="$1"
  local deleted_sidecar_root="$2"
  local codex_home="$3"

  prepare_fixture "$fixture_root"
  mkdir -p "$codex_home"

  python3 - <<'PY' "$deleted_sidecar_root" "$codex_home"
import json
import sys
from pathlib import Path

deleted_sidecar_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": "startup|resume|clear",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"python3 {deleted_sidecar_root / 'hooks' / 'session-start'}",
                        "statusMessage": "loading superpowers",
                    }
                ],
            }
        ]
    }
}
(codex_home / "hooks.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

  if ! output="$(run_fixture_hook_installer "$fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook installer to preserve a deleted unrelated SessionStart sidecar, but install failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$fixture_root" "$deleted_sidecar_root" "$codex_home"
import json
import sys
from pathlib import Path

fixture_root = Path(sys.argv[1])
deleted_sidecar_root = Path(sys.argv[2])
codex_home = Path(sys.argv[3])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 2, session_groups

commands = [group["hooks"][0]["command"] for group in session_groups]
assert f"python3 {deleted_sidecar_root / 'hooks' / 'session-start'}" in commands, commands
assert any(str(fixture_root / "hooks" / "session-start") in command for command in commands), commands
PY

  if ! output="$(run_fixture_hook_remover "$fixture_root" "$codex_home" 2>&1)"; then
    printf 'Expected Codex hook remover to preserve a deleted unrelated SessionStart sidecar, but remove failed:\n%s\n' "$output" >&2
    return 1
  fi

  python3 - <<'PY' "$deleted_sidecar_root" "$codex_home"
import json
import sys
from pathlib import Path

deleted_sidecar_root = Path(sys.argv[1])
codex_home = Path(sys.argv[2])
data = json.loads((codex_home / "hooks.json").read_text(encoding="utf-8"))
session_groups = data["hooks"]["SessionStart"]
assert len(session_groups) == 1, session_groups
command = session_groups[0]["hooks"][0]["command"]
assert command == f"python3 {deleted_sidecar_root / 'hooks' / 'session-start'}", command
PY
}

prepare_process_family_fixture() {
  local fixture_root="$1"

  if [[ -e "$fixture_root/_shared/validators/process_family_targets.txt" ]]; then
    return 0
  fi

  python3 - <<'PY' "$ROOT" "$fixture_root"
from pathlib import Path
import importlib.util
import shutil
import sys

src_root = Path(sys.argv[1])
dst_root = Path(sys.argv[2])
manifest_rel = Path("_shared/validators/process_family_targets.txt")
validator_rel = Path("_shared/validators/validate_skill_library.py")
manifest_path = src_root / manifest_rel
spec = importlib.util.spec_from_file_location("validate_skill_library", src_root / validator_rel)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
previous_dont_write_bytecode = sys.dont_write_bytecode
sys.dont_write_bytecode = True
try:
    spec.loader.exec_module(module)
finally:
    sys.dont_write_bytecode = previous_dont_write_bytecode

manifest_targets = {
    line.strip()
    for line in manifest_path.read_text(encoding="utf-8").splitlines()
    if line.strip()
}
targeted_targets = set()
for name, value in vars(module).items():
    if not name.startswith("TARGETED_") or not isinstance(value, dict):
        continue
    targeted_targets.update(
        key for key in value if isinstance(key, str) and "/" in key
    )

targets = sorted(manifest_targets | targeted_targets)

for rel in [manifest_rel, validator_rel, *map(Path, targets)]:
    src = src_root / rel
    dst = dst_root / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
PY
}

set_process_family_fixture_validator_probe() {
  local fixture_root="$1"

  cat >"$fixture_root/_shared/validators/validate_skill_library.py" <<'EOF'
#!/usr/bin/env python3
import sys
print("fixture validator probe")
sys.exit(0)
EOF
  chmod +x "$fixture_root/_shared/validators/validate_skill_library.py"
}

run_process_family_fixture_validator() {
  local fixture_root="$1"

  python3 "$fixture_root/_shared/validators/validate_skill_library.py" --root "$fixture_root" --family process
}

expect_process_family_fixture_copies_targeted_only_paths() {
  local fixture_root="$1"

  prepare_process_family_fixture "$fixture_root"
  python3 - <<'PY' "$ROOT" "$fixture_root"
from pathlib import Path
import importlib.util
import sys

src_root = Path(sys.argv[1])
fixture_root = Path(sys.argv[2])
validator_path = src_root / "_shared/validators/validate_skill_library.py"

spec = importlib.util.spec_from_file_location("validate_skill_library", validator_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
previous_dont_write_bytecode = sys.dont_write_bytecode
sys.dont_write_bytecode = True
try:
    spec.loader.exec_module(module)
finally:
    sys.dont_write_bytecode = previous_dont_write_bytecode

manifest_path = src_root / module.MANIFEST_BY_FAMILY["process"]
manifest_entries = {
    line.strip()
    for line in manifest_path.read_text(encoding="utf-8").splitlines()
    if line.strip()
}
targeted_entries = set(module.TARGETED_REQUIRED_SUBSTRINGS) | set(module.TARGETED_CONTENT_GUARDS)
missing = [
    rel_path
    for rel_path in sorted(targeted_entries - manifest_entries)
    if not (fixture_root / rel_path).exists()
]
if missing:
    raise SystemExit(
        "Fixture is missing validator-targeted non-manifest paths: " + ", ".join(missing)
    )
PY
}

expect_process_family_fixture_passes() {
  local fixture_root="$1"

  prepare_process_family_fixture "$fixture_root"
  if ! output="$(run_process_family_fixture_validator "$fixture_root" 2>&1)"; then
    printf 'Expected process-family validator to pass, but it failed:\n%s\n' "$output" >&2
    return 1
  fi
}

expect_process_family_fixture_fails_with() {
  local fixture_root="$1"
  local expected_fragment="$2"

  prepare_process_family_fixture "$fixture_root"
  if output="$(run_process_family_fixture_validator "$fixture_root" 2>&1)"; then
    printf 'Expected process-family validator to fail, but it passed.\n' >&2
    return 1
  fi

  if [[ "$output" != *"$expected_fragment"* ]]; then
    printf 'Expected process-family validator output to contain %q, but saw:\n%s\n' "$expected_fragment" "$output" >&2
    return 1
  fi
}

expect_process_family_fixture_uses_copied_validator() {
  local fixture_root="$1"

  prepare_process_family_fixture "$fixture_root"
  set_process_family_fixture_validator_probe "$fixture_root"
  if ! output="$(run_process_family_fixture_validator "$fixture_root" 2>&1)"; then
    printf 'Expected copied process-family validator probe to run, but command failed:\n%s\n' "$output" >&2
    return 1
  fi

  if [[ "$output" != *"fixture validator probe"* ]]; then
    printf 'Expected copied process-family validator probe output, but saw:\n%s\n' "$output" >&2
    return 1
  fi
}

run_self_tests() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  expect_fixture_passes "$tmpdir/base"

  mkdir -p "$tmpdir/release-surface/skills/private"
  printf 'This published file still mentions %s.\n' "$(forbidden_gemini_cli)" \
    >"$tmpdir/release-surface/skills/private/notes.md"
  expect_fixture_fails_with \
    "$tmpdir/release-surface" \
    "$(expected_issue "skills/private/notes.md" "$(forbidden_gemini_cli)")"

  mkdir -p "$tmpdir/claude-code-surface/skills/private"
  printf 'This published file still mentions %s.\n' "$(forbidden_claude_code)" \
    >"$tmpdir/claude-code-surface/skills/private/notes.md"
  expect_fixture_fails_with \
    "$tmpdir/claude-code-surface" \
    "$(expected_issue "skills/private/notes.md" "$(forbidden_claude_code)")"

  mkdir -p "$tmpdir/claude-md-surface/skills/private"
  printf 'This published file still points to %s.\n' "$(forbidden_claude_md)" \
    >"$tmpdir/claude-md-surface/skills/private/notes.md"
  expect_fixture_fails_with \
    "$tmpdir/claude-md-surface" \
    "$(expected_issue "skills/private/notes.md" "$(forbidden_claude_md)")"

  mkdir -p "$tmpdir/stale-hook-surface/skills/private"
  printf 'This published file still points to %s.\n' "$(forbidden_stale_hooks_path)" \
    >"$tmpdir/stale-hook-surface/skills/private/notes.md"
  expect_fixture_fails_with \
    "$tmpdir/stale-hook-surface" \
    "$(expected_issue "skills/private/notes.md" "$(forbidden_stale_hooks_path)")"

  expect_fixture_passes "$tmpdir/no-hook-doc-wording"
  append_text \
    "$tmpdir/no-hook-doc-wording/docs/README.codex.md" \
    "$(printf '\nThis public fork %s.\n' "$(forbidden_no_hook_bootstrap_wording)")"
  expect_fixture_fails_with \
    "$tmpdir/no-hook-doc-wording" \
    "$(expected_issue "docs/README.codex.md" "$(forbidden_no_hook_bootstrap_wording)")"

  expect_fixture_passes "$tmpdir/hook-template-required"
  rm "$tmpdir/hook-template-required/hooks/hooks.json"
  expect_fixture_fails_with "$tmpdir/hook-template-required" 'Missing required path: hooks/hooks.json'

  expect_fixture_passes "$tmpdir/package-hook-surface"
  python3 - <<'PY' "$tmpdir/package-hook-surface/package.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["files"] = [item for item in data["files"] if item != "hooks"]
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with \
    "$tmpdir/package-hook-surface" \
    'package.json `files` must include `hooks`'

  expect_fixture_passes "$tmpdir/package-cmux-script"
  python3 - <<'PY' "$tmpdir/package-cmux-script/package.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["scripts"].pop("validate:cmux-superpowers", None)
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with \
    "$tmpdir/package-cmux-script" \
    'package.json script `validate:cmux-superpowers` must be `bash tests/cmux-superpowers/install.sh && bash tests/cmux-superpowers/doctor.sh && bash tests/cmux-superpowers/team_smoke.sh`'

  expect_fixture_passes "$tmpdir/package-cmux-pack-surface"
  mkdir -p "$tmpdir/package-cmux-pack-surface/tests"
  cat >"$tmpdir/package-cmux-pack-surface/tests/.npmignore" <<'EOF'
cmux-superpowers/team_smoke.sh
EOF
  expect_fixture_fails_with \
    "$tmpdir/package-cmux-pack-surface" \
    '`npm pack --dry-run --json` must include `tests/cmux-superpowers/team_smoke.sh`'

  expect_fixture_passes "$tmpdir/package-hook-installer-pack-surface"
  mkdir -p "$tmpdir/package-hook-installer-pack-surface/scripts"
  cat >"$tmpdir/package-hook-installer-pack-surface/scripts/.npmignore" <<'EOF'
install_codex_hooks.py
EOF
  expect_fixture_fails_with \
    "$tmpdir/package-hook-installer-pack-surface" \
    '`npm pack --dry-run --json` must include `scripts/install_codex_hooks.py`'

  expect_fixture_passes "$tmpdir/package-hooks-json-pack-surface"
  mkdir -p "$tmpdir/package-hooks-json-pack-surface/hooks"
  cat >"$tmpdir/package-hooks-json-pack-surface/hooks/.npmignore" <<'EOF'
hooks.json
EOF
  expect_fixture_fails_with \
    "$tmpdir/package-hooks-json-pack-surface" \
    '`npm pack --dry-run --json` must include `hooks/hooks.json`'

  expect_fixture_passes "$tmpdir/package-session-start-pack-surface"
  mkdir -p "$tmpdir/package-session-start-pack-surface/hooks"
  cat >"$tmpdir/package-session-start-pack-surface/hooks/.npmignore" <<'EOF'
session-start
EOF
  expect_fixture_fails_with \
    "$tmpdir/package-session-start-pack-surface" \
    '`npm pack --dry-run --json` must include `hooks/session-start`'

  expect_fixture_passes "$tmpdir/launcher-script-required"
  rm "$tmpdir/launcher-script-required/scripts/install_cmux_superpowers_launcher.py"
  expect_fixture_fails_with \
    "$tmpdir/launcher-script-required" \
    'Missing required path: scripts/install_cmux_superpowers_launcher.py'

  expect_fixture_passes "$tmpdir/doc-contract"
  cat >"$tmpdir/doc-contract/README.md" <<'EOF'
Install with:
- python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
- python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
- cmux codex install-hooks
- cmux-superpowers doctor
EOF
  expect_fixture_fails_with \
    "$tmpdir/doc-contract" \
    'README.md must mention `cmux codex uninstall-hooks`'

  expect_fixture_hook_installer_writes_codex_hooks "$tmpdir/hook-installer" "$tmpdir/hook-installer-home"
  expect_fixture_hook_installer_preserves_unrelated_sessionstart_hooks \
    "$tmpdir/hook-installer-preserves-sidecar" \
    "$tmpdir/hook-installer-preserves-sidecar-home"
  expect_fixture_hook_installer_replaces_prior_superpowers_clone_path \
    "$tmpdir/hook-installer-migration-current" \
    "$tmpdir/hook-installer-migration-prior" \
    "$tmpdir/hook-installer-migration-home"
  expect_fixture_hook_installer_replaces_deleted_prior_superpowers_clone_path \
    "$tmpdir/hook-installer-deleted-migration-current" \
    "$tmpdir/deleted-prior/superpowers" \
    "$tmpdir/hook-installer-deleted-migration-home"
  expect_fixture_hook_installer_replaces_deleted_prior_superpowers_clone_path \
    "$tmpdir/hook-installer-deleted-migration-current-codex" \
    "$tmpdir/deleted-prior-codex/superpowers-codex" \
    "$tmpdir/hook-installer-deleted-migration-home-codex"
  expect_fixture_hook_remover_removes_deleted_prior_superpowers_clone_path \
    "$tmpdir/hook-installer-deleted-remove-current" \
    "$tmpdir/deleted-remove/superpowers" \
    "$tmpdir/hook-installer-deleted-remove-home"
  expect_fixture_hook_remover_removes_deleted_prior_superpowers_clone_path \
    "$tmpdir/hook-installer-deleted-remove-current-codex" \
    "$tmpdir/deleted-remove-codex/superpowers-codex" \
    "$tmpdir/hook-installer-deleted-remove-home-codex"
  expect_fixture_hook_installer_preserves_deleted_unrelated_missing_sessionstart_sidecar \
    "$tmpdir/hook-installer-preserves-deleted-sidecar" \
    "$tmpdir/superpowers-sidecar" \
    "$tmpdir/hook-installer-preserves-deleted-sidecar-home"

  expect_fixture_passes "$tmpdir/published-validator-scan"
  append_text \
    "$tmpdir/published-validator-scan/scripts/validate_codex_public_fork.py" \
    "$(printf "\nPUBLISHED_MARKER = '%s'\n" "$(forbidden_gemini_cli)")"
  expect_fixture_fails_with \
    "$tmpdir/published-validator-scan" \
    "$(expected_issue "scripts/validate_codex_public_fork.py" "$(forbidden_gemini_cli)")"

  expect_fixture_passes "$tmpdir/published-harness-scan"
  append_text \
    "$tmpdir/published-harness-scan/tests/codex-public-fork/run.sh" \
    "$(printf '\n# %s\n' "$(forbidden_gemini_cli)")"
  expect_fixture_fails_with \
    "$tmpdir/published-harness-scan" \
    "$(expected_issue "tests/codex-public-fork/run.sh" "$(forbidden_gemini_cli)")"

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
  expect_fixture_fails_with "$tmpdir/package-contract" 'package.json field `version` must be `5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/package-bugs-url"
  python3 - <<'PY' "$tmpdir/package-bugs-url/package.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["bugs"]["url"] = "https://github.com/MaxFabian25/superpowers"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with \
    "$tmpdir/package-bugs-url" \
    'package.json field `bugs.url` must be `https://github.com/MaxFabian25/superpowers/issues`'

  expect_fixture_passes "$tmpdir/package-conduct-file"
  python3 - <<'PY' "$tmpdir/package-conduct-file/package.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["files"] = [item for item in data["files"] if item != "CODE_OF_CONDUCT.md"]
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with \
    "$tmpdir/package-conduct-file" \
    'package.json `files` must include `CODE_OF_CONDUCT.md`'

  expect_fixture_passes "$tmpdir/plugin-version-contract"
  python3 - <<'PY' "$tmpdir/plugin-version-contract/.codex-plugin/plugin.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["version"] = "0.0.1"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  expect_fixture_fails_with \
    "$tmpdir/plugin-version-contract" \
    '.codex-plugin/plugin.json field `version` must be `5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/changelog-version-contract"
  cat >"$tmpdir/changelog-version-contract/CHANGELOG.md" <<'EOF'
## 5.0.6
EOF
  expect_fixture_fails_with \
    "$tmpdir/changelog-version-contract" \
    'CHANGELOG.md must contain version heading `## 5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/changelog-version-near-match"
  cat >"$tmpdir/changelog-version-near-match/CHANGELOG.md" <<'EOF'
## 5.0.6-codex.10
EOF
  expect_fixture_fails_with \
    "$tmpdir/changelog-version-near-match" \
    'CHANGELOG.md must contain version heading `## 5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/changelog-version-with-date"
  cat >"$tmpdir/changelog-version-with-date/CHANGELOG.md" <<'EOF'
## 5.0.6-codex.1 - 2026-04-08
EOF
  expect_fixture_passes "$tmpdir/changelog-version-with-date"

  expect_fixture_passes "$tmpdir/release-notes-version-contract"
  cat >"$tmpdir/release-notes-version-contract/RELEASE-NOTES.md" <<'EOF'
## 5.0.6
EOF
  expect_fixture_fails_with \
    "$tmpdir/release-notes-version-contract" \
    'RELEASE-NOTES.md must contain version heading `## 5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/release-notes-version-near-match"
  cat >"$tmpdir/release-notes-version-near-match/RELEASE-NOTES.md" <<'EOF'
## 5.0.6-codex.1-rc1
EOF
  expect_fixture_fails_with \
    "$tmpdir/release-notes-version-near-match" \
    'RELEASE-NOTES.md must contain version heading `## 5.0.6-codex.1`'

  expect_fixture_passes "$tmpdir/public-conduct-route"
  cat >"$tmpdir/public-conduct-route/CODE_OF_CONDUCT.md" <<'EOF'
Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported through
https://github.com/MaxFabian25/superpowers/issues/new/choose.
EOF
  expect_fixture_fails_with \
    "$tmpdir/public-conduct-route" \
    'CODE_OF_CONDUCT.md must use a private reporting channel'

  expect_fixture_passes "$tmpdir/platform-support-removed"
  cat >"$tmpdir/platform-support-removed/.github/ISSUE_TEMPLATE/platform_support.md" <<'EOF'
Legacy multi-platform support form.
EOF
  expect_fixture_fails_with \
    "$tmpdir/platform-support-removed" \
    'Removed path still exists: .github/ISSUE_TEMPLATE/platform_support.md'

  expect_fixture_passes "$tmpdir/bug-report-codex-version"
  cat >"$tmpdir/bug-report-codex-version/.github/ISSUE_TEMPLATE/bug_report.md" <<'EOF'
| Superpowers version | |
| Model | |
EOF
  expect_fixture_fails_with \
    "$tmpdir/bug-report-codex-version" \
    '.github/ISSUE_TEMPLATE/bug_report.md must ask for Codex version'

  expect_fixture_passes "$tmpdir/bug-report-harness"
  printf '| Harness (%s, Cursor, etc.) | |\n| Codex version | |\n' "$(forbidden_claude_code)" \
    >"$tmpdir/bug-report-harness/.github/ISSUE_TEMPLATE/bug_report.md"
  expect_fixture_fails_with \
    "$tmpdir/bug-report-harness" \
    '.github/ISSUE_TEMPLATE/bug_report.md must not ask for generic harness information'

  expect_fixture_passes "$tmpdir/feature-request-harness"
  cat >"$tmpdir/feature-request-harness/.github/ISSUE_TEMPLATE/feature_request.md" <<'EOF'
## Context
Optional: version info, harness, model, workflow where you hit this.
EOF
  expect_fixture_fails_with \
    "$tmpdir/feature-request-harness" \
    '.github/ISSUE_TEMPLATE/feature_request.md must not use generic harness wording'

  expect_fixture_passes "$tmpdir/pr-template-harness"
  printf '| Harness (%s, Cursor) | Harness version | Model | Model version/ID |\n|-------------------------------|-----------------|-------|------------------|\n|                               |                 |       |                  |\n' "$(forbidden_claude_code)" \
    >"$tmpdir/pr-template-harness/.github/PULL_REQUEST_TEMPLATE.md"
  expect_fixture_fails_with \
    "$tmpdir/pr-template-harness" \
    '.github/PULL_REQUEST_TEMPLATE.md must use Codex-only environment wording'

  expect_fixture_passes "$tmpdir/broken-symlink"
  ln -s missing-target "$tmpdir/broken-symlink/.claude-plugin"
  expect_fixture_fails_with "$tmpdir/broken-symlink" "Removed path still exists: .claude-plugin"

  expect_process_family_fixture_uses_copied_validator "$tmpdir/process-family-fixture-validator-artifact"
  expect_process_family_fixture_copies_targeted_only_paths "$tmpdir/process-family-targeted-path-copy"

  expect_process_family_fixture_passes "$tmpdir/process-family-child-elicitation"
  append_text \
    "$tmpdir/process-family-child-elicitation/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nAsk the user directly before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-elicitation" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Ask the user directly before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-clarification"
  append_text \
    "$tmpdir/process-family-child-clarification/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nAsk the user for clarification before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-clarification" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Ask the user for clarification before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-no-article-ask"
  append_text \
    "$tmpdir/process-family-child-no-article-ask/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nAsk user directly before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-no-article-ask" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Ask user directly before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-request-user-input"
  append_text \
    "$tmpdir/process-family-child-request-user-input/skills/requesting-code-review/code-reviewer.md" \
    $'\nCall `request_user_input` if you need clarification.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-request-user-input" \
    'skills/requesting-code-review/code-reviewer.md contains forbidden child elicitation text `Call `request_user_input` if you need clarification.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-get-clarification"
  append_text \
    "$tmpdir/process-family-child-get-clarification/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nGet clarification from the user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-get-clarification" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Get clarification from the user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-prompt-operator"
  append_text \
    "$tmpdir/process-family-child-prompt-operator/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nPrompt the operator for clarification before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-prompt-operator" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Prompt the operator for clarification before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-check-human"
  append_text \
    "$tmpdir/process-family-child-check-human/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nCheck with the human before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-check-human" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Check with the human before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-confirm-user"
  append_text \
    "$tmpdir/process-family-child-confirm-user/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nConfirm with the user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-confirm-user" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Confirm with the user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-confirm-no-article-user"
  append_text \
    "$tmpdir/process-family-child-confirm-no-article-user/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nConfirm with user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-confirm-no-article-user" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Confirm with user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-consult-user"
  append_text \
    "$tmpdir/process-family-child-consult-user/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nConsult the user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-consult-user" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Consult the user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-confirm-directly-user"
  append_text \
    "$tmpdir/process-family-child-confirm-directly-user/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nConfirm directly with the user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-confirm-directly-user" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Confirm directly with the user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-child-brief-question-user"
  append_text \
    "$tmpdir/process-family-child-brief-question-user/skills/subagent-driven-development/implementer-prompt.md" \
    $'\nAsk one brief clarifying question to the user before continuing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-child-brief-question-user" \
    'skills/subagent-driven-development/implementer-prompt.md contains forbidden child elicitation text `Ask one brief clarifying question to the user before continuing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-child-agent-direct-elicitation"
  append_text \
    "$tmpdir/process-family-contract-child-agent-direct-elicitation/contract/process-family.md" \
    $'\n- Child agents may ask the user directly if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-child-agent-direct-elicitation" \
    'contract/process-family.md contains forbidden root-owned elicitation text `- Child agents may ask the user directly if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-unprefixed-direct-elicitation"
  append_text \
    "$tmpdir/process-family-contract-unprefixed-direct-elicitation/contract/process-family.md" \
    $'\n- Ask the user directly if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-unprefixed-direct-elicitation" \
    'contract/process-family.md contains forbidden root-owned elicitation text `- Ask the user directly if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-child-packet-request-user-input"
  append_text \
    "$tmpdir/process-family-contract-child-packet-request-user-input/contract/prompt-packet.md" \
    $'\n- Child packets may call `request_user_input` directly if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-child-packet-request-user-input" \
    'contract/prompt-packet.md contains forbidden root-owned elicitation text `- Child packets may call `request_user_input` directly if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-cross-subject-direct-elicitation"
  append_text \
    "$tmpdir/process-family-contract-cross-subject-direct-elicitation/contract/prompt-packet.md" \
    $'\n- Child agents may ask the user directly if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-cross-subject-direct-elicitation" \
    'contract/prompt-packet.md contains forbidden root-owned elicitation text `- Child agents may ask the user directly if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-consult-user"
  append_text \
    "$tmpdir/process-family-contract-consult-user/contract/process-family.md" \
    $'\n- Child agents may consult the user if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-consult-user" \
    'contract/process-family.md contains forbidden root-owned elicitation text `- Child agents may consult the user if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-confirm-directly-user"
  append_text \
    "$tmpdir/process-family-contract-confirm-directly-user/contract/process-family.md" \
    $'\n- Confirm directly with the user if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-confirm-directly-user" \
    'contract/process-family.md contains forbidden root-owned elicitation text `- Confirm directly with the user if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-brief-question-user"
  append_text \
    "$tmpdir/process-family-contract-brief-question-user/contract/process-family.md" \
    $'\n- Ask one brief clarifying question to the user if blocked.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-brief-question-user" \
    'contract/process-family.md contains forbidden root-owned elicitation text `- Ask one brief clarifying question to the user if blocked.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-contract-when-available-request-user-input"
  append_text \
    "$tmpdir/process-family-contract-when-available-request-user-input/contract/process-family.md" \
    $'\n- When available, use `request_user_input` for discrete branch-point decisions.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-contract-when-available-request-user-input" \
    'contract/process-family.md contains stale request_user_input availability fallback text `- When available, use `request_user_input` for discrete branch-point decisions.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-brainstorming-plain-text-fallback"
  append_text \
    "$tmpdir/process-family-brainstorming-plain-text-fallback/skills/brainstorming/SKILL.md" \
    $'\n- If `request_user_input` is unavailable but the session is interactive, ask one concise plain-text question only when the answer is truly blocking.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-brainstorming-plain-text-fallback" \
    'skills/brainstorming/SKILL.md contains stale request_user_input fallback guidance `- If `request_user_input` is unavailable but the session is interactive, ask one concise plain-text question only when the answer is truly blocking.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-codex-tools-default-mode-request-user-input"
  append_text \
    "$tmpdir/process-family-codex-tools-default-mode-request-user-input/skills/using-superpowers/references/codex-tools.md" \
    $'\n- `request_user_input` is root-thread only, and Default-mode availability depends on `default_mode_request_user_input`.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-codex-tools-default-mode-request-user-input" \
    'skills/using-superpowers/references/codex-tools.md contains stale request_user_input availability guidance ``request_user_input` is root-thread only, and Default-mode availability depends on `default_mode_request_user_input`.``'

  expect_process_family_fixture_passes "$tmpdir/process-family-using-git-worktrees-plain-text-menu"
  append_text \
    "$tmpdir/process-family-using-git-worktrees-plain-text-menu/skills/using-git-worktrees/SKILL.md" \
    $'\nWhich would you prefer?\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-using-git-worktrees-plain-text-menu" \
    'skills/using-git-worktrees/SKILL.md contains stale plain-text directory-choice menu text `Which would you prefer?`'

  expect_process_family_fixture_passes "$tmpdir/process-family-writing-plans-plain-text-menu"
  append_text \
    "$tmpdir/process-family-writing-plans-plain-text-menu/skills/writing-plans/SKILL.md" \
    $'\nWhich approach?\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-writing-plans-plain-text-menu" \
    'skills/writing-plans/SKILL.md contains stale plain-text execution-choice menu text `Which approach?`'

  expect_process_family_fixture_passes "$tmpdir/process-family-finishing-branch-plain-text-menu"
  append_text \
    "$tmpdir/process-family-finishing-branch-plain-text-menu/skills/finishing-a-development-branch/SKILL.md" \
    $'\nPresent exactly these 4 options:\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-finishing-branch-plain-text-menu" \
    'skills/finishing-a-development-branch/SKILL.md contains stale plain-text closeout-menu guidance `Present exactly these 4 options:`'

  expect_process_family_fixture_passes "$tmpdir/process-family-subagent-driven-example-workflow"
  append_text \
    "$tmpdir/process-family-subagent-driven-example-workflow/skills/subagent-driven-development/SKILL.md" \
    $'\n## Example Workflow\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-subagent-driven-example-workflow" \
    'skills/subagent-driven-development/SKILL.md contains stale tutorial section heading `## Example Workflow`'

  expect_process_family_fixture_passes "$tmpdir/process-family-dispatching-real-example"
  append_text \
    "$tmpdir/process-family-dispatching-real-example/skills/dispatching-parallel-agents/SKILL.md" \
    $'\n## Real Example from Session\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-dispatching-real-example" \
    'skills/dispatching-parallel-agents/SKILL.md contains stale tutorial section heading `## Real Example from Session`'

  expect_process_family_fixture_passes "$tmpdir/process-family-dispatching-key-benefits"
  append_text \
    "$tmpdir/process-family-dispatching-key-benefits/skills/dispatching-parallel-agents/SKILL.md" \
    $'\n## Key Benefits\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-dispatching-key-benefits" \
    'skills/dispatching-parallel-agents/SKILL.md contains stale tutorial section heading `## Key Benefits`'

  expect_process_family_fixture_passes "$tmpdir/process-family-executing-plans-plain-clarification"
  append_text \
    "$tmpdir/process-family-executing-plans-plain-clarification/skills/executing-plans/SKILL.md" \
    $'\nAsk for clarification rather than guessing.\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-executing-plans-plain-clarification" \
    'skills/executing-plans/SKILL.md contains stale plain-text clarification guidance `Ask for clarification rather than guessing.`'

  expect_process_family_fixture_passes "$tmpdir/process-family-systematic-debugging-iron-law"
  append_text \
    "$tmpdir/process-family-systematic-debugging-iron-law/skills/systematic-debugging/SKILL.md" \
    $'\n## The Iron Law\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-systematic-debugging-iron-law" \
    'skills/systematic-debugging/SKILL.md contains stale tutorial section heading `## The Iron Law`'

  expect_process_family_fixture_passes "$tmpdir/process-family-systematic-debugging-rationalizations"
  append_text \
    "$tmpdir/process-family-systematic-debugging-rationalizations/skills/systematic-debugging/SKILL.md" \
    $'\n## Common Rationalizations\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-systematic-debugging-rationalizations" \
    'skills/systematic-debugging/SKILL.md contains stale tutorial section heading `## Common Rationalizations`'

  expect_process_family_fixture_passes "$tmpdir/process-family-systematic-debugging-human-partner"
  append_text \
    "$tmpdir/process-family-systematic-debugging-human-partner/skills/systematic-debugging/SKILL.md" \
    $'\n## your human partner'\''s Signals You'\''re Doing It Wrong\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-systematic-debugging-human-partner" \
    "skills/systematic-debugging/SKILL.md contains stale user-specific section heading \`## your human partner's Signals You're Doing It Wrong\`"

  expect_process_family_fixture_passes "$tmpdir/process-family-systematic-debugging-real-world-impact"
  append_text \
    "$tmpdir/process-family-systematic-debugging-real-world-impact/skills/systematic-debugging/SKILL.md" \
    $'\n## Real-World Impact\n'
  expect_process_family_fixture_fails_with \
    "$tmpdir/process-family-systematic-debugging-real-world-impact" \
    'skills/systematic-debugging/SKILL.md contains stale tutorial section heading `## Real-World Impact`'

  echo "PASS: codex public fork self-tests"
}

run_repo_contract_checks() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  require_path "hooks/hooks.json"
  require_path "hooks/session-start"
  require_path "scripts/install_codex_hooks.py"

  python3 scripts/install_codex_hooks.py --codex-home "$tmpdir/codex-home" >/dev/null
  test -f "$tmpdir/codex-home/hooks.json"

  python3 scripts/install_codex_hooks.py --codex-home "$tmpdir/codex-home" --remove >/dev/null

  require_pattern 'install_cmux_superpowers_launcher\.py' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'install_cmux_superpowers_launcher\.py --remove' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'install_codex_hooks\.py' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'install_codex_hooks\.py --remove' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'cmux codex install-hooks' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'cmux codex uninstall-hooks' README.md docs/README.codex.md .codex/INSTALL.md
  require_pattern 'cmux-superpowers doctor' README.md docs/README.codex.md .codex/INSTALL.md
  require_fixed "codex features list | rg '^codex_hooks[[:space:]]+under development[[:space:]]+true$'" README.md docs/README.codex.md .codex/INSTALL.md
  require_fixed 'the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`' README.md docs/README.codex.md .codex/INSTALL.md
  reject_pattern 'does not depend on (Codex )?hook bootstrap' README.md docs/README.codex.md .codex/INSTALL.md
  reject_fixed 'codex --enable codex_hooks' README.md docs/README.codex.md .codex/INSTALL.md
}

if [[ "${1:-}" == "self-test" ]]; then
  run_self_tests
  exit 0
fi

cd "$ROOT"

run_self_tests
run_repo_contract_checks

python3 scripts/validate_codex_public_fork.py
python3 _shared/validators/validate_skill_library.py --root "$ROOT" --family process

if [[ "${CODEX_PUBLIC_FORK_REQUIRE_RUNTIME_SMOKE:-0}" == "1" ]]; then
  codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
fi

echo "PASS: codex public fork validation bundle"
