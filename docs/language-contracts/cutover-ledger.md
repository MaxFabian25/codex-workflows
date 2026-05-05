# Cutover Ledger

## Correction Boundary: 2026-05-05

The earlier "absolute prose-only authority" interpretation is superseded.

The current target is a Natural-Language Agent Harness: move hidden human-facing orchestration policy into small, scoped natural-language artifacts, while retaining deterministic mechanics, implementation safety checks, tests, adapters, runtime helpers, and explicit tool interfaces when code is the right tool.

The broad deletion state recorded below has now been reclassified. SessionStart hook files are retained as native lightweight adapters. User-level hook installer, old validators, public-fork fixture harness, and stale subagent-driven-dev fixtures are accepted retirements.

## Correction Review Entry: Agent Harness Boundary

- Date: 2026-05-05
- Reviewer: Codex
- Scope: refinement from absolute prose-only cutover to Natural-Language Agent Harness boundary
- Files inspected: `docs/language-contracts/*`, canonical OpenSpec specs, active `refine-agent-harness-boundary` change, `package.json`, restored runtime/tool paths
- Old code gate or automation surface: broad class deletion of validators, tests, hooks, helper scripts, feature runtime, and package tasks
- Replacement prose: `harness-charter.md`, `runtime-automation-playbook.md`, `legacy-code-gate-map.md`, `retired-automation-register.md`
- Classification: mixed; human-facing orchestration policy moves to prose, deterministic mechanics and evidence providers remain code
- Invariants retained: manual human-facing readiness, root-owned routing decisions, package/release ledger review, public-fork review, archive boundary notes
- Invariants changed: executable code is no longer treated as automatically non-authoritative or retired
- Invariants removed: absolute prose-only package target
- Accepted deviations: exact-string validator enforcement is accepted as retired; public-fork package checks move to evidence review; stale fixture examples remain retired
- Runtime behavior lost: user-level hook installer and old validator command output
- Runtime behavior moved: cmux launcher remains companion-owned
- Runtime behavior retained as exception: native SessionStart hook adapter, visual brainstorming feature runtime, ExecPlan structure checker, bisection helper, graph renderer, and focused brainstorm server tests
- Search or inspection evidence: active OpenSpec change and restored paths are recorded in the refined maps
- Follow-up tasks: none for the formerly unresolved surfaces
- Readiness conclusion: Ready
- Rationale: the harness boundary is corrected and every formerly unresolved surface now has an explicit disposition.

## Baseline

- Date: 2026-05-05
- Reviewer: Codex
- Change: `replace-code-contracts-with-language-playbooks`
- Branch/worktree: existing `/Users/maxibon/.codex/superpowers` checkout on `main`
- Strategy: continue in the current dirty checkout because the OpenSpec artifacts and broad cutover edits already exist there; do not create a second worktree that would hide or fork the active uncommitted cutover state.
- Scope decision: superseded. The previous absolute prose-only scope is no longer the accepted boundary.

## Dirty Worktree Inventory At Cutover Start

Observed before applying the language-contract tree:

- Modified package/front-door files: `.codex-plugin/plugin.json`, `.codex/INSTALL.md`, `README.md`, `docs/README.codex.md`, `package.json`.
- Modified process and prompt files: `agents/code-reviewer.md`, process-family skills, subagent prompt templates, writing-skills references, and `skills/session-router/references/codex-tools.md`.
- Already deleted legacy aliases and automation: `commands/*.md`, cmux scripts, hook installer, cmux tests, and April 2026 cmux plan/spec docs.
- Validator files still present or moved: `_shared/validators/validate_skill_library.py`, `_shared/validators/process_family_targets.txt`, `scripts/validate_codex_public_fork.py`, `tests/codex-public-fork/run.sh`.
- Runtime bridge still present: `.codex-plugin/plugin.json` hook declaration, `hooks/hooks.json`, `hooks/session-start`.
- Feature runtime still present: `skills/brainstorming/scripts/*`.
- Reference validator still present: `skills/writing-plans/references/validate_execplan.py`.
- Additional helper and fixture surfaces in scope: `skills/systematic-debugging/find-polluter.sh`, `skills/writing-skills/render-graphs.js`, `tests/brainstorm-server/`, and `tests/subagent-driven-dev/`.
- New OpenSpec planning artifacts were untracked under `openspec/changes/replace-code-contracts-with-language-playbooks/`.
- New assets were untracked under `assets/`.

