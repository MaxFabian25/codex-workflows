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

hud_logs="$tmp/hud-logs"
hud_state="$tmp/hud-state"
mkdir -p "$hud_logs" "$hud_state"

hud_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$hud_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$hud_state" \
  python3 "$TEAM" team --json --cwd "$ROOT" --worker review "Audit the repo with a HUD"
)"

hud_manifest_path="$(python3 - <<'PY' "$hud_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
hud_session_id="$(python3 - <<'PY' "$hud_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
hud_workspace_id="$(python3 - <<'PY' "$hud_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$hud_workspace_id")

python3 - <<'PY' "$hud_manifest_path"
import json, sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
hud = manifest["hud"]
assert hud is not None
assert hud["pane_ref"]
assert hud["surface_ref"]
hud_json = Path(manifest["session_root"]) / "hud.json"
assert hud_json.exists(), hud_json
hud_payload = json.loads(hud_json.read_text(encoding="utf-8"))
assert hud_payload["session_id"] == manifest["session_id"], hud_payload
assert hud_payload["workspace_id"] == manifest["workspace_id"], hud_payload
assert hud_payload["main"] == manifest["main"], (hud_payload["main"], manifest["main"])
PY

hud_purge_output="$tmp/hud-purge-output.log"
assert_command_fails_with_output \
  "$hud_purge_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_STATE_ROOT="$hud_state" \
    python3 "$TEAM" cleanup --session "$hud_session_id" --purge-state
assert_contains "$hud_purge_output" "cannot purge session state while owned hud resources remain"
test -e "$hud_state/$hud_session_id" || fail "expected owned-hud purge failure to preserve session state"
python3 - <<'PY' "$hud_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "active", manifest
assert manifest["hud"]["surface_ref"], manifest["hud"]
PY
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$hud_state" \
python3 "$TEAM" cleanup --session "$hud_session_id" --close-hud --purge-state
test ! -e "$hud_state/$hud_session_id" || fail "expected owned-hud purge retry to remove session state"

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

non_git_cwd="$tmp/non-git-cwd"
non_git_logs="$tmp/non-git-logs"
non_git_state="$tmp/non-git-state"
mkdir -p "$non_git_cwd" "$non_git_logs" "$non_git_state"
cat >"$non_git_cwd/NOTES.md" <<'EOF'
temporary non-git directory
EOF

non_git_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$non_git_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$non_git_state" \
  python3 "$TEAM" team --json --cwd "$non_git_cwd" --worker review --no-hud "Audit a non-git directory"
)"
non_git_session_id="$(python3 - <<'PY' "$non_git_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
non_git_workspace_id="$(python3 - <<'PY' "$non_git_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$non_git_workspace_id")

CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$non_git_state" \
python3 "$TEAM" cleanup --session "$non_git_session_id" --close-workers --remove-worktrees --purge-state

test ! -e "$non_git_state/$non_git_session_id" || fail "expected non-git cleanup to purge session state: $non_git_state/$non_git_session_id"

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

write_logs="$tmp/write-logs"
write_state="$tmp/write-state"
write_repo="$tmp/write-repo"
write_nested_cwd="$write_repo/nested/path"
mkdir -p "$write_logs" "$write_state" "$write_repo"
git -C "$write_repo" init -q
cat >"$write_repo/README.md" <<'EOF'
temp repo
EOF
mkdir -p "$write_nested_cwd"
cat >"$write_nested_cwd/worker.txt" <<'EOF'
tracked nested file
EOF
git -C "$write_repo" add README.md
git -C "$write_repo" add "$write_nested_cwd/worker.txt"
git -C "$write_repo" -c user.name="Smoke Test" -c user.email="smoke@example.com" commit -qm "init"

implement_output="$tmp/implement-output.log"
assert_command_fails_with_output \
  "$implement_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$write_logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$write_state" \
    python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Implement a no-op change"
assert_contains "$implement_output" "ignored .worktrees/ or worktrees/ directory"
test -z "$(find "$write_state" -mindepth 1 -print -quit)" || fail "expected rejected write-capable launch to leave no state behind"
rm -rf "$write_logs"
mkdir -p "$write_logs"

cat >"$write_repo/.gitignore" <<'EOF'
.worktrees/
EOF
git -C "$write_repo" add .gitignore
git -C "$write_repo" -c user.name="Smoke Test" -c user.email="smoke@example.com" commit -qm "ignore worktrees"

