# Codex Tool Mapping

Use this reference when a skill mentions another platform's tool names.
The surfaced tool list in the active session is the runtime truth for the current turn.
This reference is aligned to the latest alpha Codex CLI surface on this machine (`codex-cli 0.129.0-alpha.6`), not a blanket contract for every older or differently configured runtime.
It intentionally assumes the V2 multi-agent surface on this machine rather than documenting legacy non-V2 collab tools.

| Skill reference | Codex-native equivalent |
|---|---|
| Structured user decision | `request_user_input(questions=[...])` |
| `Task` tool or subagent dispatch | `spawn_agent(task_name=..., agent_type=<required local role such as default|worker|explorer|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer>, message="...")` |
| Multiple `Task` calls | Multiple `spawn_agent(task_name=..., agent_type="...", message="...")` calls |
| Add message to live child without starting a turn | `send_message(...)` |
| Wake or redirect a live child with new work | `followup_task(...)`; use `followup_task(target=..., message=...)` |
| List live child agents | `list_agents(...)` |
| Wait for child mailbox updates | `wait_agent(...)` |
| Close an agent subtree you no longer need | `close_agent(...)` |
| `TodoWrite` | `update_plan(...)` |
| `Skill` tool | Read the relevant `SKILL.md` from the plugin and follow it |
| File edits | `apply_patch` |
| Shell commands | `exec_command` |
| Ongoing shell sessions | `write_stdin(...)` |
| JavaScript orchestration | `functions.exec` only when surfaced; it is a V8 async module, not Node |
| Node-backed JavaScript | `exec_command` with `node --input-type=module` or `node path/to/script.mjs` |
| Deferred tool or app discovery | `tool_search.tool_search_tool(...)` |
| Bitmap/image generation | `image_gen.imagegen(...)` when surfaced; `image_generation` is the feature flag, not the tool name |
| Parallel developer-tool fanout | `multi_tool_use.parallel(...)` |
| CSV row fanout | `spawn_agents_on_csv(...)` |

Use `request_user_input(...)` as the tool name, with `request_user_input(questions=[...])` as the normal structured-decision call shape.

## Runtime Truth

- Use the surfaced tool list in the active session as the source of truth for the current turn.
- For latest-alpha preflight on this machine, verify feature-gated surfaces with `codex features list` when the tool is relevant but not currently surfaced.
- `request_user_input` is root-thread only and enabled in this local runtime for root-thread elicitation.
- Treat it as the local structured-decision surface for eligible discrete branch-point questions.
- This reference intentionally targets the V2 child-agent surface gated by `multi_agent_v2`.
- `multi_agent_v2` gates V2 child-agent tools independently of legacy `collab`; do not tell users to enable `collab` just to surface `spawn_agent`, `send_message`, `followup_task`, `wait_agent`, `close_agent`, or `list_agents`.
- Review and guardian review sub-sessions intentionally disable `multi_agent_v2`; do not assume nested review agents can spawn further child agents even when the root session has V2 enabled.
- In `multi_agent_v2`-only sessions, legacy `send_input` and `resume_agent` remain hidden; use `send_message`, `followup_task`, and `wait_agent` for live child control.
- On `codex-cli 0.129.0-alpha.6`, the surfaced Codex tool schema requires `task_name` and `message`; the upstream handler still treats `agent_type` as optional metadata.
- This local superpowers implementation requires explicit `agent_type` on every multi-agent dispatch because role selection is part of the contract.
- The built-in roles listed above are common on this machine, but surfaced roles are not guaranteed to be exhaustive.
- `followup_task` has only `target` and `message` fields in this runtime. Do not pass an `interrupt` parameter.
- `multi_agent_v2` is configured as `[features.multi_agent_v2]`, not `[agents]`. Keep `enabled = true`, `max_concurrent_threads_per_session = 32`, and `min_wait_timeout_ms = 300000` on this workstation.
- Do not set `[agents].max_threads` while V2 is enabled; the runtime rejects that combination.
- Do not set `[agents].max_depth` to control V2 spawn trees; alpha.15 ignores the legacy V1 depth guard when `multi_agent_v2` is enabled.
- Remaining optional V2 subkeys are `usage_hint_enabled`, `usage_hint_text`, `root_agent_usage_hint_text`, `subagent_usage_hint_text`, and `hide_spawn_agent_metadata`. Leave them unset unless deliberately changing global runtime behavior; Superpowers owns dispatch guidance locally.
- This workstation sets `min_wait_timeout_ms = 300000`, so default waits fit xhigh subagent startup latency.
- `update_plan(...)` is a progress/checklist tool. It is not Plan Mode and must not be used in Plan Mode.
- `functions.exec` is useful for orchestration when surfaced, but it has no Node APIs, filesystem access, network access, persistent bindings, image emission helpers, or `codex.tool(...)` helpers unless the active tool definition says otherwise.
- Do not use or recommend `js_repl` or `js_repl_reset` by default; both feature keys are removed in this runtime.
- The built-in image tool is `image_gen.imagegen(...)` when surfaced, but it is still gated by runtime feature/model/auth checks and may not appear in every session.
- The root thread owns user elicitation.

## Current CLI And Config Notes

- `codex update` is a real top-level command in this runtime.
- `codex sandbox macos|linux|windows` accepts `--permissions-profile <NAME>` for built-in or configured permission profiles; explicit-profile calls also support `-C/--cd <DIR>` and `--include-managed-config`.
- Do not use `--full-auto`; use `--sandbox workspace-write` for the surviving exec migration path, or `--permissions-profile :workspace` for direct sandbox testing.
- Do not depend on `undo` or `ghost_snapshot`; the feature is removed and old ghost snapshot config is compatibility-only.
- Use `activity`, not `spinner`, in `tui.terminal_title`.
- `hooks` is stable and enabled on this workstation.
- `plugin_hooks` is under development and enabled on this workstation.
- `remote_compaction_v2` is under development and currently disabled in this workstation config.
- `tool_search`, `tool_suggest`, and `tool_call_mcp_elicitation` are stable and enabled on this workstation.
- Superpowers no longer depends on native plugin hooks for its core routing contract. Start sessions manually with `superpowers-codex:using-superpowers` when the workflow applies.

## Dispatch Rules

- Use a stable lowercase `task_name`.
- The parent owns clarification, escalation, and final synthesis.
- Use read-only roles for review and exploration.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Keep child packets narrow and self-contained.
