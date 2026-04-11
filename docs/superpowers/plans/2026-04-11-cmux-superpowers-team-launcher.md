# Cmux Superpowers Team Launcher Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use superpowers:using-git-worktrees to create the isolated workspace for this plan. Then use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local `cmux-superpowers` launcher that reproduces the key `cmux omx` operator experience for plain Codex CLI plus the existing local Superpowers setup.

**Architecture:** Implement a repo-owned Python conductor and installer. The conductor launches ordinary interactive `codex` processes inside cmux panes, persists owned state under `~/.cmuxterm/superpowers-team/`, reuses the existing Superpowers `SessionStart` hook plus the installed cmux Codex hooks, and isolates any write-capable workers with Git worktrees. Validation combines deterministic installer/doctor shell tests with a live cmux smoke test that uses a fake `codex` binary instead of the real agent.

**Tech Stack:** Python 3 standard library, Bash, `cmux` CLI, `codex` CLI, Git worktrees, JSON, Markdown docs

---

## File Structure

Use these absolute paths during implementation:

- Repo root: `/Users/maxibon/.codex/superpowers`
- Spec: `/Users/maxibon/.codex/superpowers/docs/superpowers/specs/2026-04-11-cmux-superpowers-team-design.md`
- Plan: `/Users/maxibon/.codex/superpowers/docs/superpowers/plans/2026-04-11-cmux-superpowers-team-launcher.md`
- Main launcher: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Installer: `/Users/maxibon/.codex/superpowers/scripts/install_cmux_superpowers_launcher.py`
- Existing hook installer: `/Users/maxibon/.codex/superpowers/scripts/install_codex_hooks.py`
- Existing SessionStart hook: `/Users/maxibon/.codex/superpowers/hooks/session-start`
- Package metadata: `/Users/maxibon/.codex/superpowers/package.json`
- Codex docs: `/Users/maxibon/.codex/superpowers/docs/README.codex.md`
- Local install docs: `/Users/maxibon/.codex/superpowers/.codex/INSTALL.md`
- Test helper: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh`
- Install test: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/install.sh`
- Doctor test: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/doctor.sh`
- Team smoke test: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`

Implementation commands below assume:

```bash
ROOT="/Users/maxibon/.codex/superpowers"
TEAM="$ROOT/scripts/cmux_superpowers_team.py"
INSTALLER="$ROOT/scripts/install_cmux_superpowers_launcher.py"
COMMON_TEST="$ROOT/tests/cmux-superpowers/common.sh"
INSTALL_TEST="$ROOT/tests/cmux-superpowers/install.sh"
DOCTOR_TEST="$ROOT/tests/cmux-superpowers/doctor.sh"
TEAM_TEST="$ROOT/tests/cmux-superpowers/team_smoke.sh"
cd "$ROOT"
```

## Task 1: Scaffold the Launcher and Local Install Surface

**Files:**
- Create: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Create: `/Users/maxibon/.codex/superpowers/scripts/install_cmux_superpowers_launcher.py`
- Create: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh`
- Create: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/install.sh`

- [ ] **Step 1: Write the failing install test and shared shell helpers**

Create `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/maxibon/.codex/superpowers"
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
  rg -q "$pattern" "$path" || fail "missing pattern '$pattern' in $path"
}
```

Create `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/install.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bin_dir="$tmp/bin"
mkdir -p "$bin_dir"

python3 "$INSTALLER" --bin-dir "$bin_dir"

wrapper="$bin_dir/cmux-superpowers"
assert_file "$wrapper"
assert_contains "$wrapper" "cmux_superpowers_team.py"
"$wrapper" --help >/dev/null

python3 "$INSTALLER" --bin-dir "$bin_dir" --remove
assert_not_exists "$wrapper"
```

