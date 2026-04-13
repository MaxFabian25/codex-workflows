#!/usr/bin/env bash
set -euo pipefail
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$TEST_DIR/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

copy_scaffold_checkout() {
  local dest="$1"

  mkdir -p "$dest/scripts" "$dest/tests/cmux-superpowers"
  cp "$TEAM" "$dest/scripts/cmux_superpowers_team.py"
  cp "$INSTALLER" "$dest/scripts/install_cmux_superpowers_launcher.py"
  cp "$ROOT/tests/cmux-superpowers/common.sh" "$dest/tests/cmux-superpowers/common.sh"
  cp "$ROOT/tests/cmux-superpowers/install.sh" "$dest/tests/cmux-superpowers/install.sh"
}

run_wrapper_parser_rejection_smoke() {
  local wrapper="$1"
  local output_dir="$2"

  local cleanup_output="$output_dir/cleanup-missing-session.log"
  assert_command_fails_with_output "$cleanup_output" "$wrapper" cleanup
  assert_contains "$cleanup_output" "the following arguments are required: --session"

  local invalid_worker_output="$output_dir/team-invalid-worker.log"
  assert_command_fails_with_output \
    "$invalid_worker_output" \
    "$wrapper" \
    team \
    --worker invalid \
    "task text"
  assert_contains "$invalid_worker_output" "invalid choice: 'invalid'"
}

run_foreign_wrapper_guard_smoke() {
  local bin_dir="$1"
  local wrapper="$bin_dir/cmux-superpowers"
  mkdir -p "$bin_dir"
  cat >"$wrapper" <<'EOF'
#!/usr/bin/env bash
echo "foreign wrapper"
EOF
  chmod +x "$wrapper"

  local install_output="$bin_dir/foreign-install.log"
  assert_command_fails_with_output \
    "$install_output" \
    python3 "$INSTALLER" --bin-dir "$bin_dir"
  assert_contains "$install_output" "Refusing to overwrite unmanaged wrapper"
  assert_contains "$wrapper" "foreign wrapper"

  local remove_output="$bin_dir/foreign-remove.log"
  assert_command_fails_with_output \
    "$remove_output" \
    python3 "$INSTALLER" --bin-dir "$bin_dir" --remove
  assert_contains "$remove_output" "Refusing to remove unmanaged wrapper"
  assert_contains "$wrapper" "foreign wrapper"
}

run_marker_lookalike_guard_smoke() {
  local bin_dir="$1"
  local wrapper="$bin_dir/cmux-superpowers"
  local fake_launcher="$bin_dir/fake-checkout/scripts/cmux_superpowers_team.py"

  mkdir -p "$(dirname "$fake_launcher")" "$bin_dir"
  cat >"$wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# cmux-superpowers-managed: superpowers-codex
# cmux-superpowers-launcher: $fake_launcher
# comment-only mention: exec python3 $fake_launcher "\$@"
exec /usr/bin/env bash -lc 'echo lookalike wrapper'
EOF
  chmod +x "$wrapper"

  local install_output="$bin_dir/lookalike-install.log"
  assert_command_fails_with_output \
    "$install_output" \
    python3 "$INSTALLER" --bin-dir "$bin_dir"
  assert_contains "$install_output" "Refusing to overwrite unmanaged wrapper"
  assert_contains "$wrapper" "lookalike wrapper"

  local remove_output="$bin_dir/lookalike-remove.log"
  assert_command_fails_with_output \
    "$remove_output" \
    python3 "$INSTALLER" --bin-dir "$bin_dir" --remove
  assert_contains "$remove_output" "Refusing to remove unmanaged wrapper"
  assert_contains "$wrapper" "lookalike wrapper"
}

