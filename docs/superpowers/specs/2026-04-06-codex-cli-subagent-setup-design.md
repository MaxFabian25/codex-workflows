# Codex CLI Subagent Setup for Superpowers

Align the local Codex CLI/TUI runtime and the local `~/.codex/superpowers` checkout with the full superpowers workflow while preserving controller-first execution, strict review gates, and selective parallel fanout.

## Goal

Make superpowers work well on this macOS Codex CLI/TUI setup without diluting the workflow into "just spawn more agents." The resulting setup must preserve the full workflow:

1. `using-superpowers`
2. `brainstorming`
3. `using-git-worktrees`
4. `writing-plans`
5. `subagent-driven-development` or `executing-plans`
6. `test-driven-development`
7. `requesting-code-review`
8. `finishing-a-development-branch`

The runtime configuration should support that control plane rather than replacing it.

## Scope

This design covers:

- Native Codex CLI/TUI on this workstation
- The live local config surfaces `~/.codex/config.macos-source.toml` and `~/.codex/config.toml`
- The local superpowers checkout at `~/.codex/superpowers`
- Codex-facing docs and prompt templates inside the local superpowers checkout

This design does not cover:

- OpenCode plugin behavior
- Claude/Cursor/Gemini behavior
- Codex App managed-worktree behavior beyond preserving existing docs
- Backward-compatibility shims for stale contracts

## Current State

Observed on 2026-04-06:

- The active Codex binary resolves to `/Users/maxibon/.npm-global/bin/codex`.
- `codex --version` reports `codex-cli 0.119.0-alpha.11`.
- `codex features list` reports `multi_agent = true`, `enable_fanout = true`, and `multi_agent_v2 = false`.
- Superpowers is exposed to Codex through native skill discovery, not through a Codex plugin manifest:
  - `~/.agents/skills/superpowers -> ~/.codex/superpowers/skills`
  - `~/.codex/skills -> ../.agents/skills`
- The live config currently enables broad concurrency:
  - `features.multi_agent = true`
  - `features.enable_fanout = true`
  - `agents.max_threads = 32`
- The live config also contains likely non-authoritative or drift-prone keys under `[agents]`:
  - `max_depth = 3`
  - `job_max_runtime_seconds = 3600`
- The local superpowers Codex docs and prompt templates drift from the observed runtime:
  - `docs/README.codex.md` says `multi_agent = true` is sufficient for subagent skills.
  - `skills/using-superpowers/references/codex-tools.md` still references `multi_agent_v2 = true`, `task_name`, and agent roles such as `planner`, `reviewer`, and `verifier`.
  - `subagent-driven-development` prompt templates still assume reviewer-style child contracts that are not safe to document unless verified against the live runtime.
  - `implementer-prompt.md` says "follow TDD if task says to," which is weaker than the README workflow claim that TDD activates during implementation.

## Design Principles

1. Preserve the workflow. Configuration supports the skill workflow; it does not redefine it.
2. Keep one controller. The parent session remains responsible for routing, arbitration, and user-facing synthesis.
3. Use fresh children narrowly. Child agents get bounded packets and focused ownership.
4. Reserve fanout for independent read-only work. Do not turn `subagent-driven-development` into parallel implementation by default.
5. Hard-cut drift. If a Codex-facing superpowers contract is stale, rewrite it to match the verified runtime instead of documenting compatibility aliases.
6. Verify the runtime, not just the repo. Local source snapshots and upstream docs are advisory; the live runtime on this machine is authoritative.

## Approaches Considered

### 1. Single global high-concurrency setup

Keep the current broad config and rely on skill text alone to preserve discipline.

Rejected because:

- It weakens the controller-first design of `brainstorming`, `writing-plans`, and `subagent-driven-development`.
- It makes accidental over-fanout cheap and likely.
- It leaves the local superpowers Codex docs drifting from reality.

### 2. Split profiles plus local hard-cut alignment

Use a conservative default profile for the normal superpowers flow, add a dedicated read-only fanout profile, and patch the local superpowers Codex-facing surfaces to match the verified runtime.

Accepted because:

- It preserves workflow fidelity.
- It supports both serial task execution and intentional parallel read-only work.
- It removes current documentation and prompt drift.