No unrelated user edits were identified during the baseline pass. The untracked assets and OpenSpec files are part of the public-fork and prose-authority cutover.

## Implementation Phase Table

| Phase | Scope | Evidence | Status |
| --- | --- | --- | --- |
| 0 | Baseline and scope control | This ledger baseline and OpenSpec status review | Superseded by refined NLAH boundary |
| 1 | Language-contract tree | `docs/language-contracts/` playbooks, map, register, template | Needs refinement to minimal harness artifacts |
| 2 | Front doors and governance | README, Codex docs, install docs, PR template, changelog, release notes | Needs recheck against refined boundary |
| 3 | Process-family replacement | Contract stubs, skill cross-reference updates, prompt packet playbook | Needs reclassification of code authority |
| 4 | Validator and harness retirement | `_shared/validators/*`, `tests/codex-public-fork/run.sh`, package scripts | Not ready until deterministic/safety value is classified |
| 5 | Hook and automation retirement | Hook files, manifest hook declaration, install helpers, cmux surfaces, visual runtime, ExecPlan validator, helper scripts, fixture tests | Not ready until runtime and utility mechanics are classified |
| 6 | Package and release cleanup | `package.json.files`, plugin metadata, package playbook | Needs recheck against retained mechanics and explicit code authorities |
| 7 | Stale-reference and archive pass | Archive notes and search ledger entry | Needs refined stale-language pass |
| 8 | Manual acceptance review | Review entries below | Not ready under refined boundary |

## Review Entry: Process And Prompt Contracts

- Date: 2026-05-05
- Reviewer: Codex
- Scope: process-family and prompt-packet replacement
- Files inspected: old process validator, target manifest, `contract/*.md`, process-family skills, subagent prompt templates
- Old code gate or automation surface: `_shared/validators/validate_skill_library.py`
- Replacement prose: `process-family-playbook.md`, `prompt-packet-playbook.md`, `review-ledger-template.md`
- Classification: policy-only validator
- Invariants retained: phase ownership, root-owned elicitation, direct `message=` dispatch, explicit child role selection, no child user requests, parent-mediated `decision_needed`
- Invariants changed: exact-string matching is replaced by manual reviewer judgment
- Invariants removed: compact SessionStart line/character budget and mandatory hook file presence
- Accepted deviations: reviewers may accept equivalent prose that satisfies the behavior even when wording differs
- Runtime behavior lost: none for prompt review itself
- Runtime behavior moved: none
- Runtime behavior retained as exception: none
- Search or inspection evidence: reviewed old validator constants and target inventory; mapped target list into `process-family-playbook.md`
- Follow-up tasks: none
- Readiness conclusion: Ready
- Rationale: The old machine-enforced behaviors are visible in prose and traceable through the map.

## Review Entry: Public Fork And Package Gates

- Date: 2026-05-05
- Reviewer: Codex
- Scope: public-fork validator, package scripts, npm payload, release docs
- Files inspected: old public-fork validator, `package.json`, plugin manifest, README, install docs, issue templates, security and conduct docs
- Old code gate or automation surface: `scripts/validate_codex_public_fork.py`, `tests/codex-public-fork/run.sh`, package `validate:*` scripts
- Replacement prose: `public-fork-playbook.md`, `package-and-release-playbook.md`
- Classification: policy-only validator, test harness, package gate
- Invariants retained: Codex-only identity, required public docs, private security/conduct route, package identity review, forbidden stale public wording review
- Invariants changed: hook files are no longer required public paths
- Invariants removed: package scripts no longer produce pass/fail validator output
- Accepted deviations: package acceptance depends on a ledgered reviewer reading package output rather than a script
- Runtime behavior lost: none; this surface was validation-only
- Runtime behavior moved: none
- Runtime behavior retained as exception: none
- Search or inspection evidence: mapped required and removed paths into public-fork playbook and package payload checklist
- Follow-up tasks: none
- Readiness conclusion: Ready
- Rationale: Public release obligations are explicit and do not depend on hidden validator code.