- [ ] **Step 2: Run the install test to verify it fails before implementation**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/install.sh
```

Expected: failure because `scripts/install_cmux_superpowers_launcher.py` and `scripts/cmux_superpowers_team.py` do not exist yet.

- [ ] **Step 3: Write the minimal launcher parser and wrapper installer**

Create `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py` with:

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="cmux-superpowers",
        description="Local cmux launcher for Superpowers-backed Codex team sessions.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor = subparsers.add_parser("doctor", help="Inspect launcher prerequisites")
    doctor.add_argument("--json", action="store_true")

    team = subparsers.add_parser("team", help="Create a cmux-backed Codex team session")
    team.add_argument("--json", action="store_true")
    team.add_argument("--cwd", default=".")
    team.add_argument("--profile")
    team.add_argument("--worker", action="append", choices=["review", "implement", "general"])
    team.add_argument("--name")
    team.add_argument("--no-hud", action="store_true")
    team.add_argument("task")

    cleanup = subparsers.add_parser("cleanup", help="Clean up an owned team session")
    cleanup.add_argument("--session", required=True)
    cleanup.add_argument("--close-workers", action="store_true")
    cleanup.add_argument("--close-hud", action="store_true")
    cleanup.add_argument("--remove-worktrees", action="store_true")
    cleanup.add_argument("--purge-state", action="store_true")

    return parser


def main() -> int:
    parser = build_parser()
    parser.parse_args()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Create `/Users/maxibon/.codex/superpowers/scripts/install_cmux_superpowers_launcher.py` with:

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
LAUNCHER_PATH = REPO_ROOT / "scripts" / "cmux_superpowers_team.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install or remove the cmux-superpowers wrapper.")
    parser.add_argument(
        "--bin-dir",
        default=str(Path.home() / ".local" / "bin"),
        help="Directory to receive the cmux-superpowers wrapper",
    )
    parser.add_argument("--remove", action="store_true", help="Remove the installed wrapper")
    return parser.parse_args()


def render_wrapper() -> str:
    python_executable = shlex.quote(str(Path(sys.executable).resolve()))
    launcher = shlex.quote(str(LAUNCHER_PATH))
    return "#!/usr/bin/env bash\nset -euo pipefail\nexec " + python_executable + " " + launcher + ' "$@"\n'


def install(bin_dir: Path) -> int:
    wrapper = bin_dir / "cmux-superpowers"
    bin_dir.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(render_wrapper(), encoding="utf-8")
    wrapper.chmod(0o755)
    print(f"Installed {wrapper}")
    return 0


def remove(bin_dir: Path) -> int:
    wrapper = bin_dir / "cmux-superpowers"
    if wrapper.exists():
        wrapper.unlink()
        print(f"Removed {wrapper}")
    else:
        print(f"No wrapper found at {wrapper}")
    return 0


def main() -> int:
    args = parse_args()
    bin_dir = Path(args.bin_dir).expanduser().resolve()
    if args.remove:
        return remove(bin_dir)
    return install(bin_dir)


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run the install test again to verify the wrapper path now works**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/install.sh
```

Expected: no output and exit status `0`.

- [ ] **Step 5: Commit the scaffolded launcher and installer**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add scripts/cmux_superpowers_team.py scripts/install_cmux_superpowers_launcher.py tests/cmux-superpowers/common.sh tests/cmux-superpowers/install.sh
git commit -m "feat: scaffold cmux superpowers launcher"
```

Expected: commit succeeds with the scaffold files only.

## Task 2: Implement `doctor` and Prerequisite Detection

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Create: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/doctor.sh`

- [ ] **Step 1: Write the failing doctor test for missing and healthy states**

Create `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/doctor.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bin_dir="$tmp/bin"
codex_home="$tmp/codex-home"
mkdir -p "$bin_dir" "$codex_home"

cat >"$bin_dir/cmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "version" ]]; then
  echo "cmux 0.test"
  exit 0
fi
echo "{}"
EOF
chmod +x "$bin_dir/cmux"

cat >"$bin_dir/codex" <<'EOF'
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
chmod +x "$bin_dir/codex"

python3 "$INSTALLER" --bin-dir "$bin_dir"

PATH="$bin_dir:$PATH" CODEX_HOME="$codex_home" python3 "$TEAM" doctor --json >"$tmp/missing.json"

python3 - <<'PY' "$tmp/missing.json"
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["cmux"]["ok"] is True
assert payload["codex"]["ok"] is True
assert payload["hooks"]["superpowers_sessionstart"] is False
assert payload["hooks"]["cmux_codex"] is False
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is True
assert payload["ok"] is False
PY

cat >"$codex_home/hooks.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/superpowers/session-start",
            "statusMessage": "loading superpowers"
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux codex-hook session-start",
            "timeout": 10
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux codex-hook prompt-submit",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cmux codex-hook stop",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF

cat >"$codex_home/config.toml" <<'EOF'
[features]
codex_hooks = true
EOF

PATH="$bin_dir:$PATH" CODEX_HOME="$codex_home" python3 "$TEAM" doctor --json >"$tmp/healthy.json"

python3 - <<'PY' "$tmp/healthy.json"
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["hooks"]["superpowers_sessionstart"] is True
assert payload["hooks"]["cmux_codex"] is True
assert payload["codex_hooks_enabled"] is True
assert payload["launcher_on_path"] is True
assert payload["ok"] is True
PY
```

