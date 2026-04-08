# Codex Tool Mapping

Use this reference when a skill mentions another platform's tool names.

| Skill reference | Codex-native equivalent |
|---|---|
| `Task` tool or subagent dispatch | `spawn_agent(task_name=..., agent_type=worker|explorer|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer, message="...")` |
| Multiple `Task` calls | Multiple `spawn_agent(...)` calls |
| Wait for child result | `wait_agent(...)` |
| Close completed child | `close_agent(...)` |
| `TodoWrite` | `update_plan(...)` |
| `Skill` tool | Read the relevant `SKILL.md` from the plugin and follow it |
| File edits | `apply_patch` |
| Shell commands | `exec_command` |

## Runtime Check

Verify the runtime surface with:

```bash
codex features list | rg '^(plugins|multi_agent|multi_agent_v2)[[:space:]]+'
```

## Dispatch Rules

- Use a stable lowercase `task_name`.
- The parent owns clarification, escalation, and final synthesis.
- Use read-only roles for review and exploration.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Keep child packets narrow and self-contained.