### 3. Wrapper-first orchestration

Add extra wrapper scripts or commands before cleaning up the underlying config and docs.

Rejected for now because:

- It adds a second control plane before the first one is clean.
- It is unnecessary until the runtime and local skill contracts are aligned.

## Recommended Runtime Architecture

### Control Plane by Workflow Stage

| Workflow Stage | Owner | Subagent policy |
|---|---|---|
| `using-superpowers` | Parent controller | No child requirement |
| `brainstorming` | Parent controller | Optional read-only scout only when clearly useful |
| `using-git-worktrees` | Parent controller | No child requirement |
| `writing-plans` | Parent controller | No child requirement |
| `subagent-driven-development` | Parent controller | One implementer child at a time; review children remain read-only |
| `executing-plans` | Parent controller | No child requirement unless the plan explicitly says otherwise |
| `test-driven-development` | Implementer lane | Mandatory for code-changing tasks |
| `requesting-code-review` | Parent + read-only reviewer child | Findings are returned to parent; parent arbitrates |
| `dispatching-parallel-agents` | Parent controller | Only for independent domains; prefer read-only explorers |
| `finishing-a-development-branch` | Parent controller | No child requirement |

### Child Role Mapping

For the verified live Codex runtime, the local superpowers checkout should document only the roles and tool shapes that can be confirmed on this workstation. The target mapping is:

- Implementer child: `worker`
- Spec-compliance reviewer: read-only reviewer packet sent to a supported read-only role
- Code-quality reviewer: read-only reviewer packet sent to a supported read-only role
- Final synthesis and decision: parent controller

If the runtime exposes `explorer` and `worker` but not a dedicated `reviewer`, the local superpowers Codex docs should map both reviewer packets to a read-only `explorer` lane and keep final arbitration in the parent session.

If a dedicated `reviewer` role is later verified in the live runtime, the docs may be updated then. Until that verification exists, do not document it as a supported Codex role.

## Recommended Config Shape

### Canonical Config Surface

Treat `~/.codex/config.macos-source.toml` as the editable source for this workstation. After changes:

1. apply or sync the live mirror to `~/.codex/config.toml`
2. verify with `which -a codex`
3. verify with `codex --version`
4. verify with `codex features list`

Do not treat stale docs or an unverified source checkout as the source of truth for live config behavior.

### Root-Level Settings

Keep shared runtime invariants at the root:

- `approval_policy = "never"`
- `sandbox_mode = "danger-full-access"`
- shared tool features such as `unified_exec`, `shell_snapshot`, `js_repl`, `memories`, `artifact`, `image_detail_original`
- `features.multi_agent = true`
- `features.enable_fanout = false`

Set a moderate root-level agent cap:

```toml
[agents]
max_threads = 12
```

Rationale:

- Profiles cannot override `agents.max_threads`, so this must work for both normal controller sessions and explicit parallel read-only sessions.
- `12` is enough headroom for bounded parallel exploration and review without normalizing 32-way fanout.
- The default workflow remains disciplined because concurrency policy is enforced by skills and prompts, not by a very low hard cap.

Remove these root-level keys unless the live runtime is re-verified to use them:

```toml
[agents]
# remove these stale keys
# max_depth = 3
# job_max_runtime_seconds = 3600
```

Rationale:

- They are present today, but they were not confirmed as supported config knobs by the runtime verification path used in this design.
- Hard-cut drift is preferable to carrying inert or speculative knobs.

### Profiles

Use two profiles:

1. `workflow_fidelity` as the default
2. `parallel_readonly` for deliberate read-only fanout sessions

Recommended shape:

```toml
profile = "workflow_fidelity"

[features]
multi_agent = true
enable_fanout = false

[agents]
max_threads = 12

[profiles.workflow_fidelity]
model = "gpt-5.4"
approval_policy = "never"
sandbox_mode = "danger-full-access"
model_reasoning_effort = "xhigh"
model_reasoning_summary = "detailed"
model_verbosity = "high"
personality = "pragmatic"

[profiles.parallel_readonly]
model = "gpt-5.4"
approval_policy = "never"
sandbox_mode = "danger-full-access"
model_reasoning_effort = "high"
model_reasoning_summary = "detailed"
model_verbosity = "medium"
personality = "pragmatic"

[profiles.parallel_readonly.features]
enable_fanout = true
```