run_cross_checkout_reinstall_smoke() {
  local output_dir="$1"
  local checkout_a="$output_dir/checkout-a"
  local checkout_b="$output_dir/checkout-b"
  local bin_dir="$output_dir/cross-checkout-bin"
  local wrapper="$bin_dir/cmux-superpowers"
  local launcher_a
  local launcher_b

  copy_scaffold_checkout "$checkout_a"
  copy_scaffold_checkout "$checkout_b"
  launcher_a="$(cd "$checkout_a" && pwd -P)/scripts/cmux_superpowers_team.py"
  launcher_b="$(cd "$checkout_b" && pwd -P)/scripts/cmux_superpowers_team.py"

  python3 "$checkout_a/scripts/install_cmux_superpowers_launcher.py" --bin-dir "$bin_dir"
  assert_file "$wrapper"
  assert_contains "$wrapper" "$launcher_a"

  python3 "$checkout_b/scripts/install_cmux_superpowers_launcher.py" --bin-dir "$bin_dir"
  assert_contains "$wrapper" "$launcher_b"
  if rg -Fq -- "$launcher_a" "$wrapper"; then
    fail "wrapper still points at checkout A after reinstall: $wrapper"
  fi
}

run_cross_checkout_remove_smoke() {
  local output_dir="$1"
  local checkout_a="$output_dir/remove-checkout-a"
  local checkout_b="$output_dir/remove-checkout-b"
  local bin_dir="$output_dir/remove-cross-checkout-bin"
  local wrapper="$bin_dir/cmux-superpowers"

  copy_scaffold_checkout "$checkout_a"
  copy_scaffold_checkout "$checkout_b"

  python3 "$checkout_a/scripts/install_cmux_superpowers_launcher.py" --bin-dir "$bin_dir"
  assert_file "$wrapper"

  python3 "$checkout_b/scripts/install_cmux_superpowers_launcher.py" --bin-dir "$bin_dir" --remove
  assert_not_exists "$wrapper"
}

write_wrapper_smoke_cmux() {
  local bin_dir="$1"
  write_cmux_executable "$bin_dir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:?}"
shift
state_root="${CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT:?}"
mkdir -p "$state_root"

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
  printf '%s' "${workspace:-workspace:install}"
}

surface_arg() {
  local surface=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --surface)
        surface="${2:?}"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  printf '%s' "${surface:-surface:main}"
}

case "$cmd" in
  version)
    echo "cmux 0.test"
    ;;
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
    printf '%s\n' "$workspace_name" >"$state_root/workspace-name"
    echo "workspace:install"
    ;;
  list-workspaces)
    if [[ -f "$state_root/workspace-name" ]]; then
      workspace_name="$(<"$state_root/workspace-name")"
      printf '* workspace:install  %s  [selected]\n' "$workspace_name"
    fi
    ;;
  list-panes)
    echo "* pane:main  [1 surface]  [focused]"
    ;;
  list-pane-surfaces)
    echo "* surface:main  smoke  [selected]"
    ;;
  identify)
    workspace="$(workspace_arg "$@")"
    surface="$(surface_arg "$@")"
    pane="pane:${surface#surface:}"
    cat <<JSON
{"caller":{"workspace_ref":"$workspace","pane_ref":"$pane","surface_ref":"$surface","tab_ref":"tab:${surface#surface:}","window_ref":"window:install","surface_type":"terminal","is_browser_surface":false},"focused":{"workspace_ref":"$workspace","pane_ref":"$pane","surface_ref":"$surface","tab_ref":"tab:${surface#surface:}","window_ref":"window:install","surface_type":"terminal","is_browser_surface":false}}
JSON
    ;;
  new-split)
    split_count=0
    if [[ -f "$state_root/split-count" ]]; then
      split_count="$(<"$state_root/split-count")"
    fi
    split_count="$((split_count + 1))"
    printf '%s\n' "$split_count" >"$state_root/split-count"
    echo "surface:worker-$split_count"
    ;;
  rename-tab|send|close-surface|close-workspace)
    exit 0
    ;;
  *)
    echo "{}"
    ;;
esac
EOF
}

