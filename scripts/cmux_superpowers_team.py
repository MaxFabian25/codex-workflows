#!/usr/bin/env python3
from __future__ import annotations

import argparse
import errno
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import uuid
from dataclasses import asdict, dataclass
from datetime import date, datetime, time, timezone
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CODEX_HOME = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
STATE_ROOT = Path(
    os.environ.get("CMUX_SUPERPOWERS_STATE_ROOT")
    or (Path.home() / ".cmuxterm" / "superpowers-team")
)
CMUX_PROBE_TIMEOUT_SECONDS = 0.5
CODEX_PROBE_TIMEOUT_SECONDS = 2.0
NOOP_EXECUTABLES = {"echo", "printf", "true", "false"}
SHELL_COMMAND_BOUNDARIES = {"&&", "||", ";", "then", "do", "elif"}
PYTHON_OPTIONS_WITH_VALUES = {"-W", "-X"}
PYTHON_REJECTED_SCRIPT_MODES = {"-c", "-m", "-"}
EXPECTED_PLUGIN_NAME = "superpowers-codex"
PLUGIN_MANIFEST_RELATIVE_PATH = Path(".codex-plugin") / "plugin.json"
CODEX_ENV_PASSTHROUGH = (
    "CODEX_HOME",
    "CMUX_SUPERPOWERS_HOOK_LOG_DIR",
    "CMUX_SUPERPOWERS_HOOK_CMUX_LOG_DIR",
    "CMUX_SUPERPOWERS_HOOK_SESSIONS_PATH",
)
ROLE_SPECS = {
    "review": {"write": False, "profile": "parallel_readonly"},
    "general": {"write": False, "profile": "workflow_fidelity"},
    "implement": {"write": True, "profile": "workflow_fidelity"},
}
CMUX_RUNNING_STATES = {"Running", "Idle"}
TOML_INTEGER_RE = re.compile(
    r"^[+-]?(?:0|[1-9](?:_?\d)*|0x[0-9A-Fa-f](?:_?[0-9A-Fa-f])*|0o[0-7](?:_?[0-7])*|0b[01](?:_?[01])*)$"
)
TOML_FLOAT_RE = re.compile(
    r"^[+-]?(?:(?:\d(?:_?\d)*)\.\d(?:_?\d)*(?:[eE][+-]?\d(?:_?\d)*)?|(?:\d(?:_?\d)*)(?:[eE][+-]?\d(?:_?\d)*)|inf|nan)$"
)
TOML_LOCAL_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
TOML_LOCAL_TIME_RE = re.compile(r"^\d{2}:\d{2}:\d{2}(?:\.\d+)?$")
TOML_LOCAL_DATETIME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?$")
TOML_OFFSET_DATETIME_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$"
)


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
    worktree_branch: str | None = None
    git_branch: str | None = None
    launcher_state: str | None = None
    cmux_state: str | None = None


class TeamLaunchError(RuntimeError):
    pass


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
    team.add_argument(
        "--worker",
        action="append",
        choices=["review", "implement", "general"],
    )
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


def resolve_binary(env_var: str, fallback: str) -> tuple[str | None, str | None]:
    override = os.environ.get(env_var)
    if override:
        candidate = Path(override).expanduser()
        if not candidate.exists():
            return None, f"{env_var} override not found: {candidate}"
        if not candidate.is_file() or not os.access(candidate, os.X_OK):
            return None, f"{env_var} override is not executable: {candidate}"
        return str(candidate.resolve()), None
    resolved = shutil.which(fallback)
    if resolved is None:
        return None, f"{fallback} not found on PATH"
    return resolved, None


def session_dir(session_id: str) -> Path:
    return STATE_ROOT / session_id


def build_packet(role: str, task: str, cwd: str, write_capable: bool) -> str:
    mode = "write-capable" if write_capable else "read-only"
    if role == "main":
        contract_lines = [
            "- Task scope: coordinate the task above from the main pane.",
            "- Pane lifecycle is owned by the external cmux-superpowers conductor.",
            "- Use Superpowers skills normally.",
        ]
    else:
        contract_lines = [
            f"- Task scope: stay within the {role} role for the task above.",
            f"- Reporting contract: report status and blockers back through the main pane.",
            "- Direct user input: do not ask the user directly; route clarification through the main pane.",
        ]
    return (
        f"# Cmux Superpowers Worker Packet\n\n"
        f"- Role: {role}\n"
        f"- Mode: {mode}\n"
        f"- Working directory: {cwd}\n\n"
        f"## Task\n\n{task}\n\n"
        f"## Contract\n\n"
        f"- You are running inside a cmux-superpowers team session.\n"
        + "\n".join(contract_lines)
        + "\n"
    )


def run(argv: list[str], *, capture: bool = True) -> subprocess.CompletedProcess[str]:
    kwargs = {
        "check": True,
        "text": True,
    }
    if capture:
        kwargs["capture_output"] = True
    return subprocess.run(argv, **kwargs)


def resolve_cmux_bin() -> str:
    path, error = resolve_binary("CMUX_SUPERPOWERS_CMUX_BIN", "cmux")
    if error:
        raise SystemExit(error)
    if path is None:
        raise SystemExit("cmux binary not found")
    return path


def resolve_codex_bin() -> str:
    path, error = resolve_binary("CMUX_SUPERPOWERS_CODEX_BIN", "codex")
    if error:
        raise SystemExit(error)
    if path is None:
        raise SystemExit("codex binary not found")
    return path


