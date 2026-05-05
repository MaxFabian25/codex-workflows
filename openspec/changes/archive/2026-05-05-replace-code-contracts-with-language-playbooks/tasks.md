## 1. Baseline And Scope Control

- [x] 1.1 Record the current dirty worktree state with special attention to pre-existing edits, deleted legacy commands, deleted cmux scripts, deleted hook installer, changed docs, changed manifest, and untracked assets.
- [x] 1.2 Create a cutover baseline note listing every existing code-backed contract, validator, fixture harness, hook, install helper, package script, and runtime helper in the current working tree and in `HEAD` for already-deleted paths.
- [x] 1.3 Decide and record whether implementation is absolute prose-only or prose authority with explicit runtime exceptions; if no new decision is supplied, proceed with the absolute prose-only interpretation requested by this plan.
- [x] 1.4 Identify unrelated user or prior-agent edits and keep them out of the OpenSpec cutover commit stack unless they directly affect the cutover.
- [x] 1.5 Record the implementation branch/worktree strategy before editing existing files.

## 2. Language-Contract Authority Tree

- [x] 2.1 Create `docs/language-contracts/README.md` describing the natural-language authority model and linking every playbook.
- [x] 2.2 Create `docs/language-contracts/session-router-playbook.md` replacing automatic router assumptions with manual session-start instructions.
- [x] 2.3 Create `docs/language-contracts/process-family-playbook.md` covering lifecycle order, process skill ownership, root-owned elicitation, child handoffs, hard-cut rules, and skill cross-reference expectations.
- [x] 2.4 Create `docs/language-contracts/prompt-packet-playbook.md` covering subagent dispatch shape, direct `message=` usage, role selection, inherited child config, no-child-elicitation behavior, `decision_needed` handoffs, and report schemas.
- [x] 2.5 Create `docs/language-contracts/package-and-release-playbook.md` covering package metadata, package files, release docs, changelog, npm payload intent, local marketplace/cache sync expectations, and manual package review.
- [x] 2.6 Create `docs/language-contracts/public-fork-playbook.md` covering public path requirements, removed path requirements, forbidden private/non-Codex wording, docs checks, issue templates, security policy, conduct policy, and public release hygiene.
- [x] 2.7 Create `docs/language-contracts/runtime-automation-playbook.md` covering hook, install, launcher, command alias, brainstorming runtime, and helper-script classification.
- [x] 2.8 Create `docs/language-contracts/review-ledger-template.md` with fields for scope, inspected files, old code gate, replacement prose, retained/changed/removed invariants, accepted deviations, runtime losses, follow-up tasks, reviewer, date, and readiness conclusion.
- [x] 2.9 Create `docs/language-contracts/cutover-ledger.md` and initialize it with the baseline inventory and implementation phase table.
- [x] 2.10 Create `docs/language-contracts/legacy-code-gate-map.md` mapping every old validator/test/script/hook/package gate to its replacement playbook, retired entry, or companion-owner entry.
- [x] 2.11 Create `docs/language-contracts/retired-automation-register.md` for command aliases, removed install helpers, removed cmux launcher surfaces, removed hook bootstrap surfaces, and any retired feature runtime.

## 3. Front-Door And Governance Rewrites

- [x] 3.1 Update `README.md` so the natural-language contract authority is the first place agents are directed for package behavior and verification.
- [x] 3.2 Update `docs/README.codex.md` so install, troubleshooting, SessionStart, release, and verification sections reference playbooks and ledgers rather than validator commands.
- [x] 3.3 Update `.codex/INSTALL.md` so manual install and manual session-start behavior are explicit if hook automation is retired.
- [x] 3.4 Update `.github/PULL_REQUEST_TEMPLATE.md` to request ledger links and manual signoff instead of validator transcripts.
- [x] 3.5 Update `CHANGELOG.md` and `RELEASE-NOTES.md` with breaking-change language for removal of code-backed gates and any automatic runtime behavior retired.
- [x] 3.6 Review `.github/ISSUE_TEMPLATE/*`, `SECURITY.md`, and `CODE_OF_CONDUCT.md` for references to validator-backed or old public-fork assumptions and update only in scope.

