#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
LAUNCHER_PATH = REPO_ROOT / "scripts" / "cmux_superpowers_team.py"


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
        f'exec {python_executable} {launcher} "$@"\n'
    )


def install(bin_dir: Path) -> int:
    if not LAUNCHER_PATH.is_file():
        print(f"Launcher not found: {LAUNCHER_PATH}", file=sys.stderr)
        return 1

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