- [ ] **Step 2: Run the doctor test to verify it fails before `doctor` is implemented**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/doctor.sh
```

Expected: failure because the current launcher returns no structured doctor payload.

- [ ] **Step 3: Implement binary, hook, and config detection in `cmux_superpowers_team.py`**

Update `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py` to include:

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CODEX_HOME = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")


def resolve_binary(env_var: str, fallback: str) -> str | None:
    explicit = os.environ.get(env_var)
    if explicit:
        path = Path(explicit).expanduser().resolve()
        return str(path) if path.exists() else None
    return shutil.which(fallback)


def load_hooks_json(codex_home: Path) -> dict:
    hooks_path = codex_home / "hooks.json"
    if not hooks_path.exists():
        return {"hooks": {}}
    with hooks_path.open(encoding="utf-8") as fh:
        payload = json.load(fh)
    hooks = payload.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise SystemExit(f"{hooks_path} field 'hooks' must be a JSON object")
    return payload


def has_superpowers_group(payload: dict) -> bool:
    for group in payload.get("hooks", {}).get("SessionStart", []):
        hooks = group.get("hooks", [])
        for hook in hooks:
            if hook.get("statusMessage") == "loading superpowers":
                return True
            command = hook.get("command", "")
            if isinstance(command, str) and "superpowers" in command and "session-start" in command:
                return True
    return False


def has_cmux_codex_hooks(payload: dict) -> bool:
    hook_map = payload.get("hooks", {})
    required = {
        "SessionStart": "cmux codex-hook session-start",
        "UserPromptSubmit": "cmux codex-hook prompt-submit",
        "Stop": "cmux codex-hook stop",
    }
    for event, marker in required.items():
        groups = hook_map.get(event, [])
        found = False
        for group in groups:
            for hook in group.get("hooks", []):
                command = hook.get("command", "")
                if isinstance(command, str) and marker in command:
                    found = True
                    break
            if found:
                break
        if not found:
            return False
    return True


def codex_hooks_enabled(codex_home: Path) -> bool:
    config_path = codex_home / "config.toml"
    if config_path.exists():
        text = config_path.read_text(encoding="utf-8")
        if "codex_hooks = true" in text:
            return True
    codex_bin = resolve_binary("CMUX_SUPERPOWERS_CODEX_BIN", "codex")
    if not codex_bin:
        return False
    from subprocess import run, PIPE
    proc = run([codex_bin, "features", "list"], check=False, capture_output=True, text=True)
    return proc.returncode == 0 and "codex_hooks" in proc.stdout and "true" in proc.stdout


def launcher_on_path() -> bool:
    return shutil.which("cmux-superpowers") is not None


def doctor_payload() -> dict:
    codex_home = DEFAULT_CODEX_HOME.expanduser().resolve()
    hooks_payload = load_hooks_json(codex_home)
    cmux_bin = resolve_binary("CMUX_SUPERPOWERS_CMUX_BIN", "cmux")
    codex_bin = resolve_binary("CMUX_SUPERPOWERS_CODEX_BIN", "codex")
    payload = {
        "cmux": {"path": cmux_bin, "ok": bool(cmux_bin)},
        "codex": {"path": codex_bin, "ok": bool(codex_bin)},
        "codex_home": str(codex_home),
        "hooks": {
            "superpowers_sessionstart": has_superpowers_group(hooks_payload),
            "cmux_codex": has_cmux_codex_hooks(hooks_payload),
        },
        "codex_hooks_enabled": codex_hooks_enabled(codex_home),
        "launcher_on_path": launcher_on_path(),
    }
    payload["ok"] = (
        payload["cmux"]["ok"]
        and payload["codex"]["ok"]
        and payload["hooks"]["superpowers_sessionstart"]
        and payload["hooks"]["cmux_codex"]
        and payload["codex_hooks_enabled"]
        and payload["launcher_on_path"]
    )
    return payload


def cmd_doctor(args: argparse.Namespace) -> int:
    payload = doctor_payload()
    if args.json:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0 if payload["ok"] else 1
    for key, value in payload.items():
        print(f"{key}: {value}")
    return 0 if payload["ok"] else 1
```

Wire the parser dispatch at the bottom:

```python
def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "doctor":
        return cmd_doctor(args)
    if args.command == "team":
        raise SystemExit("team not implemented yet")
    if args.command == "cleanup":
        raise SystemExit("cleanup not implemented yet")
    parser.error(f"unknown command {args.command}")
```

