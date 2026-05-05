## Context

The current working tree already contains a broad prose-authority implementation: validators, hook files, runtime scripts, feature tests, helper scripts, and fixture directories are deleted; `docs/language-contracts/` claims "absolute prose-only authority"; and the archived OpenSpec specs encode natural-language replacement as the primary pattern.

The user's research correction changes the target:

- Natural-Language Agent Harnesses support natural-language harness artifacts, explicit contracts, durable artifacts, and lightweight adapters. They do not imply that every executable mechanic should be deleted.
- AGENTS.md evaluation research warns that broad repo context files can reduce task success and increase cost, so context files must stay minimal and requirement-only.
- Codex agent-loop and AGENTS.md docs support explicit instruction aggregation, scoped instructions, tool/observation loops, and front-door clarity.
- SWE-agent and SWE-bench support agent-computer-interface design, multi-file reasoning, environment interaction, and verification.
- ReAct and InterCode support explicit observe-act-feedback loops.
- Reflexion supports durable textual feedback and correction memory.
- Toolformer supports treating tools/APIs as explicit callable interfaces.
- Anthropic agent-engineering guidance supports simple composable patterns, complexity only when useful, and well-documented/tested tools.
- OpenAPI is a useful analogy: an interface spec can be language-neutral and lifecycle-aware without replacing implementations.

## Goals / Non-Goals

**Goals:**

- Correct the archived prose-only plan to a Natural-Language Agent Harness plan.
- Keep deterministic mechanics in code when code is the right tool.
- Move only hidden human-facing orchestration authority to natural-language harness artifacts.
- Make the repo's agent-computer interface explicit: tools, commands, scripts, tests, inputs, outputs, write locations, side effects, evidence roles, and retained authority.
- Keep `AGENTS.md` and instruction files short, scoped, and requirement-only.
- Encode observe-act-feedback loops and failure ledgers.
- Preserve historical records by adding current boundary notes instead of rewriting old evidence.

**Non-Goals:**

- Do not create giant AGENTS files.
- Do not delete deterministic safety checks just because they are executable.
- Do not replace parsers, adapters, tests, migrations, formatters, security checks, or runtime feature mechanics with vague prose.
- Do not add wrappers, dashboards, generated control planes, or meta-agents unless they remove real ambiguity.
- Do not silently keep scripts/tests/CI as human-facing readiness authority; make any code-gated authority explicit.
- Do not rewrite archived evidence to hide the previous broad cutover.

## Decisions

### Decision 1: Rename the policy from prose-only authority to Natural-Language Agent Harness

The live docs should stop saying that repository-specific validators, hook scripts, tests, and automation are categorically not authorities. Instead:

- natural language owns human-facing workflow and decision authority;
- code owns deterministic mechanics and safety;
- tools provide evidence unless explicitly promoted to code-gated authority;
- historical evidence remains historical;
- front doors route agents to the smallest relevant harness artifact.

Alternative considered: keep "language contracts" as the top-level framing. It is close, but "agent harness" better captures interface, loop, tools, observations, artifacts, and adapters.

### Decision 2: Minimal scoped instruction files are required

`AGENTS.md` and equivalent scoped instruction files should hold only requirements that affect the scope. Broad advice and duplicate workflow prose belong in harness docs only if needed. This reduces token load and avoids context-induced over-exploration.

Alternative considered: put the full reusable prompt in `AGENTS.md`. That would directly violate the minimal-context finding.

### Decision 3: Classify code by role before deletion

Every script, test, validator, CLI task, hook, generator, and helper gets one role:

- deterministic mechanic;
- implementation safety;
- evidence provider;
- explicit code-gated authority;
- human-facing orchestration policy;
- historical record;
- unresolved blocker.

Only hidden human-facing orchestration policy should move to prose by default. Deterministic mechanics stay unless a separate product decision retires them.

Alternative considered: keep the broad retired automation register. It is useful as evidence of what happened, but not as the corrected future policy.

### Decision 4: Failure and feedback artifacts become first-class

