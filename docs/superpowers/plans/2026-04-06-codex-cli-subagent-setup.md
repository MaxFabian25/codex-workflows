# Codex CLI Subagent Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align this workstation's Codex CLI/TUI runtime and the local `~/.codex/superpowers` checkout with a v2-first, controller-led superpowers workflow using config-owned child roles.

**Architecture:** Update the global Codex config source first, add explicit custom agent TOML files under `~/.codex/agents/`, then sync the live mirror and verify runtime activation. Only after the runtime proves `multi_agent_v2 = true` for both profiles should the local superpowers Codex-facing docs and prompt templates be hard-cut to the new role contract (`implementer`, `spec_reviewer`, `code_quality_reviewer`, `parallel_explorer`, `final_reviewer`).

**Tech Stack:** TOML, Markdown, Codex CLI, git, `rg`, `cp`, `diff`

**Spec:** `/Users/maxibon/.codex/superpowers/docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md`

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `/Users/maxibon/.codex/config.macos-source.toml` | Editable workstation config source | Modify |
| `/Users/maxibon/.codex/config.toml` | Live config mirror used by Codex | Modify (sync from source) |
| `/Users/maxibon/.codex/agents/implementer.toml` | Write-capable child role for one bounded plan task | Create |
| `/Users/maxibon/.codex/agents/spec_reviewer.toml` | Read-only spec compliance reviewer | Create |
| `/Users/maxibon/.codex/agents/code_quality_reviewer.toml` | Read-only quality reviewer | Create |
| `/Users/maxibon/.codex/agents/parallel_explorer.toml` | Read-only explorer for explicit fanout lanes | Create |
| `/Users/maxibon/.codex/agents/final_reviewer.toml` | Read-only whole-change reviewer | Create |
| `/Users/maxibon/.codex/superpowers/docs/README.codex.md` | Codex install and runtime contract for this workstation | Modify |
| `/Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md` | Codex tool and role mapping reference | Modify |
| `/Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md` | Explicit parallel lane guidance | Modify |
| `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/SKILL.md` | Controller-led per-task workflow | Modify |
| `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/implementer-prompt.md` | Implementer packet template | Modify |
| `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md` | Spec reviewer packet template | Modify |
| `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md` | Code-quality reviewer packet template | Modify |
| `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md` | Standalone review workflow | Modify |
| `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/code-reviewer.md` | Shared reviewer template | Modify |

## Global Config Note

`/Users/maxibon/.codex` is not a git repository. For Tasks 1-3, replace the usual commit step with:

- a dated backup under `/Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/`
- a `diff -u` checkpoint against the backup
- explicit runtime verification commands

Repo-owned tasks in `/Users/maxibon/.codex/superpowers` use normal git commits.

---

### Task 1: Hard-Cut the Editable Config Source

**Files:**
- Modify: `/Users/maxibon/.codex/config.macos-source.toml`
- Create: `/Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/config.macos-source.toml.before`
- Create: `/Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/config.toml.before`

- [ ] **Step 1: Create a dated backup checkpoint**

Run:

```bash
mkdir -p /Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup
cp /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/config.macos-source.toml.before
cp /Users/maxibon/.codex/config.toml /Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/config.toml.before
```

Expected:
- Both backup files exist.

- [ ] **Step 2: Add the default active profile**

Insert this line immediately after `web_search = "live"` in `/Users/maxibon/.codex/config.macos-source.toml`:

```toml
profile = "workflow_fidelity"
```

- [ ] **Step 3: Replace the root `[features]` block**

Replace the existing `[features]` block in `/Users/maxibon/.codex/config.macos-source.toml` with exactly:

```toml
[features]
apply_patch_freeform = true
unified_exec = true
shell_snapshot = true
fast_mode = true
multi_agent = true
multi_agent_v2 = true
enable_fanout = false
personality = true
prevent_idle_sleep = true
js_repl = true
default_mode_request_user_input = true
artifact = true
image_detail_original = true
memories = true
responses_websockets_v2 = true
runtime_metrics = true
undo = true
image_generation = true
```

- [ ] **Step 4: Replace the root `[agents]` block and add custom role mappings**

Replace the existing `[agents]` block with the following block, inserted before `[ghost_snapshot]`:

```toml
[agents]
max_threads = 32
max_depth = 3
job_max_runtime_seconds = 3600

[agents.implementer]
description = "Write-capable superpowers implementer for one bounded plan task with mandatory TDD."
config_file = "./agents/implementer.toml"
nickname_candidates = ["Forge", "Rivet"]

[agents.spec_reviewer]
description = "Read-only superpowers reviewer that checks code against the approved task text."
config_file = "./agents/spec_reviewer.toml"
nickname_candidates = ["Gauge", "Sift"]

[agents.code_quality_reviewer]
description = "Read-only superpowers reviewer for correctness, test quality, and maintainability."
config_file = "./agents/code_quality_reviewer.toml"
nickname_candidates = ["Lint", "Proof"]

[agents.parallel_explorer]
description = "Read-only superpowers child for bounded parallel exploration and audit work."
config_file = "./agents/parallel_explorer.toml"
nickname_candidates = ["Scout", "Atlas"]

[agents.final_reviewer]
description = "Read-only whole-change reviewer for the final superpowers review pass."
config_file = "./agents/final_reviewer.toml"
nickname_candidates = ["Sentinel", "Northstar"]

[profiles.workflow_fidelity]
model = "gpt-5.4"
approval_policy = "never"
sandbox_mode = "danger-full-access"
model_reasoning_effort = "xhigh"
model_reasoning_summary = "detailed"
model_verbosity = "high"
personality = "pragmatic"

[profiles.workflow_fidelity.features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = false

[profiles.parallel_readonly]
model = "gpt-5.4"
approval_policy = "never"
sandbox_mode = "danger-full-access"
model_reasoning_effort = "high"
model_reasoning_summary = "detailed"
model_verbosity = "medium"
personality = "pragmatic"

[profiles.parallel_readonly.features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = true
```