def write_packet(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def manifest_hud_json_path(manifest: dict) -> Path | None:
    hud = manifest.get("hud")
    if not isinstance(hud, dict):
        return None
    hud_json = hud.get("hud_json")
    if not isinstance(hud_json, str) or not hud_json:
        return None
    return Path(hud_json)


def cmux_hook_sessions_path() -> Path:
    override = os.environ.get("CMUX_SUPERPOWERS_HOOK_SESSIONS_PATH")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".cmuxterm" / "codex-hook-sessions.json"


def normalize_cmux_ref(value: object, prefix: str) -> str | None:
    if not isinstance(value, str):
        return None
    candidate = value.strip()
    if not candidate:
        return None
    if candidate.startswith(prefix):
        candidate = candidate.removeprefix(prefix)
    return candidate or None


def meaningful_cmux_state(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    candidate = value.strip()
    if candidate in CMUX_RUNNING_STATES:
        return candidate
    return None


def load_cmux_session_states() -> dict[tuple[str, str], str | None]:
    path = cmux_hook_sessions_path()
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict):
        return {}
    sessions = payload.get("sessions")
    if not isinstance(sessions, dict):
        return {}
    states: dict[tuple[str, str], str | None] = {}
    for session in sessions.values():
        if not isinstance(session, dict):
            continue
        workspace_id = normalize_cmux_ref(session.get("workspaceId"), "workspace:")
        surface_id = normalize_cmux_ref(session.get("surfaceId"), "surface:")
        if not workspace_id or not surface_id:
            continue
        states[(workspace_id, surface_id)] = meaningful_cmux_state(
            session.get("lastSubtitle")
        )
    return states


def resolve_cmux_state(
    workspace_id: object,
    surface_ref: object,
    existing_state: object,
    cmux_states: dict[tuple[str, str], str | None],
) -> str | None:
    normalized_workspace_id = normalize_cmux_ref(workspace_id, "workspace:")
    normalized_surface_id = normalize_cmux_ref(surface_ref, "surface:")
    if not normalized_surface_id:
        return existing_state if isinstance(existing_state, str) else None
    if not normalized_workspace_id:
        return None
    return cmux_states.get((normalized_workspace_id, normalized_surface_id))


def git_branch_for_cwd(cwd: object) -> str | None:
    if not isinstance(cwd, str) or not cwd:
        return None
    try:
        proc = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None
    if proc.returncode != 0:
        return None
    branch = proc.stdout.strip()
    return branch or None


def main_launcher_state(main: dict[str, object]) -> str:
    surface_ref = main.get("surface_ref")
    if isinstance(surface_ref, str) and surface_ref:
        return "active"
    return "closed"


def worker_launcher_state(worker: dict[str, object]) -> str:
    surface_ref = worker.get("surface_ref")
    if isinstance(surface_ref, str) and surface_ref:
        return "active"
    worktree_path = worker.get("worktree_path")
    worktree_branch = worker.get("worktree_branch")
    if isinstance(worktree_path, str) and worktree_path:
        return "worktree_only"
    if isinstance(worktree_branch, str) and worktree_branch:
        return "branch_only"
    return "closed"


def refresh_manifest_runtime_fields(manifest: dict) -> None:
    workspace_id = manifest.get("workspace_id")
    cmux_states = load_cmux_session_states()
    main = manifest.get("main")
    if isinstance(main, dict):
        main["git_branch"] = git_branch_for_cwd(main.get("cwd"))
        main["launcher_state"] = main_launcher_state(main)
        main["cmux_state"] = resolve_cmux_state(
            workspace_id,
            main.get("surface_ref"),
            main.get("cmux_state"),
            cmux_states,
        )

    workers = manifest.get("workers")
    if not isinstance(workers, list):
        return
    for worker in workers:
        if not isinstance(worker, dict):
            continue
        worktree_branch = worker.get("worktree_branch")
        if isinstance(worktree_branch, str) and worktree_branch:
            worker["git_branch"] = worktree_branch
        else:
            worker["git_branch"] = git_branch_for_cwd(worker.get("cwd"))
        worker["launcher_state"] = worker_launcher_state(worker)
        worker["cmux_state"] = resolve_cmux_state(
            workspace_id,
            worker.get("surface_ref"),
            worker.get("cmux_state"),
            cmux_states,
        )


def persist_manifest(manifest_path: Path, manifest: dict) -> None:
    refresh_manifest_runtime_fields(manifest)
    write_json(manifest_path, manifest)
    hud_json_path = manifest_hud_json_path(manifest)
    if hud_json_path is not None:
        write_json(hud_json_path, build_hud_payload(manifest))


def build_hud_payload(manifest: dict) -> dict:
    main = manifest["main"]
    return {
        "session_id": manifest["session_id"],
        "workspace_id": manifest["workspace_id"],
        "main": dict(main),
        "workers": [dict(worker) for worker in manifest["workers"]],
    }


def write_hud_runner(session_root: Path) -> Path:
    runner = session_root / "hud_runner.sh"
    runner.write_text(
        """#!/usr/bin/env bash
set -euo pipefail

HUD_JSON="${1:?hud json path is required}"

while true; do
  printf '\\033[2J\\033[H'
  python3 - <<'PY' "$HUD_JSON"
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(f"Session: {payload['session_id']}")
print(f"Workspace: {payload['workspace_id']}")
main = payload.get("main", {})
print(
    f"Main: pane={main.get('pane_ref')} surface={main.get('surface_ref')} cwd={main.get('cwd')} "
    f"branch={main.get('git_branch')} state={main.get('launcher_state')} cmux={main.get('cmux_state')}"
)
print("")
for worker in payload.get("workers", []):
    print(
        f"{worker['worker_id']}  role={worker['role']}  "
        f"pane={worker.get('pane_ref')}  surface={worker.get('surface_ref')}  "
        f"branch={worker.get('git_branch')}  state={worker.get('launcher_state')}  cmux={worker.get('cmux_state')}"
    )
    print(f"  cwd={worker['cwd']}")
    print(f"  worktree={worker.get('worktree_path')}")
PY
  sleep 2
done
""",
        encoding="utf-8",
    )
    runner.chmod(0o755)
    return runner


def worker_state_path(session_root: str | Path, worker_id: str) -> Path:
    return Path(session_root) / "workers" / f"{worker_id}.json"


def write_worker_state_json(session_root: str | Path, worker_payload: dict) -> None:
    worker_id = worker_payload.get("worker_id")
    if not isinstance(worker_id, str) or not worker_id:
        raise ValueError("worker payload missing worker_id")
    write_json(worker_state_path(session_root, worker_id), worker_payload)


def session_manifest(
    session_id: str,
    created_at: str,
    session_root: Path,
    workspace_id: str | None,
    main_packet: Path,
    cwd: str,
    workers: list[WorkerPlan],
    *,
    main_pane: str | None = None,
    main_surface: str | None = None,
) -> dict:
    return {
        "session_id": session_id,
        "created_at": created_at,
        "workspace_id": workspace_id,
        "session_root": str(session_root),
        "main": {
            "pane_ref": main_pane,
            "surface_ref": main_surface,
            "packet_path": str(main_packet),
            "cwd": cwd,
            "git_branch": None,
            "launcher_state": None,
            "cmux_state": None,
        },
        "workers": [asdict(worker) for worker in workers],
        "hud": None,
        "cleanup": {"status": "active"},
    }


def persist_manifest_workers(
    manifest_path: Path, manifest: dict, workers: list[WorkerPlan]
) -> None:
    manifest["workers"] = [asdict(worker) for worker in workers]
    persist_manifest(manifest_path, manifest)
    session_root = manifest.get("session_root")
    if not isinstance(session_root, str) or not session_root:
        raise ValueError("manifest missing session_root")
    for worker_payload in manifest["workers"]:
        if not isinstance(worker_payload, dict):
            raise ValueError("manifest workers must be JSON objects")
        write_worker_state_json(session_root, worker_payload)


def persist_manifest_worker(
    manifest_path: Path, manifest: dict, worker_payload: dict
) -> None:
    persist_manifest(manifest_path, manifest)
    session_root = manifest.get("session_root")
    if not isinstance(session_root, str) or not session_root:
        raise ValueError("manifest missing session_root")
    write_worker_state_json(session_root, worker_payload)


def matching_worker_plan(
    workers: list[WorkerPlan], worktree_path: str, worktree_branch: str
) -> WorkerPlan | None:
    for worker in workers:
        if worker.worktree_path == worktree_path and worker.worktree_branch == worktree_branch:
            return worker
    return None


def load_hooks_json(codex_home: Path) -> dict:
    hooks_path = codex_home / "hooks.json"
    if not hooks_path.exists():
        return {"hooks": {}}
    with hooks_path.open(encoding="utf-8") as fh:
        payload = json.load(fh)
    if not isinstance(payload, dict):
        raise ValueError(f"{hooks_path} must contain a JSON object")
    if "hooks" not in payload:
        payload["hooks"] = {}
        return payload
    hooks = payload.get("hooks")
    if not isinstance(hooks, dict):
        raise ValueError(f"{hooks_path} field 'hooks' must be a JSON object")
    for event_name, groups in hooks.items():
        if not isinstance(groups, list):
            raise ValueError(f"{hooks_path} hook '{event_name}' must be a JSON array")
        for index, group in enumerate(groups):
            if not isinstance(group, dict):
                raise ValueError(
                    f"{hooks_path} hook '{event_name}' group {index} must be a JSON object"
                )
            if "matcher" in group and not isinstance(group.get("matcher"), str):
                raise ValueError(
                    f"{hooks_path} hook '{event_name}' group {index} field 'matcher' must be a JSON string"
                )
            if "hooks" not in group:
                raise ValueError(
                    f"{hooks_path} hook '{event_name}' group {index} field 'hooks' is required"
                )
            nested_hooks = group.get("hooks")
            if not isinstance(nested_hooks, list):
                raise ValueError(
                    f"{hooks_path} hook '{event_name}' group {index} field 'hooks' must be a JSON array"
                )
            for hook_index, hook in enumerate(nested_hooks):
                if not isinstance(hook, dict):
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} must be a JSON object"
                    )
                if "type" not in hook:
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} field 'type' is required"
                    )
                if not isinstance(hook.get("type"), str):
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} field 'type' must be a JSON string"
                    )
                hook_type = hook.get("type")
                if hook_type == "command" and "command" not in hook:
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} field 'command' is required"
                    )
                if "command" in hook and not isinstance(hook.get("command"), str):
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} field 'command' must be a JSON string"
                    )
                command = hook.get("command")
                if "statusMessage" in hook and not isinstance(hook.get("statusMessage"), str):
                    raise ValueError(
                        f"{hooks_path} hook '{event_name}' group {index} hook {hook_index} field 'statusMessage' must be a JSON string"
                    )
    validate_superpowers_session_start_hooks(payload, hooks_path)
    return payload


def is_hooks_session_start_path(token: str) -> bool:
    path = Path(token)
    return path.name == "session-start" and path.parent.name == "hooks"


def python_script_target(tokens: list[str]) -> str | None:
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token in PYTHON_REJECTED_SCRIPT_MODES:
            return None
        if token in PYTHON_OPTIONS_WITH_VALUES:
            index += 2
            continue
        if token.startswith("-W") or token.startswith("-X"):
            index += 1
            continue
        if token.startswith("-"):
            index += 1
            continue
        return token
    return None


