---
name: subagent-driven-development
description: Use when executing an implementation plan with write-owning task work in the current session
---

# Subagent-Driven Development

Execute an implementation plan by dispatching one fresh write-owning implementer per task, then reviewing that task with two read-only passes: spec compliance first, code quality second.

Prefer bounded dispatch packets. Use full-history fork mode only when the child genuinely needs the same conversation history.

**Core principle:** Fresh implementer per task, then spec review, then code-quality review.

**Contract references:** Follow [../../contract/process-family.md](../../contract/process-family.md), [../../contract/package-standards.md](../../contract/package-standards.md), and [../../contract/prompt-packet.md](../../contract/prompt-packet.md) when writing or updating this workflow.

## When to Use

- Use after a written implementation plan is approved and an isolated worktree exists.
- Use when tasks can be executed task-by-task by a single active write-owning child.
- Use `executing-plans` instead when execution must stay inline or in a separate sequential session.
- Return to planning when tasks are tightly coupled, underspecified, or cannot be reviewed independently.

## The Process

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

## Child Config Inheritance and Role Mapping

Child agents inherit the parent session config by default. Preserve that inheritance unless the user explicitly asks for a role-specific override.

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

## Guardrails

- Do not let child agents ask the user directly or call `request_user_input`.
- Do not use write-capable reviewers.
- Do not proceed from a task with unresolved spec or Important/Critical quality issues.
- Do not let review replace parent-side verification.
- Do not broaden a child packet beyond one task unless the plan has been revised to make that scope explicit.

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance is ✅** (wrong order)
- Move to next task while either review has open issues

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:requesting-code-review** - shared read-only review workflow; `code_quality_reviewer` must receive `../requesting-code-review/code-reviewer.md` through `./code-quality-reviewer-prompt.md`, while `final_reviewer` receives the filled shared template directly
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **superpowers:test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **superpowers:executing-plans** - Use for parallel session instead of same-session execution
