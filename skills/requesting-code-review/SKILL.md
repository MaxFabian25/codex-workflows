---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a focused read-only review child to catch issues before they cascade. The reviewer inspects the work product, returns findings, and stops; the parent owns packet quality, arbitration, and final decisions.

**Core principle:** Review early, review often.

**Contract references:** Follow [../../contract/process-family.md](../../contract/process-family.md), [../../contract/package-standards.md](../../contract/package-standards.md), and [../../contract/prompt-packet.md](../../contract/prompt-packet.md) when writing or updating review-dispatch guidance.

## When to Request Review

**Mandatory:**
- After each task in `subagent-driven-development`
- After completing a major feature or implementation batch
- Before merge to main

**Optional but valuable:**
- When stuck and a fresh read-only pass could surface the issue
- Before a risky refactor
- After fixing a complex bug

## Role Selection

- Use `code_quality_reviewer` after a completed task or implementation batch to review code quality, testing, architecture, and maintainability.
- Use `final_reviewer` for the final whole-change review before handing work off or merging.
- Both roles are read-only. Do not use write-capable child roles for review.

Dispatch them differently:
- `code_quality_reviewer`: fill `code-reviewer.md`, then paste that entire filled template into `../subagent-driven-development/code-quality-reviewer-prompt.md` and dispatch the filled message template. Use that template because it adds the extra task-quality checks that apply only to this role.
- `final_reviewer`: fill `code-reviewer.md` and dispatch that filled shared template directly with `spawn_agent(task_name=..., agent_type="final_reviewer", message="...")`.

## How to Request

### 1. Capture the review boundary

```bash
# Save this before the task starts if you expect a multi-commit task-level review
TASK_START_SHA=$(git rev-parse HEAD)

# After the task is implemented and committed, review exactly that task scope
BASE_SHA=$TASK_START_SHA
HEAD_SHA=$(git rev-parse HEAD)

# Whole-change or final_reviewer scope against main
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

# Whole-change review against another target branch
# BASE_SHA=$(git merge-base HEAD origin/<target-branch>)
# HEAD_SHA=$(git rev-parse HEAD)
```

Use a saved pre-task SHA or another explicit task-start commit for task-level review scopes. `HEAD~1` is only correct when the requested scope is exactly one commit. For `final_reviewer`, set `BASE_SHA` to the merge-base against the target branch so the child reviews the whole change, not just the most recent task commit.

### 2. Fill the shared review packet

Use `code-reviewer.md` as the shared inner template.

Placeholders:
- `{WHAT_WAS_IMPLEMENTED}` - short review-scope label
- `{PLAN_OR_REQUIREMENTS}` - what the implementation was supposed to do
- `{BASE_SHA}` - starting commit
- `{HEAD_SHA}` - ending commit
- `{DESCRIPTION}` - fuller implementation summary

The packet contract is governed by `../../contract/process-family.md`, `../../contract/package-standards.md`, and `../../contract/prompt-packet.md`.

### 3. Dispatch by role

**Task-level `code_quality_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Paste the entire filled shared template into `../subagent-driven-development/code-quality-reviewer-prompt.md`.
- Dispatch the resulting full message with `spawn_agent(task_name=..., agent_type="code_quality_reviewer", message="...")`.

**Whole-change `final_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Dispatch that filled shared template directly with `spawn_agent(task_name=..., agent_type="final_reviewer", message="...")`.

Do not send a summary or excerpt when the contract expects the full filled packet. Pass the final packet directly as the outer `message=` string for the child.

### 4. Act on feedback

- Fix Critical issues immediately
- Fix Important issues before proceeding, or record why the reviewer is wrong
- Note Minor issues for later if they are not worth blocking on

## Parent Arbitrates Disagreements

The review child reports findings. The parent decides what to do next.

- If the reviewer is right, fix the issue and re-run review if needed.
- If the reviewer is wrong, push back with technical reasoning and evidence from the code, tests, or plan.
- Do not ask the reviewer to arbitrate its own disputed finding. The parent owns that decision.

## Red Flags

**Never:**
- Skip review because a change seems simple
- Use a write-capable child to review
- Proceed with unfixed Critical issues
- Ignore Important issues without explicit parent justification
- Let review replace verification
- Send a partial or ad-hoc review packet when the contract requires the full filled template

See template at: code-reviewer.md
