#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
LAUNCHER_PATH = REPO_ROOT / "scripts" / "cmux_superpowers_team.py"
WRAPPER_MARKER = "# cmux-superpowers-managed: superpowers-codex"
WRAPPER_LAUNCHER_MARKER_PREFIX = "# cmux-superpowers-launcher: "
WRAPPER_LAUNCHER_MARKER = f"{WRAPPER_LAUNCHER_MARKER_PREFIX}{LAUNCHER_PATH}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install or remove the cmux-superpowers wrapper."
    )
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
    return (
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n"
        f"{WRAPPER_MARKER}\n"
        f"{WRAPPER_LAUNCHER_MARKER}\n"
        f'exec {python_executable} {launcher} "$@"\n'
    )


def is_managed_wrapper(path: Path) -> bool:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return False
    lines = text.splitlines()
    if len(lines) != 5:
        return False
    if lines[0] != "#!/usr/bin/env bash":
        return False
    if lines[1] != "set -euo pipefail":
        return False
    if lines[2] != WRAPPER_MARKER:
        return False
    if not lines[3].startswith(WRAPPER_LAUNCHER_MARKER_PREFIX):
        return False

    launcher_path = lines[3].removeprefix(WRAPPER_LAUNCHER_MARKER_PREFIX).strip()
    if not launcher_path:
        return False
    launcher = Path(launcher_path)
    if not launcher.is_absolute():
        return False
    if launcher.name != "cmux_superpowers_team.py" or launcher.parent.name != "scripts":
        return False

    try:
        exec_tokens = shlex.split(lines[4])
    except ValueError:
        return False
    if len(exec_tokens) != 4:
        return False
    if exec_tokens[0] != "exec":
        return False
    python_path = exec_tokens[1]
    if not python_path or not Path(python_path).is_absolute():
        return False
    if exec_tokens[2] != launcher_path or exec_tokens[3] != "$@":
        return False

    expected_exec_line = f'exec {shlex.quote(python_path)} {shlex.quote(launcher_path)} "$@"'
    return lines[4] == expected_exec_line


def install(bin_dir: Path) -> int:
    if not LAUNCHER_PATH.is_file():
        print(f"Launcher not found: {LAUNCHER_PATH}", file=sys.stderr)
        return 1

    wrapper = bin_dir / "cmux-superpowers"
    if wrapper.exists() and not is_managed_wrapper(wrapper):
        print(f"Refusing to overwrite unmanaged wrapper: {wrapper}", file=sys.stderr)
        return 1
    bin_dir.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(render_wrapper(), encoding="utf-8")
    wrapper.chmod(0o755)
    print(f"Installed {wrapper}")
    return 0


def remove(bin_dir: Path) -> int:
    wrapper = bin_dir / "cmux-superpowers"
    if wrapper.exists():
        if not is_managed_wrapper(wrapper):
            print(f"Refusing to remove unmanaged wrapper: {wrapper}", file=sys.stderr)
            return 1
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
