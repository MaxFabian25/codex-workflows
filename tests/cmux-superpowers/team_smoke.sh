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
  for workspace_id in "${owned_workspaces[@]}"; do
    "$CMUX_BIN" close-workspace --workspace "$workspace_id" >/dev/null 2>&1 || true
  done
  rm -rf "$tmp"
}
trap cleanup EXIT

cat >"$stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${CMUX_SUPERPOWERS_STUB_LOG_DIR:?}"
python3 - <<'PY'
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
assert manifest["main"]["surface_ref"]
assert len(manifest["workers"]) == 1
packet = Path(manifest["workers"][0]["packet_path"])
assert packet.exists(), packet
assert manifest["workers"][0]["role"] == "review"
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
