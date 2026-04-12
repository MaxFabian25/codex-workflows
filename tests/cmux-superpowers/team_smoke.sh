#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$TEST_DIR/common.sh"

CMUX_BIN="${CMUX_BIN:-$(command -v cmux || true)}"
test -n "$CMUX_BIN" || fail "cmux binary not found on PATH"

tmp="$(mktemp -d)"

logs="$tmp/logs"
state="$tmp/state"
stub="$tmp/codex-stub"
mkdir -p "$logs" "$state"
owned_workspaces=()

cleanup() {
  local workspace_id
  if [[ "${#owned_workspaces[@]}" -gt 0 ]]; then
    for workspace_id in "${owned_workspaces[@]}"; do
      "$CMUX_BIN" close-workspace --workspace "$workspace_id" >/dev/null 2>&1 || true
    done
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

cat >"$stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${CMUX_SUPERPOWERS_STUB_LOG_DIR:?}"
python3 - "$@" <<'PY'
import json
import os
import time
from pathlib import Path

payload = {
    "cwd": os.getcwd(),
    "argv": os.sys.argv[1:],
    "packet_path": os.environ.get("CMUX_SUPERPOWERS_PACKET_PATH"),
    "role": os.environ.get("CMUX_SUPERPOWERS_ROLE"),
    "session_id": os.environ.get("CMUX_SUPERPOWERS_SESSION_ID"),
}
path = Path(os.environ["CMUX_SUPERPOWERS_STUB_LOG_DIR"]) / f"{time.time_ns()}.json"
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
sleep 1
EOF
chmod +x "$stub"

payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$state" \
  python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Audit the repo for launch smoke coverage"
)"

manifest_path="$(python3 - <<'PY' "$payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
workspace_id="$(python3 - <<'PY' "$payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$workspace_id")

assert_file "$manifest_path"
python3 - <<'PY' "$manifest_path"
import json, sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["workspace_id"]
assert manifest["main"]["pane_ref"]
assert manifest["main"]["surface_ref"]
assert manifest["hud"] is None
assert len(manifest["workers"]) == 1
packet = Path(manifest["workers"][0]["packet_path"])
assert packet.exists(), packet
assert manifest["workers"][0]["role"] == "review"
assert manifest["workers"][0]["pane_ref"]
assert manifest["workers"][0]["surface_ref"]
worker_json = Path(manifest["session_root"]) / "workers" / "worker-1.json"
assert worker_json.exists(), worker_json
main_packet = Path(manifest["main"]["packet_path"]).read_text(encoding="utf-8")
assert "Pane lifecycle is owned by the external cmux-superpowers conductor." in main_packet
worker_packet = packet.read_text(encoding="utf-8")
assert "Reporting contract: report status and blockers back through the main pane." in worker_packet
assert "Direct user input: do not ask the user directly; route clarification through the main pane." in worker_packet
PY

log_count=0
for _ in $(seq 1 20); do
  log_count="$(find "$logs" -type f | wc -l | tr -d ' ')"
  if [[ "$log_count" -ge 2 ]]; then
    break
  fi
  sleep 0.25
done
test "$log_count" -ge 2 || fail "expected main + review codex launches, saw $log_count"
python3 - <<'PY' "$logs"
import json, sys
from pathlib import Path

entries = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(Path(sys.argv[1]).glob("*.json"))]
assert sorted(entry["role"] for entry in entries) == ["main", "review"], entries
for entry in entries:
    assert entry["argv"], entry
    assert entry["packet_path"], entry
    packet = Path(entry["packet_path"])
    assert packet.exists(), entry
    assert entry["argv"][-1] == packet.read_text(encoding="utf-8").rstrip("\n"), entry
PY

default_logs="$tmp/default-logs"
default_state="$tmp/default-state"
mkdir -p "$default_logs" "$default_state"

default_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$default_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$default_state" \
  python3 "$TEAM" team --json --cwd "$ROOT" --no-hud "Audit the repo with default workers"
)"

default_manifest_path="$(python3 - <<'PY' "$default_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
default_workspace_id="$(python3 - <<'PY' "$default_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$default_workspace_id")