write_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$write_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$write_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Implement a no-op change"
)"

write_manifest_path="$(python3 - <<'PY' "$write_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
write_workspace_id="$(python3 - <<'PY' "$write_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
write_session_id="$(python3 - <<'PY' "$write_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
owned_workspaces+=("$write_workspace_id")

write_worktree_path="$(python3 - <<'PY' "$write_manifest_path" "$write_nested_cwd"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["main"]["cwd"] == str(Path(sys.argv[2]).resolve()), manifest
assert len(manifest["workers"]) == 1, manifest
worker = manifest["workers"][0]
assert worker["role"] == "implement", worker
assert worker["write_capable"] is True, worker
assert worker["worktree_path"], worker
assert worker["worktree_branch"], worker
expected_cwd = str(Path(worker["worktree_path"]) / "nested" / "path")
assert worker["cwd"] == expected_cwd, worker
worker_json = Path(manifest["session_root"]) / "workers" / "worker-1.json"
assert worker_json.exists(), worker_json
print(worker["worktree_path"])
PY
)"
write_worktree_branch="$(python3 - <<'PY' "$write_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][0]["worktree_branch"])
PY
)"

test -d "$write_worktree_path" || fail "missing worktree: $write_worktree_path"
test -d "$write_worktree_path/nested/path" || fail "missing nested worktree cwd: $write_worktree_path/nested/path"
git -C "$write_repo" show-ref --verify --quiet "refs/heads/$write_worktree_branch" || fail "missing worktree branch: $write_worktree_branch"
git -C "$write_repo" worktree list --porcelain | rg -Fq -- "worktree $write_worktree_path" || fail "missing git worktree registration for $write_worktree_path"

write_log_count=0
for _ in $(seq 1 20); do
  write_log_count="$(find "$write_logs" -type f | wc -l | tr -d ' ')"
  if [[ "$write_log_count" -ge 2 ]]; then
    break
  fi
  sleep 0.25
done
test "$write_log_count" -ge 2 || fail "expected main + implement codex launches, saw $write_log_count"
python3 - <<'PY' "$write_logs" "$write_nested_cwd" "$write_worktree_path"
import json
import sys
from pathlib import Path

entries = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(Path(sys.argv[1]).glob("*.json"))]
scoped = [entry for entry in entries if entry["role"] in {"main", "implement"}]
assert sorted(entry["role"] for entry in scoped) == ["implement", "main"], scoped
for entry in scoped:
    if entry["role"] == "main":
        assert entry["cwd"] == str(Path(sys.argv[2]).resolve()), entry
    if entry["role"] == "implement":
        assert entry["cwd"] == str((Path(sys.argv[3]) / "nested" / "path").resolve()), entry
PY

CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$write_state" \
python3 "$TEAM" cleanup --session "$write_session_id" --close-workers --remove-worktrees --purge-state

test ! -d "$write_worktree_path" || fail "worktree still exists after cleanup: $write_worktree_path"
if git -C "$write_repo" show-ref --verify --quiet "refs/heads/$write_worktree_branch"; then
  fail "worktree branch still exists after cleanup: $write_worktree_branch"
fi
test ! -e "$write_state/$write_session_id" || fail "session state still exists after purge: $write_state/$write_session_id"

branch_in_use_logs="$tmp/branch-in-use-logs"
branch_in_use_state="$tmp/branch-in-use-state"
branch_in_use_other="$tmp/branch-in-use-other"
mkdir -p "$branch_in_use_logs" "$branch_in_use_state"
branch_in_use_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$branch_in_use_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$branch_in_use_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Cleanup should fail before removing a locked branch"
)"
branch_in_use_session_id="$(python3 - <<'PY' "$branch_in_use_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
branch_in_use_workspace_id="$(python3 - <<'PY' "$branch_in_use_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$branch_in_use_workspace_id")
branch_in_use_manifest_path="$(python3 - <<'PY' "$branch_in_use_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
branch_in_use_worktree_path="$(python3 - <<'PY' "$branch_in_use_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
worker = manifest["workers"][0]
assert worker["role"] == "implement", worker
assert worker["worktree_path"], worker
assert worker["worktree_branch"], worker
print(worker["worktree_path"])
PY
)"
branch_in_use_worktree_branch="$(python3 - <<'PY' "$branch_in_use_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][0]["worktree_branch"])
PY
)"
git -C "$write_repo" worktree add --force "$branch_in_use_other" "$branch_in_use_worktree_branch" >/dev/null
branch_in_use_cleanup_output="$tmp/branch-in-use-cleanup-output.log"
assert_command_fails_with_output \
  "$branch_in_use_cleanup_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_STATE_ROOT="$branch_in_use_state" \
    python3 "$TEAM" cleanup --session "$branch_in_use_session_id" --close-workers --remove-worktrees --purge-state
