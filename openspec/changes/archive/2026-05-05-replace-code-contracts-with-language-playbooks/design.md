## Context

Superpowers for Codex currently uses Markdown for most human-facing guidance, but important acceptance rules are encoded in executable surfaces:

- `hooks/hooks.json` and `hooks/session-start` inject the session-router packet at runtime.
- `_shared/validators/validate_skill_library.py` enforces exact process-family targets, prompt wrapper strings, child elicitation rules, compact SessionStart text, and stale artifact bans.
- `_shared/validators/validate_codex_public_fork.py` enforces package metadata, required and removed paths, hook shape, install docs, release docs, issue templates, npm package payload, and public-fork wording.
- `tests/codex-public-fork/run.sh` creates fixture repos and tests validator behavior.
- `package.json` exposes validator scripts as the release-facing gate.
- `skills/brainstorming/scripts/*` provide real browser/server runtime behavior, not just validation.
- `skills/writing-plans/references/validate_execplan.py` makes the ExecPlan reference stricter than prose alone.

The user's requested direction is the inverse of the current architecture: replace code-based contracts, validations, and automation scripts with complete natural-language-based alternatives for improved agent performance. The intended performance improvement is not runtime speed. It is agent interpretability: agents should see the contract directly in the files they read, without depending on hidden code to reject violations after the fact.

This design treats the requested change as a deliberate breaking cutover. It does not preserve hidden validators as the authority. Instead, it builds a visible language-contract system with review playbooks and evidence ledgers. Where code currently provides actual runtime behavior, this plan requires an explicit decision: convert it to manual agent workflow, move it to an external companion surface, or retire the feature.

## Goals / Non-Goals

**Goals:**

- Define a complete replacement plan for code-backed contracts, validations, and automation scripts using natural-language artifacts.
- Make every previous machine-enforced invariant visible as a named prose requirement, checklist item, or evidence-ledger field.
- Create a migration map that lets an agent remove old code gates without losing track of what each gate protected.
- Separate "contract authority" from "runtime capability" so scripts that only enforce policy can be retired differently from scripts that deliver user-facing behavior.
- Favor hard cutovers and removal of stale paths instead of compatibility shims.
- Keep the plan safe to execute in the current dirty worktree by limiting this turn to OpenSpec planning artifacts.

**Non-Goals:**

- This plan does not implement the cutover.
- This plan does not claim a prose-only replacement is behaviorally equivalent to executable validators.
- This plan does not silently retain validators as hidden authority.
- This plan does not add a new script, parser, schema, CI job, or code-based checker to replace the old ones.
- This plan does not decide whether automatic SessionStart routing must survive. It documents the manual alternative and the cost of removing the hook.
- This plan does not rewrite runtime feature code such as the brainstorming browser server unless the implementation phase chooses to retire that feature or move it out of this package.

## Decisions

### Decision 1: Make prose the source of truth, not a commentary layer

The implementation will create a `docs/language-contracts/` authority tree and route front-door docs to it. Contract files may remain in `contract/` for package compatibility during the transition, but the accepted end state is a human-readable tree that explains obligations directly:

- session routing and skill selection;
- subagent dispatch packet shape;
- root-owned user elicitation;
- child-agent handoff behavior;
- review ordering and severity language;
- package contents and release checklist;
- hook/runtime expectations;
- public-fork hygiene and removed-path policy;
- local marketplace/cache sync expectations, if still needed.

Alternative considered: keep existing Markdown contracts and only remove validators. That would be faster, but it would leave old files shaped around machine-required exact strings rather than agent-readable decision flow.

### Decision 2: Replace validators with playbooks plus ledgers

Each validator becomes two prose artifacts:

- a playbook that describes how to review the contract manually;
- a ledger template that records evidence and reviewer decisions.

For `validate_skill_library.py`, the replacement playbook must include sections for:

