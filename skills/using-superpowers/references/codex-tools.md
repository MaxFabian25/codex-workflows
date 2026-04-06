# Codex Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent(task_name=..., agent_type=..., message=...)` |
| Follow-up turn for dispatched child | `followup_task(target=..., message=...)` for immediate work, `send_message(target=..., message=...)` for queued notes |
| Task returns result | `wait_agent` to synchronize; the deliverable comes from the child completion reply, not the wait summary |
| Inspect active children | `list_agents` |
| Close completed child | `close_agent` after harvesting the deliverable and evidence |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |

## Dispatch Rules

- Always pass `task_name` to `spawn_agent(...)`.
- Prefer a stable task name for `followup_task`, `send_message`, `list_agents`, `wait_agent`, and `close_agent`.
- Preserve inherited child config by default. Do not pass `model` or `reasoning_effort` unless the user explicitly asks.
- Put the filled child instructions in the `message` field.

## Process-Family Routing

- `dispatching-parallel-agents` is for read-only investigation without shared write ownership.
- `subagent-driven-development` is for write-owning implementation in the current session.
- `executing-plans` is for sequential or separate-session implementation.
- Review prompts must use the packet format in `../../../contract/prompt-packet.md`.

## Prompt Handoff

When a skill points to a local prompt template:

1. Read the prompt file.
2. Fill its placeholders (`{BASE_SHA}`, `[PLAN_FILE_PATH]`, and similar).
3. Pass the filled prompt text to `spawn_agent(..., message=...)`.

Use `agent_type="explorer"` for read-only investigation or review packets and `agent_type="worker"` for write-owning implementation packets unless the skill says otherwise.