- [ ] **Step 5: Verify the source file checkpoint**

Run:

```bash
diff -u /Users/maxibon/.codex/backups/2026-04-06-codex-cli-subagent-setup/config.macos-source.toml.before /Users/maxibon/.codex/config.macos-source.toml
rg -n '^(profile = "workflow_fidelity"|multi_agent_v2 = true|enable_fanout = false|max_threads = 32|max_depth = 3|job_max_runtime_seconds = 3600)$' /Users/maxibon/.codex/config.macos-source.toml
rg -n '^\[agents\.(implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer)\]$' /Users/maxibon/.codex/config.macos-source.toml
```

Expected:
- `diff -u` shows the intended config-only changes.
- The first `rg` shows the new root profile/feature/agent settings.
- The second `rg` shows all five custom role blocks exactly once.

---

### Task 2: Create the Custom Agent TOML Files

**Files:**
- Create: `/Users/maxibon/.codex/agents/implementer.toml`
- Create: `/Users/maxibon/.codex/agents/spec_reviewer.toml`
- Create: `/Users/maxibon/.codex/agents/code_quality_reviewer.toml`
- Create: `/Users/maxibon/.codex/agents/parallel_explorer.toml`
- Create: `/Users/maxibon/.codex/agents/final_reviewer.toml`

- [ ] **Step 1: Create the agents directory**

Run:

```bash
mkdir -p /Users/maxibon/.codex/agents
```

Expected:
- `/Users/maxibon/.codex/agents` exists.

- [ ] **Step 2: Create `/Users/maxibon/.codex/agents/implementer.toml`**

Write exactly:

```toml
name = "implementer"
description = "Write-capable superpowers implementer for one bounded plan task with mandatory TDD."
sandbox_mode = "danger-full-access"
developer_instructions = """
You are the write-capable implementer in the superpowers workflow.

Non-negotiable rules:
- Own only the bounded task and file set assigned by the parent.
- For any code-changing task, invoke the superpowers:test-driven-development skill before writing implementation code.
- Follow RED-GREEN-REFACTOR: write the failing test, prove it fails, write the minimum code, prove it passes.
- Do not widen scope, refactor unrelated code, or guess when requirements are unclear.
- If context is missing or the task is larger than the packet suggests, stop and report NEEDS_CONTEXT or BLOCKED.
- Report status as DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.
"""
```

- [ ] **Step 3: Create `/Users/maxibon/.codex/agents/spec_reviewer.toml`**

Write exactly:

```toml
name = "spec_reviewer"
description = "Read-only superpowers reviewer that checks code against the approved task text."
sandbox_mode = "read-only"
developer_instructions = """
You are the read-only spec compliance reviewer in the superpowers workflow.

Non-negotiable rules:
- Do not edit files, stage changes, or commit.
- Distrust the implementer report and verify the changed code directly.
- Compare the implementation against the approved task text line by line.
- Report missing requirements, extra behavior, and requirement misunderstandings with file references.
- If the task is compliant, say so clearly and briefly.
"""
```

- [ ] **Step 4: Create `/Users/maxibon/.codex/agents/code_quality_reviewer.toml`**

Write exactly:

```toml
name = "code_quality_reviewer"
description = "Read-only superpowers reviewer for correctness, test quality, and maintainability."
sandbox_mode = "read-only"
developer_instructions = """
You are the read-only code quality reviewer in the superpowers workflow.

Non-negotiable rules:
- Do not edit files, stage changes, or commit.
- Review only after spec compliance has already passed.
- Categorize findings by severity: Critical, Important, or Minor.
- Focus on correctness, test quality, maintainability, and scope discipline.
- Every issue must include a concrete file reference and why it matters.
"""
```

- [ ] **Step 5: Create `/Users/maxibon/.codex/agents/parallel_explorer.toml`**

Write exactly:

```toml
name = "parallel_explorer"
description = "Read-only superpowers child for bounded parallel exploration and audit work."
sandbox_mode = "read-only"
developer_instructions = """
You are the read-only exploration agent in the superpowers workflow.

Non-negotiable rules:
- Stay read-only at all times.
- Work only on the independent question or audit slice assigned by the parent.
- Prefer targeted search and direct file references over broad narrative summaries.
- Do not propose implementation unless the parent explicitly asked for it.
- Return concise findings with concrete evidence and clear uncertainty notes.
"""
```

- [ ] **Step 6: Create `/Users/maxibon/.codex/agents/final_reviewer.toml`**

Write exactly:

```toml
name = "final_reviewer"
description = "Read-only whole-change reviewer for the final superpowers review pass."
sandbox_mode = "read-only"
developer_instructions = """
You are the read-only final reviewer in the superpowers workflow.

Non-negotiable rules:
- Do not edit files, stage changes, or commit.
- Review the full change set, not just one task packet.
- Confirm the final state matches the approved plan and that no unresolved Important or Critical issues remain.
- Call out any workflow violations such as skipped TDD or skipped review stages.
- Return a merge-readiness verdict with concrete findings.
"""
```

- [ ] **Step 7: Verify the agent files**

Run:

```bash
ls -1 /Users/maxibon/.codex/agents
rg -n '^(name|description|sandbox_mode|developer_instructions) = ' /Users/maxibon/.codex/agents/*.toml
```

Expected:
- `ls -1` shows exactly `code_quality_reviewer.toml`, `final_reviewer.toml`, `implementer.toml`, `parallel_explorer.toml`, and `spec_reviewer.toml`.
- `rg` shows all required top-level fields in each file.

- [ ] **Step 8: Record the non-git checkpoint**

Run:

```bash
diff -u /dev/null /Users/maxibon/.codex/agents/implementer.toml
diff -u /dev/null /Users/maxibon/.codex/agents/spec_reviewer.toml
diff -u /dev/null /Users/maxibon/.codex/agents/code_quality_reviewer.toml
diff -u /dev/null /Users/maxibon/.codex/agents/parallel_explorer.toml
diff -u /dev/null /Users/maxibon/.codex/agents/final_reviewer.toml
```

Expected:
- Each `diff -u` shows a file creation diff for the new agent file.

---

### Task 3: Sync the Live Config Mirror and Prove the Runtime Contract

**Files:**
- Modify: `/Users/maxibon/.codex/config.toml`

- [ ] **Step 1: Sync the live mirror from the editable source**

Run:

```bash
cp /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
```

Expected:
- `/Users/maxibon/.codex/config.toml` matches the source file byte-for-byte.

- [ ] **Step 2: Verify the source and live mirror are identical**

Run:

```bash
diff -u /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
```

Expected:
- No output.

- [ ] **Step 3: Verify the active binary and profile feature state**

Run:

```bash
which -a codex
codex --version
codex -p workflow_fidelity features list | rg -n 'multi_agent|multi_agent_v2|enable_fanout'
codex -p parallel_readonly features list | rg -n 'multi_agent|multi_agent_v2|enable_fanout'
```

Expected:
- `which -a codex` still includes `/Users/maxibon/.npm-global/bin/codex`.
- `codex --version` returns the installed alpha CLI version.
- `workflow_fidelity` shows `multi_agent = true`, `multi_agent_v2 = true`, `enable_fanout = false`.
- `parallel_readonly` shows `multi_agent = true`, `multi_agent_v2 = true`, `enable_fanout = true`.

- [ ] **Step 4: Verify the custom child-role mapping is active in both config surfaces**

Run:

```bash
rg -n '^\[agents\.(implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer)\]$' /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
rg -n 'config_file = "./agents/(implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer)\.toml"' /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
```

Expected:
- Both `rg` commands show all five role mappings in both files.

- [ ] **Step 5: Enforce the blocker stop rule**

If either profile still reports `multi_agent_v2 = false`, or if `codex -p workflow_fidelity features list` / `codex -p parallel_readonly features list` rejects the config:

```text
STOP. Report a runtime blocker with the exact failing command output. Do not continue to Tasks 4-8 until the Codex runtime is upgraded or the config surface is corrected.
```

If all runtime checks pass, continue.

---

### Task 4: Rewrite `README.codex.md` to the v2-First Workstation Contract

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/docs/README.codex.md`

- [ ] **Step 1: Replace `/Users/maxibon/.codex/superpowers/docs/README.codex.md` with the following content**

````markdown
# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery on this workstation.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. Edit the workstation config source at `~/.codex/config.macos-source.toml`.

4. Sync the live mirror:
   ```bash
   cp ~/.codex/config.macos-source.toml ~/.codex/config.toml
   ```

5. Restart Codex.

## How Codex Sees Superpowers

Codex discovers Superpowers through native skill discovery, not through a plugin manifest:

```text
~/.agents/skills/superpowers -> ~/.codex/superpowers/skills
```

The `using-superpowers` skill is discovered from that symlink and remains the workflow entrypoint.

## Required Agent Contract

For this workstation, the authoritative child-agent contract is:

```toml
profile = "workflow_fidelity"

