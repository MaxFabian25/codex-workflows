# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built, well-tested, and maintainable.

**Only dispatch after spec compliance review passes.**

```yaml
Codex subagent packet (preferred v2):
  task_name: "<stable_code_review_name>"
  agent_type: "code_quality_reviewer"
  message: |
    Your task is to perform the following.
    Follow the instructions below exactly.

    <agent-instructions>
    Stay read-only. Do not edit files, stage changes, or commit.

    Use the filled template at requesting-code-review/code-reviewer.md.

    In addition to standard code quality concerns, also check:
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this implementation create new files that are already large,
      or significantly grow existing files?
      (Don't flag pre-existing file sizes. Focus on what this change contributed.)

    WHAT_WAS_IMPLEMENTED: [from implementer's report]
    PLAN_OR_REQUIREMENTS: Task N from [plan-file]
    BASE_SHA: [commit before task]
    HEAD_SHA: [current commit]
    DESCRIPTION: [task summary]
    </agent-instructions>

    Execute this now. Output ONLY the structured
    response following the format
    specified in the instructions above.
```

**In addition to standard code quality concerns, also check:**

- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large,
  or significantly grow existing files?
  (Don't flag pre-existing file sizes. Focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
