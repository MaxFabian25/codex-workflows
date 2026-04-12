#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$TEST_DIR/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

python_bin="$(resolve_python_path python3)"

begin_scenario() {
  local name="$1"
  scenario="$(setup_doctor_scenario "$tmp" "$name")"
  bin_dir="$scenario/bin"
  codex_home="$scenario/codex-home"
  output="$scenario/$name.json"
}

run_current_doctor() {
  run_doctor_json "$python_bin" "$output" "PATH=$bin_dir:$PATH" "CODEX_HOME=$codex_home" "$@"
}

assert_status() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  test "$actual" -eq "$expected" || fail "expected $label doctor status $expected, got $actual"
}

assert_full_healthy_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is True
assert payload["codex"]["ok"] is True
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is True
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is True
assert payload["ok"] is True
PY
}

assert_missing_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is True
assert payload["codex"]["ok"] is True
assert payload["hooks"]["superpowers_sessionstart"] is False
assert payload["hooks"]["cmux_codex"] is False
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is True
assert payload["ok"] is False
PY
}

assert_missing_path_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["path"] is None
assert payload["codex"]["path"] is None
assert payload["cmux"]["ok"] is False
assert payload["codex"]["ok"] is False
assert "not found on PATH" in payload["errors"]["cmux"]
assert "not found on PATH" in payload["errors"]["codex"]
assert payload["ok"] is False
PY
}

assert_superpowers_missing_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["hooks"]["superpowers_sessionstart"] is False
assert payload["hooks"]["cmux_codex"] is True
assert payload["ok"] is False
PY
}

assert_cmux_missing_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is False
assert payload["ok"] is False
PY
}

assert_false_green_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is True
assert payload["codex_hooks_enabled"] is False
assert payload["ok"] is False
PY
}

assert_config_authoritative_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is True
assert payload["codex"]["ok"] is True
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is True
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is True
assert "codex" not in payload["errors"]
assert payload["ok"] is True
PY
}

assert_launcher_missing_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is True
assert payload["codex"]["ok"] is True
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is True
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is False
assert payload["ok"] is False
PY
}

assert_invalid_override_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["codex"]["ok"] is False
assert payload["codex_hooks_enabled"] is False
assert "override" in payload["errors"]["codex"]
assert payload["ok"] is False
PY
}

assert_unusable_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is False
assert payload["codex"]["ok"] is False
assert "exit 9" in payload["errors"]["cmux"]
assert "exit 8" in payload["errors"]["codex"]
assert "cmux broken" in payload["errors"]["cmux"]
assert "codex broken" in payload["errors"]["codex"]
assert payload["ok"] is False
PY
}

assert_commented_config_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["codex"]["ok"] is True
assert payload["codex_hooks_enabled"] is False
assert payload["ok"] is False
PY
}

assert_hook_error_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["ok"] is False
assert payload["errors"]["hooks"]
PY
}

assert_hook_error_and_no_detected_hooks_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["ok"] is False
assert payload["hooks"]["superpowers_sessionstart"] is False
assert payload["hooks"]["cmux_codex"] is False
assert payload["errors"]["hooks"]
PY
}

assert_config_error_payload() {
  python3 - <<'PY' "$1"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["codex"]["ok"] is True
assert payload["codex_hooks_enabled"] is False
assert payload["errors"]["config"]
assert payload["ok"] is False
PY
}

assert_timeout_payload() {
  python3 - <<'PY' "$1" "$2" "$3"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
elapsed = float(sys.argv[3]) - float(sys.argv[2])
assert elapsed < 4.0, elapsed
assert payload["cmux"]["ok"] is False
assert payload["codex"]["ok"] is False
assert "timeout" in payload["errors"]["cmux"]
assert "timeout" in payload["errors"]["codex"]
assert payload["ok"] is False
PY
}

scenario_missing() {
  begin_scenario "missing"
  local status
  status="$(run_current_doctor)"
  assert_missing_payload "$output"
  assert_status "$status" 1 "missing"
}

scenario_healthy() {
  begin_scenario "healthy"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "healthy"
}

scenario_slow_fallback_feature_probe() {
  begin_scenario "slow-fallback-feature-probe"
  write_healthy_hooks_fixture "$codex_home"
  assert_not_exists "$codex_home/config.toml"
  write_near_threshold_codex "$bin_dir"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "slow-fallback-feature-probe"
}

scenario_config_authoritative() {
  begin_scenario "config-authoritative"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  write_config_authoritative_codex "$bin_dir"
  local status
  status="$(run_current_doctor)"
  assert_config_authoritative_payload "$output"
  assert_status "$status" 0 "config-authoritative"
}