python3 - <<'PY' "$default_manifest_path"
import json, sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert len(manifest["workers"]) == 2
assert [worker["role"] for worker in manifest["workers"]] == ["review", "general"]
assert manifest["main"]["pane_ref"]
assert manifest["main"]["surface_ref"]
assert manifest["hud"] is None
for index, worker in enumerate(manifest["workers"], start=1):
    assert worker["pane_ref"]
    assert worker["surface_ref"]
    worker_json = Path(manifest["session_root"]) / "workers" / f"worker-{index}.json"
    assert worker_json.exists(), worker_json
PY

default_log_count=0
for _ in $(seq 1 20); do
  default_log_count="$(find "$default_logs" -type f | wc -l | tr -d ' ')"
  if [[ "$default_log_count" -ge 3 ]]; then
    break
  fi
  sleep 0.25
done
test "$default_log_count" -ge 3 || fail "expected main + review + general codex launches, saw $default_log_count"
python3 - <<'PY' "$default_logs"
import json, sys
from pathlib import Path

entries = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(Path(sys.argv[1]).glob("*.json"))]
assert sorted(entry["role"] for entry in entries) == ["general", "main", "review"], entries
for entry in entries:
    assert entry["argv"], entry
    assert entry["packet_path"], entry
    packet = Path(entry["packet_path"])
    assert packet.exists(), entry
    assert entry["argv"][-1] == packet.read_text(encoding="utf-8").rstrip("\n"), entry
PY

if [[ -x /usr/bin/python3 ]]; then
  assert_python39_config() {
    local name="$1"
    local compat_home="$tmp/$name-codex-home"
    local compat_output="$tmp/$name-doctor.json"
    mkdir -p "$compat_home"
    cat >"$compat_home/config.toml"
    set +e
    env \
      CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
      CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
      CMUX_SUPERPOWERS_FORCE_MANUAL_CONFIG_PARSER=1 \
      CMUX_SUPERPOWERS_DISABLE_CONFIG_HELPER=1 \
      CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
      CODEX_HOME="$compat_home" \
      PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
      /usr/bin/python3 "$TEAM" doctor --json >"$compat_output"
    compat_status=$?
    set -e
    test "$compat_status" -eq 0 || test "$compat_status" -eq 1 || fail "expected /usr/bin/python3 doctor status 0 or 1, got $compat_status"
    python3 - <<'PY' "$compat_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["codex_hooks_enabled"] is True, payload
PY
  }

  assert_python39_config_error() {
    local name="$1"
    local compat_home="$tmp/$name-codex-home"
    local compat_output="$tmp/$name-doctor.json"
    mkdir -p "$compat_home"
    cat >"$compat_home/config.toml"
    set +e
    env \
      CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
      CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
      CMUX_SUPERPOWERS_FORCE_MANUAL_CONFIG_PARSER=1 \
      CMUX_SUPERPOWERS_DISABLE_CONFIG_HELPER=1 \
      CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
      CODEX_HOME="$compat_home" \
      PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
      /usr/bin/python3 "$TEAM" doctor --json >"$compat_output"
    compat_status=$?
    set -e
    test "$compat_status" -eq 1 || fail "expected /usr/bin/python3 doctor status 1 for malformed config, got $compat_status"
    python3 - <<'PY' "$compat_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["codex_hooks_enabled"] is False, payload
assert payload["errors"]["config"], payload
PY
  }

  assert_python39_config python39-inline-hash <<'EOF'
features = { note = "#x", codex_hooks = true }
EOF
  assert_python39_config python39-dotted-key <<'EOF'
features.codex_hooks = true
EOF
  assert_python39_config python39-inline-comma <<'EOF'
features = { note = "hello, codex_hooks = false", codex_hooks = true }
EOF
  assert_python39_config python39-multiline-valid <<'EOF'
[features]
codex_hooks = true

prompt = [
  "one",
  "two",
]
EOF
  assert_python39_config python39-multiline-string <<'EOF'
[features]
codex_hooks = true
msg = """hello
world"""
EOF
  assert_python39_config_error python39-malformed-after-valid <<'EOF'