Profile intent:

- `workflow_fidelity` is for normal superpowers control-flow sessions:
  - `brainstorming`
  - `using-git-worktrees`
  - `writing-plans`
  - `subagent-driven-development`
  - `executing-plans`
  - `finishing-a-development-branch`
- `parallel_readonly` is for sessions where the main task is independent exploration, review clustering, or bounded domain mapping.

Do not use `parallel_readonly` as the default implementation profile.

## Local Superpowers Hard-Cut Changes

### 1. `docs/README.codex.md`

Update the Codex installation and usage docs to reflect the real local contract:

- Codex integration is native skill discovery via symlink, not a Codex plugin manifest.
- `multi_agent = true` is required.
- `enable_fanout` is optional and intended only for explicit parallel lanes.
- Remove any requirement that says `multi_agent_v2 = true` unless verified in the live runtime.
- Document the two-profile operating model and when to choose each profile.

### 2. `skills/using-superpowers/references/codex-tools.md`

Hard-cut this file to the verified live Codex contract:

- Document only verified subagent tools and argument shapes.
- Document only verified supported child roles.
- Remove or rewrite references to unverified Codex-only roles such as `planner`, `reviewer`, and `verifier`.
- Remove or rewrite `task_name` requirements unless that field is verified in the live runtime used by this workstation.
- Keep the guidance that the parent session remains responsible for user clarification and synthesis.
- State explicitly that runtime probes beat source snapshots.

### 3. `skills/subagent-driven-development/SKILL.md`

Keep the workflow, but tighten the Codex mapping:

- Preserve one implementer child at a time.
- Preserve spec-compliance review before code-quality review.
- Preserve parent-owned escalation handling.
- Add an explicit Codex note that reviewer packets must target verified supported roles only.
- Keep final integration and arbitration with the parent.

### 4. `skills/subagent-driven-development/implementer-prompt.md`

Strengthen the implementer lane:

- For any code-changing task, explicitly require the `test-driven-development` skill before implementation.
- Remove wording that makes TDD conditional on the task packet "if task says to."
- Preserve the existing self-review and escalation contract.
- Preserve the "do not guess" and "do not silently continue while unsure" rules.

### 5. `skills/subagent-driven-development/spec-reviewer-prompt.md`

Preserve the distrustful review posture, but make the Codex role mapping explicit:

- Reviewer packet is read-only.
- Reviewer verifies code, not the implementer report.
- Reviewer uses a supported read-only Codex role.
- Reviewer returns specific missing/extra items with file references.

### 6. `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

Preserve the two-stage review ladder:

- This review runs only after spec compliance passes.
- Reviewer packet is read-only.
- Reviewer uses a supported read-only Codex role.
- Findings stay severity-based and actionable.

### 7. `skills/requesting-code-review/SKILL.md`

Bring the standalone review skill in line with the same mapping:

- A review child is read-only.
- Review uses a verified supported role.
- Parent arbitrates disagreements.
- Review remains mandatory after each task in `subagent-driven-development`.

## Workflow-Specific Behavior

### `brainstorming`

- Runs in the parent controller session by default.
- Optional subagents may gather bounded read-only context, but design ownership stays with the parent.
- This stage should use `workflow_fidelity`.

### `using-git-worktrees`

- Runs in the parent controller session.
- No special subagent tuning is needed.
- This stage should use `workflow_fidelity`.

### `writing-plans`

- Runs in the parent controller session.
- The plan decides whether the next lane is `subagent-driven-development` or `executing-plans`.
- This stage should use `workflow_fidelity`.

### `subagent-driven-development`

- Parent is the controller.
- Implementer child is `worker`.
- Review children are read-only and use only verified supported roles.
- No parallel overlapping implementation by default.
- This stage should use `workflow_fidelity`.

### `executing-plans`

- This is the non-subagent implementation alternative.
- The config still matters because the parent remains the execution engine.
- This stage should use `workflow_fidelity`.

### `dispatching-parallel-agents`