def session_start_target_path(command: object) -> Path | None:
    if not isinstance(command, str):
        return None
    if "__SUPERPOWERS_" in command.upper():
        return None
    try:
        tokens = shlex.split(command)
    except ValueError:
        return None
    if not tokens:
        return None
    executable = Path(tokens[0]).name
    if executable in NOOP_EXECUTABLES:
        return None
    if is_hooks_session_start_path(tokens[0]):
        return Path(tokens[0]).expanduser()
    if not executable.startswith("python"):
        return None
    script_target = python_script_target(tokens)
    if not isinstance(script_target, str) or not is_hooks_session_start_path(script_target):
        return None
    return Path(script_target).expanduser()


def is_real_superpowers_session_start_command(command: object) -> bool:
    return session_start_target_path(command) is not None


def superpowers_plugin_root_for_target(target_path: Path | None) -> Path | None:
    if not isinstance(target_path, Path) or not target_path.is_file():
        return None
    repo_root = target_path.parent.parent.resolve(strict=False)
    manifest_path = repo_root / PLUGIN_MANIFEST_RELATIVE_PATH
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return None
    if not isinstance(payload, dict):
        return None
    if payload.get("name") != EXPECTED_PLUGIN_NAME:
        return None
    return repo_root


def is_owned_superpowers_session_start_command(command: object) -> bool:
    target_path = session_start_target_path(command)
    return superpowers_plugin_root_for_target(target_path) is not None


def iter_session_start_command_hooks(payload: dict):
    session_start = payload.get("hooks", {}).get("SessionStart", [])
    if not isinstance(session_start, list):
        return
    for group_index, group in enumerate(session_start):
        if not isinstance(group, dict) or group.get("matcher") != "startup|resume|clear":
            continue
        hooks = group.get("hooks", [])
        if not isinstance(hooks, list):
            continue
        for hook_index, hook in enumerate(hooks):
            if not isinstance(hook, dict) or hook.get("type") != "command":
                continue
            command = hook.get("command")
            if is_real_superpowers_session_start_command(command):
                yield group_index, hook_index, hook


def validate_superpowers_session_start_hooks(payload: dict, hooks_path: Path) -> None:
    candidates = list(iter_session_start_command_hooks(payload))
    if not candidates:
        return
    if any(hook.get("statusMessage") == "loading superpowers" for _, _, hook in candidates):
        return
    for group_index, hook_index, hook in candidates:
        if "statusMessage" not in hook:
            raise ValueError(
                f"{hooks_path} hook 'SessionStart' group {group_index} hook {hook_index} field 'statusMessage' is required"
            )


def has_superpowers_group(payload: dict) -> bool:
    for _, _, hook in iter_session_start_command_hooks(payload):
        if hook.get("statusMessage") != "loading superpowers":
            continue
        command = hook.get("command")
        if not is_owned_superpowers_session_start_command(command):
            continue
        return True
    return False


def normalize_shell_token(token: str) -> str:
    return token.rstrip(";")


def contains_command_invocation(command: object, executable: str, expected_args: list[str]) -> bool:
    if not isinstance(command, str):
        return False
    try:
        tokens = shlex.split(command)
    except ValueError:
        return False
    if not tokens:
        return False
    normalized_tokens = [normalize_shell_token(token) for token in tokens]
    for index, token in enumerate(normalized_tokens):
        if Path(token).name != executable:
            continue
        invocation_index = index
        if index > 0 and normalized_tokens[index - 1] == "command":
            invocation_index = index - 1
        if invocation_index > 0 and normalized_tokens[invocation_index - 1] not in SHELL_COMMAND_BOUNDARIES:
            continue
        if normalized_tokens[index + 1 : index + 1 + len(expected_args)] == expected_args:
            return True
    return False


def has_cmux_codex_hooks(payload: dict) -> bool:
    hook_map = payload.get("hooks", {})
    if not isinstance(hook_map, dict):
        return False
    required = {
        "SessionStart": ["codex-hook", "session-start"],
        "UserPromptSubmit": ["codex-hook", "prompt-submit"],
        "Stop": ["codex-hook", "stop"],
    }
    for event_name, expected_args in required.items():
        groups = hook_map.get(event_name, [])
        if not isinstance(groups, list):
            return False
        found = False
        for group in groups:
            hooks = group.get("hooks", []) if isinstance(group, dict) else []
            if not isinstance(hooks, list):
                continue
            for hook in hooks:
                if not isinstance(hook, dict) or hook.get("type") != "command":
                    continue
                command = hook.get("command")
                if contains_command_invocation(command, "cmux", expected_args):
                    found = True
                    break
            if found:
                break
        if not found:
            return False
    return True


def run_command(
    command: list[str], timeout_seconds: float
) -> tuple[subprocess.CompletedProcess[str] | None, str | None]:
    try:
        return (
            subprocess.run(
                command,
                check=False,
                capture_output=True,
                text=True,
                timeout=timeout_seconds,
            ),
            None,
        )
    except subprocess.TimeoutExpired:
        return None, f"timeout after {timeout_seconds:.1f}s"
    except OSError as exc:
        return None, f"launch failed: {exc}"


def probe_failure_detail(proc: subprocess.CompletedProcess[str]) -> str | None:
    detail = (proc.stderr or "").strip() or (proc.stdout or "").strip()
    if not detail:
        return None
    compact = " ".join(detail.split())
    if len(compact) > 160:
        return compact[:157] + "..."
    return compact


def probe_binary(
    binary: str | None, args: list[str], timeout_seconds: float
) -> tuple[bool, str | None]:
    if not binary:
        return False, None
    proc, error = run_command([binary, *args], timeout_seconds)
    if error:
        return False, error
    if proc is None:
        return False, None
    if proc.returncode != 0:
        detail = probe_failure_detail(proc)
        if detail:
            return False, f"probe exit {proc.returncode}: {detail}"
        return False, f"probe exit {proc.returncode}"
    return True, None


def probe_codex_binary(binary: str | None) -> tuple[bool, str | None]:
    return probe_binary(binary, ["--version"], CODEX_PROBE_TIMEOUT_SECONDS)


def probe_codex_features(binary: str | None) -> tuple[bool, bool, str | None]:
    if not binary:
        return False, False, None
    proc, error = run_command([binary, "features", "list"], CODEX_PROBE_TIMEOUT_SECONDS)
    if error:
        return False, False, error
    if proc is None:
        return False, False, error
    if proc.returncode != 0:
        detail = probe_failure_detail(proc)
        if detail:
            return False, False, f"probe exit {proc.returncode}: {detail}"
        return False, False, f"probe exit {proc.returncode}"
    for line in proc.stdout.splitlines():
        parts = line.split()
        if parts and parts[0] == "codex_hooks":
            return True, parts[-1].lower() == "true", None
    return True, False, None


def config_codex_hooks_setting(codex_home: Path) -> tuple[bool | None, str | None]:
    config_path = codex_home / "config.toml"
    try:
        text = config_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None, None
    except OSError as exc:
        return None, f"{config_path}: {exc}"

    if os.environ.get("CMUX_SUPERPOWERS_FORCE_MANUAL_CONFIG_PARSER") == "1":
        return config_codex_hooks_setting_manual(config_path, text)

    if tomllib is not None:
        return config_codex_hooks_setting_from_payload(
            config_path,
            load_toml_payload(config_path, text),
        )

    helper_result = config_codex_hooks_setting_via_helper(config_path)
    if helper_result is not None:
        return helper_result

    return config_codex_hooks_setting_manual(config_path, text)


def load_toml_payload(
    config_path: Path, text: str
) -> tuple[dict[str, object] | None, str | None]:
    if tomllib is None:
        return None, "tomllib unavailable"
    try:
        payload = tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        return None, f"{config_path}: {exc}"
    if not isinstance(payload, dict):
        return None, f"{config_path}: top-level TOML payload must be a table"
    return payload, None


def config_codex_hooks_setting_from_payload(
    config_path: Path, payload_result: tuple[dict[str, object] | None, str | None]
) -> tuple[bool | None, str | None]:
    payload, error = payload_result
    if error:
        return None, error
    if payload is None:
        return None, f"{config_path}: top-level TOML payload must be a table"
    features = payload.get("features")
    if isinstance(features, dict):
        value = features.get("codex_hooks")
        if isinstance(value, bool):
            return value, None
        if value is not None:
            return None, f"{config_path}: [features].codex_hooks must be a boolean"
    elif features is not None:
        return None, f"{config_path}: 'features' must be a table"
    return None, None


def helper_python_binaries() -> list[str]:
    candidates: list[str] = []
    seen: set[str] = set()
    for candidate in (shutil.which("python3"), shutil.which("python"), sys.executable):
        if not candidate:
            continue
        resolved = str(Path(candidate).expanduser())
        if resolved in seen:
            continue
        seen.add(resolved)
        candidates.append(resolved)
    return candidates


