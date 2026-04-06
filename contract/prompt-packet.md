# Prompt Packet Contract

## Codex Dispatch Format

Codex subagent prompts must use the verified packet shape for this workstation:

```yaml
Codex subagent packet (preferred v2):
  agent_type: "worker|explorer|default"
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

- Keep the `items[].text` framing above for dispatched instructions.
- Read-only review packets route through `explorer` until a dedicated `reviewer` role is verified for this environment.

## Allowed Legacy State

- No new prompt templates may use the legacy `Task tool (general-purpose)` format.
- Existing legacy prompt templates must be migrated before the process-family cutover is complete.

## Child Config Rule

- Preserve inherited child config by default.
- Do not set `model` or `reasoning_effort` unless the user explicitly asks.
