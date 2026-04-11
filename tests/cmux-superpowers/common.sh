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
