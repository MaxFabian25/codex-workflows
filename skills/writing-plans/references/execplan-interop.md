# ExecPlan Interop Notes

Use this reference when a repository already mandates `.agents/PLANS.md`, a top-level `PLANS.md`, or the user explicitly asks for an Execution-Plan / ExecPlan instead of the default superpowers plan format.

## When to Switch Formats

Switch from the default `docs/superpowers/plans/...` format to ExecPlan-compatible output when any of these are true:

- the repo already contains `.agents/PLANS.md`;
- the repo has another documented planning standard that names `PLANS.md` or `ExecPlan`;
- the user explicitly asks for `PLANS.md`, `Execution-Plan`, or `ExecPlan`;
- the repo expects a living plan that remains current during implementation.

## Preflight Checks

Before writing the plan:

1. Check whether `.agents/PLANS.md` exists and read it fully if present.
2. Else, check for a top-level `PLANS.md` or another documented planning standard.
3. If neither exists but the repo needs an ExecPlan workflow, use `PLANS.md` in this directory as the bootstrap reference.

## Required Living Sections

ExecPlan-compatible output must keep these sections current:

- `Progress`
- `Surprises & Discoveries`
- `Decision Log`
- `Outcomes & Retrospective`

These are not optional in ExecPlan mode.

## Context Pack

Collect this context before writing the plan:

1. `objective`: intended engineering outcome.
2. `constraints`: policy, repo standards, timeline, and safety boundaries.
3. `known_state`: observed repository and environment facts.
4. `unknowns`: unresolved implementation or dependency questions.
5. `success_criteria`: observable completion and verification expectations.

## Dependency-Aware Task Structuring

Use these patterns when the plan needs explicit dependency structure:

- Pattern A: independent workstreams with no shared state can be planned for parallel execution.
- Pattern B: dependent workstreams need an explicit contract and sequencing boundary.
- Pattern C: milestone execution with subagents needs scoped ownership plus review before integration.

Use dependency notes only when they clarify execution. Do not turn a simple plan into a dependency graph for its own sake.

## Validation

When ExecPlan validation is warranted, run:

    python3 references/validate_execplan.py <plan-file> --strict-evidence

For machine-readable output:

    python3 references/validate_execplan.py <plan-file> --strict-evidence --json

Useful fixtures in this directory:

- `execplan.example.valid.md`
- `execplan.example.invalid.missing-section.md`
- `execplan.example.invalid.incomplete-evidence.md`
- `execplan.example.invalid.nested-fence.md`

## Repo Bootstrap

If the repo needs ExecPlan support but lacks `.agents/PLANS.md`:

1. Copy `PLANS.md` from this directory into `.agents/PLANS.md`.
2. Add the `AGENTS.execplans.snippet.md` guidance to the repo's `AGENTS.md`.
3. Keep `writing-plans` as the plan-phase owner; do not fold execution guidance back into plan authoring.
