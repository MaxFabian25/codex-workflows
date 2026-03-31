# Codex Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(task_name=...)` calls, or `multi_tool_use.parallel` for short read-only work |
| Task returns result | `wait_agent` to synchronize; on v2 the actual deliverable comes from the child completion reply, not the wait summary |
| Task completes automatically | `close_agent` after harvesting the deliverable and evidence |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |

## Subagent dispatch requires multi-agent support

Add to your Codex config source (`~/.codex/config.wsl-source.toml` in this workspace, then sync the generated mirror):

```toml
[features]
multi_agent = true
multi_agent_v2 = true
# enable_fanout = true  # only when you need spawn_agents_on_csv
```

This enables the current v2 surface for skills like `dispatching-parallel-agents` and `subagent-driven-development`: `spawn_agent(task_name=...)`, `send_message`, `assign_task`, `list_agents`, `wait_agent`, and `close_agent`.

On v2:

- Always pass `task_name` to `spawn_agent`.
- Prefer canonical `task_name` or task paths over `agent_id` for follow-up targeting.
- Use `assign_task` for an immediate follow-up turn and `send_message` for a queued note.
- Treat `wait_agent` as synchronization, not a heartbeat or the final synthesis channel.
- Resolve user-facing clarification before dispatch; child agents do not get `request_user_input`.
- Preserve inherited child config by default; do not pass `model` or `reasoning_effort` unless the user explicitly asks for an override.

## Named agent dispatch

Claude Code skills reference named agent types like `superpowers:code-reviewer`.
Codex does not have a named agent registry — `spawn_agent(task_name=..., agent_type=..., items=[{type:"text", text: ...}])` creates agents from built-in or locally configured roles such as `default`, `explorer`, `worker`, `planner`, `reviewer`, and `verifier`.

When a skill says to dispatch a named agent type:

1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
   local prompt template like `code-quality-reviewer-prompt.md`)
2. Read the prompt content
3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
4. Spawn an agent with a stable `task_name`, a suitable `agent_type`, and the filled content in a text item inside `items`

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| `Task tool (superpowers:code-reviewer)` | `spawn_agent(task_name="code_review", agent_type="reviewer", items=[{type:"text", text: ...}])` with `code-reviewer.md` content |
| `Task tool (general-purpose)` with inline prompt | `spawn_agent(task_name="<scoped_name>", agent_type="default", items=[{type:"text", text: ...}])` with the same prompt |

### Dispatch payload framing

The text item inside `items` is user-level input, not a system prompt. Structure it
for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions

### When this workaround can be removed

This approach compensates for Codex not auto-registering named agent specs from
the local plugin or skill tree. Reusable prompt templates can still live under
`.codex/agents/` or alongside the skill, but dispatch remains explicit via
`spawn_agent(..., items=[{type:"text", text: ...}])`.

## Environment Detection

Skills that create worktrees or finish branches should detect their
environment with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
Step 1 for how each skill uses these signals.

## Codex App Finishing

When the sandbox blocks branch/push operations (detached HEAD in an
externally managed worktree), the agent commits all work and informs
the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch
names, commit messages, and PR descriptions for the user to copy.
