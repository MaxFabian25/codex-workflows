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
- `code_quality_reviewer`: fill `code-reviewer.md`, then paste that entire filled template into `../subagent-driven-development/code-quality-reviewer-prompt.md` and dispatch the filled wrapper packet. Use the wrapper because it adds the extra task-quality checks that apply only to this role.
- `final_reviewer`: fill `code-reviewer.md` and dispatch that filled shared template directly with `spawn_agent(..., agent_type="final_reviewer", message="...")`.

## How to Request

**1. Get git SHAs:**
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

**2. Dispatch the review child by role:**

**Task-level `code_quality_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Paste the entire filled shared template into `../subagent-driven-development/code-quality-reviewer-prompt.md`.
- Dispatch the full filled wrapper packet with `spawn_agent(task_name=..., agent_type="code_quality_reviewer", message="...")`.

**Whole-change `final_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Dispatch that filled shared template directly with `spawn_agent(task_name=..., agent_type="final_reviewer", message="...")`.

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` - Short review-scope label
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Fuller implementation summary

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding, or record why the reviewer is wrong
- Note Minor issues for later if they are not worth blocking on

## Examples

### Task-Level `code_quality_reviewer`

```
[Just completed Task 2: Add verification function]

[Earlier, before Task 2 started, you saved its boundary]
TASK_2_START_SHA=$(git rev-parse HEAD)

You: Let me request code review before proceeding.

BASE_SHA=$TASK_2_START_SHA
HEAD_SHA=$(git rev-parse HEAD)

The actual `message=` payload must be the entire filled `../subagent-driven-development/code-quality-reviewer-prompt.md` wrapper packet. The block below is an excerpt showing the dispatch shape only. Do not send only this excerpt.

spawn_agent(task_name="task_2_code_review", agent_type="code_quality_reviewer", message="[full filled code-quality-reviewer-prompt.md wrapper packet for Task 2]")

  Excerpt from the actual wrapper payload:
  <filled-shared-review-template>
  # Code Review Agent

  You are performing a read-only review of code changes for the requested review scope.

  **Your task:**
  1. Review Verification and repair functions for conversation index
  2. Compare against Task 2 from docs/superpowers/plans/deployment-plan.md
  3. Check code quality, architecture, and testing
  4. Categorize issues by severity
  5. Assess readiness for the requested review scope

  ## What Was Implemented

  Added verifyIndex() and repairIndex() with 4 issue types

  ## Requirements/Plan

  Task 2 from docs/superpowers/plans/deployment-plan.md

  ## Git Range to Review

  **Base:** a7981ec
  **Head:** 3df7661
  </filled-shared-review-template>

  In addition to standard code quality concerns, also check:
  - Does each file have one clear responsibility with a well-defined interface?
  - Are units decomposed so they can be understood and tested independently?
  - Is the implementation following the file structure from the plan?
  - Did this implementation create new files that are already large, or significantly grow existing files?

[Review child returns]
### Strengths
- Clean architecture with real tests around the repair flow

### Issues

#### Critical (Must Fix)
None.

#### Important (Should Fix)
1. **Missing progress indicators**
   - File: `src/indexer.ts:130`
   - What's wrong: Long-running verification and repair paths do not report progress.
   - Why it matters: Task 2 requires progress reporting every 100 items, and operators cannot tell whether the job is still advancing.
   - How to fix: Add a progress log or callback that emits every 100 processed items.

#### Minor (Nice to Have)
1. **Magic reporting interval**
   - File: `src/indexer.ts:130`
   - What's wrong: The value `100` is inlined in the reporting path.
   - Why it matters: Future changes to the reporting cadence will require hunting through implementation details.
   - How to fix: Extract a named constant such as `PROGRESS_INTERVAL`.

### Recommendations
- Add progress reporting first, then extract the reporting interval constant in the same pass.

### Assessment

**Ready for requested review scope?** With fixes

**Reasoning:** The core design is sound, but the missing progress indicator should be fixed before proceeding to Task 3.

You: [Fix progress indicators]
[Continue to Task 3]
```

### Whole-Change `final_reviewer`

```text
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

spawn_agent(task_name="final_code_review", agent_type="final_reviewer", message="[entire filled code-reviewer.md template directly for the whole change]")
```

For `final_reviewer`, the actual `message=` payload is the entire filled shared `code-reviewer.md` template directly. Do not wrap it in `../subagent-driven-development/code-quality-reviewer-prompt.md`.

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

See template at: code-reviewer.md
