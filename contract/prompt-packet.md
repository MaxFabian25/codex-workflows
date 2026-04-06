# Prompt Packet Contract

## Codex Dispatch Format

Reviewer and worker prompts must use the Codex v2 packet format:

```yaml
Codex subagent packet (preferred v2):
  task_name: "<stable_name>"
  agent_type: "worker|reviewer|explorer|default"
  items:
    - type: "text"
      text: |
        Your task is to perform the following.
        Follow the instructions below exactly.

        <agent-instructions>
        [filled prompt content]
        </agent-instructions>

        Execute this now. Output ONLY the structured
        response following the format
        specified in the instructions above.
```

## Allowed Legacy State

- No new prompt templates may use the legacy `Task tool (general-purpose)` format.
- Existing legacy prompt templates must be migrated before the process-family cutover is complete.

## Child Config Rule

- Preserve inherited child config by default.
- Do not set `model` or `reasoning_effort` unless the user explicitly asks.