def config_codex_hooks_setting_via_helper(
    config_path: Path,
) -> tuple[bool | None, str | None] | None:
    if os.environ.get("CMUX_SUPERPOWERS_DISABLE_CONFIG_HELPER") == "1":
        return None
    helper_script = """
import json
import sys

try:
    import tomllib
except ModuleNotFoundError:
    print(json.dumps({"status": "no_tomllib"}))
    raise SystemExit(3)

config_path = sys.argv[1]
text = open(config_path, encoding="utf-8").read()
try:
    payload = tomllib.loads(text)
except tomllib.TOMLDecodeError as exc:
    print(json.dumps({"status": "parse_error", "error": str(exc)}))
    raise SystemExit(2)

features = payload.get("features")
if isinstance(features, dict):
    value = features.get("codex_hooks")
    if isinstance(value, bool):
        print(json.dumps({"status": "ok", "value": value}))
        raise SystemExit(0)
    if value is not None:
        print(json.dumps({"status": "type_error", "error": "[features].codex_hooks must be a boolean"}))
        raise SystemExit(4)
elif features is not None:
    print(json.dumps({"status": "type_error", "error": "'features' must be a table"}))
    raise SystemExit(4)

print(json.dumps({"status": "ok", "value": None}))
"""
    for helper_bin in helper_python_binaries():
        proc, error = run_command([helper_bin, "-c", helper_script, str(config_path)], 2.0)
        if error or proc is None:
            continue
        try:
            payload = json.loads(proc.stdout or "{}")
        except json.JSONDecodeError:
            continue
        status = payload.get("status")
        if proc.returncode == 0 and status == "ok":
            value = payload.get("value")
            if isinstance(value, bool):
                return value, None
            if value is None:
                return None, None
            continue
        if proc.returncode == 2 and status == "parse_error":
            detail = payload.get("error")
            return None, f"{config_path}: {detail or 'invalid TOML'}"
        if proc.returncode == 4 and status == "type_error":
            detail = payload.get("error")
            return None, f"{config_path}: {detail or 'invalid features table'}"
        if proc.returncode == 3 and status == "no_tomllib":
            continue
    return None


def config_codex_hooks_setting_manual(
    config_path: Path, text: str
) -> tuple[bool | None, str | None]:
    current_section: str | None = None
    parsed_value: bool | None = None
    pending_lines: list[str] = []
    multiline_quote: str | None = None
    seen_sections: set[str] = set()
    seen_tables: set[str] = set()
    seen_keys: set[tuple[str, str]] = set()
    for raw_line in text.splitlines():
        line, multiline_quote, line_error = strip_toml_comment(raw_line, multiline_quote)
        if line_error:
            return None, f"{config_path}: {line_error}"
        if not line:
            if pending_lines:
                pending_lines.append("")
            continue
        if not pending_lines and line.startswith("["):
            if not line.endswith("]"):
                return None, f"{config_path}: invalid table header"
            current_section = line[1:-1].strip()
            if current_section in seen_tables:
                return None, f"{config_path}: duplicate table [{current_section}]"
            seen_tables.add(current_section)
            seen_sections.add(current_section)
            continue
        candidate_lines = [*pending_lines, line]
        candidate = "\n".join(candidate_lines)
        fragment_complete, fragment_error = toml_fragment_complete(candidate)
        if fragment_error:
            return None, f"{config_path}: {fragment_error}"
        if not fragment_complete:
            pending_lines = candidate_lines
            continue
        pending_lines = []
        if "=" not in candidate:
            return None, f"{config_path}: invalid TOML statement"
        key, raw_value = (part.strip() for part in candidate.split("=", 1))
        value_error = validate_toml_value(raw_value)
        if value_error:
            return None, f"{config_path}: {value_error}"
        if current_section is None and key.startswith("features."):
            if "features" in seen_sections:
                return None, f"{config_path}: duplicate table [features]"
            seen_tables.add("features")
            normalized_key = key.removeprefix("features.")
            key_ref = ("features", normalized_key)
            if key_ref in seen_keys:
                return None, f"{config_path}: duplicate key features.{normalized_key}"
            seen_keys.add(key_ref)
            if normalized_key == "codex_hooks":
                if raw_value == "true":
                    parsed_value = True
                    continue
                if raw_value == "false":
                    parsed_value = False
                    continue
                return None, f"{config_path}: [features].codex_hooks must be a boolean"
            continue
        if current_section is None and key == "features":
            if "features" in seen_tables:
                return None, f"{config_path}: duplicate table [features]"
            seen_tables.add("features")
            seen_sections.add("features")
            if raw_value.startswith("{") and raw_value.endswith("}"):
                inline_result, inline_error = inline_features_codex_hooks(raw_value, config_path)
                if inline_error:
                    return None, inline_error
                if inline_result is not None:
                    key_ref = ("features", "codex_hooks")
                    if key_ref in seen_keys:
                        return None, f"{config_path}: duplicate key features.codex_hooks"
                    seen_keys.add(key_ref)
                    parsed_value = inline_result
                continue
            return None, f"{config_path}: 'features' must be a table"
        scope = current_section or ""
        key_ref = (scope, key)
        if key_ref in seen_keys:
            qualified_key = f"{scope}.{key}" if scope else key
            return None, f"{config_path}: duplicate key {qualified_key}"
        seen_keys.add(key_ref)
        if current_section == "features" and key == "codex_hooks":
            if raw_value == "true":
                parsed_value = True
                continue
            if raw_value == "false":
                parsed_value = False
                continue
            return None, f"{config_path}: [features].codex_hooks must be a boolean"
    if multiline_quote is not None:
        return None, f"{config_path}: unterminated string"
    if pending_lines:
        return None, f"{config_path}: unbalanced delimiters"
    return parsed_value, None


def inline_features_codex_hooks(
    raw_value: str, config_path: Path
) -> tuple[bool | None, str | None]:
    body = raw_value[1:-1].strip()
    if not body:
        return None, None
    entries, split_error = split_toml_top_level(body)
    if split_error:
        return None, f"{config_path}: {split_error}"
    for entry in entries:
        item = entry.strip()
        if not item:
            return None, f"{config_path}: invalid inline table"
        if "=" not in item:
            return None, f"{config_path}: invalid inline table"
        key, value = (part.strip() for part in item.split("=", 1))
        if key != "codex_hooks":
            continue
        if value == "true":
            return True, None
        if value == "false":
            return False, None
        return None, f"{config_path}: [features].codex_hooks must be a boolean"
    return None, None


def strip_toml_comment(
    raw_line: str, multiline_quote: str | None = None
) -> tuple[str, str | None, str | None]:
    tokens: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    index = 0
    while index < len(raw_line):
        if multiline_quote is not None:
            if raw_line.startswith(multiline_quote, index):
                tokens.append(multiline_quote)
                index += 3
                multiline_quote = None
                continue
            tokens.append(raw_line[index])
            index += 1
            continue
        if raw_line.startswith('"""', index) or raw_line.startswith("'''", index):
            multiline_quote = raw_line[index : index + 3]
            tokens.append(multiline_quote)
            index += 3
            continue
        char = raw_line[index]
        if escaped:
            tokens.append(char)
            escaped = False
            index += 1
            continue
        if char == "\\" and in_double:
            tokens.append(char)
            escaped = True
            index += 1
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            tokens.append(char)
            index += 1
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            tokens.append(char)
            index += 1
            continue
        if char == "#" and not in_single and not in_double:
            break
        tokens.append(char)
        index += 1
    if escaped or in_single or in_double:
        return "", multiline_quote, "unterminated string"
    return "".join(tokens).strip(), multiline_quote, None


def split_toml_top_level(text: str) -> tuple[list[str], str | None]:
    parts: list[str] = []
    current: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    brace_depth = 0
    bracket_depth = 0
    paren_depth = 0
    for char in text:
        if escaped:
            current.append(char)
            escaped = False
            continue
        if char == "\\" and in_double:
            current.append(char)
            escaped = True
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            current.append(char)
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            current.append(char)
            continue
        if not in_single and not in_double:
            if char == "{":
                brace_depth += 1
            elif char == "}":
                brace_depth -= 1
            elif char == "[":
                bracket_depth += 1
            elif char == "]":
                bracket_depth -= 1
            elif char == "(":
                paren_depth += 1
            elif char == ")":
                paren_depth -= 1
            if brace_depth < 0 or bracket_depth < 0 or paren_depth < 0:
                return [], "unbalanced delimiters"
            elif (
                char == ","
                and brace_depth == 0
                and bracket_depth == 0
                and paren_depth == 0
            ):
                parts.append("".join(current))
                current = []
                continue
        current.append(char)
    if escaped or in_single or in_double:
        return [], "unterminated string"
    if brace_depth != 0 or bracket_depth != 0 or paren_depth != 0:
        return [], "unbalanced delimiters"
    parts.append("".join(current))
    return parts, None