- [ ] **Step 4: Run the doctor test again to verify the healthy and missing states are both reported correctly**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/doctor.sh
```

Expected: no output and exit status `0`.

- [ ] **Step 5: Commit the `doctor` implementation**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add scripts/cmux_superpowers_team.py tests/cmux-superpowers/doctor.sh
git commit -m "feat: add cmux superpowers doctor"
```

Expected: commit succeeds with only the `doctor` task files staged.

## Task 3: Implement Read-Only Team Launch, Prompt Packets, and Session Manifests

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Create: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`

- [ ] **Step 1: Write the failing live cmux smoke test for a read-only team session**

Create `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/common.sh"

CMUX_BIN="${CMUX_BIN:-$(command -v cmux || true)}"
test -n "$CMUX_BIN" || fail "cmux binary not found on PATH"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

logs="$tmp/logs"
state="$tmp/state"
stub="$tmp/codex-stub"
mkdir -p "$logs" "$state"

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

log_count="$(find "$logs" -type f | wc -l | tr -d ' ')"
test "$log_count" -ge 2 || fail "expected main + review codex launches, saw $log_count"
```

- [ ] **Step 2: Run the smoke test to verify it fails before `team` exists**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: failure because the `team` subcommand is not implemented yet.

- [ ] **Step 3: Add the role model, session state, and packet writers**

Extend `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py` with:

```python
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
import shlex
import subprocess
import uuid


STATE_ROOT = Path(os.environ.get("CMUX_SUPERPOWERS_STATE_ROOT") or (Path.home() / ".cmuxterm" / "superpowers-team"))

ROLE_SPECS = {
    "review": {"write": False, "profile": "parallel_readonly"},
    "general": {"write": False, "profile": "workflow_fidelity"},
    "implement": {"write": True, "profile": "workflow_fidelity"},
}


@dataclass
class WorkerPlan:
    worker_id: str
    role: str
    write_capable: bool
    profile: str | None
    cwd: str
    packet_path: str
    pane_ref: str | None = None
    surface_ref: str | None = None
    worktree_path: str | None = None


def session_dir(session_id: str) -> Path:
    return STATE_ROOT / session_id


def build_packet(role: str, task: str, cwd: str, write_capable: bool) -> str:
    mode = "write-capable" if write_capable else "read-only"
    return (
        f"# Cmux Superpowers Worker Packet\n\n"
        f"- Role: {role}\n"
        f"- Mode: {mode}\n"
        f"- Working directory: {cwd}\n\n"
        f"## Task\n\n{task}\n\n"
        f"## Contract\n\n"
        f"- You are running inside a cmux-superpowers team session.\n"
        f"- Use Superpowers skills normally.\n"
        f"- Stay within your declared role and ownership.\n"
        f"- Report status clearly in the terminal session.\n"
    )