## Review Entry: Runtime Automation

- Date: 2026-05-05
- Reviewer: Codex
- Scope: hooks, install helpers, cmux launcher, visual brainstorming runtime, ExecPlan validator, helper scripts, fixture tests
- Files inspected: hook files, install docs, deleted scripts/tests, visual companion docs and scripts, writing-plans references, debugging and writing-skills helpers
- Old code gate or automation surface: SessionStart hook, hook installer, cmux helpers, visual companion server, ExecPlan validator, diagnostic helper scripts, writing-skill graph helper, fixture tests
- Replacement prose: `session-router-playbook.md`, `runtime-automation-playbook.md`, `retired-automation-register.md`
- Classification: runtime bridge, install/convenience, feature runtime, reference validator
- Invariants retained: native SessionStart routing starts with `session-router`; manual session routing remains the fallback; cmux is named as companion-owned; ExecPlan plans still require manual structure/evidence review
- Invariants changed: user-level hook installer, old validators, and stale fixtures are retired instead of restored as compatibility shims
- Invariants removed: user-level hook installer execution, strict validator command output, public-fork fixture execution, and stale subagent fixture execution
- Accepted deviations: old validators and stale fixtures are accepted retirements
- Runtime behavior lost: user-level hook install/remove automation
- Runtime behavior moved: cmux launcher ownership moves to a companion plugin if available
- Runtime behavior retained as exception: native SessionStart hook adapter, browser visual companion runtime, ExecPlan structure checker, diagnostic helper scripts, writing-skill graph helper, and brainstorm server fixture tests
- Search or inspection evidence: removed files are listed in `retired-automation-register.md` and mapped in `legacy-code-gate-map.md`
- Follow-up tasks: none
- Readiness conclusion: Ready
- Rationale: Runtime losses are explicit and not presented as still working.

## Review Entry: Stale References And Archives

- Date: 2026-05-05
- Reviewer: Codex
- Scope: live docs, historical plans/specs, old namespaces, removed validators, hook/bootstrap references
- Files inspected: tracked Markdown, JSON, Python, shell, JavaScript, package files
- Old code gate or automation surface: old validator and hook references across live and historical docs
- Replacement prose: front-door docs, language-contract playbooks, archive notes under `docs/plans/` and `docs/archive/superpowers/`
- Classification: stale-reference review
- Invariants retained: historical docs remain available as context
- Invariants changed: historical docs are explicitly non-authoritative
- Invariants removed: live docs no longer instruct users to run retired validators or hook installers
- Accepted deviations: archived plans may preserve stale command transcripts for history
- Runtime behavior lost: none
- Runtime behavior moved: none
- Runtime behavior retained as exception: none
- Search or inspection evidence: `rg` searches for validators, hooks, `cmux-superpowers`, old command aliases, and `superpowers:` were summarized into this ledger
- Follow-up tasks: none
- Readiness conclusion: Ready
- Rationale: Live authorities route to language contracts; archive notes prevent stale historical docs from becoming current instructions.

## Final Accepted Risks

- The following final risks are accepted under the Natural-Language Agent Harness model:
  - exact-string validator checks are no longer code gates;
  - public-fork package policy is ledger-reviewed instead of validator-enforced;
  - stale subagent fixture examples are retired rather than rewritten in this change.

The native SessionStart adapter, visual brainstorming runtime, and `validate_execplan.py` helper are retained.

## Final Readiness

Ready under the refined Natural-Language Agent Harness boundary, pending the verification commands listed below and OpenSpec archive. All previously unresolved surfaces now have explicit dispositions.

## Closeout Report: `refine-agent-harness-boundary`

- Date: 2026-05-05
- Reviewer: Codex
- OpenSpec change: `openspec/changes/refine-agent-harness-boundary`
- Change application conclusion: Applied with blockers recorded
- Full harness migration conclusion: Not ready