[features]
codex_hooks = true
[broken
EOF
  assert_python39_config_error python39-inline-trailing-comma <<'EOF'
features = { codex_hooks = true, }
EOF
  assert_python39_config_error python39-stray-token <<'EOF'
[features]
codex_hooks = true
malformed
EOF
  assert_python39_config_error python39-broken-value <<'EOF'
[features]
codex_hooks = true
broken = 1 2
EOF
  assert_python39_config_error python39-quoted-trailing-junk <<'EOF'
[features]
codex_hooks = true
broken = "x"junk
EOF
  assert_python39_config_error python39-invalid-bare-token <<'EOF'
[features]
codex_hooks = true
broken = 1a
EOF
  assert_python39_config_error python39-duplicate-table <<'EOF'
[features]
codex_hooks = true
[other]
a = 1
[features]
other = true
EOF
  assert_python39_config_error python39-duplicate-key <<'EOF'
[features]
codex_hooks = true
codex_hooks = false
EOF
  assert_python39_config_error python39-crossform-dotted-then-table <<'EOF'
features.codex_hooks = true
[features]
other = 1
EOF
  assert_python39_config_error python39-crossform-inline-then-table <<'EOF'
features = { codex_hooks = true }
[features]
other = 1
EOF
  assert_python39_config_error python39-crossform-inline-then-dotted <<'EOF'
features = { note = "x" }
features.codex_hooks = true
EOF
  assert_python39_config_error python39-crossform-dotted-then-duplicate-key <<'EOF'
features.codex_hooks = true
[features]
codex_hooks = false
EOF
fi

reject_state="$tmp/reject-state"
mkdir -p "$reject_state"
implement_output="$tmp/implement-output.log"
assert_command_fails_with_output \
  "$implement_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$reject_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --worker implement --no-hud "Implement the approved change"
assert_contains "$implement_output" "write-capable workers are not implemented yet"
test -z "$(find "$reject_state" -mindepth 1 -print -quit)" || fail "expected rejected write-capable launch to leave no state behind"

failing_cmux="$tmp/failing-cmux"
cat >"$failing_cmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:?}"
shift
state_root="${CMUX_SUPERPOWERS_FAKE_CMUX_STATE:-}"

record_workspace() {
  local workspace_ref="$1"
  local workspace_name="$2"
  test -n "$state_root" || return 0
  mkdir -p "$state_root"
  printf '%s\n' "$workspace_ref" >"$state_root/workspace-ref"
  printf '%s\n' "$workspace_name" >"$state_root/workspace-name"
}

mark_workspace_created() {
  test -n "$state_root" || return 0
  mkdir -p "$state_root"
  : >"$state_root/workspace-created"
}

record_close_workspace() {
  local workspace_ref="$1"
  test -n "$state_root" || return 0
  mkdir -p "$state_root"
  printf '%s\n' "$workspace_ref" >>"$state_root/closed-workspaces"
}

workspace_arg() {
  local workspace=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --workspace)
        workspace="${2:?}"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  printf '%s' "$workspace"
}