def toml_fragment_complete(text: str) -> tuple[bool, str | None]:
    in_single = False
    in_double = False
    multiline_quote: str | None = None
    escaped = False
    brace_depth = 0
    bracket_depth = 0
    paren_depth = 0
    index = 0
    while index < len(text):
        if multiline_quote is not None:
            if text.startswith(multiline_quote, index):
                index += 3
                multiline_quote = None
                continue
            index += 1
            continue
        if text.startswith('"""', index) or text.startswith("'''", index):
            multiline_quote = text[index : index + 3]
            index += 3
            continue
        char = text[index]
        if escaped:
            escaped = False
            index += 1
            continue
        if char == "\\" and in_double:
            escaped = True
            index += 1
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            index += 1
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            index += 1
            continue
        if in_single or in_double:
            index += 1
            continue
        if char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth -= 1
        elif char == "[":
            bracket_depth += 1
        elif char == "]":
            bracket_depth -= 1
        elif char == "(":
            paren_depth += 1
        elif char == ")":
            paren_depth -= 1
        if brace_depth < 0 or bracket_depth < 0 or paren_depth < 0:
            return False, "unbalanced delimiters"
        index += 1
    if escaped or in_single or in_double:
        return False, "unterminated string"
    if multiline_quote is not None:
        return False, None
    return brace_depth == 0 and bracket_depth == 0 and paren_depth == 0, None


def validate_toml_value(raw_value: str) -> str | None:
    value = raw_value.strip()
    if not value:
        return "missing value"
    complete, error = toml_fragment_complete(value)
    if error:
        return error
    if not complete:
        return None
    if value.startswith("{") and value.endswith("}"):
        entries, split_error = split_toml_top_level(value[1:-1].strip())
        if split_error:
            return split_error
        if any(not entry.strip() for entry in entries):
            return "invalid inline table"
        return None
    if value.startswith("[") and value.endswith("]"):
        return None
    string_end = toml_string_end(value)
    if string_end is not None:
        if value[string_end:].strip():
            return "invalid TOML value"
        return None
    if value in {"true", "false", "inf", "+inf", "-inf", "nan", "+nan", "-nan"}:
        return None
    if is_toml_numeric_literal(value):
        return None
    if is_toml_datetime_literal(value):
        return None
    return "invalid TOML value"


def toml_string_end(value: str) -> int | None:
    if value.startswith('"""') or value.startswith("'''"):
        delimiter = value[:3]
        index = 3
        while index < len(value):
            if value.startswith(delimiter, index):
                return index + 3
            index += 1
        return None
    if value.startswith('"'):
        index = 1
        escaped = False
        while index < len(value):
            char = value[index]
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                return index + 1
            index += 1
        return None
    if value.startswith("'"):
        index = 1
        while index < len(value):
            if value[index] == "'":
                return index + 1
            index += 1
        return None
    return None


def is_toml_numeric_literal(value: str) -> bool:
    return bool(TOML_INTEGER_RE.fullmatch(value) or TOML_FLOAT_RE.fullmatch(value))


def is_toml_datetime_literal(value: str) -> bool:
    try:
        if TOML_OFFSET_DATETIME_RE.fullmatch(value):
            datetime.fromisoformat(value[:-1] + "+00:00" if value.endswith("Z") else value)
            return True
        if TOML_LOCAL_DATETIME_RE.fullmatch(value):
            datetime.fromisoformat(value)
            return True
        if TOML_LOCAL_DATE_RE.fullmatch(value):
            date.fromisoformat(value)
            return True
        if TOML_LOCAL_TIME_RE.fullmatch(value):
            time.fromisoformat(value)
            return True
    except ValueError:
        return False
    return False


def launcher_on_path() -> bool:
    return shutil.which("cmux-superpowers") is not None