assert_contains "$branch_in_use_cleanup_output" "checked out in another worktree"
test -e "$branch_in_use_state/$branch_in_use_session_id" || fail "expected branch-in-use cleanup failure to preserve session state"
test -d "$branch_in_use_worktree_path" || fail "expected branch-in-use cleanup failure to preserve worktree: $branch_in_use_worktree_path"
git -C "$write_repo" show-ref --verify --quiet "refs/heads/$branch_in_use_worktree_branch" || fail "expected branch-in-use cleanup failure to preserve branch: $branch_in_use_worktree_branch"
python3 - <<'PY' "$branch_in_use_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "active", manifest
PY

purge_owned_logs="$tmp/purge-owned-logs"
purge_owned_state="$tmp/purge-owned-state"
mkdir -p "$purge_owned_logs" "$purge_owned_state"
purge_owned_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$purge_owned_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$purge_owned_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Purge should fail closed while owned worktrees remain"
)"
purge_owned_session_id="$(python3 - <<'PY' "$purge_owned_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
purge_owned_workspace_id="$(python3 - <<'PY' "$purge_owned_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$purge_owned_workspace_id")
purge_owned_manifest_path="$(python3 - <<'PY' "$purge_owned_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
purge_owned_worktree_path="$(python3 - <<'PY' "$purge_owned_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
worker = manifest["workers"][0]
print(worker["worktree_path"])
PY
)"
purge_owned_worktree_branch="$(python3 - <<'PY' "$purge_owned_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][0]["worktree_branch"])
PY
)"
purge_owned_output="$tmp/purge-owned-output.log"
assert_command_fails_with_output \
  "$purge_owned_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_STATE_ROOT="$purge_owned_state" \
    python3 "$TEAM" cleanup --session "$purge_owned_session_id" --close-workers --purge-state
assert_contains "$purge_owned_output" "cannot purge session state while owned worktree resources remain"
test -e "$purge_owned_state/$purge_owned_session_id" || fail "expected owned-worktree purge failure to preserve session state"
test -d "$purge_owned_worktree_path" || fail "expected owned-worktree purge failure to preserve worktree: $purge_owned_worktree_path"
git -C "$write_repo" show-ref --verify --quiet "refs/heads/$purge_owned_worktree_branch" || fail "expected owned-worktree purge failure to preserve branch: $purge_owned_worktree_branch"
python3 - <<'PY' "$purge_owned_manifest_path" "$purge_owned_worktree_path" "$purge_owned_worktree_branch"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "active", manifest
worker = manifest["workers"][0]
assert worker["surface_ref"] is None, worker
assert worker["worktree_path"] == sys.argv[2], worker
assert worker["worktree_branch"] == sys.argv[3], worker
worker_json = json.loads((Path(manifest["session_root"]) / "workers" / "worker-1.json").read_text(encoding="utf-8"))
assert worker_json["surface_ref"] is None, worker_json
assert worker_json["worktree_path"] == worker["worktree_path"], worker_json
assert worker_json["worktree_branch"] == worker["worktree_branch"], worker_json
PY
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$purge_owned_state" \
python3 "$TEAM" cleanup --session "$purge_owned_session_id" --close-workers --remove-worktrees --purge-state
test ! -e "$purge_owned_state/$purge_owned_session_id" || fail "expected owned-worktree purge retry to purge session state"
test ! -d "$purge_owned_worktree_path" || fail "expected owned-worktree purge retry to remove worktree: $purge_owned_worktree_path"
if git -C "$write_repo" show-ref --verify --quiet "refs/heads/$purge_owned_worktree_branch"; then
  fail "expected owned-worktree purge retry to delete branch: $purge_owned_worktree_branch"
fi