run_wrapper_team_cleanup_smoke() {
  local wrapper="$1"
  local output_dir="$2"
  local wrapper_dir
  wrapper_dir="$(cd "$(dirname "$wrapper")" && pwd -P)"
  local repo="$output_dir/wrapper-repo"
  local state_root="$output_dir/wrapper-state"

  mkdir -p "$repo" "$state_root"
  git -C "$repo" init -q
  cat >"$repo/README.md" <<'EOF'
temp repo
EOF
  git -C "$repo" add README.md
  git -C "$repo" -c user.name="Smoke Test" -c user.email="smoke@example.com" commit -qm "init"
  cat >"$repo/.gitignore" <<'EOF'
.worktrees/
EOF
  git -C "$repo" add .gitignore
  git -C "$repo" -c user.name="Smoke Test" -c user.email="smoke@example.com" commit -qm "ignore worktrees"

  local team_output="$output_dir/team-output.json"
  env \
    PATH="$wrapper_dir:$PATH" \
    CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$output_dir/wrapper-cmux-state" \
    CMUX_SUPERPOWERS_STATE_ROOT="$state_root" \
    "$wrapper" \
    team \
    --json \
    --cwd "$repo" \
    --worker implement \
    --no-hud \
    "task text" >"$team_output"

  local session_id
  session_id="$(python3 - <<'PY' "$team_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print(payload["session_id"])
PY
)"
  local manifest_path
  manifest_path="$(python3 - <<'PY' "$team_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print(payload["manifest_path"])
PY
)"
  local worktree_path
  worktree_path="$(python3 - <<'PY' "$manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert len(manifest["workers"]) == 1, manifest
worker = manifest["workers"][0]
assert worker["role"] == "implement", worker
assert worker["write_capable"] is True, worker
assert worker["worktree_path"], worker
print(worker["worktree_path"])
PY
)"

  test -d "$worktree_path" || fail "missing worktree: $worktree_path"

  env \
    PATH="$wrapper_dir:$PATH" \
    CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$output_dir/wrapper-cmux-state" \
    CMUX_SUPERPOWERS_STATE_ROOT="$state_root" \
    "$wrapper" \
    cleanup \
    --session "$session_id" \
    --close-workers \
    --remove-worktrees \
    --purge-state

  test ! -d "$worktree_path" || fail "worktree still exists after cleanup: $worktree_path"
  test ! -e "$state_root/$session_id" || fail "session state still exists after purge: $state_root/$session_id"
}

run_wrapper_cleanup_from_removed_launch_subdir_smoke() {
  local wrapper="$1"
  local output_dir="$2"
  local wrapper_dir
  wrapper_dir="$(cd "$(dirname "$wrapper")" && pwd -P)"
  local repo="$output_dir/wrapper-subdir-repo"
  local launch_cwd="$repo/tasks/launch"
  local state_root="$output_dir/wrapper-subdir-state"

  mkdir -p "$launch_cwd" "$state_root"
  git -C "$repo" init -q
  cat >"$repo/README.md" <<'EOF'
temp repo
EOF
  cat >"$repo/tasks/launch/.keep" <<'EOF'
keep
EOF
  cat >"$repo/.gitignore" <<'EOF'
.worktrees/
EOF
  git -C "$repo" add README.md .gitignore tasks/launch/.keep
  git -C "$repo" -c user.name="Smoke Test" -c user.email="smoke@example.com" commit -qm "init"

  local team_output="$output_dir/team-subdir-output.json"
  env \
    PATH="$wrapper_dir:$PATH" \
    CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$output_dir/wrapper-subdir-cmux-state" \
    CMUX_SUPERPOWERS_STATE_ROOT="$state_root" \
    "$wrapper" \
    team \
    --json \
    --cwd "$launch_cwd" \
    --worker implement \
    --no-hud \
    "task text" >"$team_output"

  local session_id
  session_id="$(python3 - <<'PY' "$team_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print(payload["session_id"])
PY
)"
  local manifest_path
  manifest_path="$(python3 - <<'PY' "$team_output"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print(payload["manifest_path"])
PY
)"
  local worktree_path
  worktree_path="$(python3 - <<'PY' "$manifest_path"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert len(manifest["workers"]) == 1, manifest
