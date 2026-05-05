---
name: writing-plans
description: Use when an approved spec needs an implementation plan
---

# Writing Plans

Write the implementation contract for an approved design.

**Contract alignment:** This skill owns the `plan` phase only. It does not create worktrees or dispatch implementation work.

**Contract references:** Follow `../../docs/language-contracts/process-family-playbook.md`, `../../docs/language-contracts/prompt-packet-playbook.md`, and `../../docs/language-contracts/package-and-release-playbook.md` for phase ownership, dispatch packet format, and package structure.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

Assume the implementer is technically strong but new to this codebase, toolchain, and domain. Make the local conventions, file boundaries, and verification expectations explicit.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use codex-workflows:using-git-worktrees to create the isolated workspace for this plan. Then use codex-workflows:subagent-driven-development (recommended) or codex-workflows:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Workflow

1. Read the approved spec, relevant repo docs, and existing code patterns before writing tasks. An OpenSpec change directory may be the approved spec input when the repo uses OpenSpec.
2. If the repo already uses `.agents/PLANS.md`, a top-level `PLANS.md`, or the user explicitly asks for an ExecPlan, switch to the compatible references in `references/`, follow that planning standard exactly, and perform the manual ExecPlan review in `references/execplan-interop.md`.
3. Map the files to create or modify, what each file is responsible for, and which boundaries must stay stable.
4. Write bite-sized tasks with exact file paths, verification commands, and commit boundaries. Keep tasks self-contained and ordered so another engineer can execute them without re-deciding the design.
5. Default to zero-shot plan writing. Include code or interface snippets only when the repo standard requires them, an interface would otherwise be ambiguous, or a high-risk seam needs an exact example.
6. Keep placeholders out of the plan. If a step depends on a concrete name, command, path, or behavior, write it explicitly.
7. Self-review the finished plan against the spec, then save it to `docs/codex-workflows/plans/YYYY-MM-DD-<feature-name>.md` unless the user or repo specifies a different location.

## Required Output

- Every plan begins with the required header above.
- Use exact file paths and call out create/modify/test ownership clearly.
- Include the verification commands that prove each task is complete.
- Prefer focused steps that align with TDD and frequent verification where the repo supports that workflow.
- If the spec spans multiple independent subsystems, split it into separate plans instead of forcing one oversized plan.

## Self-Review

- Check spec coverage: every requirement should map to one or more tasks.
- Check for placeholders, vague instructions, or missing verification.
- Check type, naming, and interface consistency across the whole plan.
- Fix gaps inline before presenting the plan.

## Execution Handoff

After the plan is approved, the next required step is isolation. Use `codex-workflows:using-git-worktrees` to create the isolated workspace before either execution mode.

After saving the plan, use `request_user_input` to offer the execution choice.

Offer:
- `Subagent-Driven (Recommended)` - dispatch a fresh subagent per task with review between tasks
- `Inline Execution` - execute tasks in this session with `executing-plans` checkpoints

Do not write this as a plain-text numbered menu.

**If Subagent-Driven chosen:**
- First use `codex-workflows:using-git-worktrees` to create the isolated workspace
- **REQUIRED SUB-SKILL:** Use codex-workflows:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- First use `codex-workflows:using-git-worktrees` to create the isolated workspace
- **REQUIRED SUB-SKILL:** Use codex-workflows:executing-plans
- Batch execution with checkpoints for review

## References

- `plan-document-reviewer-prompt.md`: Review packet template for plan-quality checks before finalizing.
- `references/execplan-interop.md`: Distilled guidance for repos that already require `.agents/PLANS.md` / ExecPlan output.
- `references/PLANS.md`: Canonical ExecPlan standard text for repo bootstrap or compatibility checks.
- `references/AGENTS.execplans.snippet.md`: Minimal `AGENTS.md` snippet enabling ExecPlan workflows.
- `references/execplan.example.valid.md`: Passing ExecPlan example.
- `references/execplan.example.invalid.missing-section.md`: Failing ExecPlan example missing a required section.
- `references/execplan.example.invalid.incomplete-evidence.md`: Failing ExecPlan example with incomplete evidence.
- `references/execplan.example.invalid.nested-fence.md`: Failing ExecPlan example showing nested-fence violations.
- `references/execplan-interop.md`: Manual ExecPlan compatibility and review guidance.
