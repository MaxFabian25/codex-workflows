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

prepare_process_family_fixture() {
  local fixture_root="$1"

  if [[ -e "$fixture_root/_shared/validators/process_family_targets.txt" ]]; then
    return 0
  fi

  python3 - <<'PY' "$ROOT" "$fixture_root"
from pathlib import Path
import shutil
import sys

src_root = Path(sys.argv[1])
dst_root = Path(sys.argv[2])
manifest_rel = Path("_shared/validators/process_family_targets.txt")
validator_rel = Path("_shared/validators/validate_skill_library.py")
manifest_path = src_root / manifest_rel
targets = [line.strip() for line in manifest_path.read_text(encoding="utf-8").splitlines() if line.strip()]

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
    $'\nThis package does not depend on hook bootstrap.\n'
  expect_fixture_passes "$tmpdir/no-hook-doc-wording"

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

if [[ "${CODEX_PUBLIC_FORK_REQUIRE_RUNTIME_SMOKE:-0}" == "1" ]]; then
  codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
fi

echo "PASS: codex public fork validation bundle"
