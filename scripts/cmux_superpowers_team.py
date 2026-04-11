#!/usr/bin/env python3
from __future__ import annotations

import argparse


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


def main() -> int:
    parser = build_parser()
    parser.parse_args()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
