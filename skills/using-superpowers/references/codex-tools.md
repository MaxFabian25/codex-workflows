# Codex Tool Mapping

Use this reference when a skill mentions another platform's tool names.
The surfaced tool list in the active session is the runtime truth for the current turn.
This reference is aligned to the latest alpha Codex CLI surface on this machine, not a blanket contract for every older or differently configured runtime.
It intentionally assumes the V2 multi-agent surface on this machine rather than documenting legacy non-V2 collab tools.

| Skill reference | Codex-native equivalent |
|---|---|
| Structured user decision | `request_user_input(questions=[...])` |
| `Task` tool or subagent dispatch | `spawn_agent(task_name=..., agent_type=<required local role such as default|worker|explorer|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer>, message="...")` |
| Multiple `Task` calls | Multiple `spawn_agent(task_name=..., agent_type="...", message="...")` calls |
| Add message to live child without starting a turn | `send_message(...)` |
| Wake or redirect a live child with new work | `followup_task(...)` |
| List live child agents | `list_agents(...)` |
| Wait for child mailbox updates | `wait_agent(...)` |
| Close an agent subtree you no longer need | `close_agent(...)` |
| `TodoWrite` | `update_plan(...)` |
| `Skill` tool | Read the relevant `SKILL.md` from the plugin and follow it |
| File edits | `apply_patch` |
| Shell commands | `exec_command` |
| Bitmap/image generation | Built-in `image_generation` when surfaced; otherwise follow the active session or skill-specific fallback path |
| Parallel developer-tool fanout | `multi_tool_use.parallel(...)` |

Use `request_user_input(...)` as the tool name, with `request_user_input(questions=[...])` as the normal structured-decision call shape.

## Runtime Truth

- Use the surfaced tool list in the active session as the source of truth for the current turn.
- For latest-alpha preflight on this machine, verify feature-gated surfaces with `codex features list` when the tool is relevant but not currently surfaced.
- `request_user_input` is root-thread only and enabled in this local runtime for root-thread elicitation.
- Treat it as the local structured-decision surface for eligible discrete branch-point questions.
- This reference intentionally targets the V2 child-agent surface gated by `multi_agent_v2`.
- On `codex-cli 0.121.0-alpha.1` / `rust-v0.121.0-alpha.1`, this surfaced Codex tool schema requires `task_name` and `message`; the upstream handler still treats `agent_type` as optional metadata.
- This local superpowers implementation requires explicit `agent_type` on every multi-agent dispatch because role selection is part of the contract.
- The built-in roles listed above are common on this machine, but surfaced roles are not guaranteed to be exhaustive.
- The built-in `image_generation` tool is a real Codex CLI surface, but it is still gated by runtime feature/model/auth checks and may not appear in every session.
- The root thread owns user elicitation.

## Dispatch Rules

- Use a stable lowercase `task_name`.
- The parent owns clarification, escalation, and final synthesis.
- Use read-only roles for review and exploration.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Keep child packets narrow and self-contained.
