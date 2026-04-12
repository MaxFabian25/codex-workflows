#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$TEST_DIR/../.." && pwd -P)"
TEAM="$ROOT/scripts/cmux_superpowers_team.py"
INSTALLER="$ROOT/scripts/install_cmux_superpowers_launcher.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  test -f "$1" || fail "missing file: $1"
}

assert_not_exists() {
  test ! -e "$1" || fail "unexpected path exists: $1"
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  rg -Fq -- "$pattern" "$path" || fail "missing pattern '$pattern' in $path"
}

assert_command_fails() {
  if "$@"; then
    fail "command unexpectedly succeeded: $*"
  fi
}

assert_command_fails_with_output() {
  local output_path="$1"
  shift

  if "$@" >"$output_path" 2>&1; then
    fail "command unexpectedly succeeded: $*"
  fi
}

resolve_python_path() {
  "$@" -c 'from pathlib import Path; import sys; print(Path(sys.executable).resolve())'
}

write_executable() {
  local path="$1"
  cat >"$path"
  chmod +x "$path"
}

extract_session_start_target() {
  local command="$1"

  python3 - <<'PY' "$command"
from pathlib import Path
import shlex
import sys

PYTHON_OPTIONS_WITH_VALUES = {"-W", "-X"}
PYTHON_REJECTED_SCRIPT_MODES = {"-c", "-m", "-"}


def is_hooks_session_start_path(token: str) -> bool:
    path = Path(token)
    return path.name == "session-start" and path.parent.name == "hooks"


def python_script_target(tokens: list[str]) -> str | None:
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token in PYTHON_REJECTED_SCRIPT_MODES:
            return None
        if token in PYTHON_OPTIONS_WITH_VALUES:
            index += 2
            continue
        if token.startswith("-W") or token.startswith("-X"):
            index += 1
            continue
        if token.startswith("-"):
            index += 1
            continue
        return token
    return None


command = sys.argv[1]
if "__SUPERPOWERS_" in command.upper():
    raise SystemExit(0)

try:
    tokens = shlex.split(command)
except ValueError:
    raise SystemExit(0)

if not tokens:
    raise SystemExit(0)

if is_hooks_session_start_path(tokens[0]):
    print(tokens[0])
    raise SystemExit(0)

if not Path(tokens[0]).name.startswith("python"):
    raise SystemExit(0)

target = python_script_target(tokens)
if isinstance(target, str) and is_hooks_session_start_path(target):
    print(target)
PY
}

ensure_session_start_target_exists() {
  local command="$1"
  local target
  target="$(extract_session_start_target "$command")"
  if [[ -z "$target" || -e "$target" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  write_executable "$target" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo '{}'
EOF
}

write_plugin_identity_for_session_start_command() {
  local command="$1"
  local plugin_name="${2:-superpowers-codex}"
  local target
  target="$(extract_session_start_target "$command")"
  if [[ -z "$target" ]]; then
    return 0
  fi
  local plugin_root
  plugin_root="$(dirname "$(dirname "$target")")"
  mkdir -p "$plugin_root/.codex-plugin"
  cat >"$plugin_root/.codex-plugin/plugin.json" <<EOF
{
  "name": "$plugin_name"
}
EOF
}

write_cmux_executable() {
  local bin_dir="$1"
  write_executable "$bin_dir/cmux"
}

write_codex_executable() {
  local bin_dir="$1"
  write_executable "$bin_dir/codex"
}

write_default_cmux() {
  local bin_dir="$1"
  write_cmux_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "version" ]]; then
  echo "cmux 0.test"
  exit 0
fi
echo "{}"
EOF
}

write_default_codex() {
  local bin_dir="$1"
  write_codex_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "features" && "${2:-}" == "list" ]]; then
  cat <<'OUT'
codex_hooks                      under development  true
OUT
  exit 0
fi
echo "codex stub"
EOF
}

write_false_feature_codex() {
  local bin_dir="$1"
  write_codex_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "features" && "${2:-}" == "list" ]]; then
  cat <<'OUT'
codex_hooks                      under development  false
unrelated_feature                experimental       true
OUT
  exit 0
fi
echo "codex stub"
EOF
}

write_near_threshold_codex() {
  local bin_dir="$1"
  write_codex_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "features" && "${2:-}" == "list" ]]; then
  sleep 0.6
  cat <<'OUT'
