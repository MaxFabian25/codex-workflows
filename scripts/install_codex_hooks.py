#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK_TEMPLATE_PATH = REPO_ROOT / "hooks" / "hooks.json"
HOOK_SCRIPT_PATH = REPO_ROOT / "hooks" / "session-start"
SESSION_START_COMMAND_PLACEHOLDER = "__SUPERPOWERS_SESSION_START_COMMAND__"
SESSION_START_MATCHER = "startup|resume|clear"
SESSION_START_STATUS_MESSAGE = "loading superpowers"
PYTHON_OPTIONS_WITH_VALUES = {"-W", "-X"}
PYTHON_REJECTED_SCRIPT_MODES = {"-c", "-m", "-"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install or remove Superpowers Codex hooks.")
    parser.add_argument(
        "--codex-home",
        default=os.environ.get("CODEX_HOME") or str(Path.home() / ".codex"),
        help="Codex home directory containing hooks.json (default: %(default)s)",
    )
    parser.add_argument(
        "--remove",
        action="store_true",
        help="Remove the installed Superpowers SessionStart hook instead of installing it",
    )
    return parser.parse_args()


def shell_command(parts: list[str]) -> str:
    if os.name == "nt":
        return subprocess.list2cmdline(parts)
    return " ".join(shlex.quote(part) for part in parts)


def build_session_start_command() -> str:
    python_executable = str(Path(sys.executable).resolve())
    return shell_command([python_executable, str(HOOK_SCRIPT_PATH)])


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
    if is_hooks_session_start_path(tokens[0]):
        return Path(tokens[0]).expanduser().resolve(strict=False)
    if not Path(tokens[0]).name.startswith("python"):
        return None
    script_target = python_script_target(tokens)
    if isinstance(script_target, str) and is_hooks_session_start_path(script_target):
        return Path(script_target).expanduser().resolve(strict=False)
    return None


def load_json_file(path: Path) -> dict:
    if not path.exists():
        return {"hooks": {}}

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"{path} is not valid JSON: {exc.msg}") from exc

    if not isinstance(payload, dict):
        raise SystemExit(f"{path} must contain a JSON object")

    hooks = payload.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise SystemExit(f"{path} field `hooks` must be a JSON object")

    return payload


def load_template(command: str) -> dict:
    payload = load_json_file(HOOK_TEMPLATE_PATH)
    try:
        session_start_group = payload["hooks"]["SessionStart"][0]
        handler = session_start_group["hooks"][0]
    except (KeyError, IndexError, TypeError) as exc:
        raise SystemExit(f"{HOOK_TEMPLATE_PATH} is missing the SessionStart command template") from exc

    if session_start_group.get("matcher") != SESSION_START_MATCHER:
        raise SystemExit(f"{HOOK_TEMPLATE_PATH} must use `{SESSION_START_MATCHER}` as its SessionStart matcher")

    if handler.get("command") != SESSION_START_COMMAND_PLACEHOLDER:
        raise SystemExit(
            f"{HOOK_TEMPLATE_PATH} must use `{SESSION_START_COMMAND_PLACEHOLDER}` as its command placeholder"
        )

    handler["command"] = command
    return payload


def is_superpowers_handler(handler: object) -> bool:
    if not isinstance(handler, dict):
        return False
    if handler.get("type") != "command":
        return False
    target_path = session_start_target_path(handler.get("command"))
    return target_path == HOOK_SCRIPT_PATH.resolve()


def remove_owned_handlers(session_groups: list[object]) -> tuple[list[object], bool]:
    filtered_groups: list[object] = []
    removed_any = False
    for group in session_groups:
        if not isinstance(group, dict):
            filtered_groups.append(group)
            continue
        hooks = group.get("hooks")
        if not isinstance(hooks, list):
            filtered_groups.append(group)
            continue
        remaining_hooks = [handler for handler in hooks if not is_superpowers_handler(handler)]
        if len(remaining_hooks) == len(hooks):
            filtered_groups.append(group)
            continue
        removed_any = True
        if remaining_hooks:
            group_copy = dict(group)
            group_copy["hooks"] = remaining_hooks
            filtered_groups.append(group_copy)
    return filtered_groups, removed_any


def write_hooks_file(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def install(codex_home: Path) -> int:
    if not HOOK_SCRIPT_PATH.is_file():
        raise SystemExit(f"Missing SessionStart hook script: {HOOK_SCRIPT_PATH}")

    hooks_path = codex_home / "hooks.json"
    payload = load_json_file(hooks_path)
    hooks = payload["hooks"]

    session_groups = hooks.get("SessionStart", [])
    if not isinstance(session_groups, list):
        raise SystemExit(f"{hooks_path} field `hooks.SessionStart` must be an array when present")

    desired_payload = load_template(build_session_start_command())
    desired_group = desired_payload["hooks"]["SessionStart"][0]
    filtered_groups, _ = remove_owned_handlers(session_groups)
    filtered_groups.append(desired_group)
    hooks["SessionStart"] = filtered_groups

    write_hooks_file(hooks_path, payload)
    print(f"Installed Superpowers SessionStart hook in {hooks_path}")
    return 0


def remove(codex_home: Path) -> int:
    hooks_path = codex_home / "hooks.json"
    payload = load_json_file(hooks_path)
    hooks = payload["hooks"]

    session_groups = hooks.get("SessionStart", [])
    if not isinstance(session_groups, list):
        raise SystemExit(f"{hooks_path} field `hooks.SessionStart` must be an array when present")

    filtered_groups, removed_any = remove_owned_handlers(session_groups)
    if not removed_any:
        print(f"No Superpowers SessionStart hook found in {hooks_path}")
        return 0

    if filtered_groups:
        hooks["SessionStart"] = filtered_groups
    else:
        hooks.pop("SessionStart", None)

    write_hooks_file(hooks_path, payload)
    print(f"Removed Superpowers SessionStart hook from {hooks_path}")
    return 0


def main() -> int:
    args = parse_args()
    codex_home = Path(args.codex_home).expanduser().resolve()
    if args.remove:
        return remove(codex_home)
    return install(codex_home)


if __name__ == "__main__":
    raise SystemExit(main())
