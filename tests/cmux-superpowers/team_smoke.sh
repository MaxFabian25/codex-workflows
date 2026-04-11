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
case "$cmd" in
  new-workspace)
    echo "workspace:fail"
    ;;
  list-panes)
    echo "* pane:fail  [1 surface]  [focused]"
    ;;
  list-pane-surfaces)
    echo "* surface:fail  smoke  [selected]"
    ;;
  identify)
    cat <<'JSON'
{"caller":{"workspace_ref":"workspace:fail","pane_ref":"pane:fail","surface_ref":"surface:fail","tab_ref":"tab:fail","window_ref":"window:fail","surface_type":"terminal","is_browser_surface":false},"focused":{"workspace_ref":"workspace:fail","pane_ref":"pane:fail","surface_ref":"surface:fail","tab_ref":"tab:fail","window_ref":"window:fail","surface_type":"terminal","is_browser_surface":false}}
JSON
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
    CMUX_SUPERPOWERS_FAIL_MODE="malformed" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/malformed-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$malformed_state" \
    python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Fail on malformed split output"
assert_contains "$malformed_output" "team launch failed"
test -z "$(find "$malformed_state" -mindepth 1 -print -quit)" || fail "expected malformed launch to leave no state behind"
