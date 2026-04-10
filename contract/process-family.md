# Process Family Contract

## Lifecycle Order

The process family owns one canonical phase order:

1. `design`
2. `plan`
3. `isolate`
4. `implement`
5. `review`
6. `verify`
7. `finish`

## Ownership Rules

- `brainstorming` owns `design` only.
- `writing-plans` owns `plan` only.
- `using-git-worktrees` owns `isolate` only.
- `subagent-driven-development` owns write-owning implementation in the current session.
- `executing-plans` owns sequential or separate-session implementation.
- `dispatching-parallel-agents` is for read-only or non-owning parallel investigation, not write-owning execution or direct user elicitation.
- `requesting-code-review` and `receiving-code-review` own review interactions, not verification or finish decisions.
- `verification-before-completion` owns evidence collection before success claims.
- `finishing-a-development-branch` owns closeout after verification passes.

## Root-Owned Elicitation

- The root thread owns all user decisions.
- When available, use `request_user_input` for discrete branch-point decisions.
- Child agents never ask the user directly.
- Child agents return unresolved decisions to the parent using a `decision_needed` handoff.

## Hard-Cut Rules

- Do not preserve backward-compatibility shims by default.
- Do not let later-phase skills restate earlier-phase ownership.
- When two skills overlap, prefer the narrower skill whose ownership matches the current phase.

## Required Cross-References

Process-family skills should point to:

- `../../contract/process-family.md`
- `../../contract/prompt-packet.md` when they dispatch subagents
- `../../contract/package-standards.md`