def run(argv: list[str], *, capture: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(argv, check=True, text=True, capture_output=capture)


def resolve_cmux_bin() -> str:
    path = resolve_binary("CMUX_SUPERPOWERS_CMUX_BIN", "cmux")
    if not path:
        raise SystemExit("cmux binary not found")
    return path


def resolve_codex_bin() -> str:
    path = resolve_binary("CMUX_SUPERPOWERS_CODEX_BIN", "codex")
    if not path:
        raise SystemExit("codex binary not found")
    return path


def write_packet(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
```

- [ ] **Step 4: Implement read-only workspace creation and worker launch through cmux**

Add these helpers and `cmd_team`:

```python
def cmux_json(*args: str) -> dict:
    proc = run([resolve_cmux_bin(), *args])
    return json.loads(proc.stdout)


def cmux_text(*args: str) -> str:
    return run([resolve_cmux_bin(), *args]).stdout.strip()


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def codex_command(cwd: str, packet_path: Path, role: str, profile: str | None, session_id: str) -> str:
    exports = [
        f"CMUX_SUPERPOWERS_PACKET_PATH={shlex.quote(str(packet_path))}",
        f"CMUX_SUPERPOWERS_ROLE={shlex.quote(role)}",
        f"CMUX_SUPERPOWERS_SESSION_ID={shlex.quote(session_id)}",
    ]
    profile_flags = ["-p", profile] if profile else []
    prompt_expr = f'PROMPT=$(cat {shlex.quote(str(packet_path))})'
    cmd = [resolve_codex_bin(), "-C", cwd, *profile_flags]
    return f"cd -- {shlex.quote(cwd)} && {prompt_expr} && {' '.join(exports)} {shell_join(cmd)} \"$PROMPT\""


def cmd_team(args: argparse.Namespace) -> int:
    session_id = f"session-{uuid.uuid4().hex[:8]}"
    session_root = session_dir(session_id)
    session_root.mkdir(parents=True, exist_ok=True)
    workers = args.worker or ["review", "general"]
    task = args.task
    cwd = str(Path(args.cwd).expanduser().resolve())

    main_packet = session_root / "packets" / "main.md"
    write_packet(main_packet, build_packet("main", task, cwd, write_capable=False))
    main_command = codex_command(cwd, main_packet, "main", args.profile or "workflow_fidelity", session_id)

    workspace_name = args.name or f"superpowers-{session_id}"
    run([resolve_cmux_bin(), "new-workspace", "--name", workspace_name, "--cwd", cwd, "--command", main_command], capture=False)
    workspace_id = cmux_text("current-workspace")
    focused = cmux_json("identify")["focused"]
    main_surface = focused["surface_ref"]
    main_pane = focused["pane_ref"]

    planned_workers: list[WorkerPlan] = []
    anchor_surface = main_surface
    for index, role in enumerate(workers, start=1):
        worker_id = f"worker-{index}"
        role_spec = ROLE_SPECS[role]
        packet_path = session_root / "packets" / f"{worker_id}.md"
        write_packet(packet_path, build_packet(role, task, cwd, role_spec["write"]))
        run([resolve_cmux_bin(), "new-split", "right" if index == 1 else "down", "--workspace", workspace_id, "--surface", anchor_surface], capture=False)
        focused = cmux_json("identify")["focused"]
        anchor_surface = focused["surface_ref"]
        run([resolve_cmux_bin(), "rename-tab", "--workspace", workspace_id, "--surface", anchor_surface, worker_id], capture=False)
        run([resolve_cmux_bin(), "send", "--workspace", workspace_id, "--surface", anchor_surface, codex_command(cwd, packet_path, role, role_spec["profile"], session_id) + "\n"], capture=False)
        planned_workers.append(
            WorkerPlan(
                worker_id=worker_id,
                role=role,
                write_capable=role_spec["write"],
                profile=role_spec["profile"],
                cwd=cwd,
                packet_path=str(packet_path),
                pane_ref=focused["pane_ref"],
                surface_ref=focused["surface_ref"],
            )
        )

    manifest = {
        "session_id": session_id,
        "created_at": datetime.now(UTC).isoformat(),
        "workspace_id": workspace_id,
        "session_root": str(session_root),
        "main": {
            "pane_ref": main_pane,
            "surface_ref": main_surface,
            "packet_path": str(main_packet),
            "cwd": cwd,
        },
        "workers": [asdict(worker) for worker in planned_workers],
        "hud": None,
        "cleanup": {"status": "active"},
    }
    manifest_path = session_root / "manifest.json"
    write_json(manifest_path, manifest)
    for worker in planned_workers:
        write_json(session_root / "workers" / f"{worker.worker_id}.json", asdict(worker))

    if args.json:
        print(json.dumps({"session_id": session_id, "workspace_id": workspace_id, "manifest_path": str(manifest_path)}))
    else:
        print(f"Created {session_id} in {workspace_id}")
    return 0
```

Update `main()` dispatch:

```python
    if args.command == "team":
        return cmd_team(args)
```

- [ ] **Step 5: Run the smoke test again to verify manifest creation and read-only launches**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: the read-only lane passes and records one main plus one review worker launch in the stub log directory.

- [ ] **Step 6: Commit the read-only team launch**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add scripts/cmux_superpowers_team.py tests/cmux-superpowers/team_smoke.sh
git commit -m "feat: add read-only cmux superpowers team launch"
```

Expected: commit succeeds with only the read-only launch changes.

## Task 4: Add Write-Capable Worker Isolation and Owned Cleanup

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Modify: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`

- [ ] **Step 1: Extend the smoke test with failing isolation and cleanup coverage**

Append this block to `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`:

```bash
repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
git -C "$repo" init -q
cat >"$repo/README.md" <<'EOF'
temp repo
EOF
git -C "$repo" add README.md
git -C "$repo" commit -qm "init"

set +e
CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
CMUX_SUPERPOWERS_STATE_ROOT="$state" \
python3 "$TEAM" team --json --cwd "$repo" --worker implement --no-hud "Implement a no-op change" >/dev/null 2>&1
status="$?"
set -e
test "$status" -ne 0 || fail "expected write-capable launch to fail without ignored worktree directory"

cat >"$repo/.gitignore" <<'EOF'
.worktrees/
EOF
git -C "$repo" add .gitignore
git -C "$repo" commit -qm "ignore worktrees"

payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$state" \
  python3 "$TEAM" team --json --cwd "$repo" --worker implement --no-hud "Implement a no-op change"
)"

manifest_path="$(python3 - <<'PY' "$payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"

session_id="$(python3 - <<'PY' "$payload"
import json, sys
print(json.loads(sys.argv[1])["session_id"])
PY
)"