print(manifest["workers"][0]["worktree_path"])
PY
)"

  test -d "$worktree_path" || fail "missing worktree: $worktree_path"
  rm -rf "$repo/tasks"

  env \
    PATH="$wrapper_dir:$PATH" \
    CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$output_dir/wrapper-subdir-cmux-state" \
    CMUX_SUPERPOWERS_STATE_ROOT="$state_root" \
    "$wrapper" \
    cleanup \
    --session "$session_id" \
    --close-workers \
    --remove-worktrees \
    --purge-state

  test ! -d "$worktree_path" || fail "worktree still exists after cleanup: $worktree_path"
  test ! -e "$state_root/$session_id" || fail "session state still exists after purge: $state_root/$session_id"
}

run_wrapper_write_lane_preflight_smoke() {
  local wrapper="$1"
  local output_dir="$2"
  local wrapper_dir
  wrapper_dir="$(cd "$(dirname "$wrapper")" && pwd -P)"
  local cwd="$output_dir/non-git"
  local state_root="$output_dir/non-git-state"
  local cmux_state_root="$output_dir/non-git-cmux-state"
  local failed_output="$output_dir/non-git-team.log"

  mkdir -p "$cwd"
  assert_command_fails_with_output \
    "$failed_output" \
    env \
      PATH="$wrapper_dir:$PATH" \
      CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$cmux_state_root" \
      CMUX_SUPERPOWERS_STATE_ROOT="$state_root" \
      "$wrapper" \
      team \
      --json \
      --cwd "$cwd" \
      --worker implement \
      --no-hud \
      "task text"
  assert_contains "$failed_output" "Write-capable workers require a git repo."
  assert_not_exists "$cmux_state_root/workspace-name"
  if [[ -d "$state_root" ]] && find "$state_root" -mindepth 1 -print -quit | grep -q .; then
    fail "write-lane preflight should not create session state in $state_root"
  fi
}

run_wrapper_parser_smoke() {
  local wrapper="$1"
  local output_dir="$2"
  local wrapper_dir
  wrapper_dir="$(cd "$(dirname "$wrapper")" && pwd -P)"
  local codex_home="$output_dir/codex-home"

  write_wrapper_smoke_cmux "$wrapper_dir"
  write_default_codex "$wrapper_dir"
  write_healthy_hooks_fixture "$codex_home"
  write_enabled_config "$codex_home"

  env \
    PATH="$wrapper_dir:$PATH" \
    CODEX_HOME="$codex_home" \
    CMUX_SUPERPOWERS_INSTALL_FAKE_CMUX_STATE_ROOT="$output_dir/wrapper-cmux-state" \
    "$wrapper" \
    doctor --json >/dev/null
  run_wrapper_team_cleanup_smoke "$wrapper" "$output_dir"
  run_wrapper_cleanup_from_removed_launch_subdir_smoke "$wrapper" "$output_dir"
  run_wrapper_write_lane_preflight_smoke "$wrapper" "$output_dir"
  run_wrapper_parser_rejection_smoke "$wrapper" "$output_dir"
}

run_install_roundtrip() {
  local bin_dir="$1"
  local expected_root
  expected_root="$(cd "$2" && pwd -P)"
  local expected_python
  expected_python="$(resolve_python_path python3)"

  mkdir -p "$bin_dir"

  python3 "$INSTALLER" --bin-dir "$bin_dir"

  local wrapper="$bin_dir/cmux-superpowers"
  assert_file "$wrapper"
  assert_contains "$wrapper" "$expected_python"
  assert_contains "$wrapper" "$expected_root/scripts/cmux_superpowers_team.py"
  run_wrapper_parser_smoke "$wrapper" "$bin_dir"

  python3 "$INSTALLER" --bin-dir "$bin_dir" --remove
  assert_not_exists "$wrapper"
}

run_default_install_roundtrip() {
  local home_dir="$1"
  local expected_root
  expected_root="$(cd "$2" && pwd -P)"
  local expected_python
  expected_python="$(resolve_python_path env HOME="$home_dir" python3)"

  HOME="$home_dir" python3 "$INSTALLER"

  local wrapper="$home_dir/.local/bin/cmux-superpowers"
  assert_file "$wrapper"
  assert_contains "$wrapper" "$expected_python"
  assert_contains "$wrapper" "$expected_root/scripts/cmux_superpowers_team.py"
  HOME="$home_dir" run_wrapper_parser_smoke "$wrapper" "$home_dir"

  HOME="$home_dir" python3 "$INSTALLER" --remove
  assert_not_exists "$wrapper"
}

