#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import uuid
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

import tomllib


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


def is_real_superpowers_session_start_command(command: object) -> bool:
    if not isinstance(command, str):
        return False
    if "__SUPERPOWERS_" in command.upper():
        return False
    try:
        tokens = shlex.split(command)
    except ValueError:
        return False
    if not tokens:
        return False
    executable = Path(tokens[0]).name
    if executable in NOOP_EXECUTABLES:
        return False
    if is_hooks_session_start_path(tokens[0]):
        return True
    if not executable.startswith("python"):
        return False
    script_target = python_script_target(tokens)
    return isinstance(script_target, str) and is_hooks_session_start_path(script_target)


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
        if not is_real_superpowers_session_start_command(command):
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

    try:
        payload = tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        return None, f"{config_path}: {exc}"
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


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def first_ref(text: str, prefix: str) -> str:
    for token in text.split():
        if token.startswith(prefix):
            return token
    raise TeamLaunchError(f"missing {prefix} ref in cmux output: {text}")


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


def cmd_team(args: argparse.Namespace) -> int:
    workers = args.worker or ["review", "general"]
    if any(bool(ROLE_SPECS[role]["write"]) for role in workers):
        raise SystemExit("team not implemented yet: write-capable workers are not implemented yet")
    session_id = f"session-{uuid.uuid4().hex[:8]}"
    session_root = session_dir(session_id)
    session_root.mkdir(parents=True, exist_ok=True)
    task = args.task
    cwd = str(Path(args.cwd).expanduser().resolve())
    workspace_id: str | None = None

    try:
        main_packet = session_root / "packets" / "main.md"
        write_packet(main_packet, build_packet("main", task, cwd, write_capable=False))
        main_command = codex_command(
            cwd, main_packet, "main", args.profile or "workflow_fidelity", session_id
        )

        workspace_name = args.name or f"superpowers-{session_id}"
        workspace_id = first_ref(
            cmux_text(
                "new-workspace",
                "--name",
                workspace_name,
                "--cwd",
                cwd,
                "--command",
                main_command,
            ),
            "workspace:",
        )
        main_pane = cmux_selected_pane(workspace_id)
        main_surface = cmux_selected_surface(workspace_id, main_pane)
        main_context = caller_context(workspace_id, main_surface)
        main_surface = str(main_context["surface_ref"])
        main_pane = str(main_context["pane_ref"])

        planned_workers: list[WorkerPlan] = []
        anchor_surface = main_surface
        for index, role in enumerate(workers, start=1):
            worker_id = f"worker-{index}"
            role_spec = ROLE_SPECS[role]
            packet_path = session_root / "packets" / f"{worker_id}.md"
            write_packet(packet_path, build_packet(role, task, cwd, role_spec["write"]))
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
                    codex_command(cwd, packet_path, role, role_spec["profile"], session_id)
                    + "\n",
                ]
            )
            planned_workers.append(
                WorkerPlan(
                    worker_id=worker_id,
                    role=role,
                    write_capable=bool(role_spec["write"]),
                    profile=role_spec["profile"],
                    cwd=cwd,
                    packet_path=str(packet_path),
                    pane_ref=str(focused["pane_ref"]),
                    surface_ref=str(focused["surface_ref"]),
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
        if close_error:
            raise SystemExit(
                f"team launch failed: {launch_detail}; {close_error}; session state preserved at {session_root}"
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
        raise SystemExit("cleanup not implemented yet")
    parser.error(f"unknown command {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
