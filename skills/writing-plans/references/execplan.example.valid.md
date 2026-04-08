# Example Feature Execution Plan

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

After this change, operators can run `./bin/example --health-check` and get a deterministic success response instead of a missing-command error. The proof is that the command exits with status 0 and prints `healthy`.

## Progress

- [x] (2026-01-01 12:00Z) Wrote the health-check command handler and CLI wiring.
- [ ] Add docs for the new command.

## Surprises & Discoveries

- Observation: The CLI parser already reserves `--health-check`.
  Evidence: `rg -n "health-check" src/cli.rs` returned a placeholder match.

## Decision Log

- Decision: Reuse the existing CLI parser instead of adding a second command entry point.
  Rationale: Keeps shell completion and help generation in one place.
  Date/Author: 2026-01-01 / Codex

## Outcomes & Retrospective

The command works end-to-end and prints the expected output. Remaining work is limited to user-facing documentation.

## Context and Orientation

The CLI entry point lives in `src/main.rs`, argument parsing in `src/cli.rs`, and the health-check logic belongs in `src/health.rs`. There is no existing runtime dependency for the new command beyond the current binary.

## Plan of Work

Update `src/cli.rs` to recognize `--health-check`, add a `run_health_check()` helper in `src/health.rs`, and call it from `src/main.rs` before the normal command dispatch path. Add a focused test in `tests/health_check.rs`.

## Concrete Steps

Run the unit test after wiring the helper:

    Command: cargo test health_check_returns_healthy -- --nocapture
    Working directory: /repo
    Expected result: one passing test and the string `healthy` in stdout
    Observed result: test passed and stdout contained `healthy`
    Exit status: 0
    Timestamp (UTC): 2026-01-01 12:05Z

## Validation and Acceptance

Run `cargo test health_check_returns_healthy -- --nocapture` and then `./target/debug/example --health-check`. Expect the test to pass and the command to print `healthy`.

## Idempotence and Recovery

The steps are additive and safe to rerun. If the command wiring fails, revert the CLI changes and retry the helper integration before re-running tests.

## Artifacts and Notes

Short expected output:

    running 1 test
    test health_check_returns_healthy ... ok

## Interfaces and Dependencies

Define in `src/health.rs`:

    pub fn run_health_check() -> &'static str