### Applied Boundary

The active correction narrows the previous broad prose-only migration into a Natural-Language Agent Harness policy:

- human-facing orchestration authority lives in small prose artifacts and ledgers;
- deterministic mechanics, implementation safety, feature runtime, lightweight adapters, tests, and evidence providers stay in code when code is the right tool;
- commands, tests, package tooling, manifests, hashes, and generated output are evidence by default;
- a tool becomes human-facing code authority only when a scoped playbook explicitly declares that role;
- historical broad-cutover evidence remains historical and is not rewritten.

### Exact Changed File Inventory

Tracked modified files:

- `.codex-plugin/plugin.json`
- `.codex/INSTALL.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `CHANGELOG.md`
- `README.md`
- `RELEASE-NOTES.md`
- `agents/code-reviewer.md`
- `contract/package-standards.md`
- `contract/process-family.md`
- `contract/prompt-packet.md`
- `contract/runtime-surfaces.md`
- `docs/README.codex.md`
- `package.json`
- `skills/brainstorming/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `skills/finishing-a-development-branch/SKILL.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `skills/requesting-code-review/code-reviewer.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/systematic-debugging/root-cause-tracing.md`
- `skills/test-driven-development/SKILL.md`
- `skills/using-git-worktrees/SKILL.md`
- `skills/session-router/SKILL.md`
- `skills/session-router/references/codex-tools.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/references/execplan-interop.md`
- `skills/writing-skills/SKILL.md`
- `skills/writing-skills/persuasion-principles.md`
- `skills/writing-skills/testing-skills-with-subagents.md`

Tracked deleted files:

- `_shared/validators/process_family_targets.txt`
- `_shared/validators/validate_skill_library.py`
- `commands/brainstorm.md`
- `commands/execute-plan.md`
- `commands/write-plan.md`
- `docs/archive/superpowers/plans/2026-04-11-cmux-superpowers-team-launcher.md`
- `docs/archive/superpowers/specs/2026-04-11-cmux-superpowers-team-design.md`
- `hooks/hooks.json`
- `hooks/session-start`
- `scripts/cmux_superpowers_team.py`
- `scripts/install_cmux_superpowers_launcher.py`
- `scripts/install_codex_hooks.py`
- `scripts/validate_codex_public_fork.py`
- `tests/cmux-superpowers/common.sh`
- `tests/cmux-superpowers/doctor.sh`
- `tests/cmux-superpowers/install.sh`
- `tests/cmux-superpowers/team_smoke.sh`
- `tests/codex-public-fork/run.sh`
- `tests/subagent-driven-dev/go-fractals/design.md`
- `tests/subagent-driven-dev/go-fractals/plan.md`
- `tests/subagent-driven-dev/go-fractals/scaffold.sh`
- `tests/subagent-driven-dev/svelte-todo/design.md`
- `tests/subagent-driven-dev/svelte-todo/plan.md`
- `tests/subagent-driven-dev/svelte-todo/scaffold.sh`

Untracked added files:

- `assets/app-icon.png`
- `assets/codex-workflows-small.svg`
- `docs/language-contracts/README.md`
- `docs/language-contracts/cutover-ledger.md`
- `docs/language-contracts/harness-charter.md`
- `docs/language-contracts/legacy-code-gate-map.md`
- `docs/language-contracts/package-and-release-playbook.md`
- `docs/language-contracts/process-family-playbook.md`
- `docs/language-contracts/prompt-packet-playbook.md`
- `docs/language-contracts/public-fork-playbook.md`
- `docs/language-contracts/retired-automation-register.md`
- `docs/language-contracts/review-ledger-template.md`
- `docs/language-contracts/runtime-automation-playbook.md`
- `docs/language-contracts/session-router-playbook.md`
- `docs/plans/README.md`
- `docs/codex-workflows/README.md`
- `openspec/config.yaml`
- `openspec/specs/cutover-governance/spec.md`
- `openspec/specs/language-contract-authority/spec.md`
- `openspec/specs/manual-agent-automation/spec.md`
- `openspec/specs/prose-validation-playbooks/spec.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/.openspec.yaml`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/design.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/proposal.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/specs/cutover-governance/spec.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/specs/language-contract-authority/spec.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/specs/manual-agent-automation/spec.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/specs/prose-validation-playbooks/spec.md`
- `openspec/changes/archive/2026-05-05-replace-code-contracts-with-language-playbooks/tasks.md`
- `openspec/changes/refine-agent-harness-boundary/.openspec.yaml`
- `openspec/changes/refine-agent-harness-boundary/design.md`
- `openspec/changes/refine-agent-harness-boundary/proposal.md`
- `openspec/changes/refine-agent-harness-boundary/specs/cutover-governance/spec.md`
- `openspec/changes/refine-agent-harness-boundary/specs/language-contract-authority/spec.md`
- `openspec/changes/refine-agent-harness-boundary/specs/manual-agent-automation/spec.md`
- `openspec/changes/refine-agent-harness-boundary/specs/prose-validation-playbooks/spec.md`
- `openspec/changes/refine-agent-harness-boundary/tasks.md`