- This is the explicit parallel lane.
- It is appropriate for:
  - independent read-only research questions
  - parallel codebase exploration
  - read-only audit clusters
- It is not the default implementation lane for plan execution.
- This stage should use `parallel_readonly`.

### `requesting-code-review`

- Use a read-only reviewer child or the parent review surface, depending on the verified runtime.
- Review remains mandatory after each task in `subagent-driven-development`.
- This stage should usually stay in `workflow_fidelity`, unless the entire session is a bounded parallel review wave.

### `finishing-a-development-branch`

- Parent only.
- Final verification, merge/PR/keep/discard decision, and cleanup remain outside the child swarm.
- This stage should use `workflow_fidelity`.

## Error Handling and Stop Rules

### Unsupported Runtime Contract

If the live runtime does not support a documented role or argument shape:

- stop using it in the local superpowers Codex docs immediately
- replace it with the verified supported contract
- do not keep "temporary" compatibility wording

### Blocked Child

If an implementer or reviewer child reports missing context or a blocker:

- the parent must refine the packet, narrow scope, or answer the question
- the parent must not re-dispatch the same packet unchanged

### Excessive Fanout

If the agent cap is hit or the session becomes coordination-heavy:

- close completed children
- collapse back to parent synthesis
- if the work is not truly independent, switch back to the normal controller lane

### TDD Enforcement Failure

If a code-changing task starts implementation before tests:

- treat it as a workflow violation
- rewrite the Codex-facing prompt/template that allowed it
- do not document this as acceptable "flexibility"

## Verification Plan

Implementation is complete only when all of the following are true.

### Runtime Verification

Run:

```bash
which -a codex
codex --version
codex features list
```

Expected:

- active binary still resolves to the intended npm-global Codex install
- the runtime still exposes `multi_agent`
- `enable_fanout` is disabled by default and enabled only under the parallel profile

### Skill Discovery Verification

Run:

```bash
ls -la ~/.agents/skills/superpowers
ls ~/.codex/superpowers/skills
```

Expected:

- the symlink remains intact
- Codex still sees the superpowers skill tree

### Prompt/Doc Contract Verification

Check the Codex-facing superpowers files for stale Codex claims:

```bash
rg -n 'multi_agent_v2|task_name|agent_type[ =:]+".*(planner|reviewer|verifier)"' \
  ~/.codex/superpowers/docs/README.codex.md \
  ~/.codex/superpowers/skills/using-superpowers/references/codex-tools.md \
  ~/.codex/superpowers/skills/subagent-driven-development \
  ~/.codex/superpowers/skills/requesting-code-review/SKILL.md
```

Expected after implementation:

- Codex-facing docs only contain runtime-verified claims
- stale Codex role assumptions are removed or rewritten
- legitimate workflow file names such as `spec-reviewer-prompt.md` are not treated as failures by the check

### Workflow Smoke Verification

Run targeted prompts and inspect transcripts or notifications for:

1. `brainstorming` stays parent-led
2. `dispatching-parallel-agents` dispatches bounded read-only children
3. `subagent-driven-development` uses one implementer child at a time
4. spec review happens before code-quality review
5. implementer packets for code changes explicitly require TDD

## Implementation Surface

Planned file changes for the implementation phase:

- `/Users/maxibon/.codex/config.macos-source.toml`
- `/Users/maxibon/.codex/config.toml`
- `/Users/maxibon/.codex/superpowers/docs/README.codex.md`
- `/Users/maxibon/.codex/superpowers/skills/using-superpowers/references/codex-tools.md`
- `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/SKILL.md`
- `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/implementer-prompt.md`
- `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md`
- `/Users/maxibon/.codex/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md`
- `/Users/maxibon/.codex/superpowers/skills/requesting-code-review/SKILL.md`

## Done Criteria

This design is successful when:

- the default Codex profile supports the full superpowers workflow without encouraging broad fanout
- an explicit parallel profile exists for independent read-only subagent waves
- the local superpowers Codex docs no longer drift from the verified runtime
- TDD is explicit in the Codex implementer lane
- review remains mandatory and read-only
- unsupported or unverified Codex contracts are removed instead of documented as if they were real