Every major harness workflow should include:

1. inspect current state;
2. identify authority and scope;
3. make the smallest safe change;
4. run focused evidence checks;
5. classify results;
6. continue, rollback, ask for human decision, or close out.

Failures get a short ledger: failing command or observation, relevant files, likely cause, next probe, stop condition, and whether human input is required.

Alternative considered: keep only final cutover ledgers. That misses the feedback loop that lets agents recover from environment observations.

### Decision 5: Existing broad deletion state is not accepted by default

The current worktree had removed runtime scripts, validators, hooks, and tests. Under the corrected policy, those deletions are not automatically accepted. They must be reclassified:

- restore or retain deterministic mechanics and implementation safety checks;
- demote human-facing decision gates to evidence roles or natural-language ledgers;
- preserve historical records;
- document code-gated authority where the repo explicitly wants it;
- leave explicit accepted-retirement records when restoration is not justified by deterministic mechanics, safety, feature runtime, or adapter value.

Alternative considered: immediately restore all deleted files. That would be too destructive in a dirty worktree and would revert edits without explicit approval. This correction restores deterministic mechanics and the native SessionStart adapter, then records accepted retirement for stale policy gates and fixture harnesses.

## Migration Plan

### Phase 0: Record correction boundary

- Add this OpenSpec change.
- Patch language-contract docs to state the corrected boundary.
- Mark the prior absolute prose-only ledger as superseded until final refined dispositions are recorded.

### Phase 1: Build the harness charter

- Add or revise a concise harness charter.
- Define instruction precedence, protected scopes, decision authority, evidence roles, retained code checks, tool/script/test roles, live/external policy, history policy, fail-closed behavior, and final recommendation labels.

### Phase 2: Reclassify automation

- Inventory scripts/tests/hooks/validators, including deleted files from `HEAD`.
- Reclassify each as deterministic mechanic, safety, evidence provider, explicit code authority, orchestration policy, historical record, or unresolved.
- Mark broad deletions not ready until classification is complete, then record final retained or retired dispositions.

### Phase 3: Restore or explicitly retire mechanics

- Restore deterministic mechanics if their deletion has no accepted product rationale.
- Keep safety checks for malformed input, unsafe writes, missing files, destructive side effects, migrations, credentials, production data, or external systems.
- Demote decision-only validators to evidence/runbook status only when their deterministic safety value is covered.

### Phase 4: Update front doors and specs

- Update README/INDEX/AGENTS/specs/OpenSpec docs to route agents to the harness charter, not broad prose-only governance.
- Mark historical code-gate docs as archived when needed.
- Keep front-door instructions small.

### Phase 5: Verify as evidence

- Run OpenSpec validation.
- Run package inspection and focused checks relevant to changed implementation surfaces.
- Record failures in a failure ledger rather than claiming hidden authority.
- Use final closeout ledger for human-facing readiness.

## Risks / Trade-offs

- [Risk] Current broad deletion already removed useful mechanics. Mitigation: reclassify deleted files from `HEAD`, restore deterministic mechanics and the native hook adapter, and explicitly retire stale mixed policy surfaces.
- [Risk] Reintroducing code gates can recreate hidden authority. Mitigation: label each retained code gate as deterministic safety, evidence provider, or explicit authority.
- [Risk] Minimal context can omit useful guidance. Mitigation: front doors point to scoped harness docs and evidence bundles.
- [Risk] Natural-language ledgers can drift. Mitigation: keep ledgers small, date them, and tie them to exact paths and observations.
- [Risk] Too many harness docs can become another governance layer. Mitigation: keep only docs that remove ambiguity for real workflows.

## Acceptance

This correction is accepted when:

- OpenSpec deltas validate;
- live harness docs no longer claim absolute prose-only authority;
- current ledgers mark broad deletion as superseded and all formerly unresolved surfaces have final dispositions;
- automation/runbook docs distinguish deterministic mechanics from human-facing orchestration decisions;
- final reporting names the active blockers caused by prior broad deletions.