- process-family target inventory;
- skill description clarity;
- subagent prompt packet shape;
- child no-elicitation rule;
- root-owned decision rule;
- SessionStart router text, if SessionStart is retained;
- forbidden stale dispatch formats;
- stale artifacts such as `.DS_Store` and `__pycache__`;
- contract cross-references.

For `validate_codex_public_fork.py`, the replacement playbook must include sections for:

- required public paths;
- deliberately removed paths;
- package metadata;
- npm payload review by reading `package.json`;
- manifest fields;
- hook fields, if retained;
- install docs;
- issue templates, security policy, conduct policy, release notes, and changelog;
- forbidden private or non-Codex wording.

Alternative considered: build a smaller validator that checks only the ledger. That would keep a code gate, which conflicts with the requested complete natural-language alternative.

### Decision 3: Treat runtime scripts differently from policy scripts

Not all scripts are equivalent:

- Policy scripts and validators can become playbooks.
- Install scripts can become manual installation guides.
- Deprecated alias commands can be retired.
- Native hook scripts provide runtime integration and cannot be replaced by prose without losing automatic injection.
- Browser companion scripts provide real interactive behavior and cannot be replaced by prose without retiring or downgrading that feature.

The plan therefore requires classification before deletion:

1. **Policy-only**: replace with playbook and remove code.
2. **Install/convenience**: replace with manual procedure and remove code.
3. **Runtime bridge**: either accept manual workflow, move to companion plugin, or retain as a named exception outside this cutover.
4. **Feature runtime**: either retire the feature, move the feature to a separate package, or keep the code and declare it out of scope for the prose-only contract cutover.

Alternative considered: delete every executable file under `hooks/`, `scripts/`, `tests/`, and `skills/**/scripts`. That is exhaustive but technically destructive. It would remove automatic session routing and visual brainstorming runtime behavior.

### Decision 4: Make automatic SessionStart routing an explicit product decision

If the natural-language cutover is absolute, `hooks/hooks.json`, `hooks/session-start`, and the plugin manifest hook declaration must be removed or made non-authoritative. The replacement is a manual session-start playbook:

1. At the start of a session, read the session-router contract.
2. Decide whether a skill applies.
3. Load the narrowest matching skill.
4. If dispatched as a subagent, skip the router.
5. Give user, system, developer, and repo instructions priority.

This is agent-visible and code-free, but it sacrifices automatic injection. The plan must make that trade-off explicit.

Alternative considered: keep the hook script as a minimal compatibility bridge while replacing all other validators. That is safer operationally but not a complete replacement of automation scripts.

### Decision 5: Use ledgers as acceptance records

Every implementation slice must produce an evidence ledger. The ledger is a Markdown record, not generated data. It must include:

- date and author;
- scope;
- files inspected;
- old code gate being replaced;
- new language contract location;
- reviewer judgment;
- accepted deviations;
- runtime behavior lost, retained, or moved;
- follow-up tasks;
- explicit "ready" or "not ready" conclusion.

Alternative considered: rely on the final PR description. That is too late and too coarse for a multi-surface cutover.

### Decision 6: Keep OpenSpec as the planning layer for this change

OpenSpec is used to write the plan, specs, and tasks. This does not mean the final implementation will keep OpenSpec as a permanent machine gate for the package. OpenSpec validation can be used to verify these planning artifacts before implementation, because the user explicitly requested `$openspec`.

Alternative considered: write a standalone Markdown plan outside OpenSpec. That would be simpler but would ignore the requested workflow.

## Replacement Architecture

### New documentation authority tree

The implementation should create these planned artifacts:

- `docs/language-contracts/README.md`
- `docs/language-contracts/session-router-playbook.md`
- `docs/language-contracts/process-family-playbook.md`
- `docs/language-contracts/prompt-packet-playbook.md`
- `docs/language-contracts/package-and-release-playbook.md`
- `docs/language-contracts/public-fork-playbook.md`
- `docs/language-contracts/runtime-automation-playbook.md`
- `docs/language-contracts/review-ledger-template.md`
- `docs/language-contracts/cutover-ledger.md`
- `docs/language-contracts/legacy-code-gate-map.md`
- `docs/language-contracts/retired-automation-register.md`