## 4. Process-Family Contract Replacement

- [x] 4.1 Rewrite or reroute `contract/process-family.md` to the new process-family playbook authority.
- [x] 4.2 Rewrite or reroute `contract/prompt-packet.md` to the new prompt-packet playbook authority.
- [x] 4.3 Rewrite or reroute `contract/package-standards.md` to the package-and-release playbook authority.
- [x] 4.4 Rewrite or reroute `contract/runtime-surfaces.md` to the runtime-automation playbook authority.
- [x] 4.5 Update process-family skill cross-references in `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/dispatching-parallel-agents/SKILL.md`, `skills/subagent-driven-development/SKILL.md`, `skills/requesting-code-review/SKILL.md`, and other affected skills.
- [x] 4.6 Update subagent prompt templates so they read naturally and no longer preserve exact validator-mandated phrases purely for machine matching.
- [x] 4.7 Convert important validator-enforced examples into prose scenarios in the relevant playbooks.
- [x] 4.8 Fill a process-family evidence ledger entry proving every old process-family target has a prose successor or accepted retirement note.

## 5. Validator And Test Harness Retirement

- [x] 5.1 Convert `_shared/validators/validate_skill_library.py` behavior into checklist items in `process-family-playbook.md`, `prompt-packet-playbook.md`, and `review-ledger-template.md`.
- [x] 5.2 Convert `_shared/validators/process_family_targets.txt` behavior into the target inventory section of `legacy-code-gate-map.md`.
- [x] 5.3 Remove `_shared/validators/process_family_targets.txt` only after the target inventory is complete.
- [x] 5.4 Remove `_shared/validators/validate_skill_library.py` only after the process-family ledger entry is complete.
- [x] 5.5 Convert `_shared/validators/validate_codex_public_fork.py` behavior into `public-fork-playbook.md`, `package-and-release-playbook.md`, and the public-fork ledger entry.
- [x] 5.6 Convert `tests/codex-public-fork/run.sh` fixture scenarios into prose examples or checklist items.
- [x] 5.7 Remove `tests/codex-public-fork/run.sh` only after public-fork fixture scenarios are represented in prose or intentionally retired.
- [x] 5.8 Remove package scripts `validate:process-family` and `validate:public-fork` from `package.json`.
- [x] 5.9 Update package file lists to exclude retired validator and test directories if no longer shipped.
- [x] 5.10 Fill a validator-retirement ledger entry stating the loss of deterministic checking and the accepted manual-review replacement.

## 6. Hook And Automation Replacement

- [x] 6.1 Classify `hooks/hooks.json` and `hooks/session-start` as runtime bridge automation and decide whether automatic SessionStart is retired, moved, or retained as an explicit exception.
- [x] 6.2 If automatic SessionStart is retired, remove the manifest hook declaration from `.codex-plugin/plugin.json`, remove `hooks/hooks.json`, remove `hooks/session-start`, and update install docs to the manual session-start playbook.
- [x] 6.3 If automatic SessionStart is retained as an exception, record the exception in `runtime-automation-playbook.md`, `legacy-code-gate-map.md`, and `cutover-ledger.md`.
- [x] 6.4 Classify already-deleted `commands/brainstorm.md`, `commands/write-plan.md`, and `commands/execute-plan.md` as deprecated aliases and record their modern replacements in `retired-automation-register.md`.
- [x] 6.5 Classify already-deleted `scripts/install_codex_hooks.py` as retired user-level hook bootstrap automation and record the manual or native-plugin replacement.
- [x] 6.6 Classify already-deleted cmux launcher scripts and tests as moved, retired, or companion-owned; verify the docs do not imply this package still owns them unless companion ownership is real.
- [x] 6.7 Classify `skills/brainstorming/scripts/server.cjs`, `start-server.sh`, `stop-server.sh`, `helper.js`, and `frame-template.html` as feature runtime.
- [x] 6.8 If the absolute prose-only target is kept, retire or move the visual brainstorming runtime and update `skills/brainstorming/SKILL.md` and `skills/brainstorming/visual-companion.md`.
- [x] 6.9 If visual brainstorming runtime is retained as an exception, record it explicitly in the runtime playbook and cutover ledger.
- [x] 6.10 Classify `skills/writing-plans/references/validate_execplan.py` as a reference validator and replace it with prose review criteria if it remains in the package.
- [x] 6.11 Fill an automation-retirement ledger entry for every removed or retained-exception automation surface.