multi_cleanup_logs="$tmp/multi-cleanup-logs"
multi_cleanup_state="$tmp/multi-cleanup-state"
multi_cleanup_fake_git_dir="$tmp/multi-cleanup-fake-git"
multi_cleanup_fake_cmux_dir="$tmp/multi-cleanup-fake-cmux"
mkdir -p "$multi_cleanup_logs" "$multi_cleanup_state" "$multi_cleanup_fake_git_dir" "$multi_cleanup_fake_cmux_dir"
multi_cleanup_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$multi_cleanup_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$multi_cleanup_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --worker implement --no-hud "Cleanup should stay retry-safe after a late multi-worker failure"
)"
multi_cleanup_session_id="$(python3 - <<'PY' "$multi_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
multi_cleanup_workspace_id="$(python3 - <<'PY' "$multi_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$multi_cleanup_workspace_id")
multi_cleanup_manifest_path="$(python3 - <<'PY' "$multi_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
multi_cleanup_worker_1_path="$(python3 - <<'PY' "$multi_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert [worker["role"] for worker in manifest["workers"]] == ["implement", "implement"], manifest
print(manifest["workers"][0]["worktree_path"])
PY
)"
multi_cleanup_worker_1_branch="$(python3 - <<'PY' "$multi_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][0]["worktree_branch"])
PY
)"
multi_cleanup_worker_2_path="$(python3 - <<'PY' "$multi_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][1]["worktree_path"])
PY
)"
multi_cleanup_worker_2_branch="$(python3 - <<'PY' "$multi_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][1]["worktree_branch"])
PY
)"
real_git="$(command -v git)"
real_cmux="$CMUX_BIN"
cat >"$multi_cleanup_fake_git_dir/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
real_git="${CMUX_SUPERPOWERS_REAL_GIT:?}"
fail_branch="${CMUX_SUPERPOWERS_FAIL_BRANCH_DELETE:-}"
orig=("$@")
if [[ "${1:-}" == "-C" ]]; then
  shift 2
fi
if [[ "${1:-}" == "branch" && "${2:-}" == "-D" && "${3:-}" == "$fail_branch" ]]; then
  echo "forced late branch delete failure for $fail_branch" >&2
  exit 73
fi
exec "$real_git" "${orig[@]}"
EOF
chmod +x "$multi_cleanup_fake_git_dir/git"
cat >"$multi_cleanup_fake_cmux_dir/cmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
real_cmux="${CMUX_SUPERPOWERS_REAL_CMUX:?}"
if [[ "${1:-}" == "close-surface" && "${CMUX_SUPERPOWERS_FAIL_CLOSE_SURFACE:-0}" == "1" ]]; then
  echo "forced retry close-surface failure" >&2
  exit 74
fi
exec "$real_cmux" "$@"
EOF
chmod +x "$multi_cleanup_fake_cmux_dir/cmux"
multi_cleanup_output="$tmp/multi-cleanup-output.log"
assert_command_fails_with_output \
  "$multi_cleanup_output" \
  env \
    PATH="$multi_cleanup_fake_git_dir:$PATH" \
    CMUX_SUPERPOWERS_REAL_GIT="$real_git" \
    CMUX_SUPERPOWERS_FAIL_BRANCH_DELETE="$multi_cleanup_worker_2_branch" \
    CMUX_SUPERPOWERS_REAL_CMUX="$real_cmux" \
    CMUX_SUPERPOWERS_CMUX_BIN="$multi_cleanup_fake_cmux_dir/cmux" \
    CMUX_SUPERPOWERS_STATE_ROOT="$multi_cleanup_state" \
    python3 "$TEAM" cleanup --session "$multi_cleanup_session_id" --close-workers --remove-worktrees --purge-state
assert_contains "$multi_cleanup_output" "forced late branch delete failure"
test -e "$multi_cleanup_state/$multi_cleanup_session_id" || fail "expected late multi-worker cleanup failure to preserve session state"
test ! -d "$multi_cleanup_worker_1_path" || fail "expected late multi-worker cleanup failure to remove first worktree: $multi_cleanup_worker_1_path"
if git -C "$write_repo" show-ref --verify --quiet "refs/heads/$multi_cleanup_worker_1_branch"; then
  fail "expected late multi-worker cleanup failure to delete first branch: $multi_cleanup_worker_1_branch"
