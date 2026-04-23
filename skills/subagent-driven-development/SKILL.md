---
name: subagent-driven-development
description: Use when executing an implementation plan with write-owning task work in the current session
---

# Subagent-Driven Development

Execute an implementation plan by dispatching one fresh write-owning implementer per task, then reviewing that task with two read-only passes: spec compliance first, code quality second.

**Core principle:** Fresh implementer per task, then spec review, then code-quality review.

**Contract references:** Follow [../../contract/process-family.md](../../contract/process-family.md), [../../contract/package-standards.md](../../contract/package-standards.md), and [../../contract/prompt-packet.md](../../contract/prompt-packet.md) when writing or updating this workflow.

## When to Use

- Use after a written implementation plan is approved and an isolated worktree exists.
- Use when tasks can be executed task-by-task by a single active write-owning child.
- Use `executing-plans` instead when execution must stay inline or in a separate sequential session.
- Return to planning when tasks are tightly coupled, underspecified, or cannot be reviewed independently.

## Workflow

### 1. Initialize controller state

- Read the full plan once.
- Extract each task with its files, requirements, and verification commands.
- Record the task-start SHA before dispatching each implementation task.
- Initialize or update parent `update_plan(...)` tracking.

### 2. Dispatch one implementer

- Fill `./implementer-prompt.md` with exactly one task, relevant plan context, current branch/worktree context, and required verification.
- Dispatch with `spawn_agent(task_name=..., agent_type="implementer", message="...")`.
- Keep only one write-owning implementer active for the current task.

### 3. Handle implementer status

- `DONE`: inspect the summary and proceed to spec review.
- `DONE_WITH_CONCERNS`: read concerns first; resolve correctness or scope concerns before review.
- `NEEDS_CONTEXT`: add the missing context and re-dispatch a revised bounded packet.
- `BLOCKED`: change the plan, scope, context, or ownership before any re-dispatch.

Never re-dispatch unchanged after an escalation.

### 4. Run task reviews

- Dispatch `spec_reviewer` with `./spec-reviewer-prompt.md`.
- If spec review finds gaps, send the implementer a bounded fix packet and repeat spec review.
- After spec review passes, fill the shared `../requesting-code-review/code-reviewer.md` template, embed it in `./code-quality-reviewer-prompt.md`, and dispatch `code_quality_reviewer`.
- If code-quality review finds blocking issues, send the implementer a bounded fix packet and repeat the relevant review.

### 5. Complete the task

- Verify the required command evidence in the parent thread.
- Mark the task complete only after implementation, spec review, code-quality review, and parent verification are done.
- Repeat from step 2 for the next task.

### 6. Finish the change

- After all tasks are complete, dispatch `final_reviewer` with the filled shared `../requesting-code-review/code-reviewer.md` template directly.
- Resolve final-review findings before closeout.
- Use `superpowers:finishing-a-development-branch` for merge, PR, keep, or discard decisions.

## Child Boundaries and Role Mapping

Child agents inherit the parent session config by default. Preserve that inheritance unless the user explicitly asks for a role-specific override.

- Children may escalate to the parent/root thread, but may not ask the user directly or call `request_user_input`.
- Do not pass `model` or `reasoning_effort` in `spawn_agent(task_name=..., agent_type="...", message="...")` during normal operation.
- Use the config-owned superpowers role mapping instead of generic built-in role guessing:
  - `implementer` for the single active write-owning child
  - `spec_reviewer` for the read-only spec compliance pass
  - `code_quality_reviewer` for the read-only code quality pass
  - `final_reviewer` for the whole-change review at the end
- Reviewers stay read-only.
- The parent remains responsible for user clarification, packet refinement, arbitration, and final synthesis.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent
- `../requesting-code-review/code-reviewer.md` - Shared read-only review template; `code_quality_reviewer` embeds the filled template inside `./code-quality-reviewer-prompt.md`, while `final_reviewer` receives the filled shared template directly

## Hard Rules

- Do not use write-capable reviewers.
- Do not proceed from a task with unresolved spec or Important/Critical quality issues.
- Do not let review replace parent-side verification.
- Do not broaden a child packet beyond one task unless the plan has been revised to make that scope explicit.
- Do not start implementation on main/master branch without explicit user consent.
- Do not skip reviews (spec compliance or code quality).
- Do not proceed with unfixed blocking issues.
- Do not dispatch multiple implementation subagents in parallel.
- Do not make the subagent read the plan file from disk when the packet should contain the task text.
- Do not skip scene-setting context for the implementer packet.
- Do not accept "close enough" when the spec reviewer found a mismatch.
- Do not skip review loops after a reviewer finds issues.
- Do not let implementer self-review replace the actual review passes.
- Do not start code quality review before spec compliance passes.
- Do not move to the next task while either review has open issues.
