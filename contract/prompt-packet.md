# Prompt Packet Contract

## Codex Dispatch Format

Codex subagent prompts must use the verified packet shape for the local operator environment:

```yaml
Codex subagent packet:
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
- The verified outer `spawn_agent(..., agent_type=...)` role surface in this environment includes `parallel_explorer`, `implementer`, `spec_reviewer`, `code_quality_reviewer`, and `final_reviewer`.
- Current wrapper packet templates for read-only review still use inner `agent_type: "explorer"` until packet-level bindings are verified end-to-end.

## Allowed Legacy State

- No new prompt templates may use the legacy `Task tool (general-purpose)` format.
- Existing legacy prompt templates must be migrated before the process-family cutover is complete.

## Child Config Rule

- Preserve inherited child config by default.
- Do not set `model` or `reasoning_effort` unless the user explicitly asks.

## Child Elicitation Rule

- Child packets must not instruct the child to call `request_user_input`.
- If a child discovers ambiguity, it must return a `decision_needed` handoff to the parent.
- Keep parent-owned arbitration and user-facing clarification in the root thread.
