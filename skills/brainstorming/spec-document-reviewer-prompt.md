# Spec Document Reviewer Prompt Template

Use this template when dispatching a spec document reviewer subagent.

**Purpose:** Verify the spec document is complete, consistent, and ready for implementation planning.

**Dispatch after:** Spec document is written to docs/codex-workflows/specs/

Pass the following content directly as the `message` string in `spawn_agent(task_name="...", agent_type="...", message="...")`:

Dispatch this packet with `agent_type="parallel_explorer"` in the local V2-only contract.

```md
Your task is to perform the following.
Follow the instructions below exactly.

<agent-instructions>
Review the spec document at [SPEC_FILE_PATH].

Verify that it is complete, internally consistent, and ready for implementation planning.

Elicitation boundary:
- Do not ask the user directly or call `request_user_input`.
- If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.

Check:
- Completeness: TODOs, placeholders, "TBD" markers, or missing sections
- Consistency: contradictions or conflicting requirements
- Clarity: ambiguity likely to make the planner build the wrong thing
- Scope: more than one independent subsystem bundled into one spec
- YAGNI: unrequested features or over-engineered additions

Calibration:
- Only flag issues that would cause real problems during implementation planning.
- Do not block on minor wording improvements, stylistic preferences, or uneven detail.
- Approve unless there are serious gaps that would lead to a flawed plan.

Output format:
## Spec Review

**Status:** Approved | Issues Found

**Issues (if any):**
- [Section X]: [specific issue] - [why it matters for planning]

**Recommendations (advisory, do not block approval):**
- [suggestions for improvement]
</agent-instructions>

Execute this now. Output ONLY the structured
response following the format
specified in the instructions above.
```

**Reviewer returns:** Status, Issues (if any), Recommendations
