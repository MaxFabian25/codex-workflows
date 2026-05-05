## 1. Correct The OpenSpec Boundary

- [x] 1.1 Validate this change against the archived `replace-code-contracts-with-language-playbooks` specs and confirm the delta narrows, rather than expands, the prior prose-only model.
- [x] 1.2 Update canonical OpenSpec specs or archive this change so the live spec tree no longer treats prose-only deletion as the target.
- [x] 1.3 Preserve the archived broad-cutover change as historical evidence; add a current boundary note instead of rewriting the archive.

## 2. Patch Harness Docs

- [x] 2.1 Update `docs/language-contracts/README.md` to describe Natural-Language Agent Harness authority, not absolute prose-only authority.
- [x] 2.2 Update `cutover-ledger.md` to mark the prior absolute prose-only readiness claim superseded and not-ready under the refined policy until deleted surfaces are reclassified.
- [x] 2.3 Update `legacy-code-gate-map.md` to include refined dispositions: deterministic mechanic, safety, evidence provider, explicit code authority, prose-controlled human decision, historical, accepted retirement, or unresolved blocker.
- [x] 2.4 Update `runtime-automation-playbook.md` so feature runtime, hooks, tests, validators, and helpers are not automatically retired.
- [x] 2.5 Update `package-and-release-playbook.md` so package scripts, tests, and CI are evidence or explicit authority by declaration rather than categorically excluded.
- [x] 2.6 Update `session-router-playbook.md` to allow a lightweight SessionStart adapter when its source of truth remains the natural-language router contract.
- [x] 2.7 Update `process-family-playbook.md` and `prompt-packet-playbook.md` with minimal-context, failure-ledger, and parallel-agent rules where relevant.

## 3. Reclassify Current Deletions

- [x] 3.1 Reclassify deleted validators as human-facing policy, deterministic safety, evidence provider, or mixed.
- [x] 3.2 Reclassify deleted hooks as lightweight adapter, retired adapter, or unresolved product decision.
- [x] 3.3 Reclassify deleted visual brainstorming scripts as feature runtime and mark the current deletion unresolved unless accepted product rationale exists.
- [x] 3.4 Reclassify deleted tests as deterministic behavior tests, old fixture-harness checks, or historical examples.
- [x] 3.5 Reclassify deleted helper scripts such as bisection and diagram rendering as utility mechanics or accepted retirement.
- [x] 3.6 Record every unresolved deletion as a blocker or caveat in the ledger.

## 4. Front-Door And Instruction Hygiene

- [x] 4.1 Keep README and install docs concise; route to harness artifacts without duplicating the whole prompt.
- [x] 4.2 Ensure `AGENTS.md` or equivalent scoped instructions stay short, scoped, and requirement-only.
- [x] 4.3 Remove or rewrite live wording that says commands/scripts/tests/CI can never be authoritative.
- [x] 4.4 Add explicit wording where the repo deliberately chooses a code-gated authority.

## 5. Verification And Closeout

- [x] 5.1 Run `openspec validate refine-agent-harness-boundary --strict`.
- [x] 5.2 Run focused stale-language searches for `absolute prose-only`, `no executable`, `not acceptance authorities`, `retired validators`, and similar broad claims.
- [x] 5.3 Run `openspec status --change refine-agent-harness-boundary`.
- [x] 5.4 Report exact changed files, unresolved blockers, and whether any deleted deterministic mechanics still need restoration or explicit retirement.

## 6. Final Disposition Decisions

- [x] 6.1 Restore native SessionStart adapter files and manifest declaration.
- [x] 6.2 Accept retirement of user-level hook installer.
- [x] 6.3 Accept retirement of old process and public-fork validators as hidden policy gates.
- [x] 6.4 Accept retirement of public-fork and subagent-driven-dev fixture harnesses.
- [x] 6.5 Update package payload expectations and final closeout ledger so no unresolved surfaces remain.