worktree_path="$(python3 - <<'PY' "$manifest_path"
import json, sys
from pathlib import Path
manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(manifest["workers"][0]["worktree_path"])
PY
)"

test -d "$worktree_path" || fail "missing worktree: $worktree_path"

CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
CMUX_SUPERPOWERS_STATE_ROOT="$state" \
python3 "$TEAM" cleanup --session "$session_id" --close-workers --remove-worktrees --purge-state

test ! -d "$worktree_path" || fail "worktree still exists after cleanup: $worktree_path"
test ! -e "$state/$session_id" || fail "session state still exists after purge: $state/$session_id"
```

- [ ] **Step 2: Run the smoke test again to verify the new write-capable lane fails before worktree support exists**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: failure because the current `team` code does not create isolated worktrees and `cleanup` is not implemented.

- [ ] **Step 3: Implement worktree selection, write-worker preparation, and owned cleanup**

Add these helpers to `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`:

```python
def git_text(*args: str, cwd: str) -> str:
    return run(["git", "-C", cwd, *args]).stdout.strip()


def repo_root_for(cwd: str) -> str:
    return git_text("rev-parse", "--show-toplevel", cwd=cwd)


def choose_worktree_root(repo_root: str) -> Path:
    for rel in [".worktrees", "worktrees"]:
        probe = subprocess.run(["git", "-C", repo_root, "check-ignore", "-q", rel], check=False)
        if probe.returncode == 0:
            root = Path(repo_root) / rel / "cmux-superpowers"
            root.mkdir(parents=True, exist_ok=True)
            return root
    raise SystemExit("Write-capable workers require an ignored .worktrees/ or worktrees/ directory.")


def prepare_worker_root(base_cwd: str, session_id: str, worker_id: str, write_capable: bool) -> tuple[str, str | None]:
    if not write_capable:
        return base_cwd, None
    repo_root = repo_root_for(base_cwd)
    worktree_root = choose_worktree_root(repo_root)
    branch = f"cmux-superpowers/{session_id}-{worker_id}"
    path = worktree_root / f"{session_id}-{worker_id}"
    run(["git", "-C", repo_root, "worktree", "add", str(path), "-b", branch], capture=False)
    return str(path), str(path)


def cmd_cleanup(args: argparse.Namespace) -> int:
    manifest_path = session_dir(args.session) / "manifest.json"
    if not manifest_path.exists():
        raise SystemExit(f"session manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    workspace_id = manifest["workspace_id"]

    if args.close_workers:
        for worker in manifest.get("workers", []):
            surface_ref = worker.get("surface_ref")
            if surface_ref:
                subprocess.run([resolve_cmux_bin(), "close-surface", "--workspace", workspace_id, "--surface", surface_ref], check=False, text=True)

    if args.close_hud and manifest.get("hud", {}).get("surface_ref"):
        subprocess.run([resolve_cmux_bin(), "close-surface", "--workspace", workspace_id, "--surface", manifest["hud"]["surface_ref"]], check=False, text=True)

    if args.remove_worktrees:
        repo_root = manifest["main"]["cwd"]
        for worker in manifest.get("workers", []):
            worktree_path = worker.get("worktree_path")
            if worktree_path:
                subprocess.run(["git", "-C", repo_root_for(repo_root), "worktree", "remove", "--force", worktree_path], check=False, text=True)

    manifest["cleanup"] = {"status": "cleaned"}
    write_json(manifest_path, manifest)
    if args.purge_state:
        import shutil as _shutil
        _shutil.rmtree(session_dir(args.session), ignore_errors=True)
    return 0
```

Change the worker preparation inside `cmd_team`:

```python
        worker_cwd, worktree_path = prepare_worker_root(cwd, session_id, worker_id, role_spec["write"])
        write_packet(packet_path, build_packet(role, task, worker_cwd, role_spec["write"]))
```

And record those values:

```python
                cwd=worker_cwd,
                packet_path=str(packet_path),
                worktree_path=worktree_path,
```

Update `main()`:

```python
    if args.command == "cleanup":
        return cmd_cleanup(args)
```

- [ ] **Step 4: Run the smoke test again to verify write-worker isolation and cleanup both pass**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: the write-capable lane fails closed without ignored worktree storage, succeeds once `.worktrees/` is ignored, and cleanup removes the owned worktree and state directory.

- [ ] **Step 5: Commit the isolation and cleanup changes**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add scripts/cmux_superpowers_team.py tests/cmux-superpowers/team_smoke.sh
git commit -m "feat: add worktree isolation and cleanup"
```

Expected: commit succeeds with only the isolation/cleanup changes staged.

## Task 5: Add the Optional HUD Pane and Session Read Model

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`
- Modify: `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`

- [ ] **Step 1: Extend the smoke test with failing HUD expectations**

Append this block to `/Users/maxibon/.codex/superpowers/tests/cmux-superpowers/team_smoke.sh`:

```bash
payload="$(
  CMUX_SUPERPOWERS_CMUX_BIN="$CMUX_BIN" \
  CMUX_SUPERPOWERS_CODEX_BIN="$stub" \
  CMUX_SUPERPOWERS_STUB_LOG_DIR="$logs" \
  CMUX_SUPERPOWERS_STATE_ROOT="$state" \
  python3 "$TEAM" team --json --cwd "$ROOT" --worker review "Audit the repo with a HUD"
)"

