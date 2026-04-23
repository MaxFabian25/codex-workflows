---
name: brainstorming
description: "Use when a request needs design exploration and explicit user approval before implementation planning."
---

# Brainstorming Ideas Into Designs

Turn a request into an approved design and written spec before planning or implementation.

**Contract alignment:** This skill owns the `design` phase only. After the written spec is approved, hand off to `writing-plans`. Workspace isolation starts later via `using-git-worktrees` during implementation, not during brainstorming.

**Contract references:** Follow `../../contract/process-family.md`, `../../contract/prompt-packet.md`, and `../../contract/package-standards.md` when updating this skill and its supporting packets.

## Use When

- A request needs design exploration, tradeoff analysis, or a written spec before planning.
- The user must approve the design before implementation planning begins.

## Do Not Use When

- There is already an approved written spec. Use `writing-plans`.
- The user is asking to execute an approved plan. Use the implementation-phase skills instead.

## Workflow

1. Explore the current project context first: relevant files, docs, recent commits, and existing patterns.
2. If the request spans multiple independent subsystems, decompose it and choose the first implementation slice before refining details.
3. If upcoming questions are primarily visual, offer the visual companion once. If the user accepts, load `skills/brainstorming/visual-companion.md` before using it.
4. Ask clarifying questions one at a time until the goal, constraints, success criteria, and boundaries are clear.
5. Propose 2-3 approaches with tradeoffs and a recommendation.
6. Present the design in sections scaled to complexity and get user approval as you go.
7. Write the approved spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` unless the user or repo sets a different location.
8. Self-review the spec for placeholders, contradictions, scope drift, and ambiguity, then ask the user to review the written spec.
9. After written-spec approval, invoke `writing-plans` and no other next-phase skill.

## Root-Thread Decisions

- The root thread owns user decisions and user-facing elicitation.
- Use `request_user_input` for eligible discrete branch-point decisions such as approach selection, section approval, and the written-spec approval gate.
- Do not replace an eligible branch-point with a plain-text multiple-choice prompt.
- Keep it to one decision per tool call unless two choices are inseparable.
- Use normal prose for explanatory discussion, editorial feedback, and questions that need rich free text.
- If the user asked for subagents and the request decomposes cleanly into read-only lanes, use `dispatching-parallel-agents` to map the slices before the next branch-point question.

## Spec Output

- Cover the architecture, major components, data flow, failure handling, and testing expectations.
- Follow the existing codebase patterns and include only refactors that directly support the requested goal.
- Keep the design scoped to one implementation plan. If that is not possible, split it into smaller specs first.
- Commit the written spec after the self-review pass.

## Handoff

- Do not invoke implementation skills, write code, scaffold a project, or take other implementation action before design approval.
- Stop after the written spec is approved.
- The only next skill is `writing-plans`.
- Isolation begins later with `using-git-worktrees`, not during brainstorming.
