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

    command = handler.get("command")
    status_message = handler.get("statusMessage")
    if status_message == SESSION_START_STATUS_MESSAGE:
        return True
    if not isinstance(command, str):
        return False
    return "session-start" in command and "superpowers" in command


def is_superpowers_group(group: object) -> bool:
    if not isinstance(group, dict):
        return False
    hooks = group.get("hooks")
    if not isinstance(hooks, list):
        return False
    return any(is_superpowers_handler(handler) for handler in hooks)


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
    filtered_groups = [group for group in session_groups if not is_superpowers_group(group)]
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

    filtered_groups = [group for group in session_groups if not is_superpowers_group(group)]
    if len(filtered_groups) == len(session_groups):
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