manifest_path="$(python3 - <<'PY' "$payload"
import json, sys
print(json.loads(sys.argv[1])["manifest_path"])
PY
)"

python3 - <<'PY' "$manifest_path"
import json, sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
hud = manifest["hud"]
assert hud is not None
assert hud["surface_ref"]
hud_json = Path(manifest["session_root"]) / "hud.json"
assert hud_json.exists(), hud_json
PY
```

- [ ] **Step 2: Run the smoke test to verify it fails before HUD support exists**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: failure because the current implementation always records `hud: null`.

- [ ] **Step 3: Implement `hud.json`, a simple HUD runner, and bottom-pane launch**

Add to `/Users/maxibon/.codex/superpowers/scripts/cmux_superpowers_team.py`:

```python
def build_hud_payload(manifest: dict) -> dict:
    return {
        "session_id": manifest["session_id"],
        "workspace_id": manifest["workspace_id"],
        "main": manifest["main"],
        "workers": [
            {
                "worker_id": worker["worker_id"],
                "role": worker["role"],
                "cwd": worker["cwd"],
                "worktree_path": worker.get("worktree_path"),
                "pane_ref": worker.get("pane_ref"),
                "surface_ref": worker.get("surface_ref"),
            }
            for worker in manifest["workers"]
        ],
    }


def write_hud_runner(session_root: Path) -> Path:
    runner = session_root / "hud_runner.sh"
    runner.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
HUD_JSON="$1"
while true; do
  clear
  python3 - <<'PY' "$HUD_JSON"
import json, sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
print(f"Session: {payload['session_id']}")
print(f"Workspace: {payload['workspace_id']}")
print("")
for worker in payload['workers']:
    print(f"{worker['worker_id']}  role={worker['role']}  cwd={worker['cwd']}")
PY
  sleep 2