fi
test ! -d "$multi_cleanup_worker_2_path" || fail "expected late multi-worker cleanup failure to remove second worktree before branch delete failure: $multi_cleanup_worker_2_path"
git -C "$write_repo" show-ref --verify --quiet "refs/heads/$multi_cleanup_worker_2_branch" || fail "expected late multi-worker cleanup failure to preserve second branch: $multi_cleanup_worker_2_branch"
python3 - <<'PY' "$multi_cleanup_manifest_path" "$multi_cleanup_worker_2_branch"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "active", manifest
worker_1, worker_2 = manifest["workers"]
assert worker_1["surface_ref"] is None, worker_1
assert worker_2["surface_ref"] is None, worker_2
assert worker_1["worktree_path"] is None, worker_1
assert worker_1["worktree_branch"] is None, worker_1
assert worker_2["worktree_path"] is None, worker_2
assert worker_2["worktree_branch"] == sys.argv[2], worker_2
worker_1_json = json.loads((Path(manifest["session_root"]) / "workers" / "worker-1.json").read_text(encoding="utf-8"))
worker_2_json = json.loads((Path(manifest["session_root"]) / "workers" / "worker-2.json").read_text(encoding="utf-8"))
assert worker_1_json["surface_ref"] == worker_1["surface_ref"], worker_1_json
assert worker_1_json["worktree_path"] == worker_1["worktree_path"], worker_1_json
assert worker_1_json["worktree_branch"] == worker_1["worktree_branch"], worker_1_json
assert worker_2_json["surface_ref"] == worker_2["surface_ref"], worker_2_json
assert worker_2_json["worktree_path"] == worker_2["worktree_path"], worker_2_json
assert worker_2_json["worktree_branch"] == worker_2["worktree_branch"], worker_2_json
PY
CMUX_SUPERPOWERS_REAL_CMUX="$real_cmux" \
CMUX_SUPERPOWERS_FAIL_CLOSE_SURFACE="1" \
CMUX_SUPERPOWERS_CMUX_BIN="$multi_cleanup_fake_cmux_dir/cmux" \
CMUX_SUPERPOWERS_STATE_ROOT="$multi_cleanup_state" \
python3 "$TEAM" cleanup --session "$multi_cleanup_session_id" --close-workers --remove-worktrees --purge-state
test ! -e "$multi_cleanup_state/$multi_cleanup_session_id" || fail "expected retry-safe multi-worker cleanup to purge session state"
if git -C "$write_repo" show-ref --verify --quiet "refs/heads/$multi_cleanup_worker_2_branch"; then
  fail "expected retry-safe multi-worker cleanup to delete second branch: $multi_cleanup_worker_2_branch"
fi

hud_cleanup_logs="$tmp/hud-cleanup-logs"
hud_cleanup_state="$tmp/hud-cleanup-state"
mkdir -p "$hud_cleanup_logs" "$hud_cleanup_state"
hud_cleanup_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$hud_cleanup_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$hud_cleanup_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement "Refresh hud.json after cleanup mutates worker state"
)"
hud_cleanup_session_id="$(python3 - <<'PY' "$hud_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
hud_cleanup_workspace_id="$(python3 - <<'PY' "$hud_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$hud_cleanup_workspace_id")
hud_cleanup_manifest_path="$(python3 - <<'PY' "$hud_cleanup_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
hud_cleanup_worktree_path="$(python3 - <<'PY' "$hud_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
worker = manifest["workers"][0]
assert worker["role"] == "implement", worker
assert manifest["hud"]["surface_ref"], manifest["hud"]
assert worker["surface_ref"], worker
assert worker["worktree_path"], worker
print(worker["worktree_path"])
PY
)"
test -d "$hud_cleanup_worktree_path" || fail "expected hud cleanup worktree to exist before cleanup: $hud_cleanup_worktree_path"
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$hud_cleanup_state" \
python3 "$TEAM" cleanup --session "$hud_cleanup_session_id" --close-workers --remove-worktrees
test ! -d "$hud_cleanup_worktree_path" || fail "expected hud cleanup to remove worktree: $hud_cleanup_worktree_path"
python3 - <<'PY' "$hud_cleanup_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
worker = manifest["workers"][0]
worker_json = json.loads((Path(manifest["session_root"]) / "workers" / "worker-1.json").read_text(encoding="utf-8"))
hud_json = json.loads((Path(manifest["session_root"]) / "hud.json").read_text(encoding="utf-8"))
hud_worker = hud_json["workers"][0]

