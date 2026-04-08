#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT"

python3 scripts/validate_codex_public_fork.py
python3 _shared/validators/validate_skill_library.py --root "$ROOT" --family process
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'

echo "PASS: codex public fork validation bundle"
