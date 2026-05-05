---
name: requesting-code-review
description: Use when task, feature, or merge-ready work needs review
---

# Requesting Code Review

Dispatch a focused read-only review child. The child reports findings; the parent owns packet quality, arbitration, and final decisions.

**Contract references:** Follow [../../docs/language-contracts/process-family-playbook.md](../../docs/language-contracts/process-family-playbook.md), [../../docs/language-contracts/package-and-release-playbook.md](../../docs/language-contracts/package-and-release-playbook.md), and [../../docs/language-contracts/prompt-packet-playbook.md](../../docs/language-contracts/prompt-packet-playbook.md) when writing or updating review-dispatch guidance.

## Use When

- After each task in `subagent-driven-development`.
- After a major feature or implementation batch.
- Before merge or handoff.
- When a fresh read-only pass could surface a bug, scope drift, or test gap.

## Roles

- `code_quality_reviewer`: task or batch review for correctness, tests, architecture, maintainability, and risks.
- `final_reviewer`: whole-change review before merge or handoff.
- Reviewers are read-only. Do not use write-capable child roles for review.

## Workflow

1. Capture the review boundary:

```bash
TASK_START_SHA=$(git rev-parse HEAD)
BASE_SHA=$TASK_START_SHA
HEAD_SHA=$(git rev-parse HEAD)
```

For final review, set `BASE_SHA=$(git merge-base HEAD origin/main)` or the target branch merge-base.

2. Fill `code-reviewer.md`.

Placeholders:
- `{WHAT_WAS_IMPLEMENTED}` - short review-scope label
- `{PLAN_OR_REQUIREMENTS}` - what the implementation was supposed to do
- `{BASE_SHA}` - starting commit
- `{HEAD_SHA}` - ending commit
- `{DESCRIPTION}` - fuller implementation summary

The packet contract is governed by `../../docs/language-contracts/process-family-playbook.md`, `../../docs/language-contracts/package-and-release-playbook.md`, and `../../docs/language-contracts/prompt-packet-playbook.md`.

3. Dispatch by role:

- Task-level `code_quality_reviewer`: paste the filled shared template into `../subagent-driven-development/code-quality-reviewer-prompt.md`, then call `spawn_agent(task_name=..., agent_type="code_quality_reviewer", message="...")`.
- Whole-change `final_reviewer`: dispatch the filled `code-reviewer.md` template directly with `spawn_agent(task_name=..., agent_type="final_reviewer", message="...")`.

Do not send a summary or excerpt when the contract expects the full filled packet. Pass the final packet directly as the outer `message=` string for the child.

4. Act on findings:
- Fix Critical issues immediately.
- Fix Important issues before proceeding, or record why the reviewer is wrong with evidence.
- Note Minor issues only when they are not worth blocking on.

## Parent Arbitration

- If the reviewer is right, fix the issue and rerun review when needed.
- If the reviewer is wrong, push back with technical reasoning and evidence from code, tests, or plan.
- Do not ask the reviewer to arbitrate its own disputed finding.

## Guardrails

- Do not skip review because a change seems simple.
- Do not use a write-capable child to review.
- Do not proceed with unresolved Critical or unjustified Important issues.
- Do not let review replace verification.
- Do not dispatch a partial or ad-hoc review packet when the full template is required.