def doctor_payload() -> dict:
    codex_home = DEFAULT_CODEX_HOME.expanduser().resolve()
    cmux_bin, cmux_resolve_error = resolve_binary("CMUX_SUPERPOWERS_CMUX_BIN", "cmux")
    codex_bin, codex_resolve_error = resolve_binary("CMUX_SUPERPOWERS_CODEX_BIN", "codex")
    errors: dict[str, str] = {}

    try:
        hooks_payload = load_hooks_json(codex_home)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        hooks_payload = {"hooks": {}}
        errors["hooks"] = str(exc)

    if cmux_resolve_error:
        errors["cmux"] = cmux_resolve_error
    if codex_resolve_error:
        errors["codex"] = codex_resolve_error

    cmux_ok, cmux_error = probe_binary(cmux_bin, ["version"], CMUX_PROBE_TIMEOUT_SECONDS)
    codex_ok, codex_error = probe_codex_binary(codex_bin)
    if cmux_error:
        errors["cmux"] = cmux_error
    if codex_error:
        errors["codex"] = codex_error
    config_value, config_error = config_codex_hooks_setting(codex_home)
    if config_error:
        codex_hooks_ok = False
    elif config_value is not None:
        codex_hooks_ok = config_value
    else:
        _, codex_hooks_ok, codex_feature_error = probe_codex_features(codex_bin)
        if codex_feature_error and "codex" not in errors:
            errors["codex"] = codex_feature_error
    if config_error:
        errors["config"] = config_error

    payload = {
        "cmux": {"path": cmux_bin, "ok": cmux_ok},
        "codex": {"path": codex_bin, "ok": codex_ok},
        "codex_home": str(codex_home),
        "hooks": {
            "superpowers_sessionstart": has_superpowers_group(hooks_payload),
            "cmux_codex": has_cmux_codex_hooks(hooks_payload),
        },
        "codex_hooks_enabled": codex_hooks_ok,
        "launcher_on_path": launcher_on_path(),
        "errors": errors,
    }
    payload["ok"] = (
        payload["cmux"]["ok"]
        and payload["codex"]["ok"]
        and payload["hooks"]["superpowers_sessionstart"]
        and payload["hooks"]["cmux_codex"]
        and payload["codex_hooks_enabled"]
        and payload["launcher_on_path"]
        and not payload["errors"]
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


def cmux_json(*args: str) -> dict:
    proc = run([resolve_cmux_bin(), *args])
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise TeamLaunchError(f"invalid cmux JSON: {exc}") from exc


def cmux_text(*args: str) -> str:
    return run([resolve_cmux_bin(), *args]).stdout.strip()


def git_text(*args: str, cwd: str) -> str:
    return run(["git", "-C", cwd, *args]).stdout.strip()


def repo_root_for(cwd: str) -> str:
    return git_text("rev-parse", "--show-toplevel", cwd=cwd)


def choose_worktree_root(repo_root: str) -> Path:
    for rel in [".worktrees/", "worktrees/"]:
        probe = subprocess.run(
            ["git", "-C", repo_root, "check-ignore", "-q", rel],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if probe.returncode == 0:
            root = Path(repo_root) / rel.removesuffix("/") / "cmux-superpowers"
            root.mkdir(parents=True, exist_ok=True)
            return root
    raise SystemExit("Write-capable workers require an ignored .worktrees/ or worktrees/ directory.")


def map_worktree_cwd(base_cwd: str, repo_root: str, worktree_path: Path) -> str:
    repo_root_path = Path(repo_root).resolve()
    base_cwd_path = Path(base_cwd).resolve()
    worktree_root = worktree_path.resolve()
    try:
        relative_cwd = base_cwd_path.relative_to(repo_root_path)
    except ValueError as exc:
        raise SystemExit(
            "Write-capable worker cwd must stay within the repo root."
        ) from exc
    mapped_cwd = (worktree_root / relative_cwd).resolve()
    try:
        mapped_cwd.relative_to(worktree_root)
    except ValueError as exc:
        raise SystemExit(
            "Write-capable worker cwd resolved outside the isolated worktree."
        ) from exc
    try:
        mapped_cwd.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise SystemExit(f"Write-capable worker cwd could not be prepared: {exc}") from exc
    if not mapped_cwd.is_dir():
        raise SystemExit("Write-capable worker cwd is not a directory.")
    return str(mapped_cwd)


def prepare_worker_root(
    base_cwd: str, session_id: str, worker_id: str, write_capable: bool
) -> tuple[str, str | None, str | None]:
    if not write_capable:
        return base_cwd, None, None
    repo_root = repo_root_for(base_cwd)
    worktree_root = choose_worktree_root(repo_root)
    branch = f"cmux-superpowers/{session_id}-{worker_id}"
    path = worktree_root / f"{session_id}-{worker_id}"
    run(["git", "-C", repo_root, "worktree", "add", "-b", branch, str(path)])
    return map_worktree_cwd(base_cwd, repo_root, path), str(path), branch


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def first_ref(text: str, prefix: str) -> str:
    for token in text.split():
        if token.startswith(prefix):
            return token
    raise TeamLaunchError(f"missing {prefix} ref in cmux output: {text}")


def refs_from_text(text: str, prefix: str) -> list[str]:
    refs: list[str] = []
    seen: set[str] = set()
    for token in text.split():
        if not token.startswith(prefix):
            continue
        if token in seen:
            continue
        seen.add(token)
        refs.append(token)
    return refs


def workspace_refs_from_listing(text: str) -> set[str]:
    refs: set[str] = set()
    for raw_line in text.splitlines():
        try:
            refs.add(first_ref(raw_line, "workspace:"))
        except TeamLaunchError:
            continue
    return refs


def workspace_lines_from_listing(text: str) -> dict[str, str]:
    lines: dict[str, str] = {}
    for raw_line in text.splitlines():
        try:
            lines[first_ref(raw_line, "workspace:")] = raw_line
        except TeamLaunchError:
            continue
    return lines


def has_alnum_token(token: str) -> bool:
    return any(char.isalnum() for char in token)


def workspace_session_marker(session_id: str) -> str:
    return f"sp-{session_id.removeprefix('session-')}"


def workspace_name_for_session(session_marker: str, requested_label: str | None) -> str:
    return session_marker


def workspace_display_name(raw_line: str, workspace_ref: str) -> str:
    _, suffix = raw_line.split(workspace_ref, 1)
    tokens = suffix.split()
    while tokens and tokens[-1] == "[selected]":
        tokens.pop()
    while tokens and not has_alnum_token(tokens[0]):
        tokens.pop(0)
    return " ".join(tokens)


def workspace_display_matches_expected_name(display_name: str, expected_name: str) -> bool:
    if not display_name:
        return False
    return display_name == expected_name


def validate_workspace_ref_name(
    workspace_ref: str, expected_workspace_name: str
) -> str | None:
    try:
        listing = cmux_text("list-workspaces")
    except BaseException as exc:
        if isinstance(exc, KeyboardInterrupt):
            raise
        return launch_failure_detail(exc)
    raw_line = workspace_lines_from_listing(listing).get(workspace_ref)
    if raw_line is None:
        return f"workspace {workspace_ref} not present in cmux list-workspaces"
    display_name = workspace_display_name(raw_line, workspace_ref)
    if workspace_display_matches_expected_name(display_name, expected_workspace_name):
        return None
    return (
        "workspace display does not match expected session workspace name: "
        f"recovered {workspace_ref} as {display_name!r} for expected {expected_workspace_name!r}"
    )


def snapshot_workspace_refs() -> tuple[set[str] | None, str | None]:
    try:
        return workspace_refs_from_listing(cmux_text("list-workspaces")), None
    except BaseException as exc:
        if isinstance(exc, KeyboardInterrupt):
            raise
        return None, launch_failure_detail(exc)


def recover_workspace_ref_by_delta(
    refs_before_launch: set[str] | None,
    refs_before_error: str | None,
    expected_workspace_name: str,
) -> tuple[str | None, str | None]:
    if refs_before_launch is None:
        detail = refs_before_error or "pre-launch workspace snapshot unavailable"
        return None, detail
    try:
        listing_after_launch = cmux_text("list-workspaces")
    except BaseException as exc:
        if isinstance(exc, KeyboardInterrupt):
            raise
        return None, launch_failure_detail(exc)
    refs_after_launch = workspace_refs_from_listing(listing_after_launch)
    workspace_lines = workspace_lines_from_listing(listing_after_launch)
    recovered_refs = sorted(refs_after_launch - refs_before_launch)
    if len(recovered_refs) == 1:
        recovered_ref = recovered_refs[0]
        raw_line = workspace_lines.get(recovered_ref)
        display_name = workspace_display_name(raw_line, recovered_ref) if raw_line else ""
        if not workspace_display_matches_expected_name(display_name, expected_workspace_name):
            return None, (
                "workspace display does not match expected session workspace name: "
                f"recovered {recovered_ref} as {display_name!r} for expected {expected_workspace_name!r}"
            )
        return recovered_ref, None
    if not recovered_refs:
        return None, "no new workspace refs detected in cmux list-workspaces"
    return None, (
        "ambiguous workspace recovery: found "
        f"{len(recovered_refs)} new workspace refs ({', '.join(recovered_refs)})"
    )


def resolve_workspace_ref_after_launch(
    workspace_output: str,
    refs_before_launch: set[str] | None,
    refs_before_error: str | None,
    expected_workspace_name: str,
) -> tuple[str | None, str | None]:
    output_refs = refs_from_text(workspace_output, "workspace:")
    if refs_before_launch is not None:
        if len(output_refs) != 1 or output_refs[0] in refs_before_launch:
            return recover_workspace_ref_by_delta(
                refs_before_launch,
                refs_before_error,
                expected_workspace_name,
            )
        validation_error = validate_workspace_ref_name(output_refs[0], expected_workspace_name)
        if validation_error is None:
            return output_refs[0], None
        recovered_workspace_id, recovery_error = recover_workspace_ref_by_delta(
            refs_before_launch,
            refs_before_error,
            expected_workspace_name,
        )
        if recovered_workspace_id is not None:
            return recovered_workspace_id, None
        return None, recovery_error or validation_error
    if len(output_refs) != 1:
        detail = refs_before_error or f"missing unique workspace ref in cmux output: {workspace_output}"
        return None, detail
    validation_error = validate_workspace_ref_name(output_refs[0], expected_workspace_name)
    if validation_error:
        return None, validation_error
    return output_refs[0], None


def cmux_selected_pane(workspace_id: str) -> str:
    return first_ref(cmux_text("list-panes", "--workspace", workspace_id), "pane:")


def cmux_selected_surface(workspace_id: str, pane_ref: str) -> str:
    return first_ref(
        cmux_text("list-pane-surfaces", "--workspace", workspace_id, "--pane", pane_ref),
        "surface:",
    )


def caller_context(workspace_id: str, surface_ref: str) -> dict[str, object]:
    payload = cmux_json("identify", "--workspace", workspace_id, "--surface", surface_ref)
    caller = payload.get("caller")
    if not isinstance(caller, dict):
        raise TeamLaunchError("cmux identify missing caller context")
    if not isinstance(caller.get("surface_ref"), str) or not isinstance(
        caller.get("pane_ref"), str
    ):
        raise TeamLaunchError("cmux identify missing pane or surface ref")
    return caller


def launch_failure_detail(exc: BaseException) -> str:
    if isinstance(exc, subprocess.CalledProcessError):
        detail = (exc.stderr or "").strip() or (exc.stdout or "").strip()
        return detail or f"exit {exc.returncode}"
    detail = str(exc).strip()
    if detail:
        return detail
    if isinstance(exc, SystemExit):
        return f"exit {exc.code}"
    return exc.__class__.__name__


def codex_command(
    cwd: str, packet_path: Path, role: str, profile: str | None, session_id: str
) -> str:
    exports = [
        f"CMUX_SUPERPOWERS_PACKET_PATH={shlex.quote(str(packet_path))}",
        f"CMUX_SUPERPOWERS_ROLE={shlex.quote(role)}",
        f"CMUX_SUPERPOWERS_SESSION_ID={shlex.quote(session_id)}",
    ]
    for env_name in CODEX_ENV_PASSTHROUGH:
        env_value = os.environ.get(env_name)
        if env_value:
            exports.append(f"{env_name}={shlex.quote(env_value)}")
    stub_log_dir = os.environ.get("CMUX_SUPERPOWERS_STUB_LOG_DIR")
    if stub_log_dir:
        exports.append(f"CMUX_SUPERPOWERS_STUB_LOG_DIR={shlex.quote(stub_log_dir)}")
    profile_flags = ["-p", profile] if profile else []
    prompt_expr = f'PROMPT=$(cat {shlex.quote(str(packet_path))})'
    cmd = [resolve_codex_bin(), "-C", cwd, *profile_flags]
    return (
        f"cd -- {shlex.quote(cwd)} && {prompt_expr} && "
        f"{' '.join(exports)} {shell_join(cmd)} \"$PROMPT\""
    )


def cleanup_step_error(command: list[str], description: str) -> str | None:
    proc = subprocess.run(command, check=False, text=True, capture_output=True)
    if proc.returncode == 0:
        return None
    detail = probe_failure_detail(proc) or f"exit {proc.returncode}"
    return f"{description}: {detail}"


def owned_worktree_entries(workers: list[dict[str, object]]) -> list[tuple[str | None, str | None]]:
    entries: list[tuple[str | None, str | None]] = []
    for worker in workers:
        worktree_path = worker.get("worktree_path")
        worktree_branch = worker.get("worktree_branch")
        if not worktree_path and not worktree_branch:
            continue
        entries.append(
            (
                str(worktree_path) if isinstance(worktree_path, str) else None,
                str(worktree_branch) if isinstance(worktree_branch, str) else None,
            )
        )
    return entries


def owned_worktree_descriptions(workers: list[dict[str, object]]) -> list[str]:
    descriptions: list[str] = []
    for worker in workers:
        details: list[str] = []
        worktree_path = worker.get("worktree_path")
        worktree_branch = worker.get("worktree_branch")
        if worktree_path:
            details.append("worktree")
        if worktree_branch:
            details.append("branch")
        if not details:
            continue
        worker_id = worker.get("worker_id")
        label = str(worker_id) if isinstance(worker_id, str) and worker_id else "worker"
        descriptions.append(f"{label} ({', '.join(details)})")
    return descriptions


def owned_hud_descriptions(hud: object) -> list[str]:
    if not isinstance(hud, dict):
        return []
    surface_ref = hud.get("surface_ref")
    if not isinstance(surface_ref, str) or not surface_ref:
        return []
    return [f"hud ({surface_ref})"]


def branch_checked_out_elsewhere_error(
    repo_root: str, owned_worktree_path: str | None, worktree_branch: str | None
) -> str | None:
    if not worktree_branch:
        return None
    target_ref = f"refs/heads/{worktree_branch}"
    owned_path = str(Path(owned_worktree_path).resolve()) if owned_worktree_path else None
    other_paths: list[str] = []
    current_path: str | None = None
    current_branch: str | None = None
    for raw_line in git_text("worktree", "list", "--porcelain", cwd=repo_root).splitlines():
        if not raw_line:
            if current_path and current_branch == target_ref:
                resolved_path = str(Path(current_path).resolve())
                if resolved_path != owned_path:
                    other_paths.append(resolved_path)
            current_path = None
            current_branch = None
            continue
        if raw_line.startswith("worktree "):
            current_path = raw_line.removeprefix("worktree ").strip()
            continue
        if raw_line.startswith("branch "):
            current_branch = raw_line.removeprefix("branch ").strip()
    if current_path and current_branch == target_ref:
        resolved_path = str(Path(current_path).resolve())
        if resolved_path != owned_path:
            other_paths.append(resolved_path)
    if not other_paths:
        return None
    return (
        f"branch {worktree_branch} is checked out in another worktree: "
        + ", ".join(other_paths)
    )


def purge_session_state_dir(session_root: Path) -> None:
    if not session_root.exists():
        return
    parent = session_root.parent
    if not os.access(parent, os.W_OK | os.X_OK):
        raise PermissionError(
            errno.EACCES,
            f"parent directory is not writable: {parent}",
            str(parent),
        )
    shutil.rmtree(session_root)
    if session_root.exists():
        raise OSError(f"session state still exists after purge: {session_root}")


def cmd_cleanup(args: argparse.Namespace) -> int:
    manifest_path = session_dir(args.session) / "manifest.json"
    if not manifest_path.exists():
        raise SystemExit(f"session manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    workspace_id = manifest.get("workspace_id")
    workers = manifest.get("workers", [])
    worktree_entries = owned_worktree_entries(workers)
    hud = manifest.get("hud")

    try:
        if args.close_workers:
            cmux_bin = resolve_cmux_bin()
            for worker in manifest.get("workers", []):
                surface_ref = worker.get("surface_ref")
                if surface_ref:
                    if not workspace_id:
                        raise SystemExit(
                            "cleanup failed: session manifest missing workspace_id for worker cleanup"
                        )
                    error = cleanup_step_error(
                        [
                            cmux_bin,
                            "close-surface",
                            "--workspace",
                            workspace_id,
                            "--surface",
                            surface_ref,
                        ],
                        f"close-surface failed for {worker.get('worker_id', 'worker')} ({surface_ref})",
                    )
                    if error:
                        raise SystemExit(f"cleanup failed: {error}")
                    worker["surface_ref"] = None
                    persist_manifest_worker(manifest_path, manifest, worker)

        if args.close_hud and isinstance(hud, dict):
            surface_ref = hud.get("surface_ref")
            if surface_ref:
                if not workspace_id:
                    raise SystemExit(
                        "cleanup failed: session manifest missing workspace_id for hud cleanup"
                    )
                error = cleanup_step_error(
                    [
                        resolve_cmux_bin(),
                        "close-surface",
                        "--workspace",
                        workspace_id,
                        "--surface",
                        surface_ref,
                    ],
                    f"close-surface failed for hud ({surface_ref})",
                )
                if error:
                    raise SystemExit(f"cleanup failed: {error}")
                hud["surface_ref"] = None
                persist_manifest(manifest_path, manifest)

        if args.remove_worktrees and worktree_entries:
            main = manifest.get("main")
            main_cwd = main.get("cwd") if isinstance(main, dict) else None
            if not isinstance(main_cwd, str) or not main_cwd:
                raise SystemExit("cleanup failed: session manifest missing main.cwd")
            repo_root = repo_root_for(main_cwd)
            for worktree_path, worktree_branch in worktree_entries:
                branch_error = branch_checked_out_elsewhere_error(
                    repo_root, worktree_path, worktree_branch
                )
                if branch_error:
                    raise SystemExit(f"cleanup failed: {branch_error}")
            for worker in workers:
                worktree_path = worker.get("worktree_path")
                worktree_branch = worker.get("worktree_branch")
                if not worktree_path and not worktree_branch:
                    continue
                if worktree_path:
                    error = cleanup_step_error(
                        ["git", "-C", repo_root, "worktree", "remove", "--force", worktree_path],
                        f"git worktree remove failed for {worktree_path}",
                    )
                    if error:
                        raise SystemExit(f"cleanup failed: {error}")
                    worker["worktree_path"] = None
                    persist_manifest_worker(manifest_path, manifest, worker)
                if worktree_branch:
                    error = cleanup_step_error(
                        ["git", "-C", repo_root, "branch", "-D", worktree_branch],
                        f"git branch delete failed for {worktree_branch}",
                    )
                    if error:
                        raise SystemExit(f"cleanup failed: {error}")
                    worker["worktree_branch"] = None
                    persist_manifest_worker(manifest_path, manifest, worker)
        remaining_worktree_resources = owned_worktree_descriptions(manifest.get("workers", []))
        remaining_hud_resources = owned_hud_descriptions(hud)
        if args.purge_state and remaining_hud_resources and remaining_worktree_resources:
            raise SystemExit(
                "cleanup failed: cannot purge session state while owned hud and worktree resources remain: "
                + ", ".join(remaining_hud_resources + remaining_worktree_resources)
                + "; rerun cleanup with --close-hud and --remove-worktrees"
            )
        if args.purge_state and remaining_hud_resources:
            raise SystemExit(
                "cleanup failed: cannot purge session state while owned hud resources remain: "
                + ", ".join(remaining_hud_resources)
                + "; rerun cleanup with --close-hud"
            )
        if args.purge_state and remaining_worktree_resources:
            raise SystemExit(
                "cleanup failed: cannot purge session state while owned worktree resources remain: "
                + ", ".join(remaining_worktree_resources)
                + "; rerun cleanup with --remove-worktrees"
            )
    except SystemExit as exc:
        detail = launch_failure_detail(exc)
        if detail.startswith("cleanup failed: "):
            raise SystemExit(detail) from None
        raise SystemExit(f"cleanup failed: {detail}") from None
    except BaseException as exc:
        if isinstance(exc, KeyboardInterrupt):
            raise
        detail = launch_failure_detail(exc)
        raise SystemExit(f"cleanup failed: {detail}") from None

    manifest["cleanup"] = {"status": "cleaned"}
    persist_manifest(manifest_path, manifest)
    if args.purge_state:
        session_root = session_dir(args.session)
        try:
            purge_session_state_dir(session_root)
        except OSError as exc:
            raise SystemExit(
                f"cleanup failed: failed to purge session state at {session_root}: {exc}"
            ) from None
    return 0


def cmd_team(args: argparse.Namespace) -> int:
    workers = args.worker or ["review", "general"]
    session_id = f"session-{uuid.uuid4().hex[:8]}"
    session_root = session_dir(session_id)
    session_root.mkdir(parents=True, exist_ok=True)
    task = args.task
    cwd = str(Path(args.cwd).expanduser().resolve())
    session_marker = workspace_session_marker(session_id)
    workspace_name = workspace_name_for_session(session_marker, args.name)
    workspace_id: str | None = None
    preserve_session_state = False
    created_worktrees: list[tuple[str, str]] = []
    manifest_path = session_root / "manifest.json"

    try:
        main_packet = session_root / "packets" / "main.md"
        write_packet(main_packet, build_packet("main", task, cwd, write_capable=False))
        created_at = datetime.now(timezone.utc).isoformat()
        planned_workers: list[WorkerPlan] = []
        manifest = session_manifest(
            session_id,
            created_at,
            session_root,
            workspace_id,
            main_packet,
            cwd,
            planned_workers,
        )
        persist_manifest(manifest_path, manifest)
        main_command = codex_command(
            cwd, main_packet, "main", args.profile or "workflow_fidelity", session_id
        )
        workspace_refs_before_launch, workspace_refs_before_error = snapshot_workspace_refs()

        workspace_output = cmux_text(
            "new-workspace",
            "--name",
            workspace_name,
            "--cwd",
            cwd,
            "--command",
            main_command,
        )
        workspace_id, workspace_error = resolve_workspace_ref_after_launch(
            workspace_output,
            workspace_refs_before_launch,
            workspace_refs_before_error,
            workspace_name,
        )
        if workspace_id is None:
            preserve_session_state = True
            detail = workspace_error or "workspace recovery failed"
            raise TeamLaunchError(
                f"unable to recover workspace ref after new-workspace output: {detail}"
            )
        manifest["workspace_id"] = workspace_id
        persist_manifest(manifest_path, manifest)
        main_pane = cmux_selected_pane(workspace_id)
        main_surface = cmux_selected_surface(workspace_id, main_pane)
        main_context = caller_context(workspace_id, main_surface)
        main_surface = str(main_context["surface_ref"])
        main_pane = str(main_context["pane_ref"])
        manifest["main"]["pane_ref"] = main_pane
        manifest["main"]["surface_ref"] = main_surface
        persist_manifest(manifest_path, manifest)
        anchor_surface = main_surface
        for index, role in enumerate(workers, start=1):
            worker_id = f"worker-{index}"
            role_spec = ROLE_SPECS[role]
            worker_profile = args.profile or role_spec["profile"]
            packet_path = session_root / "packets" / f"{worker_id}.md"
            worker_cwd, worktree_path, worktree_branch = prepare_worker_root(
                cwd, session_id, worker_id, bool(role_spec["write"])
            )
            if worktree_path and worktree_branch:
                created_worktrees.append((worktree_path, worktree_branch))
            write_packet(
                packet_path,
                build_packet(role, task, worker_cwd, bool(role_spec["write"])),
            )
            worker_plan = WorkerPlan(
                worker_id=worker_id,
                role=role,
                write_capable=bool(role_spec["write"]),
                profile=worker_profile,
                cwd=worker_cwd,
                packet_path=str(packet_path),
                worktree_path=worktree_path,
                worktree_branch=worktree_branch,
            )
            planned_workers.append(worker_plan)
            write_json(session_root / "workers" / f"{worker_id}.json", asdict(worker_plan))
            persist_manifest_workers(manifest_path, manifest, planned_workers)
            anchor_surface = first_ref(
                cmux_text(
                    "new-split",
                    "right" if index == 1 else "down",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    anchor_surface,
                ),
                "surface:",
            )
            focused = caller_context(workspace_id, anchor_surface)
            run(
                [
                    resolve_cmux_bin(),
                    "rename-tab",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    anchor_surface,
                    worker_id,
                ]
            )
            run(
                [
                    resolve_cmux_bin(),
                    "send",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    anchor_surface,
                    codex_command(
                        worker_cwd,
                        packet_path,
                        role,
                        worker_profile,
                        session_id,
                    )
                    + "\n",
                ]
            )
            worker_plan.pane_ref = str(focused["pane_ref"])
            worker_plan.surface_ref = str(focused["surface_ref"])
            write_json(session_root / "workers" / f"{worker_id}.json", asdict(worker_plan))
            persist_manifest_workers(manifest_path, manifest, planned_workers)

        if not args.no_hud:
            hud_json_path = session_root / "hud.json"
            write_json(hud_json_path, build_hud_payload(manifest))
            hud_runner = write_hud_runner(session_root)
            hud_surface = first_ref(
                cmux_text(
                    "new-split",
                    "down",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    main_surface,
                ),
                "surface:",
            )
            hud_context = caller_context(workspace_id, hud_surface)
            hud_surface = str(hud_context["surface_ref"])
            hud_pane = str(hud_context["pane_ref"])
            run(
                [
                    resolve_cmux_bin(),
                    "rename-tab",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    hud_surface,
                    "hud",
                ]
            )
            run(
                [
                    resolve_cmux_bin(),
                    "send",
                    "--workspace",
                    workspace_id,
                    "--surface",
                    hud_surface,
                    f"bash {shlex.quote(str(hud_runner))} {shlex.quote(str(hud_json_path))}\n",
                ]
            )
            manifest["hud"] = {
                "pane_ref": hud_pane,
                "surface_ref": hud_surface,
                "hud_json": str(hud_json_path),
            }
            persist_manifest(manifest_path, manifest)

        if args.json:
            print(
                json.dumps(
                    {
                        "session_id": session_id,
                        "workspace_id": workspace_id,
                        "manifest_path": str(manifest_path),
                    }
                )
            )
        else:
            print(f"Created {session_id} in {workspace_id}")
        return 0
    except BaseException as exc:
        if isinstance(exc, KeyboardInterrupt):
            raise
        launch_detail = launch_failure_detail(exc)
        close_error = None
        if workspace_id:
            close_proc = subprocess.run(
                [resolve_cmux_bin(), "close-workspace", "--workspace", workspace_id],
                check=False,
                text=True,
                capture_output=True,
            )
            if close_proc.returncode != 0:
                close_detail = probe_failure_detail(close_proc) or f"exit {close_proc.returncode}"
                close_error = f"close-workspace failed: {close_detail}"
        rollback_cleanup_errors: list[str] = []
        if close_error or preserve_session_state:
            rollback_cleanup_errors = []
        elif created_worktrees:
            repo_root = repo_root_for(cwd)
            for worktree_path, worktree_branch in created_worktrees:
                branch_error = branch_checked_out_elsewhere_error(
                    repo_root, worktree_path, worktree_branch
                )
                if branch_error:
                    rollback_cleanup_errors.append(branch_error)
            if rollback_cleanup_errors:
                details = [f"team launch failed: {launch_detail}"]
                details.extend(rollback_cleanup_errors)
                details.append(f"session state preserved at {session_root}")
                raise SystemExit("; ".join(details)) from None
            for worktree_path, worktree_branch in created_worktrees:
                worktree_error = cleanup_step_error(
                    ["git", "-C", repo_root, "worktree", "remove", "--force", worktree_path],
                    f"git worktree remove failed for rollback path {worktree_path}",
                )
                if worktree_error:
                    rollback_cleanup_errors.append(worktree_error)
                    continue
                cleaned_worker = matching_worker_plan(
                    planned_workers, worktree_path, worktree_branch
                )
                if cleaned_worker is not None:
                    cleaned_worker.worktree_path = None
                    persist_manifest_workers(manifest_path, manifest, planned_workers)
                branch_error = cleanup_step_error(
                    ["git", "-C", repo_root, "branch", "-D", worktree_branch],
                    f"git branch delete failed for rollback path {worktree_branch}",
                )
                if branch_error:
                    rollback_cleanup_errors.append(branch_error)
                    continue
                if cleaned_worker is not None:
                    cleaned_worker.worktree_branch = None
                    persist_manifest_workers(manifest_path, manifest, planned_workers)
        if close_error or preserve_session_state or rollback_cleanup_errors:
            details = [f"team launch failed: {launch_detail}"]
            if close_error:
                details.append(close_error)
            details.extend(rollback_cleanup_errors)
            details.append(f"session state preserved at {session_root}")
            raise SystemExit(
                "; ".join(details)
            ) from None
        shutil.rmtree(session_root, ignore_errors=True)
        raise SystemExit(f"team launch failed: {launch_detail}") from None


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "doctor":
        return cmd_doctor(args)
    if args.command == "team":
        return cmd_team(args)
    if args.command == "cleanup":
        return cmd_cleanup(args)
    parser.error(f"unknown command {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