done
""",
        encoding="utf-8",
    )
    runner.chmod(0o755)
    return runner
```

Update the end of `cmd_team`:

```python
    manifest["hud"] = None
    if not args.no_hud:
        hud_json_path = session_root / "hud.json"
        write_json(hud_json_path, build_hud_payload(manifest))
        hud_runner = write_hud_runner(session_root)
        run([resolve_cmux_bin(), "new-split", "down", "--workspace", workspace_id, "--surface", anchor_surface], capture=False)
        focused = cmux_json("identify")["focused"]
        hud_surface = focused["surface_ref"]
        run([resolve_cmux_bin(), "rename-tab", "--workspace", workspace_id, "--surface", hud_surface, "hud"], capture=False)
        run([resolve_cmux_bin(), "send", "--workspace", workspace_id, "--surface", hud_surface, f"bash {shlex.quote(str(hud_runner))} {shlex.quote(str(hud_json_path))}\n"], capture=False)
        manifest["hud"] = {
            "surface_ref": hud_surface,
            "pane_ref": focused["pane_ref"],
            "hud_json": str(hud_json_path),
        }
        write_json(hud_json_path, build_hud_payload(manifest))
```

- [ ] **Step 4: Run the smoke test again to verify the HUD lane now records owned HUD state**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
bash tests/cmux-superpowers/team_smoke.sh
```

Expected: the HUD lane passes, `hud.json` exists, and the manifest records a non-null HUD surface.

- [ ] **Step 5: Commit the HUD support**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add scripts/cmux_superpowers_team.py tests/cmux-superpowers/team_smoke.sh
git commit -m "feat: add cmux superpowers hud pane"
```

Expected: commit succeeds with only the HUD task files staged.

## Task 6: Wire Package Validation and Update the Install Docs

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/package.json`
- Modify: `/Users/maxibon/.codex/superpowers/docs/README.codex.md`
- Modify: `/Users/maxibon/.codex/superpowers/.codex/INSTALL.md`

- [ ] **Step 1: Run the failing docs check to prove the new launcher flow is not yet documented**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
rg -n 'cmux-superpowers|install_cmux_superpowers_launcher' docs/README.codex.md .codex/INSTALL.md
```

Expected: exit status `1` because neither doc currently mentions the new launcher.

- [ ] **Step 2: Add the package validation script and update both install docs**

Update the `scripts` block in `/Users/maxibon/.codex/superpowers/package.json` to:

```json
  "scripts": {
    "validate:public-fork": "bash tests/codex-public-fork/run.sh",
    "validate:process-family": "python3 _shared/validators/validate_skill_library.py --root . --family process",
    "validate:cmux-superpowers": "bash tests/cmux-superpowers/install.sh && bash tests/cmux-superpowers/doctor.sh && bash tests/cmux-superpowers/team_smoke.sh"
  }
```

Insert this new section after the existing Codex hook install step in `/Users/maxibon/.codex/superpowers/docs/README.codex.md`:

````md
### 5. Install the local cmux launcher

```bash
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
```

### 6. Restart Codex
````

Add this verification block under `## Verify` in the same file:

````md
Confirm the local launcher is installed and the workstation is ready:

```bash
command -v cmux-superpowers
cmux-superpowers doctor
```
````

Add this usage example under `## Recommended workflow order`:

````md
For a pane-based local team session in cmux, use:

```bash
cmux-superpowers team --worker review --worker implement "Implement the approved plan in this repository"
```
````

Make the same install and verify additions in `/Users/maxibon/.codex/superpowers/.codex/INSTALL.md`, using the same command examples and numbering.

- [ ] **Step 3: Run the docs check, byte-compile the Python scripts, and run the full validation bundle**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
rg -n 'cmux-superpowers|install_cmux_superpowers_launcher' docs/README.codex.md .codex/INSTALL.md
python3 -m py_compile scripts/cmux_superpowers_team.py scripts/install_cmux_superpowers_launcher.py
npm run validate:cmux-superpowers
```

Expected:

- `rg` prints the new launcher references
- `py_compile` exits `0`
- `npm run validate:cmux-superpowers` exits `0`

- [ ] **Step 4: Commit the docs and validation wiring**

Run:

```bash
cd /Users/maxibon/.codex/superpowers
git add package.json docs/README.codex.md .codex/INSTALL.md
git commit -m "docs: add cmux superpowers launcher workflow"
```

Expected: commit succeeds with the docs and package metadata updates staged.

## Self-Review

- [ ] **Spec coverage:** Re-read `/Users/maxibon/.codex/superpowers/docs/superpowers/specs/2026-04-11-cmux-superpowers-team-design.md` and confirm the plan covers:
  - standalone local launcher
  - native cmux orchestration
  - ordinary interactive Codex worker processes
  - hook composition
  - explicit session state under `~/.cmuxterm/superpowers-team/`
  - worktree isolation for write-capable workers
  - `doctor`, `team`, and `cleanup`
  - optional HUD
  - docs and installer updates

- [ ] **Placeholder scan:** Run:

```bash
cd /Users/maxibon/.codex/superpowers
rg -n 'TBD|TODO|placeholder|implement later|similar to Task' docs/superpowers/plans/2026-04-11-cmux-superpowers-team-launcher.md | grep -v "rg -n 'TBD|TODO|placeholder|implement later|similar to Task'"
```

Expected: no matches.

- [ ] **Type and command consistency:** Re-check:
  - `cmux-superpowers` command name is spelled the same in scripts, tests, and docs
  - `CMUX_SUPERPOWERS_CMUX_BIN`, `CMUX_SUPERPOWERS_CODEX_BIN`, `CMUX_SUPERPOWERS_STATE_ROOT`, and `CMUX_SUPERPOWERS_STUB_LOG_DIR` are spelled identically everywhere
  - role names stay exactly `review`, `implement`, and `general`
  - test commands reference the right file paths under `tests/cmux-superpowers/`