The `README.md`, `.codex/INSTALL.md`, and `docs/README.codex.md` front doors should point to this tree as the contract authority.

### Legacy code-gate map

The migration map should include at least these rows:

- `_shared/validators/validate_skill_library.py` -> `docs/language-contracts/process-family-playbook.md` and `review-ledger-template.md`
- `_shared/validators/process_family_targets.txt` -> `docs/language-contracts/process-family-playbook.md` target inventory section
- `_shared/validators/validate_codex_public_fork.py` -> `docs/language-contracts/public-fork-playbook.md`
- `tests/codex-public-fork/run.sh` -> `docs/language-contracts/public-fork-playbook.md` and fixture-review checklist
- `package.json` validator scripts -> `docs/language-contracts/package-and-release-playbook.md`
- `hooks/hooks.json` -> `docs/language-contracts/session-router-playbook.md`, if automatic hooks are retired
- `hooks/session-start` -> `docs/language-contracts/session-router-playbook.md`, if automatic hooks are retired
- `skills/writing-plans/references/validate_execplan.py` -> `docs/language-contracts/process-family-playbook.md` ExecPlan review section
- `skills/brainstorming/scripts/*` -> `docs/language-contracts/runtime-automation-playbook.md`, with a feature-retirement or companion-package decision
- already-deleted `commands/*` -> `docs/language-contracts/retired-automation-register.md`
- already-deleted legacy `scripts/*` -> `docs/language-contracts/retired-automation-register.md`

### Review ledger workflow

Every replacement must follow this manual sequence:

1. Identify the old gate.
2. Read the old gate's behavior.
3. Copy each enforced invariant into a prose checklist.
4. Mark whether each invariant is retained, changed, or removed.
5. Add an evidence entry showing where the new prose contract lives.
6. Record runtime or quality risk.
7. Require a second read-through for high-risk surfaces such as hooks, package release, and subagent dispatch.
8. Close the ledger with a clear acceptance statement.

### Manual quality gates

The implementation cannot use code validators as final proof. Instead it should use manual gates:

- Contract review gate: all new playbooks are internally consistent and linked from front doors.
- Dispatch review gate: every subagent prompt still tells children not to ask the user directly and states how to return unresolved decisions.
- Release review gate: package contents are described in prose and manually compared to intended package files.
- Runtime review gate: any removed automation has a documented manual replacement, companion owner, or retired-feature note.
- Drift review gate: stale references to removed validators, scripts, and hooks are manually searched and logged.
- Signoff gate: the cutover ledger states whether the package is ready despite loss of machine enforcement.

These gates are intentionally natural-language procedures. The implementation may use `rg`, `git diff`, and `git status` as inspection aids while writing the ledger, but the accepted authority is the written review judgment.

## Migration Plan

### Phase 0: Freeze scope and baseline

- Record current dirty worktree state without reverting user changes.
- Identify which current deletions already point toward the cutover, especially deleted legacy commands, cmux scripts, hook installer, and cmux tests.
- Create a baseline inventory of code-backed contracts, validators, and automation.
- Decide whether this change is "absolute prose-only" or "prose authority with minimal runtime exceptions." The requested plan assumes absolute prose-only, but the implementation must still record runtime losses.

### Phase 1: Build the language-contract tree

- Add the new `docs/language-contracts/` authority tree.
- Write the overview first, then focused playbooks.
- Keep every old invariant traceable to a new prose clause or an explicit removal entry.
- Add ledger templates before deleting validators so reviewers have somewhere to record evidence.

### Phase 2: Rewrite front doors and package guidance

- Update `README.md`, `docs/README.codex.md`, and `.codex/INSTALL.md` to point to manual playbooks instead of code validators.
- Update `.github/PULL_REQUEST_TEMPLATE.md` to request ledger links instead of validator transcript snippets.
- Update release docs to explain that acceptance is prose-led.

