#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
LOCAL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
MANIFEST="$LOCAL_ROOT/_shared/validators/process_family_targets.txt"
REMOTE_REPO="/home/maxfa/.codex/superpowers"
REMOTE_HELPER="/Users/maxibon/.agents/skills/maxfa-remote/scripts/maxfa_remote.py"
REMOTE_WIN_ALIAS="maxfa-win"
WSL_DISTRO="Ubuntu-24.04"
WSL_USER="maxfa"
WSL_HOME="/home/maxfa"
SUPPORT_PATHS=(
  "_shared/validators/process_family_targets.txt"
  "_shared/validators/validate_skill_library.py"
)

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'Missing required file: %s\n' "$path" >&2
    exit 1
  fi
}

remote_wsl() {
  local command="$1"
  ssh "$REMOTE_WIN_ALIAS" \
    "wsl.exe -d $WSL_DISTRO -u $WSL_USER --cd $WSL_HOME $command"
}

compare_hash() {
  local rel="$1"
  local local_hash
  local remote_hash
  local_hash="$(shasum -a 256 "$LOCAL_ROOT/$rel" | awk '{print $1}')"
  remote_hash="$(
    python3 "$REMOTE_HELPER" wsl --cmd "sha256sum $REMOTE_REPO/$rel" | awk 'NR == 1 {print $1}'
  )"

  if [[ "$local_hash" != "$remote_hash" ]]; then
    printf 'Hash mismatch: %s\n' "$rel" >&2
    printf '  local:  %s\n' "$local_hash" >&2
    printf '  remote: %s\n' "$remote_hash" >&2
    return 1
  fi
}

require_file "$MANIFEST"
require_file "$REMOTE_HELPER"

archive_list="$(mktemp)"
cleanup() {
  rm -f "$archive_list"
}
trap cleanup EXIT

cat "$MANIFEST" > "$archive_list"
for rel in "${SUPPORT_PATHS[@]}"; do
  printf '%s\n' "$rel" >> "$archive_list"
done

while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  require_file "$LOCAL_ROOT/$rel"
done < "$archive_list"

remote_wsl "mkdir -p $REMOTE_REPO"
tar -C "$LOCAL_ROOT" -cf - -T "$archive_list" | remote_wsl "tar -C $REMOTE_REPO -xf -"

while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  compare_hash "$rel"
done < "$archive_list"

python3 "$REMOTE_HELPER" repo-status --repo "$REMOTE_REPO"