scenario_missing_path() {
  local missing_path_home="$tmp/missing-path-home"
  write_healthy_hooks_fixture "$missing_path_home"
  write_enabled_config "$missing_path_home"

  local launcher_only_bin="$tmp/launcher-only-bin"
  mkdir -p "$launcher_only_bin"
  python3 "$INSTALLER" --bin-dir "$launcher_only_bin" >/dev/null

  local missing_path_output="$tmp/missing-path.json"
  local status
  status="$(run_doctor_json "$python_bin" "$missing_path_output" "PATH=$launcher_only_bin" "CODEX_HOME=$missing_path_home")"
  assert_missing_path_payload "$missing_path_output"
  assert_status "$status" 1 "missing-path"
}

scenario_launcher_missing_on_path() {
  begin_scenario "launcher-missing-on-path"
  rm -f "$bin_dir/cmux-superpowers"
  assert_not_exists "$bin_dir/cmux-superpowers"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_launcher_missing_payload "$output"
  assert_status "$status" 1 "launcher-missing-on-path"
}

scenario_neutral_command() {
  begin_scenario "neutral-command"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture "$codex_home" "$session_start_target"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "neutral-command"
}

scenario_interpreter_command() {
  begin_scenario "interpreter-command"
  write_healthy_hooks_fixture "$codex_home" "$python_bin /tmp/superpowers/hooks/session-start"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "interpreter-command"
}

scenario_sidecar_session_start() {
  begin_scenario "sidecar-session-start"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  python3 - <<'PY' "$codex_home/hooks.json"
import json
import sys
from pathlib import Path

hooks_path = Path(sys.argv[1])
payload = json.loads(hooks_path.read_text(encoding="utf-8"))
payload["hooks"]["SessionStart"].append(
    {
        "matcher": "startup|resume|clear",
        "hooks": [
            {
                "type": "command",
                "command": "echo sidecar",
            }
        ],
    }
)
hooks_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "sidecar-session-start"
}

scenario_unrelated_hooks_sidecar() {
  begin_scenario "unrelated-hooks-sidecar"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  python3 - <<'PY' "$codex_home/hooks.json"
import json
import sys
from pathlib import Path

hooks_path = Path(sys.argv[1])
payload = json.loads(hooks_path.read_text(encoding="utf-8"))
payload["hooks"]["SessionStart"].append(
    {
        "matcher": "startup|resume|clear",
        "hooks": [
            {
                "type": "command",
                "command": "/tmp/another-plugin/hooks/session-start",
            }
        ],
    }
)
hooks_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "unrelated-hooks-sidecar"
}

scenario_python_c_mode() {
  begin_scenario "python-c-mode"
  write_healthy_hooks_fixture "$codex_home" "$python_bin -c 'print(123)' /tmp/superpowers/hooks/session-start"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "python-c-mode"
}

scenario_python_module_mode() {
  begin_scenario "python-module-mode"
  write_healthy_hooks_fixture "$codex_home" "$python_bin -m pkg /tmp/superpowers/hooks/session-start"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "python-module-mode"
}

scenario_non_executed_session_start() {
  begin_scenario "non-executed-session-start"
  write_healthy_hooks_fixture "$codex_home" "test -x /tmp/not-executed/session-start"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "non-executed-session-start"
}

scenario_wrong_target_interpreter() {
  begin_scenario "wrong-target-interpreter"
  write_healthy_hooks_fixture "$codex_home" "python /tmp/not-superpowers/session-start"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "wrong-target-interpreter"
}

scenario_guarded_cmux() {
  begin_scenario "guarded-cmux"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture \
    "$codex_home" \
    "$session_start_target" \
    "startup|resume|clear" \
    "command" \
    "loading superpowers" \
    "[ -n \"\$CMUX_SURFACE_ID\" ] && command -v cmux >/dev/null 2>&1 && cmux codex-hook session-start || echo '{}'" \
    "[ -n \"\$CMUX_SURFACE_ID\" ] && command -v cmux >/dev/null 2>&1 && cmux codex-hook prompt-submit || echo '{}'" \
    "[ -n \"\$CMUX_SURFACE_ID\" ] && command -v cmux >/dev/null 2>&1 && cmux codex-hook stop || echo '{}'"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "guarded-cmux"
}

scenario_if_then_cmux() {
  begin_scenario "if-then-cmux"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture \
    "$codex_home" \
    "$session_start_target" \
    "startup|resume|clear" \
    "command" \
    "loading superpowers" \
    "if [ -n \"\$CMUX_SURFACE_ID\" ]; then cmux codex-hook session-start; else echo {}; fi" \
    "if [ -n \"\$CMUX_SURFACE_ID\" ]; then cmux codex-hook prompt-submit; else echo {}; fi" \
    "if [ -n \"\$CMUX_SURFACE_ID\" ]; then cmux codex-hook stop; else echo {}; fi"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "if-then-cmux"
}

