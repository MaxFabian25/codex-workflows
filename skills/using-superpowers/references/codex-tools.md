# Codex Tool Mapping

Skills may still mention Claude Code tool names. On this workstation, translate them to the local Codex contract below.

| Skill references | Codex equivalent |
|---|---|
| `Task` tool (dispatch subagent) | `spawn_agent(task_name=..., agent_type="<configured_role>", items=[{type:"text", text: ...}])` |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(...)` calls using `agent_type="parallel_explorer"` for bounded read-only fanout |
| Task returns result | `wait_agent` to synchronize, then read the child completion reply |
| Task completes automatically | `close_agent` after harvesting the child result |
| `TodoWrite` | `update_plan` |
| `Skill` tool | Skills load natively; follow the referenced skill instructions |
| `Read`, `Write`, `Edit` | Native file tools |
| `Bash` | Native shell tools |

## Required Runtime Flags

Add to the workstation config source at `~/.codex/config.macos-source.toml`, then sync `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = false
```

For the explicit parallel profile:

```toml
[profiles.parallel_readonly.features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = true
```

`multi_agent_v2` is authoritative for the profile feature-state contract on this workstation. If the live runtime does not activate it, stop and fix the runtime before trusting any local docs. These checks verify profile flags; they do not by themselves prove end-to-end custom-role dispatch.

## Config-Owned Child Roles

Codex custom agents are defined in `~/.codex/config.macos-source.toml` and backed by `~/.codex/agents/*.toml`.

| Role | Use |
|---|---|
| `implementer` | One bounded code-changing task |
| `spec_reviewer` | Read-only spec compliance review |
| `code_quality_reviewer` | Read-only quality review |
| `parallel_explorer` | Read-only independent exploration and audit work |
| `final_reviewer` | Read-only whole-change review |

Treat these role names as the configured local contract. If actual dispatch behavior is in doubt, verify it separately instead of guessing between generic built-in roles.

## Dispatch Rules

- Always pass a stable lowercase `task_name`.
- Keep the parent session responsible for user clarification, escalation handling, and final synthesis.
- Use `implementer` for code-changing work, one child at a time.
- Use `spec_reviewer` before `code_quality_reviewer`.
- Use `parallel_explorer` for bounded read-only fanout.
- Use `final_reviewer` after the plan is complete.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Document only runtime behavior that was verified against the installed binary.

## Dispatch Payload Framing

The text item inside `items` is user-level input. Structure it like this:

```text
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content]
</agent-instructions>

Execute this now. Output ONLY the structured response requested above.
```

Use task framing, keep the packet narrow, and include all required context instead of making the child read the plan file on its own.

## Environment Detection

Skills that create worktrees or finish branches should detect their environment with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` means you are already in a linked worktree
- empty `BRANCH` means detached HEAD

## Codex App Finishing

When the sandbox blocks branch or push operations in an externally managed worktree, the agent should still commit locally, report the current commit SHA, and hand off branch creation or PR creation to the host environment.
