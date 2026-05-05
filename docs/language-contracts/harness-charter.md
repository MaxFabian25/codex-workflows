# Harness Charter

This charter replaces the earlier broad "prose-only" framing.

## Core Objective

Make the repository's agent-computer interface explicit. Human-facing workflow authority lives in small, scoped natural-language harness artifacts: charters, scoped instructions, specs, playbooks, runbooks, ledgers, ADRs, postmortems, and closeout records.

Deterministic mechanics remain in code where code is the right tool: parsers, adapters, builds, tests, migrations, formatters, safety checks, reproducible calculations, low-level validation of malformed inputs, unsafe-write prevention, and real feature runtime.

## Boundary

- Prose decides human-facing states unless the repo explicitly chooses code-gated authority.
- Tools provide evidence by default.
- Code still owns deterministic mechanics and safety.
- Historical evidence stays historical; add current boundary notes instead of rewriting old records.
- Instruction files stay small, scoped, and requirement-only.

## Instruction Precedence

1. System, developer, user, and direct repo instructions.
2. Deeper scoped `AGENTS.md` files for files under their scope.
3. Active task packets for child agents.
4. This harness charter and scoped playbooks.
5. Skill instructions and package defaults.

When two repo documents disagree, use the narrower and newer live authority. Archived evidence remains historical context.

## Decision Authority

Natural-language harness artifacts own human-facing decisions:

- ready or not ready;
- current or stale;
- final, complete, or handoff-ready;
- release, promotion, deployment, or publication suitability;
- traceability and review status;
- rollback, incident, caveat, blocker, and non-issue labels.

Tools provide evidence unless a playbook explicitly declares a code-gated authority.

## Retained Code Roles

- `deterministic-mechanic`: parsing, formatting, builds, adapters, reproducible calculations, codegen, or feature runtime.
- `implementation-safety`: malformed-input checks, missing-file checks, unsafe-path prevention, destructive-write guards, credential protections, migration checks, production-data protections, and external-side-effect guards.
- `evidence-provider`: tests, dry-runs, package inspection, hashes, generated manifests, search, and focused scripts that inform a human decision.
- `explicit-code-authority`: a deliberately retained code gate for security, compatibility, schema, migration, release, or compliance boundaries.

Hidden human-facing orchestration policy should move to playbooks and ledgers.

## Explicit Code Authority

Current explicit code-gated authority: none for human-facing package readiness.

Retained scripts, tests, and package tooling are deterministic mechanics, feature runtime, implementation safety, or evidence providers unless a scoped playbook later promotes one to explicit code authority and records the rationale.

## Protected Scopes

Fail closed before mutating credentials, production data, migrations, customer or partner files, live external systems, canonical release artifacts, generated artifacts whose source is unclear, or archived evidence that should remain historical.

If a wrong assumption could mutate a protected scope, stop and record a blocker or ask the root thread for a decision.

## Agent-Computer Interface

Every retained tool or command should have an explicit role:

- inputs;
- outputs;
- write locations;
- external side effects;
- downstream consumers;
- evidence role;
- authority role;
- stop conditions;
- human-approval points.

## Observe-Act-Feedback Loop

Major workflows follow this loop:

1. inspect current state;
2. identify authority and scope;
3. make the smallest safe change;
4. run focused evidence checks;
5. classify results;
6. continue, rollback, ask for a human decision, or close out.

Failures get a short ledger entry with the failing command or observation, relevant files, likely cause, next smallest probe, stop condition, and whether human input is needed.

## Minimal Context Rule

Do not create giant `AGENTS.md` files. Put only scoped requirements in instruction files. Use linked harness artifacts for workflow details.

## Parallel-Agent Rule

Parallel agents are read-only by default. Give each child one narrow question, require cited evidence, prohibit edits unless explicitly assigned non-overlapping ownership, and keep synthesis in the parent.

## Final Labels

Use these labels in ledgers and closeout records:

- `ready`
- `not-ready`
- `blocked`
- `ready-with-caveats`
- `non-issue`
- `needs-human-decision`
- `historical-only`
