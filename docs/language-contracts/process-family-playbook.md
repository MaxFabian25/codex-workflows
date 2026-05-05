# Process Family Playbook

The process family defines which Codex Workflows skill owns each phase of work. It replaces the former process-family validator and target manifest.

## Lifecycle Order

1. `design`
2. `plan`
3. `isolate`
4. `implement`
5. `review`
6. `verify`
7. `finish`

Do not let a later-phase skill restate or take over an earlier phase. When two skills overlap, use the narrower skill whose ownership matches the current phase.

## Phase Ownership

| Phase | Owner |
| --- | --- |
| `design` | `brainstorming` |
| `plan` | `writing-plans` |
| `isolate` | `using-git-worktrees` |
| `implement` | `subagent-driven-development` for write-owning child execution, or `executing-plans` for sequential execution |
| `review` | `requesting-code-review` and `receiving-code-review` |
| `verify` | `verification-before-completion` |
| `finish` | `finishing-a-development-branch` |
| read-only investigation | `dispatching-parallel-agents` |

`dispatching-parallel-agents` is not write-owning execution and is not direct user elicitation.

## Root-Owned Elicitation

- The root thread owns all user-facing decisions.
- Use `request_user_input` for eligible discrete branch-point decisions when the active session exposes it.
- Child agents must not ask the user directly and must not call `request_user_input`.
- Child agents return unresolved decisions to the parent with a `decision_needed` handoff.

## Hard-Cut Rule

Do not preserve backward-compatibility shims by default. Deprecated aliases and stale namespace surfaces should stay removed unless a later explicit product decision restores them. This rule does not justify deleting deterministic mechanics, implementation safety checks, feature runtime, or evidence tools that still have a clear role.

## Process Target Inventory

These files were the former process-family validator targets. Review them manually when a process-family change is made:

- `contract/package-standards.md`
- `contract/process-family.md`
- `contract/prompt-packet.md`
- `contract/runtime-surfaces.md`
- `skills/session-router/SKILL.md`
- `skills/session-router/references/codex-tools.md`
- `skills/brainstorming/SKILL.md`
- `skills/brainstorming/spec-document-reviewer-prompt.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-plans/plan-document-reviewer-prompt.md`
- `skills/using-git-worktrees/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md`
- `skills/executing-plans/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `skills/requesting-code-review/code-reviewer.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/finishing-a-development-branch/SKILL.md`
- `skills/writing-skills/SKILL.md`

## Manual Review Checklist

- Instruction files stay short, scoped, and requirement-only.
- Every user-facing skill has `SKILL.md` frontmatter with `name` and `description`.
- Skill descriptions are concise and route to the right phase.
- Process-family skills link to the relevant language-contract playbooks.
- Prompt-dispatch skills also link to `prompt-packet-playbook.md`.
- The root-owned elicitation rule is present in dispatch and review packet surfaces.
- Stale dispatch formats such as nested YAML packets, `items:`, `Task tool`, and inner `agent_type:` fields are not used as live guidance.
- Historical docs that still mention removed validators or old namespaces are treated as archived context.
- `.DS_Store`, `__pycache__`, and generated cache artifacts are not intentionally shipped.

## Failure Ledger Rule

When a process-family review fails, record:

- failing command or observation;
- relevant files;
- likely cause;
- next smallest probe;
- stop condition;
- whether human input is needed.

## ExecPlan Review

`skills/writing-plans/references/validate_execplan.py` is a deterministic structure and evidence helper. It does not decide human-facing readiness by itself. When a repo requires an ExecPlan-compatible plan, reviewers inspect the plan manually for:

- required sections defined by the repo;
- clear goal, architecture, file ownership, and verification commands;
- no placeholders;
- complete evidence for claims;
- no nested fence breakage in Markdown;
- explicit task boundaries and stop conditions.

Record the review in the cutover or project ledger. Cite validator output as evidence when it was run, and state whether it is evidence only or explicit code authority for that repo.