assert manifest["cleanup"]["status"] == "cleaned", manifest
assert worker["surface_ref"] is None, worker
assert worker["worktree_path"] is None, worker
assert worker_json["surface_ref"] == worker["surface_ref"], worker_json
assert worker_json["worktree_path"] == worker["worktree_path"], worker_json
assert hud_worker["surface_ref"] == worker["surface_ref"], (hud_worker, worker)
assert hud_worker["worktree_path"] == worker["worktree_path"], (hud_worker, worker)
PY
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$hud_cleanup_state" \
python3 "$TEAM" cleanup --session "$hud_cleanup_session_id" --close-hud --purge-state
test ! -e "$hud_cleanup_state/$hud_cleanup_session_id" || fail "expected hud cleanup retry to purge session state"

purge_fail_logs="$tmp/purge-fail-logs"
purge_fail_state="$tmp/purge-fail-state"
mkdir -p "$purge_fail_logs" "$purge_fail_state"
purge_fail_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$purge_fail_logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$purge_fail_state" \
  python3 "$TEAM" team --json --cwd "$ROOT" --worker review --no-hud "Purge-state should fail closed"
)"
purge_fail_session_id="$(python3 - <<'PY' "$purge_fail_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
purge_fail_workspace_id="$(python3 - <<'PY' "$purge_fail_payload"
import json, sys
print(json.loads(sys.argv[1])["workspace_id"])
PY
)"
owned_workspaces+=("$purge_fail_workspace_id")
purge_fail_manifest_path="$(python3 - <<'PY' "$purge_fail_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
chmod 555 "$purge_fail_state"
purge_fail_output="$tmp/purge-fail-output.log"
assert_command_fails_with_output \
  "$purge_fail_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
    CMUX_SUPERPOWERS_STATE_ROOT="$purge_fail_state" \
    python3 "$TEAM" cleanup --session "$purge_fail_session_id" --purge-state
chmod 755 "$purge_fail_state"
assert_contains "$purge_fail_output" "failed to purge session state"
test -e "$purge_fail_state/$purge_fail_session_id" || fail "expected purge-state failure to preserve session state"
python3 - <<'PY' "$purge_fail_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "cleaned", manifest
PY
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$purge_fail_state" \
python3 "$TEAM" cleanup --session "$purge_fail_session_id" --purge-state
test ! -e "$purge_fail_state/$purge_fail_session_id" || fail "expected retry after purge-state failure to remove session state"

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
    case "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" in
      malformed)
        echo "not-a-surface-ref"
        ;;
      cleanup-close-surface)
        echo "surface:cleanup-worker"
        ;;
      *)
        echo "forced split failure" >&2
        exit 9
        ;;
    esac
    ;;
  rename-tab|send)
    exit 0
    ;;
  close-surface)
    if [[ "${CMUX_SUPERPOWERS_FAIL_MODE:-exit}" == "cleanup-close-surface" ]]; then
      echo "forced close-surface failure" >&2
      exit 12
    fi
    exit 0
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

cleanup_fail_state="$tmp/cleanup-fail-state"
cleanup_fail_cmux_state="$tmp/cleanup-fail-cmux-state"
mkdir -p "$cleanup_fail_state"
cleanup_fail_payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
  CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$cleanup_fail_cmux_state" \
  CMUX_SUPERPOWERS_FAIL_MODE="cleanup-close-surface" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/cleanup-fail-logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$cleanup_fail_state" \
  python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Cleanup should fail closed"
)"
cleanup_fail_manifest_path="$(python3 - <<'PY' "$cleanup_fail_payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"
cleanup_fail_session_id="$(python3 - <<'PY' "$cleanup_fail_payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"
cleanup_fail_worktree_path="$(python3 - <<'PY' "$cleanup_fail_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert len(manifest["workers"]) == 1, manifest
worker = manifest["workers"][0]
assert worker["role"] == "implement", worker
assert worker["worktree_path"], worker
print(worker["worktree_path"])
PY
)"
test -d "$cleanup_fail_worktree_path" || fail "expected cleanup-failure worktree to exist before cleanup: $cleanup_fail_worktree_path"
cleanup_fail_output="$tmp/cleanup-fail-output.log"
assert_command_fails_with_output \
  "$cleanup_fail_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$cleanup_fail_cmux_state" \
    CMUX_SUPERPOWERS_FAIL_MODE="cleanup-close-surface" \
    CMUX_SUPERPOWERS_STATE_ROOT="$cleanup_fail_state" \
    python3 "$TEAM" cleanup --session "$cleanup_fail_session_id" --close-workers --remove-worktrees --purge-state
