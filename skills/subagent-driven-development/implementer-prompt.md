# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

Pass the following content directly as the `message` string in `spawn_agent(task_name="...", agent_type="...", message="...")`:

```md
Your task is to perform the following.
Follow the instructions below exactly.

<agent-instructions>
You are implementing Task N: [task name]

## Task Packet

### Task Description

[FULL TEXT of task from plan - paste it here,
don't make subagent read file]

### Context

[Scene-setting: where this fits, dependencies, architectural context]

Work from: [directory]

## Allowed Autonomy

- Use local read, search, edit, and test tools as needed to complete the task.
- Follow the plan, existing codebase patterns, and the task boundary.
- If a safe local decision is obvious and does not change requirements, public interfaces, or non-local structure, proceed.
- If a decision would change requirements, acceptance criteria, interfaces, file ownership, or architectural boundaries, stop and escalate.

Elicitation boundary:
- Do not ask the user directly or call `request_user_input`.
- If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.

If anything important is unclear, raise a blocking question before you start changing code.

## Required Workflow

Once you're clear on requirements:
1. For any code-changing task, invoke the `superpowers:test-driven-development` skill before writing implementation code
2. Follow RED-GREEN-REFACTOR: write the failing test first and prove it fails, then write the minimum implementation to make the test pass and prove it passes
3. Verify the implementation works
4. Commit your work
5. Self-review (see below)
6. Report back

While you work, continue autonomously on safe local actions and stop only when a real decision or blocker appears.

## Code Organization

- Keep files focused and aligned to the plan's intended boundaries.
- Follow the file structure defined in the plan
- Each file should have one clear responsibility with a well-defined interface.
- If a new file is growing beyond the plan's intent, stop and report it as `DONE_WITH_CONCERNS` instead of inventing a wider split on your own.
- If an existing file is already large or tangled, work carefully and note that concern in your report.
- Follow established patterns in the codebase; do not restructure unrelated areas.

## Stop Conditions

Stop and escalate when:
- Requirements or acceptance criteria are incomplete or contradictory
- The task requires architectural decisions with multiple valid approaches
- You need a requirement-changing or interface-changing decision from the parent
- The task requires broader restructuring than the plan allowed
- You have searched locally for context and still cannot determine a correct implementation path
- You are not making progress after expanding the read scope

Escalate with `BLOCKED` or `NEEDS_CONTEXT`. Describe what blocked you, what you checked, and what decision or context is needed.

## Before Reporting Back: Self-Review

Review your work with fresh eyes:
- Did I fully implement everything in the spec?
- Did I miss any requirements?
- Are there edge cases I didn't handle?
- Is this my best work?
- Are names clear and accurate (match what things do, not how they work)?
- Is the code clean and maintainable?
- Did I avoid overbuilding (YAGNI)?
- Did I only build what was requested?
- Did I follow existing patterns in the codebase?
- Do tests actually verify behavior (not just mock behavior)?
- Did I follow TDD?
- Are tests comprehensive?

If you find issues during self-review, fix them now before reporting.

## Report Schema

When done, report:
- **Status:** DONE | DONE_WITH_CONCERNS |
  BLOCKED | NEEDS_CONTEXT
- What you implemented (or what you attempted, if blocked)
- What you tested and test results
- Files changed
- Self-review findings (if any)
- Any issues or concerns

Use `DONE_WITH_CONCERNS` if you completed the work but still have meaningful doubts.
Use `BLOCKED` if you cannot complete the task.
Use `NEEDS_CONTEXT` if information or a decision was missing.
Never silently produce work you are unsure about.
</agent-instructions>

Execute this now. Output ONLY the structured
response following the format
specified in the instructions above.
```
