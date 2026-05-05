# Legacy Code Gate Map

This map records old code-backed gates and automation surfaces. The earlier prose-only retirement decisions are superseded by the Natural-Language Agent Harness boundary.

Each surface needs one refined disposition:

- deterministic mechanic;
- implementation safety;
- evidence provider;
- explicit code authority;
- human-facing orchestration policy;
- historical record;
- accepted retirement;
- unresolved blocker.

| Old surface | Refined role | Former purpose | Current disposition |
| --- | --- | --- | --- |
| `_shared/validators/validate_skill_library.py` | accepted retirement | Enforced process target inventory, skill frontmatter, prompt packet phrases, child elicitation rules, SessionStart compactness, stale dispatch guards, and cache-artifact bans. | Human-facing policy moved to `process-family-playbook.md` and `prompt-packet-playbook.md`; exact-string checks are no longer code authority. Use focused search and ledger review as evidence. |
| `_shared/validators/process_family_targets.txt` | human-facing orchestration policy | Listed process-family files the validator had to inspect. | Target inventory is visible in `process-family-playbook.md`; no code mechanic is required. |
| `scripts/validate_codex_public_fork.py` | accepted retirement | Enforced public paths, removed paths, package metadata, npm payload contents, manifest fields, hook bootstrap, docs snippets, issue templates, conduct/security reporting, and forbidden public wording. | Public-fork readiness belongs in `public-fork-playbook.md` and ledgers. Deterministic package evidence comes from `npm pack --dry-run --json`, manifest inspection, docs inspection, and focused searches. |
| `tests/codex-public-fork/run.sh` | accepted retirement | Built fixtures to prove the public-fork validator caught missing paths, stale docs, and package drift. | Retired because it encoded stale hook/cmux expectations; no replacement package script is created. |
| `package.json` scripts `validate:process-family` and `validate:public-fork` | human-facing orchestration policy | Exposed validators as release-facing commands. | No package script silently decides release readiness. Future scripts must declare evidence or explicit authority role. |
| `.codex-plugin/plugin.json` `hooks` field | retained lightweight adapter | Advertised native SessionStart hook discovery. | Restored as a native plugin hook declaration. |
| `hooks/hooks.json` | retained lightweight adapter | Declared native SessionStart command using `${PLUGIN_ROOT}`. | Restored with `python3 "${PLUGIN_ROOT}/hooks/session-start"` as the plugin-native command. |
| `hooks/session-start` | retained lightweight adapter | Emitted compact `hookSpecificOutput.additionalContext` that told Codex to route through `session-router`. | Restored; source of truth remains `session-router-playbook.md`. |
| `scripts/install_codex_hooks.py` | accepted retirement | Installed or removed user-level hook bootstrap. | Retired because it mutates `~/.codex/hooks.json`; native plugin hooks are the supported adapter path. |
| `scripts/install_cmux_superpowers_launcher.py` | companion-owned | Installed local cmux launcher wrapper. | Companion package ownership if retained. |
| `scripts/cmux_superpowers_team.py` | companion-owned | Launched cmux team sessions. | Companion-owned by `cmux-superpowers`; not shipped here. |
| `tests/cmux-superpowers/*` | companion-owned | Tested cmux launcher install, doctor, and team smoke behavior. | Companion package should own tests if the launcher remains supported. |
| `commands/brainstorm.md` | accepted retirement | Legacy command alias for brainstorming. | Use direct `codex-workflows:brainstorming` skill invocation. |
| `commands/write-plan.md` | accepted retirement | Legacy command alias for writing plans. | Use direct `codex-workflows:writing-plans` skill invocation. |
| `commands/execute-plan.md` | accepted retirement | Legacy command alias for execution. | Use direct `codex-workflows:executing-plans` or `subagent-driven-development` skill invocation. |
| `skills/brainstorming/scripts/server.cjs` | retained feature runtime | Served browser visual brainstorming sessions and state events. | Restored as feature runtime used only through `visual-companion.md`. |
| `skills/brainstorming/scripts/start-server.sh` | retained feature runtime | Started the visual companion server. | Restored as feature runtime. |
| `skills/brainstorming/scripts/stop-server.sh` | retained feature runtime | Stopped the visual companion server. | Restored as feature runtime. |
| `skills/brainstorming/scripts/helper.js` | retained feature runtime | Captured browser selections for the visual companion. | Restored as browser interaction evidence. |
| `skills/brainstorming/scripts/frame-template.html` | retained feature runtime | Framed visual companion content. | Restored as feature runtime. |
| `tests/brainstorm-server/*` | retained evidence provider | Tested the visual companion server lifecycle, package metadata, and WebSocket protocol. | Restored as focused runtime evidence. |
| `skills/writing-plans/references/validate_execplan.py` | retained deterministic mechanic | Checked ExecPlan Markdown structure and evidence. | Restored as structural diagnostics; manual review decides readiness. |
| `skills/systematic-debugging/find-polluter.sh` | retained deterministic mechanic | Ran candidate tests one by one to locate filesystem pollution. | Restored as debugging evidence. |
| `skills/writing-skills/render-graphs.js` | retained deterministic mechanic | Rendered Graphviz blocks from skill docs. | Restored as utility mechanic/evidence. |
| `tests/subagent-driven-dev/*` | accepted retirement | Held sample project plans and shell scaffolds, including stale non-Codex setup. | Retired because the fixtures use obsolete `superpowers:` framing and are not current deterministic runtime or safety mechanics. |
| Historical `docs/plans/*` and `docs/archive/superpowers/*` | historical record | Older implementation plans and specs may reference removed validators or old namespaces. | Non-authoritative archive. New package obligations live in `docs/language-contracts/`. |

## Current Status

This map is fully dispositioned for the Natural-Language Agent Harness correction. Restored feature runtime, utility mechanics, and the native SessionStart adapter are not blockers. Retired validators and fixtures are accepted retirements, not compatibility shims.