case "$cmd" in
  new-workspace)
    workspace_name=""
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --name)
          workspace_name="${2:?}"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    case "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" in
      workspace-malformed)
        record_workspace "workspace:recover" "$workspace_name"
        mark_workspace_created
        echo "not-a-workspace-ref"
        ;;
      workspace-intruder)
        record_workspace "workspace:intruder" "$workspace_name"
        mark_workspace_created
        echo "not-a-workspace-ref"
        ;;
      workspace-truncated)
        record_workspace "workspace:intruder" "$workspace_name"
        mark_workspace_created
        echo "not-a-workspace-ref"
        ;;
      workspace-noisy)
        record_workspace "workspace:recover" "$workspace_name"
        mark_workspace_created
        echo "status workspace:existing created workspace:recover"
        ;;
      workspace-missing-output-ref)
        record_workspace "workspace:recover" "$workspace_name"
        mark_workspace_created
        echo "workspace:intruder"
        ;;
      workspace-ambiguous)
        mark_workspace_created
        echo "not-a-workspace-ref"
        ;;
      workspace-unrecoverable)
        echo "not-a-workspace-ref"
        ;;
      *)
        record_workspace "workspace:fail" "$workspace_name"
        mark_workspace_created
        echo "workspace:fail"
        ;;
    esac
    ;;
  list-workspaces)
    printf '  workspace:existing  ⠇ Existing workspace\n'
    printf '  workspace:duplicate  Elearning App Project\n'
    if [[ -n "$state_root" && -f "$state_root/workspace-created" ]]; then
      case "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" in
        workspace-malformed)
          printf '* %s  ⠏ %s  [selected]\n' "$(<"$state_root/workspace-ref")" "$(<"$state_root/workspace-name")"
          ;;
        workspace-intruder)
          session_marker="$(cut -d' ' -f1 "$state_root/workspace-name")"
          printf '* workspace:intruder  ⠏ %sevil decoy  [selected]\n' "$session_marker"
          ;;
        workspace-truncated)
          workspace_name="$(<"$state_root/workspace-name")"
          printf '* workspace:intruder  ⠏ %s...  [selected]\n' "${workspace_name%??}"
          ;;
        workspace-noisy)
          printf '* %s  ⠏ %s  [selected]\n' "$(<"$state_root/workspace-ref")" "$(<"$state_root/workspace-name")"
          ;;
        workspace-missing-output-ref)
          printf '* %s  ⠏ %s  [selected]\n' "$(<"$state_root/workspace-ref")" "$(<"$state_root/workspace-name")"
          ;;
        workspace-ambiguous)
          printf '  workspace:recover-a  ⠏ candidate one\n'
          printf '* workspace:recover-b  ⠏ candidate two  [selected]\n'
          ;;
        *)
          printf '* %s  ⠏ %s  [selected]\n' "$(<"$state_root/workspace-ref")" "$(<"$state_root/workspace-name")"
          ;;
      esac
    fi
    ;;
  list-panes)
    workspace="$(workspace_arg "$@")"
    if [[ "$workspace" == "workspace:recover" ]]; then
      echo "* pane:recover  [1 surface]  [focused]"
    else
      echo "* pane:fail  [1 surface]  [focused]"
    fi
    ;;
  list-pane-surfaces)
    workspace="$(workspace_arg "$@")"
    if [[ "$workspace" == "workspace:recover" ]]; then
      echo "* surface:recover  smoke  [selected]"
    else
      echo "* surface:fail  smoke  [selected]"
    fi
    ;;
  identify)
    workspace="$(workspace_arg "$@")"
    if [[ "$workspace" == "workspace:recover" ]]; then
      cat <<'JSON'
{"caller":{"workspace_ref":"workspace:recover","pane_ref":"pane:recover","surface_ref":"surface:recover","tab_ref":"tab:recover","window_ref":"window:recover","surface_type":"terminal","is_browser_surface":false},"focused":{"workspace_ref":"workspace:recover","pane_ref":"pane:recover","surface_ref":"surface:recover","tab_ref":"tab:recover","window_ref":"window:recover","surface_type":"terminal","is_browser_surface":false}}
JSON
    else
      cat <<'JSON'
{"caller":{"workspace_ref":"workspace:fail","pane_ref":"pane:fail","surface_ref":"surface:fail","tab_ref":"tab:fail","window_ref":"window:fail","surface_type":"terminal","is_browser_surface":false},"focused":{"workspace_ref":"workspace:fail","pane_ref":"pane:fail","surface_ref":"surface:fail","tab_ref":"tab:fail","window_ref":"window:fail","surface_type":"terminal","is_browser_surface":false}}
JSON
    fi
    ;;
  new-split)
    if [[ "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" == "malformed" ]]; then
      echo "not-a-surface-ref"
    else
      echo "forced split failure" >&2
      exit 9
    fi
    ;;
  close-workspace)
    workspace="$(workspace_arg "$@")"
    record_close_workspace "$workspace"
    if [[ "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" == "close" ]]; then
      echo "forced close-workspace failure" >&2
      exit 11
    fi
    exit 0
    ;;
  *)
    echo "unexpected command: $cmd" >&2
    exit 7
    ;;
esac
EOF
chmod +x "$failing_cmux"

failed_launch_state="$tmp/failed-launch-state"
mkdir -p "$failed_launch_state"
failed_launch_output="$tmp/failed-launch-output.log"
assert_command_fails_with_output \
  "$failed_launch_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/failed-launch-cmux-state" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/failed-launch-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$failed_launch_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Fail during split"