## 7. Package, Manifest, And Runtime-Copy Cleanup

- [x] 7.1 Update `.codex-plugin/plugin.json` to remove or revise `hooks` and `defaultPrompt` assumptions according to the SessionStart decision.
- [x] 7.2 Update package metadata and `files` entries so shipped artifacts match the natural-language authority model.
- [x] 7.3 Update `package.json` scripts so no removed validator command remains advertised.
- [x] 7.4 Review `assets/`, docs, and manifest UI metadata for stale validator, hook, command, or companion-plugin wording.
- [x] 7.5 Document any required local marketplace/cache sync as a manual release playbook step rather than a script.
- [x] 7.6 Fill a package/release evidence ledger entry confirming intended shipped files by reading package configuration and recording reviewer judgment.

## 8. Stale Reference And Historical Authority Pass

- [x] 8.1 Search tracked Markdown, JSON, Python, shell, JavaScript, and package files for references to retired validators, validator scripts, old commands, deleted install scripts, old hook bootstrap paths, and stale namespaces.
- [x] 8.2 Decide whether `docs/superpowers/plans/*`, `docs/superpowers/specs/*`, `docs/plans/*`, and test fixture plans are historical archives or live authorities.
- [x] 8.3 Add a non-authoritative archive note to historical docs if stale code-gate content remains intentionally preserved.
- [x] 8.4 Remove or rewrite stale references in live docs and skill entrypoints.
- [x] 8.5 Fill a stale-reference ledger entry listing searched patterns and accepted archive exceptions.

## 9. Manual Acceptance Review

- [x] 9.1 Perform a contract review using `docs/language-contracts/process-family-playbook.md` and `prompt-packet-playbook.md`.
- [x] 9.2 Perform a public-fork review using `public-fork-playbook.md`.
- [x] 9.3 Perform a package/release review using `package-and-release-playbook.md`.
- [x] 9.4 Perform a runtime automation review using `runtime-automation-playbook.md`.
- [x] 9.5 Perform a front-door review by reading `README.md`, `docs/README.codex.md`, and `.codex/INSTALL.md` from scratch as a new agent.
- [x] 9.6 Perform a final ledger consistency review, ensuring every old code gate has exactly one retained, replaced, moved, or retired status.
- [x] 9.7 State the accepted risks in `cutover-ledger.md`, especially loss of deterministic validation and any loss of automatic SessionStart or visual runtime behavior.
- [x] 9.8 Mark the cutover ready only if reviewers can understand package obligations without executing repository-specific validators.

## 10. OpenSpec Closeout

- [x] 10.1 Run `openspec status --change replace-code-contracts-with-language-playbooks` to confirm OpenSpec artifacts are complete before implementation begins.
- [x] 10.2 Run `openspec validate replace-code-contracts-with-language-playbooks --strict` if available in the local CLI and record any OpenSpec planning issues separately from product validation.
- [x] 10.3 Keep this OpenSpec change open until implementation and manual ledgers are complete.
- [x] 10.4 Archive this OpenSpec change only after the natural-language authority tree, retired-surface register, ledgers, and front-door rewrites are accepted.
