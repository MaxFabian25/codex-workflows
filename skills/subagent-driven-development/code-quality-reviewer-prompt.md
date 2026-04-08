# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built, well-tested, and maintainable.

**Only dispatch after spec compliance review passes.**

Before dispatching, fill `../requesting-code-review/code-reviewer.md` completely and paste the filled template into this packet. Do not ask the child to read the shared template from disk.

```yaml
Codex subagent packet:
  agent_type: "explorer"
  items:
    - type: "text"
      text: |
        Your task is to perform the following.
        Follow the instructions below exactly.

        <agent-instructions>
        Stay read-only. Do not edit files, stage changes, or commit.

        The filled shared review template is included below. Treat it as the primary review contract.

        <filled-shared-review-template>
        [paste fully filled ../requesting-code-review/code-reviewer.md here]
        </filled-shared-review-template>

        In addition to standard code quality concerns, also check:
        - Does each file have one clear responsibility with a well-defined interface?
        - Are units decomposed so they can be understood and tested independently?
        - Is the implementation following the file structure from the plan?
        - Did this implementation create new files that are already large,
          or significantly grow existing files?
          (Don't flag pre-existing file sizes. Focus on what this change contributed.)
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

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Recommendations, Assessment