### Final Dispositions

- SessionStart adapters: `.codex-plugin/plugin.json` hook declaration, `hooks/hooks.json`, and `hooks/session-start` are retained lightweight adapters.
- Hook installer: `scripts/install_codex_hooks.py` is accepted retirement because it mutates `~/.codex/hooks.json`; native plugin hooks are the supported adapter path.
- Mixed process validator: `_shared/validators/validate_skill_library.py` and `_shared/validators/process_family_targets.txt` are accepted retirements. Human-facing policy moved to playbooks; focused search and ledger review provide evidence.
- Public-fork validator and fixture harness: `scripts/validate_codex_public_fork.py` and `tests/codex-public-fork/run.sh` are accepted retirements. Public-fork readiness is ledger-controlled and package evidence comes from `npm pack --dry-run --json`, manifest inspection, docs inspection, and focused searches.
- Subagent-driven-dev fixtures: `tests/subagent-driven-dev/*` are accepted retirement because they are stale examples, not current package runtime or safety mechanics.

### Retained And Retired Mechanics

- Retained: native SessionStart hook adapter, visual brainstorming scripts, brainstorm server tests, ExecPlan structure checker, debugging bisection helper, and graph renderer.
- Accepted retirement: user-level hook installer, process validator, process target manifest, public-fork validator, public-fork fixture runner, subagent-driven-dev fixtures, and deprecated `commands/*.md` aliases.
- Companion-owned already recorded: cmux launcher scripts and cmux tests.

### Verification Evidence

- `openspec status --change refine-agent-harness-boundary`: 4/4 artifacts complete.
- `openspec instructions apply --change refine-agent-harness-boundary --json`: 29/29 tasks complete after this closeout entry.
- `openspec validate refine-agent-harness-boundary --strict`: valid after this closeout entry.
- `python3 hooks/session-start`: emitted valid `hookSpecificOutput` JSON with `hookEventName` set to `SessionStart` and additional context pointing to `codex-workflows:session-router`.
- `npm --prefix tests/brainstorm-server ci && npm --prefix tests/brainstorm-server test`: 25 passed, 0 failed.
- `npm pack --dry-run --json`: package inspection succeeded with 79 entries; payload includes `hooks/`, `docs/language-contracts/`, retained feature runtime, and retained helper scripts while excluding `_shared/`, retired validator scripts, and retired fixture harnesses.
- Focused stale-language search found no live broad prose-only claims matching the searched stale phrases.
- File-existence inspection confirmed retained runtime/evidence utilities and hook adapter files are present in the worktree; accepted-retirement surfaces remain absent.

### Closeout Decision

The `refine-agent-harness-boundary` correction is applied because the repo now records the corrected authority model, front-door routing, final classifications, and exact file inventory.

The broader Natural-Language Agent Harness migration is ready for archive after verification because all previously unresolved deterministic, adapter, validator, and fixture surfaces now have explicit dispositions.
