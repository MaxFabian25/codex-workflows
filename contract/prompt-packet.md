# Prompt Packet Contract

## Codex Dispatch Format

Codex subagent prompts must use the verified packet shape for this workstation:

```yaml
Codex subagent packet:
  agent_type: "worker|explorer|parallel_explorer|implementer|spec_reviewer|code_quality_reviewer|final_reviewer|default"
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
- The broader verified `spawn_agent(..., agent_type=...)` surface in this environment includes `parallel_explorer`, `implementer`, `spec_reviewer`, `code_quality_reviewer`, and `final_reviewer`.
- Current read-only review packet templates still route through `explorer` until dedicated packet role bindings are verified end-to-end.

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