if [[ "${CMUX_SUPERPOWERS_SKIP_MISSING_LAUNCHER_CHECK:-0}" != "1" ]]; then
  launcher_only_root="$tmp/missing-launcher-only-repo"
  copy_scaffold_checkout "$launcher_only_root"
  rm "$launcher_only_root/scripts/cmux_superpowers_team.py"

  assert_not_exists "$launcher_only_root/scripts/cmux_superpowers_team.py"
  assert_file "$launcher_only_root/scripts/install_cmux_superpowers_launcher.py"
  missing_launcher_output="$tmp/missing-launcher-only-output.log"
  assert_command_fails_with_output "$missing_launcher_output" \
    python3 "$launcher_only_root/scripts/install_cmux_superpowers_launcher.py" \
      --bin-dir "$tmp/missing-launcher-only-bin"
  assert_contains "$missing_launcher_output" "Launcher not found"
  assert_contains "$missing_launcher_output" "$launcher_only_root/scripts/cmux_superpowers_team.py"
fi

if [[ "${CMUX_SUPERPOWERS_SKIP_NEGATIVE_CHECK:-0}" != "1" ]]; then
  broken_root="$tmp/missing-launcher-repo"
  copy_scaffold_checkout "$broken_root"
  rm "$broken_root/scripts/cmux_superpowers_team.py"
  rm "$broken_root/scripts/install_cmux_superpowers_launcher.py"

  assert_not_exists "$broken_root/scripts/cmux_superpowers_team.py"
  assert_not_exists "$broken_root/scripts/install_cmux_superpowers_launcher.py"
  negative_output="$tmp/missing-launcher-output.log"
  assert_command_fails_with_output "$negative_output" \
    env \
      CMUX_SUPERPOWERS_SKIP_MISSING_LAUNCHER_CHECK=1 \
      CMUX_SUPERPOWERS_SKIP_NEGATIVE_CHECK=1 \
      CMUX_SUPERPOWERS_SKIP_PORTABLE_CHECK=1 \
      CMUX_SUPERPOWERS_SKIP_DEFAULT_PATH_CHECK=1 \
      bash "$broken_root/tests/cmux-superpowers/install.sh"
  assert_contains "$negative_output" "$broken_root/scripts/install_cmux_superpowers_launcher.py"
fi

if [[ -f "$INSTALLER" ]]; then
  run_foreign_wrapper_guard_smoke "$tmp/foreign-bin"
  run_marker_lookalike_guard_smoke "$tmp/lookalike-bin"
  run_cross_checkout_reinstall_smoke "$tmp"
  run_cross_checkout_remove_smoke "$tmp"
fi

bin_dir="$tmp/bin"
run_install_roundtrip "$bin_dir" "${CMUX_SUPERPOWERS_EXPECT_ROOT:-$ROOT}"

if [[ "${CMUX_SUPERPOWERS_SKIP_DEFAULT_PATH_CHECK:-0}" != "1" ]]; then
  home_dir="$tmp/home"
  mkdir -p "$home_dir"
  run_default_install_roundtrip "$home_dir" "${CMUX_SUPERPOWERS_EXPECT_ROOT:-$ROOT}"
fi

if [[ "${CMUX_SUPERPOWERS_SKIP_PORTABLE_CHECK:-0}" != "1" ]]; then
  portable_root="$tmp/portable-repo"
  copy_scaffold_checkout "$portable_root"
  portable_root="$(cd "$portable_root" && pwd -P)"

  CMUX_SUPERPOWERS_SKIP_PORTABLE_CHECK=1 \
    CMUX_SUPERPOWERS_SKIP_MISSING_LAUNCHER_CHECK=1 \
    CMUX_SUPERPOWERS_SKIP_NEGATIVE_CHECK=1 \
    CMUX_SUPERPOWERS_SKIP_DEFAULT_PATH_CHECK=1 \
    CMUX_SUPERPOWERS_EXPECT_ROOT="$portable_root" \
    bash "$portable_root/tests/cmux-superpowers/install.sh"
fi
