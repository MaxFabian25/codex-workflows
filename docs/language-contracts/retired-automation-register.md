# Automation Disposition Register

This register records executable or command surfaces reviewed during the Natural-Language Agent Harness correction.

The earlier broad prose-only retirement rationale is superseded. Each surface below uses the refined disposition: accepted retirement, retained deterministic mechanic, retained safety, evidence provider, explicit code authority, companion-owned, historical, or unresolved blocker.

| Surface | Refined disposition | Authority or evidence role |
| --- | --- | --- |
| `hooks/hooks.json` | retained lightweight adapter | Native plugin hook adapter that points SessionStart at `hooks/session-start`; source of truth remains `session-router-playbook.md`. |
| `hooks/session-start` | retained lightweight adapter | Emits the `superpowers-codex:using-superpowers` router instruction as SessionStart context. |
| `.codex-plugin/plugin.json` `hooks` field | retained lightweight adapter | Declares the native plugin hook file. |
| `scripts/install_codex_hooks.py` | accepted retirement | User-level hook installer mutates `~/.codex/hooks.json`; native plugin hooks are the supported adapter path. |
| `scripts/install_cmux_superpowers_launcher.py` | companion-owned | Launcher ownership belongs outside this core package if a companion plugin exists. |
| `scripts/cmux_superpowers_team.py` | companion-owned | Team launcher runtime belongs outside this core package if retained. |
| `tests/cmux-superpowers/` | companion-owned | Companion package should own these tests if the launcher remains supported. |
| `commands/brainstorm.md` | accepted retirement | Deprecated alias; use `superpowers-codex:brainstorming`. |
| `commands/write-plan.md` | accepted retirement | Deprecated alias; use `superpowers-codex:writing-plans`. |
| `commands/execute-plan.md` | accepted retirement | Deprecated alias; use `superpowers-codex:executing-plans` or `superpowers-codex:subagent-driven-development`. |
| `_shared/validators/validate_skill_library.py` | accepted retirement | Human-facing policy moved to process/prompt playbooks; exact-string and stale-route checks are accepted as reviewer/search evidence rather than code gates. |
| `_shared/validators/process_family_targets.txt` | prose-controlled human decision | Target inventory is visible in `process-family-playbook.md`; no runtime mechanic is required. |
| `scripts/validate_codex_public_fork.py` | accepted retirement | Public-fork readiness is ledger-controlled; package metadata/path checks use `npm pack --dry-run --json`, manifest inspection, docs inspection, and ledger review. |
| `tests/codex-public-fork/run.sh` | accepted retirement | Fixture harness encoded stale hook/cmux expectations; current public-fork evidence is package inspection plus playbook review. |
| `package.json` `validate:*` scripts | prose-controlled human decision | No package script silently decides release readiness; future scripts must declare evidence or explicit authority role. |
| `skills/brainstorming/scripts/server.cjs` | retained feature runtime | Local browser companion server used only when the skill offers it and the user accepts. |
| `skills/brainstorming/scripts/start-server.sh` | retained feature runtime | Starts the local visual companion server. |
| `skills/brainstorming/scripts/stop-server.sh` | retained feature runtime | Stops the local visual companion server. |
| `skills/brainstorming/scripts/helper.js` | retained feature runtime | Captures browser interaction events as evidence. |
| `skills/brainstorming/scripts/frame-template.html` | retained feature runtime | Provides the browser frame for visual comparison. |
| `tests/brainstorm-server/` | retained evidence provider | Focused tests for visual companion server behavior. |
| `skills/writing-plans/references/validate_execplan.py` | retained deterministic mechanic | Structural diagnostics for ExecPlan-style Markdown; manual review decides readiness. |
| `skills/systematic-debugging/find-polluter.sh` | retained deterministic mechanic | Debugging helper that produces evidence for pollution isolation. |
| `skills/writing-skills/render-graphs.js` | retained deterministic mechanic | Utility for rendering graph artifacts from skill docs. |
| `tests/subagent-driven-dev/` | accepted retirement | Stale examples used obsolete `superpowers:` framing and are not current runtime mechanics or safety checks. |

## Do Not Recreate

Do not recreate retired surfaces as compatibility shims during routine maintenance. Restoration is appropriate only when a surface owns deterministic mechanics, safety, feature runtime, or a lightweight adapter role. A future change may restore one after recording:

- why prose/manual workflow is insufficient;
- which package owns the executable;
- whether it is an exception or a new product direction;
- which front-door docs and release notes changed.