[features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = false

[agents]
max_threads = 32
max_depth = 3
job_max_runtime_seconds = 3600
```

Rules:

- `multi_agent_v2 = true` is required for both `workflow_fidelity` and `parallel_readonly`.
- The v2 child-role mapping takes precedence over generic legacy `multi_agent` role guessing.
- `max_depth = 3` and `job_max_runtime_seconds = 3600` are authoritative.
- `enable_fanout` stays off in the default controller profile and is enabled only for the explicit parallel lane.
- If either `codex -p workflow_fidelity features list` or `codex -p parallel_readonly features list` does not show `multi_agent_v2 = true`, stop and treat that as a runtime blocker instead of weakening the docs.

## Profiles

- `workflow_fidelity`: default controller-first profile for `brainstorming`, `using-git-worktrees`, `writing-plans`, `subagent-driven-development`, `executing-plans`, `requesting-code-review`, and `finishing-a-development-branch`
- `parallel_readonly`: explicit profile for bounded read-only fanout such as `dispatching-parallel-agents`

Do not use `parallel_readonly` as the default implementation profile.

## Child Role Mapping

Superpowers relies on config-owned child roles declared in `~/.codex/config.macos-source.toml` and backed by `~/.codex/agents/*.toml`:

| Role | Workflow use | Access mode |
|---|---|---|
| `implementer` | One bounded code-changing task in `subagent-driven-development` | Write-capable |
| `spec_reviewer` | Spec-compliance review after each task | Read-only |
| `code_quality_reviewer` | Code-quality review after spec passes | Read-only |
| `parallel_explorer` | Independent parallel exploration and audit work | Read-only |
| `final_reviewer` | Final whole-change review pass | Read-only |

Skills should dispatch these mapped role names directly. The parent session remains responsible for user clarification, arbitration, and final synthesis.

## Updating

```bash
cd ~/.codex/superpowers && git pull
cp ~/.codex/config.macos-source.toml ~/.codex/config.toml
```

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.codex/superpowers/skills`
3. Restart Codex

### v2 not activating

Run:

```bash
codex -p workflow_fidelity features list
codex -p parallel_readonly features list
```

If either profile reports `multi_agent_v2 = false`, stop and fix the runtime or config before trusting any subagent workflow docs.
````

- [ ] **Step 2: Verify the README contract text**

Run:

```bash
rg -n 'multi_agent_v2|max_depth = 3|job_max_runtime_seconds = 3600|workflow_fidelity|parallel_readonly|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer' /Users/maxibon/.codex/superpowers/docs/README.codex.md
rg -n 'multi_agent = true is sufficient|subagent skills.*optional' /Users/maxibon/.codex/superpowers/docs/README.codex.md
```

Expected:
- The first `rg` hits the new workstation contract.
- The second `rg` returns no results.

- [ ] **Step 3: Commit**

```bash
git -C /Users/maxibon/.codex/superpowers add docs/README.codex.md
git -C /Users/maxibon/.codex/superpowers commit -m "docs(codex): hard-cut v2 workstation contract"
```

---

### Task 5: Rewrite the Codex Tool Mapping Reference

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md`

- [ ] **Step 1: Replace `/Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md` with the following content**

````markdown
# Codex Tool Mapping

Skills may still mention Claude Code tool names. On this workstation, translate them to the local Codex contract below.

| Skill references | Codex equivalent |
|---|---|
| `Task` tool (dispatch subagent) | `spawn_agent(task_name=..., agent_type="<configured_role>", message="...")` |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(...)` calls; use `agent_type="parallel_explorer"` as the default bounded read-only fanout lane |
| Task returns result | `wait_agent` to synchronize, then read the child completion reply |
| Task completes automatically | `close_agent` when no further follow-up is needed after harvesting the child result |
| `TodoWrite` | `update_plan` |
| `Skill` tool | Use the available skills list, open the relevant `SKILL.md`, and follow it |
| `Read`, `Write`, `Edit` | Use native file tools such as `exec_command` for reads and `apply_patch` for edits |
| `Bash` | Use native shell tools such as `exec_command` |

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

The top-level `message` field is user-level input. Structure it like this:

```text
Your task is to perform the following.
Follow the instructions below exactly.

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
````

- [ ] **Step 2: Verify the tool mapping rewrite**

Run:

```bash
rg -n 'multi_agent_v2|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer|spawn_agent|wait_agent|close_agent' /Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md
rg -n 'send_message|assign_task|list_agents|agent_type="worker"|agent_type="reviewer"' /Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md
```

Expected:
- The first `rg` shows the v2-first runtime contract and custom role names.
- The second `rg` returns no results.

- [ ] **Step 3: Commit**

```bash
git -C /Users/maxibon/.codex/superpowers add skills/using-superpowers/references/codex-tools.md
git -C /Users/maxibon/.codex/superpowers commit -m "docs(codex-tools): map v2 roles to custom superpowers agents"
```

---

### Task 6: Tighten the Explicit Parallel Lane

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md`

- [ ] **Step 1: Replace the `Codex v2 translation` paragraph**

Replace the paragraph that begins with `**Codex v2 translation:**` with exactly:

```markdown
**Codex v2 translation:** Use `spawn_agent(task_name=..., agent_type="parallel_explorer", message="...")` for the default read-only fanout lane. Keep follow-up coordination in the parent, use one long `wait_agent` only when blocked on a child, and reserve write-capable child roles for explicitly approved non-overlapping implementation slices.
```

- [ ] **Step 2: Replace the example parallel dispatch block**

Replace the three example `spawn_agent(...)` lines under `### 3. Dispatch in Parallel` with exactly:

```text
spawn_agent(task_name="map_abort_failures", agent_type="parallel_explorer", message="Read src/agents/agent-tool-abort.test.ts and explain the root cause of the failing cases. Stay read-only and return file references.")
spawn_agent(task_name="map_batch_completion", agent_type="parallel_explorer", message="Read batch-completion-behavior.test.ts and summarize the failing-path root cause with evidence. Stay read-only.")
spawn_agent(task_name="map_tool_approval_race", agent_type="parallel_explorer", message="Investigate tool-approval-race-conditions.test.ts, identify the root cause, and return evidence. Stay read-only.")
# All three run concurrently; the parent keeps synthesis and decides whether implementation is needed later
```

- [ ] **Step 3: Add a no-overlap guard to `When NOT to Use`**

Insert this bullet at the end of the `When NOT to Use` section:

```markdown
**Overlapping implementation:** If two children would edit the same files or shared state, do not use this skill as the execution lane. Go back to the controller-first plan flow instead.
```

- [ ] **Step 4: Verify the parallel lane contract**

Run:

```bash
rg -n 'parallel_explorer|read-only|overlapping implementation' /Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md
rg -n 'agent_type="worker"' /Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md
```

Expected:
- The first `rg` shows the read-only `parallel_explorer` lane.
- The second `rg` returns no results.

- [ ] **Step 5: Commit**

```bash
git -C /Users/maxibon/.codex/superpowers add skills/dispatching-parallel-agents/SKILL.md
git -C /Users/maxibon/.codex/superpowers commit -m "docs(parallel): default fanout to read-only parallel_explorer"
```

---

### Task 7: Hard-Cut the Subagent-Driven Development Workflow

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/SKILL.md`
- Modify: `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/implementer-prompt.md`
- Modify: `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md`
- Modify: `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md`

- [ ] **Step 1: Replace the `## Child Config Inheritance` section in `SKILL.md`**

Replace the entire `## Child Config Inheritance` section with exactly:

```markdown
## Child Config Inheritance and Role Mapping

Child agents inherit the parent session config by default. Preserve that inheritance unless the user explicitly asks for a role-specific override.

- Do not pass `model` or `reasoning_effort` in `spawn_agent(...)` during normal operation.
- Use the config-owned superpowers role mapping instead of generic built-in role guessing:
  - `implementer` for the single active code-changing child
  - `spec_reviewer` for the read-only spec compliance pass
  - `code_quality_reviewer` for the read-only code quality pass
  - `final_reviewer` for the whole-change review at the end
- Reviewers stay read-only.
- The parent remains responsible for user clarification, packet refinement, arbitration, and final synthesis.
```

- [ ] **Step 2: Replace `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/implementer-prompt.md` with the following content**

````markdown
# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```yaml
Codex subagent packet (preferred v2):
  task_name: "<stable_task_name>"
  agent_type: "implementer"
  message: |
    Your task is to perform the following.
    Follow the instructions below exactly.

    <agent-instructions>
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here,
    don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Raise them now.** Return a blocking question
    before starting work if anything is unclear.

    ## Your Job

    Once you're clear on requirements:
    1. For any code-changing task, invoke the `superpowers:test-driven-development` skill before writing implementation code
    2. Follow RED-GREEN-REFACTOR: write the failing test first and prove it fails, then write the minimum implementation to make the test pass and prove it passes
    3. Verify the implementation works
    4. Commit your work
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something
    unexpected or unclear, stop and report a
    blocking question.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Code Organization

    You reason best about code you can hold in
    context at once, and your edits are more
    reliable when files are focused.
    Keep this in mind:
    - Follow the file structure defined in the plan
    - Each file should have one clear responsibility
      with a well-defined interface
    - If a file you're creating is growing beyond
      the plan's intent, stop and report
      it as DONE_WITH_CONCERNS — don't split files
      on your own without plan guidance
    - If an existing file you're modifying is
      already large or tangled, work carefully
      and note it as a concern in your report
    - In existing codebases, follow established
      patterns. Improve code you're touching
      the way a good developer would, but don't
      restructure things outside your task.

    ## When You're in Over Your Head

    It is always OK to stop and say
    "this is too hard for me."
    Bad work is worse than no work.
    You will not be penalized for escalating.

    **STOP and escalate when:**
    - The task requires architectural decisions with multiple valid approaches
    - You need to understand code beyond what was provided and can't find clarity
    - You feel uncertain about whether your approach is correct
    - The task involves restructuring existing code
      in ways the plan didn't anticipate
    - You've been reading file after file trying
      to understand the system without progress

    **How to escalate:** Report back with status
    BLOCKED or NEEDS_CONTEXT. Describe specifically
    what you're stuck on, what you've tried, and
    what kind of help you need. The controller can
    provide more context, tighten the packet,
    preserve inherited config,
    or break the task into smaller pieces.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what
      things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior
      (not just mock behavior)?
    - Did I follow TDD?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS |
      BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns

    Use DONE_WITH_CONCERNS if you completed the
    work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. Never
    silently produce work you're unsure about.
    </agent-instructions>

    Execute this now. Output ONLY the structured
    response following the format
    specified in the instructions above.
```
````

- [ ] **Step 3: Replace `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md` with the following content**

````markdown
# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify the implementer built what was requested, nothing more and nothing less.

```yaml
Codex subagent packet (preferred v2):
  task_name: "<stable_spec_review_name>"
  agent_type: "spec_reviewer"
  message: |
    Your task is to perform the following.
    Follow the instructions below exactly.

    <agent-instructions>
    You are reviewing whether an implementation matches its specification.

    ## Hard Rules

    - Stay read-only. Do not edit files, stage changes, or commit.
    - Verify the code directly. Do not trust the implementer report.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## CRITICAL: Do Not Trust the Report

    The implementer finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual code they wrote
    - Compare actual implementation to requirements line by line
    - Check for missing pieces they claimed to implement
    - Look for extra features they didn't mention

    ## Your Job

    Read the implementation code and verify:

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there requirements they skipped or missed?
    - Did they claim something works but didn't actually implement it?

    **Extra/unneeded work:**
    - Did they build things that weren't requested?
    - Did they over-engineer or add unnecessary features?
    - Did they add "nice to haves" that weren't in spec?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?
    - Did they implement the right feature but the wrong way?

    Report:
    - ✅ Spec compliant
    - ❌ Issues found: [list specific missing or extra items with file references]
    </agent-instructions>

    Execute this now. Output ONLY the structured
    response following the format
    specified in the instructions above.
```
````

- [ ] **Step 4: Replace `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md` with the following content**

````markdown
# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built, well-tested, and maintainable.

**Only dispatch after spec compliance review passes.**

Before dispatching, fill `../requesting-code-review/code-reviewer.md` completely and paste the filled template into this packet. Do not ask the child to read the shared template from disk.

```yaml
Codex subagent packet (preferred v2):
  task_name: "<stable_code_review_name>"
  agent_type: "code_quality_reviewer"
  message: |
    Your task is to perform the following.
    Follow the instructions below exactly.

    <agent-instructions>
    Stay read-only. Do not edit files, stage changes, or commit.

    The filled shared review template is included below. Treat it as the primary review contract.

    <filled-shared-review-template>
    [paste fully filled ../requesting-code-review/code-reviewer.md here]
    </filled-shared-review-template>

    In addition to standard code quality concerns, also check:
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this implementation create new files that are already large,
      or significantly grow existing files?
      (Don't flag pre-existing file sizes. Focus on what this change contributed.)
    </agent-instructions>

    Execute this now. Output ONLY the structured
    response following the format
    specified in the instructions above.
```

**In addition to standard code quality concerns, the reviewer should check:**

- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large,
  or significantly grow existing files?
  (Don't flag pre-existing file sizes. Focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Recommendations, Assessment
````

- [ ] **Step 5: Verify the subagent workflow hard cut**

Run:

```bash
rg -n 'implementer|spec_reviewer|code_quality_reviewer|final_reviewer|test-driven-development|Stay read-only' /Users/maxibon/.codex/superpowers/skills/subagent-driven-development/SKILL.md /Users/maxibon/.codex/superpowers/skills/subagent-driven-development/implementer-prompt.md /Users/maxibon/.codex/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md /Users/maxibon/.codex/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md
rg -n 'agent_type: "worker"|agent_type: "reviewer"|following TDD if task says to' /Users/maxibon/.codex/superpowers/skills/subagent-driven-development
```

Expected:
- The first `rg` shows the config-owned role names, read-only reviewer language, and explicit TDD requirement.
- The second `rg` returns no results.

- [ ] **Step 6: Commit**

```bash
git -C /Users/maxibon/.codex/superpowers add skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/spec-reviewer-prompt.md skills/subagent-driven-development/code-quality-reviewer-prompt.md
git -C /Users/maxibon/.codex/superpowers commit -m "docs(subagents): align superpowers workflow to config-owned v2 roles"
```

---

### Task 8: Align the Standalone Review Workflow

**Files:**
- Modify: `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md`
- Modify: `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/code-reviewer.md`

- [ ] **Step 1: Replace `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md` with the following content**

````markdown
---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a focused read-only review child to catch issues before they cascade. The reviewer inspects the work product, returns findings, and stops; the parent owns packet quality, arbitration, and final decisions.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in `subagent-driven-development`
- After completing a major feature or implementation batch
- Before merge to main

**Optional but valuable:**
- When stuck and a fresh read-only pass could surface the issue
- Before a risky refactor
- After fixing a complex bug

## Role Selection

- Use `code_quality_reviewer` after a completed task or implementation batch to review code quality, testing, architecture, and maintainability.
- Use `final_reviewer` for the final whole-change review before handing work off or merging.
- Both roles are read-only. Do not use write-capable child roles for review.

Dispatch them differently:
- `code_quality_reviewer`: fill `code-reviewer.md`, then paste that entire filled template into `../subagent-driven-development/code-quality-reviewer-prompt.md` and dispatch the filled wrapper packet. Use the wrapper because it adds the extra task-quality checks that apply only to this role.
- `final_reviewer`: fill `code-reviewer.md` and dispatch that filled shared template directly with `spawn_agent(..., agent_type="final_reviewer", message="...")`.

## How to Request

**1. Get git SHAs:**

```bash
# Save this before the task starts if you expect a multi-commit task-level review
TASK_START_SHA=$(git rev-parse HEAD)

# After the task is implemented and committed, review exactly that task scope
BASE_SHA=$TASK_START_SHA
HEAD_SHA=$(git rev-parse HEAD)

# Whole-change or final_reviewer scope against main
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

# Whole-change review against another target branch
# BASE_SHA=$(git merge-base HEAD origin/<target-branch>)
# HEAD_SHA=$(git rev-parse HEAD)
```

Use a saved pre-task SHA or another explicit task-start commit for task-level review scopes. `HEAD~1` is only correct when the requested scope is exactly one commit. For `final_reviewer`, set `BASE_SHA` to the merge-base against the target branch so the child reviews the whole change, not just the most recent task commit.

**2. Dispatch the review child by role:**

**Task-level `code_quality_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Paste the entire filled shared template into `../subagent-driven-development/code-quality-reviewer-prompt.md`.
- Dispatch the full filled wrapper packet with `spawn_agent(task_name=..., agent_type="code_quality_reviewer", message="...")`.

**Whole-change `final_reviewer`:**
- Fill the shared template at `code-reviewer.md`.
- Dispatch that filled shared template directly with `spawn_agent(task_name=..., agent_type="final_reviewer", message="...")`.

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` - Short review-scope label
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Fuller implementation summary

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding, or record why the reviewer is wrong
- Note Minor issues for later if they are not worth blocking on

## Examples

### Task-Level `code_quality_reviewer`

```text
[Just completed Task 2: Add verification function]

[Earlier, before Task 2 started, you saved its boundary]
TASK_2_START_SHA=$(git rev-parse HEAD)

You: Let me request code review before proceeding.

BASE_SHA=$TASK_2_START_SHA
HEAD_SHA=$(git rev-parse HEAD)

The actual `message=` payload must be the entire filled `../subagent-driven-development/code-quality-reviewer-prompt.md` wrapper packet. The block below is an excerpt showing the dispatch shape only. Do not send only this excerpt.

spawn_agent(task_name="task_2_code_review", agent_type="code_quality_reviewer", message="[full filled code-quality-reviewer-prompt.md wrapper packet for Task 2]")

  Excerpt from the actual wrapper payload:
  <filled-shared-review-template>
  # Code Review Agent

  You are performing a read-only review of code changes for the requested review scope.

  **Your task:**
  1. Review Verification and repair functions for conversation index
  2. Compare against Task 2 from docs/superpowers/plans/deployment-plan.md
  3. Check code quality, architecture, and testing
  4. Categorize issues by severity
  5. Assess readiness for the requested review scope

  ## What Was Implemented

  Added verifyIndex() and repairIndex() with 4 issue types

  ## Requirements/Plan

  Task 2 from docs/superpowers/plans/deployment-plan.md

  ## Git Range to Review

  **Base:** a7981ec
  **Head:** 3df7661
  </filled-shared-review-template>

  In addition to standard code quality concerns, also check:
  - Does each file have one clear responsibility with a well-defined interface?
  - Are units decomposed so they can be understood and tested independently?
  - Is the implementation following the file structure from the plan?
  - Did this implementation create new files that are already large, or significantly grow existing files?

[Review child returns]
### Strengths
- Clean architecture with real tests around the repair flow

### Issues

#### Critical (Must Fix)
None.

#### Important (Should Fix)
1. **Missing progress indicators**
   - File: `src/indexer.ts:130`
   - What's wrong: Long-running verification and repair paths do not report progress.
   - Why it matters: Task 2 requires progress reporting every 100 items, and operators cannot tell whether the job is still advancing.
   - How to fix: Add a progress log or callback that emits every 100 processed items.

#### Minor (Nice to Have)
1. **Magic reporting interval**
   - File: `src/indexer.ts:130`
   - What's wrong: The value `100` is inlined in the reporting path.
   - Why it matters: Future changes to the reporting cadence will require hunting through implementation details.
   - How to fix: Extract a named constant such as `PROGRESS_INTERVAL`.

### Recommendations
- Add progress reporting first, then extract the reporting interval constant in the same pass.

### Assessment

**Ready for requested review scope?** With fixes

**Reasoning:** The core design is sound, but the missing progress indicator should be fixed before proceeding to Task 3.

You: [Fix progress indicators]
[Continue to Task 3]
```

### Whole-Change `final_reviewer`

```text
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

spawn_agent(task_name="final_code_review", agent_type="final_reviewer", message="[entire filled code-reviewer.md template directly for the whole change]")
```

For `final_reviewer`, the actual `message=` payload is the entire filled shared `code-reviewer.md` template directly. Do not wrap it in `../subagent-driven-development/code-quality-reviewer-prompt.md`.

## Parent Arbitrates Disagreements

The review child reports findings. The parent decides what to do next.

- If the reviewer is right, fix the issue and re-run review if needed.
- If the reviewer is wrong, push back with technical reasoning and evidence from the code, tests, or plan.
- Do not ask the reviewer to arbitrate its own disputed finding. The parent owns that decision.

## Integration with Workflows

**Subagent-Driven Development:**
- Review after each task
- Use `code_quality_reviewer`
- Fix Important and Critical issues before moving on

**Executing Plans:**
- Review after each batch
- Use `code_quality_reviewer` or `final_reviewer` depending on scope

**Before Finish or Merge:**
- Use `final_reviewer`

## Red Flags

**Never:**
- Skip review because a change seems simple
- Use a write-capable child to review
- Proceed with unfixed Critical issues
- Ignore Important issues without explicit parent justification
- Let review replace verification

See template at: code-reviewer.md
````

- [ ] **Step 2: Replace `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/code-reviewer.md` with the following content**

````markdown
# Code Review Agent

You are reviewing code changes for production readiness.

**Hard Rules:**
- Stay read-only. Do not edit files, stage changes, or commit.
- Review the actual diff and changed files.
- Give a clear merge-readiness verdict.

**Your task:**
1. Review {WHAT_WAS_IMPLEMENTED}
2. Compare against {PLAN_OR_REQUIREMENTS}
3. Check code quality, architecture, and testing
4. Categorize issues by severity
5. Assess production readiness

## What Was Implemented

{DESCRIPTION}

## Requirements/Plan

{PLAN_OR_REQUIREMENTS}

## Git Range to Review

**Base:** {BASE_SHA}
**Head:** {HEAD_SHA}

```bash
git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}
```

## Review Checklist

**Code Quality:**
- Clean separation of concerns?
- Proper error handling?
- DRY principle followed?
- Edge cases handled?

**Architecture:**
- Sound design decisions?
- Scope discipline preserved?
- Any unnecessary complexity?

**Testing:**
- Tests actually test logic rather than mocks alone?
- TDD evidence present where code changed?
- Edge cases covered?
- All relevant tests passing?

**Requirements:**
- All plan requirements met?
- Implementation matches spec?
- No scope creep?
- Intentional breaking changes clearly documented?

**Production Readiness:**
- No obvious bugs?
- No hidden workflow violations?
- Documentation complete where required?

## Output Format

### Strengths
[What is well done? Be specific.]

### Issues

#### Critical (Must Fix)
[Bugs, broken functionality, data-loss risks, security issues]

#### Important (Should Fix)
[Missing requirements, test gaps, maintainability problems, workflow violations]

#### Minor (Nice to Have)
[Small polish items]

**For each issue:**
- File:line reference
- What is wrong
- Why it matters
- How to fix, if not obvious

### Recommendations
[Targeted improvements for code, tests, or process]

### Assessment

**Ready to merge?** [Yes/No/With fixes]

**Reasoning:** [Technical assessment in 1-2 sentences]
````

- [ ] **Step 3: Verify the review workflow alignment**

Run:

```bash
rg -n 'code_quality_reviewer|final_reviewer|read-only|PLAN_OR_REQUIREMENTS|TDD evidence present' /Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md /Users/maxibon/.codex/superpowers/skills/requesting-code-review/code-reviewer.md
rg -n 'agent_type="reviewer"|PLAN_REFERENCE|Backward compatibility considered' /Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md /Users/maxibon/.codex/superpowers/skills/requesting-code-review/code-reviewer.md
```

Expected:
- The first `rg` shows the custom review roles, read-only review contract, and placeholder alignment.
- The second `rg` returns no results.

- [ ] **Step 4: Commit**

```bash
git -C /Users/maxibon/.codex/superpowers add skills/requesting-code-review/SKILL.md skills/requesting-code-review/code-reviewer.md
git -C /Users/maxibon/.codex/superpowers commit -m "docs(review): align review workflow to read-only custom roles"
```

---

### Task 9: Run the Integrated Verification Bundle

**Files:**
- Verify only: `/Users/maxibon/.codex/config.macos-source.toml`
- Verify only: `/Users/maxibon/.codex/config.toml`
- Verify only: `/Users/maxibon/.codex/agents/*.toml`
- Verify only: `/Users/maxibon/.codex/superpowers/docs/README.codex.md`
- Verify only: `/Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md`
- Verify only: `/Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md`
- Verify only: `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/*`
- Verify only: `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/*`

- [ ] **Step 1: Re-run the global runtime verification**

Run:

```bash
diff -u /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
which -a codex
codex --version
codex -p workflow_fidelity features list | rg -n 'multi_agent|multi_agent_v2|enable_fanout'
codex -p parallel_readonly features list | rg -n 'multi_agent|multi_agent_v2|enable_fanout'
rg -n '^\[agents\.(implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer)\]$' /Users/maxibon/.codex/config.macos-source.toml /Users/maxibon/.codex/config.toml
```

Expected:
- `diff -u` returns no output.
- Both profiles show `multi_agent_v2 = true`.
- `workflow_fidelity` shows `enable_fanout = false`.
- `parallel_readonly` shows `enable_fanout = true`.
- Both config files show all five role mappings.

- [ ] **Step 2: Re-run the docs and prompt contract verification**

Run:

```bash
rg -n 'multi_agent_v2|workflow_fidelity|parallel_readonly|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer|test-driven-development|read-only' /Users/maxibon/.codex/superpowers/docs/README.codex.md /Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md /Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md /Users/maxibon/.codex/superpowers/skills/subagent-driven-development /Users/maxibon/.codex/superpowers/skills/requesting-code-review
rg -n 'agent_type="worker"|agent_type="reviewer"|PLAN_REFERENCE|following TDD if task says to|send_message|assign_task|list_agents|multi_agent = true is sufficient' /Users/maxibon/.codex/superpowers/docs/README.codex.md /Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md /Users/maxibon/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md /Users/maxibon/.codex/superpowers/skills/subagent-driven-development /Users/maxibon/.codex/superpowers/skills/requesting-code-review
```

Expected:
- The first `rg` finds the new v2-first contract and role mapping.
- The second `rg` returns no results.

- [ ] **Step 3: Verify repo cleanliness and commit integrity**

Run:

```bash
git -C /Users/maxibon/.codex/superpowers diff --check
git -C /Users/maxibon/.codex/superpowers status --short
git -C /Users/maxibon/.codex/superpowers log --oneline -n 4
```

Expected:
- `git diff --check` returns no output.
- `git status --short` returns no output.
- `git log --oneline -n 4` shows the four new documentation/config-contract commits on top.

- [ ] **Step 4: Workflow smoke check**

Run targeted smoke prompts in a disposable session and confirm:

1. `brainstorming` stays parent-led under `workflow_fidelity`
2. `dispatching-parallel-agents` defaults to `parallel_explorer`
3. `subagent-driven-development` uses `implementer`, then `spec_reviewer`, then `code_quality_reviewer`
4. code-changing implementer packets explicitly require `superpowers:test-driven-development`
5. final whole-change review uses `final_reviewer`

Expected:
- The workflow follows the configured custom role names instead of generic built-in guessing.

---

## Self-Review

### Spec Coverage Check

- Runtime contract (`multi_agent_v2`, `max_depth = 3`, `job_max_runtime_seconds = 3600`) is covered by Tasks 1-3 and Task 9.
- Config-owned child-role mapping is covered by Tasks 1-3 and Task 9.
- README and Codex tool docs hard-cut is covered by Tasks 4-5.
- `dispatching-parallel-agents` explicit parallel-lane alignment is covered by Task 6. This is an intentional addition because the approved spec described the workflow stage but did not list the skill in the implementation surface.
- `subagent-driven-development` and TDD enforcement are covered by Task 7.
- `requesting-code-review` alignment is covered by Task 8. Updating `code-reviewer.md` is an intentional addition to remove the placeholder drift between `PLAN_OR_REQUIREMENTS` and `PLAN_REFERENCE`.

### Placeholder Scan

Checked for: `TODO`, `TBD`, `implement later`, `add appropriate`, `similar to Task`, undefined placeholder names, and vague verification language. No placeholders remain in this plan.

### Type and Name Consistency

- Custom agent names are consistent across config, agent TOMLs, docs, and prompts: `implementer`, `spec_reviewer`, `code_quality_reviewer`, `parallel_explorer`, `final_reviewer`.
- Review template placeholder is consistent everywhere: `PLAN_OR_REQUIREMENTS`.
- TDD requirement is unconditional for code-changing implementer tasks.
