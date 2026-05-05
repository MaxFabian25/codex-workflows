# Prompt Packet Playbook

This playbook replaces validator-enforced prompt packet checks with readable dispatch requirements.

## Codex Dispatch Shape

Use the active Codex child-agent tools exactly as surfaced in the current session. For this package's V2 child-agent contract, dispatch full child instructions directly as the outer `message` value:

```text
spawn_agent(task_name="short_task_name", agent_type="parallel_explorer|implementer|spec_reviewer|code_quality_reviewer|final_reviewer", message="<full filled packet>")
```

Do not wrap the message in an inner YAML packet, an `items:` list, or an inner `agent_type:` field. Role selection belongs to the outer tool call.

## Prompt Body Shape

Prompt templates should retain this readable envelope unless the active runtime requires a different format:

```md
Your task is to perform the following.
Follow the instructions below exactly.

<agent-instructions>
[filled prompt content]
</agent-instructions>

Execute this now. Output ONLY the structured
response following the format
specified in the instructions above.
```

## Role Selection

- `parallel_explorer`: read-only investigation and source mapping.
- `implementer`: one bounded write-owning implementation task.
- `spec_reviewer`: read-only implementation-vs-spec review.
- `code_quality_reviewer`: read-only task or batch review.
- `final_reviewer`: read-only whole-change review before merge or handoff.

Do not set `model` or `reasoning_effort` in normal operation. Children inherit the parent config unless the user explicitly asks for an override.

## Child Elicitation Boundary

Every child packet that may encounter ambiguity must say:

- do not ask the user directly;
- do not call `request_user_input`;
- return ambiguity to the parent/root thread.

Use `decision_needed` when a child has enough evidence to frame a parent decision:

```text
decision_needed: yes
decision_id: short_stable_identifier
recommended_option: <child recommendation>
options:
- <option A>
- <option B>
evidence:
- <file or observation supporting the decision>
```

The parent decides whether to ask the user or make a documented assumption.

## Parallel-Agent Policy

Parallel agents are read-only by default. Use them for independent investigation lanes, not broad duplicate reviews. Each child packet should include:

- one narrow question;
- read-only scope unless explicitly assigned non-overlapping write ownership;
- required file/source references;
- a clear return format;
- a reminder that parent synthesis and user decisions stay in the root thread.

## Failure Handoff

When a child hits a failed command, unclear authority, missing prerequisite, or protected-scope risk, it should return the operational evidence instead of hidden reasoning:

- failing command or observation;
- relevant files or artifacts;
- likely cause if supported by evidence;
- next smallest probe;
- stop condition;
- whether a parent or human decision is needed.

## Manual Review Checklist

- The dispatch examples use direct `message=` strings.
- The child role is explicit in the outer dispatch call.
- Prompt templates do not use legacy `Task tool`, `items:`, `text: |`, or nested `agent_type:` formats.
- Children stay inside their read/write ownership boundary.
- Review children are read-only.
- Implementation children have one bounded task and clear stop conditions.
- `DONE`, `DONE_WITH_CONCERNS`, `BLOCKED`, and `NEEDS_CONTEXT` statuses are used consistently where the packet defines them.