### Phase 3: Replace process-family validator authority

- Rewrite `contract/*.md` or move their authority into `docs/language-contracts/`.
- Update skill cross-references to the new prose authority.
- Replace exact-string validator assumptions with explicit natural-language criteria.
- Remove `_shared/validators/process_family_targets.txt` after every target has a prose successor.
- Remove `_shared/validators/validate_skill_library.py`.
- Remove `npm run validate:process-family` from `package.json`.

### Phase 4: Replace public-fork validator authority

- Write the public-fork playbook from the current validator behavior.
- Create a public-fork ledger template.
- Remove public-fork fixture-harness expectations from `tests/codex-public-fork/run.sh`, then retire the test harness when the playbook covers every behavior.
- Remove `_shared/validators/validate_codex_public_fork.py`.
- Remove `npm run validate:public-fork` from `package.json`.

### Phase 5: Replace hook and automation behavior

- Decide whether automatic SessionStart is retired, moved, or retained as an explicit exception.
- If retired, remove plugin manifest hook declaration, `hooks/hooks.json`, and `hooks/session-start`; replace install docs with manual session-router instructions.
- If moved, create a companion-owner note and remove hook ownership from this package.
- Review `skills/brainstorming/scripts/*`. If the goal remains absolute prose-only, retire visual companion runtime or move it to a separate plugin/package. If the feature must survive, declare it out of scope for the automation cutover.
- Replace install and launcher automation references with manual steps or retired-surface entries.

### Phase 6: Package and release cleanup

- Update `package.json.files` so removed code directories are not shipped.
- Update `package.json.scripts` so it does not expose removed validators.
- Remove or update package docs that promise executable validation.
- Update changelog and release notes with a breaking-change section.
- If runtime copies in local marketplace/cache must be synced, document that as a manual release step rather than a script.

### Phase 7: Manual acceptance review

- Fill the cutover ledger.
- Run a manual stale-reference pass using search as an inspection aid.
- Review each playbook against the old validator behavior.
- State accepted losses: no automatic validation, no automatic hook if retired, no automated feature runtime if retired.
- Record final readiness in prose.

## Risks / Trade-offs

- [Risk] Agents miss subtle regressions that validators used to catch. Mitigation: make each old invariant a named checklist item and require evidence-ledger entries for every removal.
- [Risk] Removing `hooks/session-start` loses automatic router injection. Mitigation: document a manual session-start playbook and state that this is a product trade-off, not a transparent replacement.
- [Risk] Removing package validators lets release payload drift. Mitigation: add a package-and-release playbook with an explicit package file review.
- [Risk] Removing fixture tests loses regression examples. Mitigation: convert important fixture cases into prose scenarios and review examples.
- [Risk] Removing brainstorming scripts removes a working browser workflow. Mitigation: classify it as feature runtime and either move it to a companion package or retire the feature with a clear note.
- [Risk] Historical plans/specs keep stale references alive. Mitigation: add a stale-authority review and mark archival docs as non-authoritative.
- [Risk] The current dirty worktree contains unrelated edits. Mitigation: implementation tasks must preserve user changes, inspect conflicts before editing, and keep the OpenSpec cutover commits scoped.

## Acceptance Strategy

Because the requested end state removes code validators, acceptance must be documented rather than machine-proven. The implementation is accepted only when:

- every old validator/test/script surface is mapped to a prose playbook, retired register entry, or companion-owner entry;
- front-door docs identify the natural-language contract authority;
- package scripts no longer advertise removed validators;
- removed runtime behavior is explicitly listed;
- ledgers contain evidence for each high-risk replacement;
- reviewers can read the package from scratch and understand the obligations without executing a custom validator.

OpenSpec validation remains acceptable for this proposal package before implementation because it validates the plan structure requested through `$openspec`, not the final product contract.