scenario_command_prefixed_cmux() {
  begin_scenario "command-prefixed-cmux"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture \
    "$codex_home" \
    "$session_start_target" \
    "startup|resume|clear" \
    "command" \
    "loading superpowers" \
    "command cmux codex-hook session-start" \
    "command cmux codex-hook prompt-submit" \
    "command cmux codex-hook stop"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "command-prefixed-cmux"
}

scenario_wrong_matcher() {
  begin_scenario "wrong-matcher"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture "$codex_home" "$session_start_target" "startup|resume"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "wrong-matcher"
}

scenario_wrong_type() {
  begin_scenario "wrong-type"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture "$codex_home" "$session_start_target" "startup|resume|clear" "log"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "wrong-type"
}

scenario_inert_cmux() {
  begin_scenario "inert-cmux"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture \
    "$codex_home" \
    "$session_start_target" \
    "startup|resume|clear" \
    "command" \
    "loading superpowers" \
    "cmux codex-hook session-start" \
    "cmux codex-hook prompt-submit" \
    "echo cmux codex-hook stop"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_cmux_missing_payload "$output"
  assert_status "$status" 1 "inert-cmux"
}

scenario_placeholder() {
  begin_scenario "placeholder"
  write_healthy_hooks_fixture "$codex_home" "__SUPERPOWERS_SESSION_START_COMMAND__"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "placeholder"
}

scenario_deleted_session_start_target() {
  begin_scenario "deleted-session-start-target"
  local session_start_target="$scenario/plugin/hooks/session-start"
  write_healthy_hooks_fixture "$codex_home" "$session_start_target"
  write_enabled_config "$codex_home"
  rm -f "$session_start_target"
  assert_not_exists "$session_start_target"
  local status
  status="$(run_current_doctor)"
  assert_superpowers_missing_payload "$output"
  assert_status "$status" 1 "deleted-session-start-target"
}

scenario_false_green() {
  begin_scenario "false-green"
  write_healthy_hooks_fixture "$codex_home"
  write_false_feature_codex "$bin_dir"
  local status
  status="$(run_current_doctor)"
  assert_false_green_payload "$output"
  assert_status "$status" 1 "false-green"
}

scenario_invalid_override() {
  begin_scenario "invalid-override"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  local invalid_override_bin="$scenario/not-a-binary"
  mkdir -p "$invalid_override_bin"
  local status
  status="$(run_current_doctor "CMUX_SUPERPOWERS_CODEX_BIN=$invalid_override_bin")"
  assert_invalid_override_payload "$output"
  assert_status "$status" 1 "invalid-override"
}

scenario_unusable() {
  begin_scenario "unusable"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"

  local bad_cmux="$scenario/bad-cmux"
  write_executable "$bad_cmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "version" ]]; then
  echo "cmux broken" >&2
  exit 9
fi
echo "{}"
exit 9
EOF

  local bad_codex="$scenario/bad-codex"
  write_executable "$bad_codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "features" && "${2:-}" == "list" ]]; then
  echo "codex broken" >&2
  exit 8
fi
echo "codex broken" >&2
exit 8
EOF

  local status
  status="$(run_current_doctor "CMUX_SUPERPOWERS_CMUX_BIN=$bad_cmux" "CMUX_SUPERPOWERS_CODEX_BIN=$bad_codex")"
  assert_unusable_payload "$output"
  assert_status "$status" 1 "unusable"
}

scenario_commented_config() {
  begin_scenario "commented-config"
  write_healthy_hooks_fixture "$codex_home"
  write_config_toml "$codex_home" <<'EOF'
[features]
# codex_hooks = true
EOF
  write_false_feature_codex "$bin_dir"
  local status
  status="$(run_current_doctor)"
  assert_commented_config_payload "$output"
  assert_status "$status" 1 "commented-config"
}

scenario_invalid_hooks_shape() {
  begin_scenario "invalid-hooks-shape"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": {}
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_and_no_detected_hooks_payload "$output"
  assert_status "$status" 1 "invalid-hooks-shape"
}

scenario_null_hooks() {
  begin_scenario "null-hooks"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": null
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "null-hooks"
}

scenario_null_group_hooks() {
  begin_scenario "null-group-hooks"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": null
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "null-group-hooks"
}

scenario_missing_group_hooks() {
  begin_scenario "missing-group-hooks"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear"
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "missing-group-hooks"
}

scenario_non_string_matcher() {
  begin_scenario "non-string-matcher"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": [],
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "non-string-matcher"
}