assert_contains "$failed_launch_output" "team launch failed"
test -z "$(find "$failed_launch_state" -mindepth 1 -print -quit)" || fail "expected failed launch to leave no state behind"

close_fail_state="$tmp/close-fail-state"
mkdir -p "$close_fail_state"
close_fail_output="$tmp/close-fail-output.log"
assert_command_fails_with_output \
  "$close_fail_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/close-fail-cmux-state" \
    CMUX_SUPERPOWERS_FAIL_MODE="close" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/close-fail-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$close_fail_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Fail during rollback close"
assert_contains "$close_fail_output" "close-workspace failed"
test -n "$(find "$close_fail_state" -mindepth 1 -print -quit)" || fail "expected close-workspace failure to preserve state"

malformed_state="$tmp/malformed-state"
mkdir -p "$malformed_state"
malformed_output="$tmp/malformed-output.log"
assert_command_fails_with_output \
  "$malformed_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/malformed-cmux-state" \
    CMUX_SUPERPOWERS_FAIL_MODE="malformed" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/malformed-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$malformed_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Fail on malformed split output"
assert_contains "$malformed_output" "team launch failed"
test -z "$(find "$malformed_state" -mindepth 1 -print -quit)" || fail "expected malformed launch to leave no state behind"

workspace_recovery_state="$tmp/workspace-recovery-state"
mkdir -p "$workspace_recovery_state"
workspace_recovery_output="$tmp/workspace-recovery-output.log"
workspace_recovery_cmux_state="$tmp/workspace-recovery-cmux-state"
assert_command_fails_with_output \
  "$workspace_recovery_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$workspace_recovery_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-malformed" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-recovery-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_recovery_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name 'recoverable [workspace]' --worker review --no-hud "Recover malformed workspace output"
assert_contains "$workspace_recovery_output" "forced split failure"
test -z "$(find "$workspace_recovery_state" -mindepth 1 -print -quit)" || fail "expected recovered malformed workspace launch to leave no state behind"
python3 - <<'PY' "$workspace_recovery_cmux_state/workspace-name"
import re
import sys
from pathlib import Path

workspace_name = Path(sys.argv[1]).read_text(encoding="utf-8").strip()
assert re.match(r"sp-[0-9a-f]{8}\Z", workspace_name), workspace_name
PY

workspace_intruder_state="$tmp/workspace-intruder-state"
mkdir -p "$workspace_intruder_state"
workspace_intruder_output="$tmp/workspace-intruder-output.log"
workspace_intruder_cmux_state="$tmp/workspace-intruder-cmux-state"
assert_command_fails_with_output \
  "$workspace_intruder_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$workspace_intruder_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-intruder" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-intruder-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_intruder_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name target-workspace --worker review --no-hud "Fail closed on foreign singleton delta"
assert_contains "$workspace_intruder_output" "workspace display does not match expected session workspace name"
test -n "$(find "$workspace_intruder_state" -mindepth 1 -print -quit)" || fail "expected hostile singleton-delta recovery to preserve state"
test ! -f "$workspace_intruder_cmux_state/closed-workspaces" || fail "expected hostile singleton-delta recovery to avoid closing a foreign workspace"

workspace_truncated_state="$tmp/workspace-truncated-state"
mkdir -p "$workspace_truncated_state"
workspace_truncated_output="$tmp/workspace-truncated-output.log"
workspace_truncated_cmux_state="$tmp/workspace-truncated-cmux-state"
assert_command_fails_with_output \
  "$workspace_truncated_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$workspace_truncated_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-truncated" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-truncated-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_truncated_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name target-workspace --worker review --no-hud "Fail closed on truncated singleton delta"
assert_contains "$workspace_truncated_output" "workspace display does not match expected session workspace name"
test -n "$(find "$workspace_truncated_state" -mindepth 1 -print -quit)" || fail "expected hostile truncated singleton recovery to preserve state"
test ! -f "$workspace_truncated_cmux_state/closed-workspaces" || fail "expected hostile truncated singleton recovery to avoid closing a foreign workspace"

