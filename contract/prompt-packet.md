# Prompt Packet Contract

## Codex Dispatch Format

Codex subagent prompts must be passed directly as the outer `message=` string on `spawn_agent(task_name=..., agent_type="...", message="...")`.
Do not wrap the message in an inner YAML packet, nested `items:` list, or inner `agent_type:` field.
On the latest alpha V2 surface, `task_name` and `message` are the required dispatch fields in the raw schema, but this local superpowers implementation additionally requires explicit outer `agent_type` because role selection is part of the contract.

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

- Pass the message body directly to `spawn_agent(task_name="...", agent_type="...", message="...")`.
- For this local implementation, always set `agent_type` explicitly on multi-agent dispatch.
- The current built-in roles on this machine include `default`, `worker`, `explorer`, `parallel_explorer`, `implementer`, `spec_reviewer`, `code_quality_reviewer`, and `final_reviewer`.

## Legacy Formats Are Forbidden

Do not use the legacy `Task tool (general-purpose)` format in live prompt templates.
Treat any archived example that still uses it as stale before reuse.

## Child Config Rule

Preserve inherited child config by default.
Do not set `model` or `reasoning_effort` unless the user explicitly asks.

## Child Elicitation Rule

- Child packets must not instruct the child to call `request_user_input`.
If a child discovers ambiguity, it must return a `decision_needed` handoff to the parent.
Keep parent-owned arbitration and user-facing clarification in the root thread.
