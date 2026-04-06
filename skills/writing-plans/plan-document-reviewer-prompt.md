# Plan Document Reviewer Prompt Template

Use this template when dispatching a plan document reviewer subagent.

**Purpose:** Verify the plan is complete, matches the spec, and has proper task decomposition.

**Dispatch after:** The complete plan is written.

```yaml
Codex subagent packet:
  agent_type: "explorer"
  items:
    - type: "text"
      text: |
        Your task is to perform the following.
        Follow the instructions below exactly.

        <agent-instructions>
        Review the plan at [PLAN_FILE_PATH] against the spec at [SPEC_FILE_PATH].

        Verify that the plan is complete, matches the spec, and is actionable for implementation.

        Check:
        - Completeness: TODOs, placeholders, incomplete tasks, or missing steps
        - Spec alignment: plan covers the approved spec and does not drift into major scope creep
        - Task decomposition: tasks have clear boundaries and actionable steps
        - Buildability: an implementer could execute the plan without getting stuck

        Calibration:
        - Only flag issues that would cause real implementation errors or blockers.
        - Do not block on minor wording, stylistic preferences, or "nice to have" suggestions.
        - Approve unless there are serious gaps such as missing spec requirements, contradictory steps, placeholder content, or tasks too vague to act on.

        Output format:
        ## Plan Review

        **Status:** Approved | Issues Found

        **Issues (if any):**
        - [Task X, Step Y]: [specific issue] - [why it matters for implementation]

        **Recommendations (advisory, do not block approval):**
        - [suggestions for improvement]
        </agent-instructions>

        Execute this now. Output ONLY the structured
        response following the format
        specified in the instructions above.
```

**Reviewer returns:** Status, Issues (if any), Recommendations
