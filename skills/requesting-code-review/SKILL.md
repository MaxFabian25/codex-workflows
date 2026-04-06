---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a focused read-only review child to catch issues before they cascade. The reviewer inspects the work product, returns findings, and stops; the parent owns packet quality, arbitration, and final decisions.

**Core principle:** Review early, review often.

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

Both roles are read-only. Do not use write-capable child roles for review.

The shared `code-reviewer.md` template serves both scopes:
- `code_quality_reviewer` uses it for task-level readiness to proceed.
- `final_reviewer` uses the same template for readiness to merge or hand off.

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch the review child:**

Fill the template at `code-reviewer.md`, then dispatch it by putting the filled review packet inside the top-level `message`.

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Brief summary

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding, or record why the reviewer is wrong
- Note Minor issues for later if they are not worth blocking on

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch review child]
task_name: task_2_code_review
agent_type: code_quality_reviewer
message: |
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

[Review child returns]
### Strengths
- Clean architecture, real tests

### Issues

#### Important (Should Fix)
- Missing progress indicators

#### Minor (Nice to Have)
- Magic number (100) for reporting interval

### Recommendations
- Add progress reporting before moving to Task 3

### Assessment

**Ready for requested review scope?** With fixes

**Reasoning:** The core design is sound, but the missing progress indicator should be fixed before proceeding.

You: [Fix progress indicators]
[Continue to Task 3]
```

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

See template at: requesting-code-review/code-reviewer.md
