---
name: executing-plans
description: Use when executing a written implementation plan in a separate or sequential session with review checkpoints
---

# Executing Plans

## Overview

Execute a written implementation plan sequentially when `subagent-driven-development` is not the right fit.

**Contract alignment:** This skill owns sequential or separate-session implementation when `subagent-driven-development` is not the right fit.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for lifecycle ownership and package structure.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

Use `superpowers:using-git-worktrees` before implementation unless the user explicitly approved working on the current branch.

## Required Flow

### 1. Load and review the plan

- Read the plan completely before editing.
- Identify missing context, unsafe assumptions, or task-order problems.
- If the plan has critical gaps, stop and surface the exact blocker before implementation.
- If the plan is executable, create `update_plan(...)` tracking.

### 2. Execute tasks sequentially

For each task:
- mark it `in_progress`;
- follow the task steps exactly unless verification proves the plan is wrong;
- run the specified verification commands;
- inspect failures instead of skipping or weakening verification;
- mark the task complete only after verification passes or the remaining limitation is explicitly documented.

### 3. Handle blockers

- If a discrete root-thread branch decision blocks execution, use `request_user_input`.
- If the blocker needs rich context or plan repair rather than a discrete choice, stop and explain it in prose.
- If verification fails repeatedly, stop and use the appropriate debugging or review skill instead of guessing.

### 4. Complete development

After all tasks complete and verified:
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill for test verification and closeout decisions

## Stop Conditions

- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly
- The work would start on `main` or `master` without explicit user consent

## Revisit the Plan When

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking
- The implementation reveals a missing task or invalid task order

Do not force through blockers. Revise the plan or route the decision through the root thread.

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
