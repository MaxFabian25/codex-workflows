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

run_wrapper_parser_smoke() {
  local wrapper="$1"
  local output_dir="$2"

  "$wrapper" doctor --json >/dev/null
  "$wrapper" team --json --cwd . --profile demo --worker review --worker implement --worker general --name scaffold --no-hud "task text" >/dev/null
  "$wrapper" cleanup --session demo --close-workers --close-hud --remove-worktrees --purge-state >/dev/null
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