workspace_noisy_state="$tmp/workspace-noisy-state"
mkdir -p "$workspace_noisy_state"
workspace_noisy_output="$tmp/workspace-noisy-output.log"
workspace_noisy_cmux_state="$tmp/workspace-noisy-cmux-state"
assert_command_fails_with_output \
  "$workspace_noisy_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$workspace_noisy_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-noisy" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-noisy-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_noisy_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name noisy-workspace --worker review --no-hud "Ignore foreign workspace token in noisy new-workspace output"
assert_contains "$workspace_noisy_output" "forced split failure"
test -z "$(find "$workspace_noisy_state" -mindepth 1 -print -quit)" || fail "expected noisy new-workspace recovery launch to leave no state behind"
assert_file "$workspace_noisy_cmux_state/closed-workspaces"
grep -Fx "workspace:recover" "$workspace_noisy_cmux_state/closed-workspaces" >/dev/null || fail "expected noisy new-workspace recovery to close the recovered workspace"
if grep -Fx "workspace:existing" "$workspace_noisy_cmux_state/closed-workspaces" >/dev/null; then
  fail "expected noisy new-workspace recovery to avoid closing the foreign workspace"
fi

workspace_missing_output_ref_state="$tmp/workspace-missing-output-ref-state"
mkdir -p "$workspace_missing_output_ref_state"
workspace_missing_output_ref_output="$tmp/workspace-missing-output-ref-output.log"
workspace_missing_output_ref_cmux_state="$tmp/workspace-missing-output-ref-cmux-state"
assert_command_fails_with_output \
  "$workspace_missing_output_ref_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$workspace_missing_output_ref_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-missing-output-ref" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-missing-output-ref-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_missing_output_ref_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name hidden-workspace --worker review --no-hud "Do not trust missing foreign output workspace ref"
assert_contains "$workspace_missing_output_ref_output" "forced split failure"
test -z "$(find "$workspace_missing_output_ref_state" -mindepth 1 -print -quit)" || fail "expected missing-output-ref recovery launch to leave no state behind"
assert_file "$workspace_missing_output_ref_cmux_state/closed-workspaces"
grep -Fx "workspace:recover" "$workspace_missing_output_ref_cmux_state/closed-workspaces" >/dev/null || fail "expected missing-output-ref recovery to close the recovered workspace"
if grep -Fx "workspace:intruder" "$workspace_missing_output_ref_cmux_state/closed-workspaces" >/dev/null; then
  fail "expected missing-output-ref recovery to avoid closing the foreign output workspace"
fi

workspace_ambiguous_state="$tmp/workspace-ambiguous-state"
mkdir -p "$workspace_ambiguous_state"
workspace_ambiguous_output="$tmp/workspace-ambiguous-output.log"
assert_command_fails_with_output \
  "$workspace_ambiguous_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/workspace-ambiguous-cmux-state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-ambiguous" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-ambiguous-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_ambiguous_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name ambiguous-workspace --worker review --no-hud "Fail closed on ambiguous workspace recovery"
assert_contains "$workspace_ambiguous_output" "ambiguous workspace recovery"
test -n "$(find "$workspace_ambiguous_state" -mindepth 1 -print -quit)" || fail "expected ambiguous malformed workspace launch to preserve state"
test ! -f "$tmp/workspace-ambiguous-cmux-state/closed-workspaces" || fail "expected ambiguous workspace recovery failure to avoid closing any workspace"

workspace_unrecoverable_state="$tmp/workspace-unrecoverable-state"
mkdir -p "$workspace_unrecoverable_state"
workspace_unrecoverable_output="$tmp/workspace-unrecoverable-output.log"
assert_command_fails_with_output \
  "$workspace_unrecoverable_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/workspace-unrecoverable-cmux-state" \
    CMUX_SUPERPOWERS_FAIL_MODE="workspace-unrecoverable" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/workspace-unrecoverable-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$workspace_unrecoverable_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --name unrecoverable-workspace --worker review --no-hud "Preserve state on unrecoverable workspace output"
assert_contains "$workspace_unrecoverable_output" "unable to recover workspace ref"
test -n "$(find "$workspace_unrecoverable_state" -mindepth 1 -print -quit)" || fail "expected unrecoverable malformed workspace launch to preserve state"
test ! -f "$tmp/workspace-unrecoverable-cmux-state/closed-workspaces" || fail "expected unrecoverable workspace recovery failure to avoid closing any workspace"