scenario_missing_superpowers_command() {
  begin_scenario "missing-superpowers-command"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "missing-superpowers-command"
}

scenario_missing_cmux_command() {
  begin_scenario "missing-cmux-command"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/hooks/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux codex-hook prompt-submit",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux codex-hook stop",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "missing-cmux-command"
}

scenario_non_string_command() {
  begin_scenario "non-string-command"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": 123,
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "non-string-command"
}

scenario_missing_type() {
  begin_scenario "missing-type"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "command": "/tmp/superpowers/hooks/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "missing-type"
}

scenario_non_string_status_message() {
  begin_scenario "non-string-status-message"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/session-start",
            "statusMessage": 123
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "non-string-status-message"
}

scenario_missing_status_message() {
  begin_scenario "missing-status-message"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/hooks/session-start"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "missing-status-message"
}

scenario_non_string_type() {
  begin_scenario "non-string-type"
  write_hooks_json "$codex_home" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": 123,
            "command": "/tmp/superpowers/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      }
    ]
  }
}
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_payload "$output"
  assert_status "$status" 1 "non-string-type"
}

scenario_malformed_hooks() {
  begin_scenario "malformed-hooks"
  write_hooks_json "$codex_home" <<'EOF'
{"hooks":
EOF
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_hook_error_and_no_detected_hooks_payload "$output"
  assert_status "$status" 1 "malformed-hooks"
}

scenario_invalid_config() {
  begin_scenario "invalid-config"
  write_healthy_hooks_fixture "$codex_home"
  write_config_toml "$codex_home" <<'EOF'
[features]
codex_hooks = "false"
EOF
  local status
  status="$(run_current_doctor)"
  assert_config_error_payload "$output"
  assert_status "$status" 1 "invalid-config"
}

scenario_invalid_features_shape() {
  begin_scenario "invalid-features-shape"
  write_healthy_hooks_fixture "$codex_home"
  write_config_toml "$codex_home" <<'EOF'
features = 1
EOF
  local status
  status="$(run_current_doctor)"
  assert_config_error_payload "$output"
  assert_status "$status" 1 "invalid-features-shape"
}

scenario_hanging() {
  begin_scenario "hanging"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  write_hanging_cmux "$bin_dir"
  write_hanging_codex "$bin_dir"

  local hanging_start
  hanging_start="$(python3 - <<'PY'
import time
print(time.monotonic())
PY
)"

  local status
  status="$(run_current_doctor)"

  local hanging_end
  hanging_end="$(python3 - <<'PY'
import time
print(time.monotonic())
PY
)"

  assert_timeout_payload "$output" "$hanging_start" "$hanging_end"
  assert_status "$status" 1 "hanging"
}

scenario_late_healthy() {
  begin_scenario "late-healthy"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"
  local status
  status="$(run_current_doctor)"
  assert_full_healthy_payload "$output"
  assert_status "$status" 0 "late-healthy"
}

run_baseline_scenarios() {
  scenario_missing
  scenario_healthy
  scenario_slow_fallback_feature_probe
  scenario_config_authoritative
  scenario_missing_path
  scenario_launcher_missing_on_path
}

run_hook_detection_scenarios() {
  scenario_neutral_command
  scenario_interpreter_command
  scenario_sidecar_session_start
  scenario_unrelated_hooks_sidecar
  scenario_python_c_mode
  scenario_python_module_mode
  scenario_non_executed_session_start
  scenario_wrong_target_interpreter
  scenario_guarded_cmux
  scenario_if_then_cmux
  scenario_command_prefixed_cmux
  scenario_wrong_matcher
  scenario_wrong_type
  scenario_inert_cmux
  scenario_placeholder
  scenario_deleted_session_start_target
}

run_probe_behavior_scenarios() {
  scenario_false_green
  scenario_invalid_override
  scenario_unusable
  scenario_commented_config
}

run_hook_validation_scenarios() {
  scenario_invalid_hooks_shape
  scenario_null_hooks
  scenario_null_group_hooks
  scenario_missing_group_hooks
  scenario_non_string_matcher
  scenario_missing_superpowers_command
  scenario_missing_cmux_command
  scenario_non_string_command
  scenario_missing_type
  scenario_non_string_status_message
  scenario_missing_status_message
  scenario_non_string_type
  scenario_malformed_hooks
}

run_config_validation_scenarios() {
  scenario_invalid_config
  scenario_invalid_features_shape
}

run_timeout_scenarios() {
  scenario_hanging
  scenario_late_healthy
}

main() {
  run_baseline_scenarios
  run_hook_detection_scenarios
  run_probe_behavior_scenarios
  run_hook_validation_scenarios
  run_config_validation_scenarios
  run_timeout_scenarios
}

main "$@"