codex_hooks                      under development  true
OUT
  exit 0
fi
echo "codex stub"
EOF
}

write_config_authoritative_codex() {
  local bin_dir="$1"
  write_codex_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--version" ]]; then
  echo "codex 0.test"
  exit 0
fi
if [[ "${1:-}" == "features" && "${2:-}" == "list" ]]; then
  echo "features unavailable" >&2
  exit 9
fi
echo "codex stub"
EOF
}

write_hanging_cmux() {
  local bin_dir="$1"
  write_cmux_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "version" ]]; then
  sleep 5
  echo "cmux slow"
  exit 0
fi
echo "{}"
EOF
}

write_hanging_codex() {
  local bin_dir="$1"
  write_codex_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--version" ]]; then
  sleep 5
  echo "codex slow"
  exit 0
fi
echo "codex stub"
EOF
}

write_hooks_json() {
  local codex_home="$1"
  mkdir -p "$codex_home"
  cat >"$codex_home/hooks.json"
}

write_config_toml() {
  local codex_home="$1"
  mkdir -p "$codex_home"
  cat >"$codex_home/config.toml"
}

write_enabled_config() {
  local codex_home="$1"
  write_config_toml "$codex_home" <<'EOF'
[features]
codex_hooks = true
EOF
}

write_healthy_hooks_fixture() {
  local codex_home="$1"
  local session_start_command="${2:-$codex_home/superpowers/hooks/session-start}"
  local matcher="${3:-startup|resume|clear}"
  local session_start_type="${4:-command}"
  local status_message="${5:-loading superpowers}"
  local cmux_session_start_command="${6:-cmux codex-hook session-start}"
  local cmux_prompt_submit_command="${7:-cmux codex-hook prompt-submit}"
  local cmux_stop_command="${8:-cmux codex-hook stop}"

  mkdir -p "$codex_home"
  SESSION_START_COMMAND="$session_start_command" \
  SESSION_START_MATCHER="$matcher" \
  SESSION_START_TYPE="$session_start_type" \
  SESSION_START_STATUS="$status_message" \
  CMUX_SESSION_START_COMMAND="$cmux_session_start_command" \
  CMUX_PROMPT_SUBMIT_COMMAND="$cmux_prompt_submit_command" \
  CMUX_STOP_COMMAND="$cmux_stop_command" \
  python3 - <<'PY' >"$codex_home/hooks.json"
import json
import os
import sys

payload = {
    "hooks": {
        "SessionStart": [
            {
                "matcher": os.environ["SESSION_START_MATCHER"],
                "hooks": [
                    {
                        "type": os.environ["SESSION_START_TYPE"],
                        "command": os.environ["SESSION_START_COMMAND"],
                        "statusMessage": os.environ["SESSION_START_STATUS"],
                    }
                ],
            },
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": os.environ["CMUX_SESSION_START_COMMAND"],
                        "timeout": 10,
                    }
                ],
            },
        ],
        "UserPromptSubmit": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": os.environ["CMUX_PROMPT_SUBMIT_COMMAND"],
                        "timeout": 10,
                    }
                ],
            }
        ],
        "Stop": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": os.environ["CMUX_STOP_COMMAND"],
                        "timeout": 10,
                    }
                ],
            }
        ],
    }
}

json.dump(payload, sys.stdout, indent=2)
sys.stdout.write("\n")
PY
  ensure_session_start_target_exists "$session_start_command"
  write_plugin_identity_for_session_start_command "$session_start_command"
}

setup_doctor_scenario() {
  local tmp_root="$1"
  local name="$2"
  local scenario="$tmp_root/$name"
  local bin_dir="$scenario/bin"
  local codex_home="$scenario/codex-home"

  mkdir -p "$bin_dir" "$codex_home"
  write_default_cmux "$bin_dir"
  write_default_codex "$bin_dir"
  python3 "$INSTALLER" --bin-dir "$bin_dir" >/dev/null
  printf '%s\n' "$scenario"
}

run_doctor_json() {
  local python_path="$1"
  local output_path="$2"
  shift 2

  set +e
  env "$@" "$python_path" "$TEAM" doctor --json >"$output_path"
  local status=$?
  set -e

  printf '%s\n' "$status"
}
