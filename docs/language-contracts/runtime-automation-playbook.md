# Runtime Automation Playbook

This playbook records how executable surfaces are classified under the Natural-Language Agent Harness boundary.

## Classification Categories

- `human-facing orchestration policy`: executable code silently decided readiness, currentness, promotion, release, handoff, approval, rollback, or similar human-facing state; move the decision to a playbook and ledger.
- `deterministic mechanic`: code parses, adapts APIs, builds, formats, computes, migrates, imports/exports, generates, or executes real product behavior; retain unless separately retired.
- `implementation safety`: code prevents malformed inputs, missing files, unsafe paths, destructive writes, credential leakage, production data corruption, invalid migrations, or unsafe external effects; retain unless an equally safe replacement exists.
- `evidence provider`: code produces useful observations but does not decide human-facing status by itself.
- `explicit code authority`: code is deliberately chosen by the repo as an authority for a bounded status; document the choice.
- `install/convenience`: helper code automates setup; retain, replace with manual steps, or retire based on actual value.
- `runtime bridge`: code connects the package to a host runtime; retain as a lightweight adapter, move, or retire with product rationale.
- `feature runtime`: code provides user-facing behavior; retain, move, or retire with product rationale.
- `deprecated alias`: old command or namespace surface; remove and document replacement.
- `test harness`: fixture code checks deterministic behavior, safety, or old policy; keep deterministic/safety tests, demote policy fixtures to evidence, or retire historical fixtures.

## Current Decisions

The earlier broad prose-only interpretation is superseded.

The formerly unresolved surfaces from the broad prose-only pass are now dispositioned:

- SessionStart hook files are retained lightweight adapters.
- `scripts/install_codex_hooks.py` is retired because user-level hook installation mutates external user state; native plugin hooks are the supported adapter path.
- `_shared/validators/validate_skill_library.py`, `scripts/validate_codex_public_fork.py`, and `tests/codex-public-fork/run.sh` are retired policy gates or stale fixture harnesses; their human-facing decisions live in playbooks and ledgers.
- `tests/subagent-driven-dev/*` is retired as stale historical fixture material, not current package runtime.
- Visual brainstorming scripts are retained feature runtime when present; their tests are retained evidence for that runtime.
- `skills/writing-plans/references/validate_execplan.py` is a deterministic structure/evidence helper, not final human readiness authority.
- Utility scripts such as bisection and diagram rendering are deterministic mechanics or evidence providers unless separately retired.

## Manual Replacements

- Session start: use the native SessionStart hook adapter when the host loads plugin hooks; otherwise read `session-router-playbook.md` and `skills/using-superpowers/SKILL.md`.
- Process-family review: use `process-family-playbook.md`.
- Subagent packet review: use `prompt-packet-playbook.md`.
- Package/release review: use `package-and-release-playbook.md`.
- Public-fork review: use `public-fork-playbook.md`.
- Visual brainstorming: use normal prose by default; when visual comparison would materially help and the user accepts, follow `skills/brainstorming/visual-companion.md` and treat its scripts as feature runtime.
- cmux team launcher: use a separate companion plugin if available.

## Retained Tool Contracts

- `hooks/hooks.json`: input is the plugin runtime's SessionStart event; output is a command invocation for `hooks/session-start`; role is lightweight runtime adapter.
- `hooks/session-start`: input is no user data; output is JSON `hookSpecificOutput.additionalContext`; role is lightweight runtime adapter and evidence of the router instruction.
- `skills/brainstorming/scripts/*`: inputs are visual content files and runtime flags; outputs are browser pages and event logs; writes stay under the configured brainstorm session directory; side effects are a local server and browser-observable content; role is feature runtime plus evidence.
- `tests/brainstorm-server/*`: inputs are the retained visual companion scripts; outputs are test results; writes stay in temporary test workspaces; role is evidence for feature runtime.
- `skills/writing-plans/references/validate_execplan.py`: input is an ExecPlan-style Markdown file; output is structural diagnostics; role is deterministic evidence, not human readiness authority.
- `skills/systematic-debugging/find-polluter.sh`: inputs are candidate test commands; output is the first pollution-inducing candidate; role is deterministic debugging evidence.
- `skills/writing-skills/render-graphs.js`: inputs are Graphviz blocks in skill docs; outputs are rendered graph artifacts; role is utility mechanic/evidence.

## Review Checklist

- Every removed automation file is listed in `retired-automation-register.md` with a refined classification.
- Every old automation category has a replacement playbook, retained-code role, explicit authority role, historical note, or accepted retirement in `legacy-code-gate-map.md`.
- Front-door docs do not instruct users to run retired helpers.
- Feature loss is explicit in release notes and the cutover ledger when accepted.
- Any retained executable must state whether it is deterministic mechanic, safety, evidence provider, feature runtime, runtime bridge, or explicit code authority.