assert_contains "$cleanup_fail_output" "close-surface"
test -e "$cleanup_fail_state/$cleanup_fail_session_id" || fail "expected cleanup failure to preserve session state"
test -d "$cleanup_fail_worktree_path" || fail "expected cleanup failure to preserve worktree: $cleanup_fail_worktree_path"
python3 - <<'PY' "$cleanup_fail_manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["cleanup"]["status"] == "active", manifest
PY

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

implement_close_fail_state="$tmp/implement-close-fail-state"
mkdir -p "$implement_close_fail_state"
implement_close_fail_output="$tmp/implement-close-fail-output.log"
assert_command_fails_with_output \
  "$implement_close_fail_output" \
  env \
    CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
    CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/implement-close-fail-cmux-state" \
    CMUX_SUPERPOWERS_FAIL_MODE="close" \
    CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
    CMUX_SUPERPOWERS_STUB_LOG_DIR="$tmp/implement-close-fail-logs" \
    CMUX_SUPERPOWERS_STATE_ROOT="$implement_close_fail_state" \
    python3 "$TEAM" team --json --cwd "$write_nested_cwd" --worker implement --no-hud "Fail during implement rollback close"
assert_contains "$implement_close_fail_output" "close-workspace failed"
test -n "$(find "$implement_close_fail_state" -mindepth 1 -print -quit)" || fail "expected implement close-workspace failure to preserve state"
implement_close_fail_worker_json="$(find "$implement_close_fail_state" -path '*/workers/worker-1.json' -print -quit)"
test -n "$implement_close_fail_worker_json" || fail "expected implement close-workspace failure to preserve worker metadata"
implement_close_fail_session_id="$(python3 - <<'PY' "$implement_close_fail_worker_json"
import sys
from pathlib import Path

print(Path(sys.argv[1]).parents[1].name)
PY
)"
implement_close_fail_worktree_path="$(python3 - <<'PY' "$implement_close_fail_worker_json"
import json
import sys
from pathlib import Path

worker = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert worker["role"] == "implement", worker
assert worker["worktree_path"], worker
assert worker["worktree_branch"], worker
print(worker["worktree_path"])
PY
)"
implement_close_fail_worktree_branch="$(python3 - <<'PY' "$implement_close_fail_worker_json"
import json
import sys
from pathlib import Path

worker = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(worker["worktree_branch"])
PY
)"
test -d "$implement_close_fail_worktree_path" || fail "expected implement close-workspace failure to preserve worktree: $implement_close_fail_worktree_path"
git -C "$write_repo" show-ref --verify --quiet "refs/heads/$implement_close_fail_worktree_branch" || fail "expected implement close-workspace failure to preserve branch: $implement_close_fail_worktree_branch"
CMUX_SUPERPOWERS_CMUX_BIN="$failing_cmux" \
CMUX_SUPERPOWERS_FAKE_CMUX_STATE="$tmp/implement-close-fail-cmux-state" \
CMUX_SUPERPOWERS_FAIL_MODE="ok" \
CMUX_SUPERPOWERS_STATE_ROOT="$implement_close_fail_state" \
python3 "$TEAM" cleanup --session "$implement_close_fail_session_id" --close-workers --remove-worktrees --purge-state
test ! -e "$implement_close_fail_state/$implement_close_fail_session_id" || fail "expected preserved implement close-workspace failure cleanup to purge state"
test ! -d "$implement_close_fail_worktree_path" || fail "expected preserved implement close-workspace failure cleanup to remove worktree: $implement_close_fail_worktree_path"
if git -C "$write_repo" show-ref --verify --quiet "refs/heads/$implement_close_fail_worktree_branch"; then
  fail "expected preserved implement close-workspace failure cleanup to delete branch: $implement_close_fail_worktree_branch"
fi

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
