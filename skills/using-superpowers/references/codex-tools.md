# Codex Tool Mapping

Use this reference when a skill mentions another platform's tool names.

| Skill reference | Codex-native equivalent |
|---|---|
| Structured user decision | `request_user_input(questions=[...])` |
| `Task` tool or subagent dispatch | `spawn_agent(task_name=..., agent_type=worker|explorer|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer, message="...")` |
| Multiple `Task` calls | Multiple `spawn_agent(...)` calls |
| Add message to live child | `send_message(...)` |
| Wake a live child with new work | `followup_task(...)` |
| List live child agents | `list_agents(...)` |
| Wait for child result | `wait_agent(...)` |
| Close completed child | `close_agent(...)` |
| `TodoWrite` | `update_plan(...)` |
| `Skill` tool | Read the relevant `SKILL.md` from the plugin and follow it |
| File edits | `apply_patch` |
| Shell commands | `exec_command` |

Use `request_user_input(...)` as the tool name, with `request_user_input(questions=[...])` as the normal structured-decision call shape.

## Runtime Check

Verify the runtime surface with:

```bash
codex features list | rg '^(plugins|multi_agent_v2|default_mode_request_user_input)[[:space:]]+'
```

## Feature Gates

- Use `request_user_input` in Default mode only when `default_mode_request_user_input` is enabled.
- Use the V2 child-agent surface (`send_message(...)`, `followup_task(...)`, `list_agents(...)`) only when `multi_agent_v2` is enabled.
- The root thread owns user elicitation.

## Dispatch Rules

- Use a stable lowercase `task_name`.
- The parent owns clarification, escalation, and final synthesis.
- Use read-only roles for review and exploration.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Keep child packets narrow and self-contained.
