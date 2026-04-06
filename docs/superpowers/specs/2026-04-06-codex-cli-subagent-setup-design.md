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
- The live config also contains these currently active `[agents]` settings:
  - `max_depth = 3`
  - `job_max_runtime_seconds = 3600`
- The local superpowers Codex docs and prompt templates drift from the observed runtime:
  - `docs/README.codex.md` says `multi_agent = true` is sufficient for subagent skills.
  - `skills/using-superpowers/references/codex-tools.md` already encodes a more v2-oriented mapping than the live runtime verification supported during the first draft of this design.
  - `subagent-driven-development` prompt templates still assume reviewer-style child contracts that are not safe to document unless verified against the live runtime.
  - `implementer-prompt.md` says "follow TDD if task says to," which is weaker than the README workflow claim that TDD activates during implementation.

## User-Directed Target Contract

The user has explicitly changed the target contract for this design:

- `multi_agent_v2` must be enabled for both profiles
- the v2 tool mapping must take precedence over the regular `multi_agent` mapping
- `agents.max_depth = 3` is authoritative
- `agents.job_max_runtime_seconds = 3600` is authoritative
- child mapping is customizable in `config.toml` and must be tailored to the superpowers workflow and skills

This creates an explicit conflict with the live runtime snapshot observed on April 6, 2026, where `codex features list` reported `multi_agent_v2 = false`.

For this design, the user-directed target contract takes precedence over the initial runtime-first recommendation. The implementation phase must therefore:

1. configure both profiles for `multi_agent_v2 = true`
2. rewrite the local superpowers Codex docs in v2-first form
3. preserve `agents.max_depth = 3` and `agents.job_max_runtime_seconds = 3600` as authoritative limits
4. tailor config-level child mappings to the superpowers workflow rather than relying on generic built-in defaults
5. verify whether the installed Codex binary actually activates that contract
6. treat any inability to activate v2 or the tailored child mapping as an explicit implementation blocker or upgrade requirement, not as a reason to silently fall back to legacy mapping

## Design Principles

1. Preserve the workflow. Configuration supports the skill workflow; it does not redefine it.
2. Keep one controller. The parent session remains responsible for routing, arbitration, and user-facing synthesis.
3. Use fresh children narrowly. Child agents get bounded packets and focused ownership.
4. Reserve fanout for independent read-only work. Do not turn `subagent-driven-development` into parallel implementation by default.
5. Hard-cut drift. If a Codex-facing superpowers contract is stale, rewrite it to match the verified runtime instead of documenting compatibility aliases.
6. Verify the runtime, not just the repo. Local source snapshots and upstream docs are advisory; the live runtime on this machine is authoritative.
7. When the user explicitly sets a stronger target contract than the currently observed runtime, design to that target and turn any runtime mismatch into blocker evidence rather than silently weakening the contract.

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

Child-role mapping is a config-owned contract in this design, not just a documentation convention and not just a fixed set of built-ins. The local `config.toml` child-mapping surface must be tailored to the superpowers workflow.

The target logical mappings are:

| Logical child | Workflow use | Required behavior |
|---|---|---|
| `implementer` | `subagent-driven-development` code-changing task | write-capable child, bounded ownership, TDD required |
| `spec_reviewer` | post-implementer spec compliance review | read-only child, distrust implementer report, verify against task text |
| `code_quality_reviewer` | post-spec code quality review | read-only child, severity-based findings |
| `parallel_explorer` | `dispatching-parallel-agents` and bounded read-only scouting | read-only child, independent-domain exploration |
| `final_reviewer` | end-of-plan review pass | read-only child, whole-change review |

The parent session remains the orchestrator. The config-level child mapping should support these logical roles explicitly rather than forcing the skills to guess between generic built-ins.

If the runtime requires those logical roles to resolve onto built-in roles such as `worker` or `explorer`, that resolution should live in `config.toml` and be documented there. The local superpowers Codex docs should reference the configured mapping, not pretend the built-in names are the workflow contract.

## Recommended Config Shape

### Canonical Config Surface

Treat `~/.codex/config.macos-source.toml` as the editable source for this workstation. After changes:

1. apply or sync the live mirror to `~/.codex/config.toml`
2. verify with `zsh -lic 'which -a codex'`
3. verify with `zsh -lic 'codex --version'`
4. verify with `codex features list`

Do not treat stale docs or an unverified source checkout as the source of truth for live config behavior.

### Root-Level Settings

Keep shared runtime invariants at the root:

- `approval_policy = "never"`
- `sandbox_mode = "danger-full-access"`
- shared tool features such as `unified_exec`, `shell_snapshot`, `js_repl`, `memories`, `artifact`, `image_detail_original`
- `features.multi_agent = true`
- `features.enable_fanout = false`

Keep the authoritative root-level agent cap aligned with the live config and branch docs:

```toml
[agents]
max_threads = 32
max_depth = 3
job_max_runtime_seconds = 3600
```

Rationale:

- Profiles cannot override `agents.max_threads`, so this must work for both normal controller sessions and explicit parallel read-only sessions.
- `max_depth = 3` and `job_max_runtime_seconds = 3600` are authoritative in this workstation design.
- `32` is the final authoritative workstation cap already reflected in the live config and branch docs.
- The default workflow remains disciplined because concurrency policy is enforced by skills, prompts, and profile feature-state rather than by reducing the shared hard cap below the documented runtime contract.

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
max_threads = 32
max_depth = 3
job_max_runtime_seconds = 3600

[profiles.workflow_fidelity]
model = "gpt-5.4"
approval_policy = "never"
sandbox_mode = "danger-full-access"
model_reasoning_effort = "xhigh"
model_reasoning_summary = "detailed"
model_verbosity = "high"
personality = "pragmatic"

[profiles.workflow_fidelity.features]
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
multi_agent_v2 = true
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

### Config-Level Child Mapping

In addition to feature flags and numeric limits, the implementation must use the authoritative `config.toml` child-mapping surface to tailor child behavior to superpowers.

This design requires config-level mappings for at least:

- `implementer`
- `spec_reviewer`
- `code_quality_reviewer`
- `parallel_explorer`
- `final_reviewer`

Requirements:

- the mapping must be v2-first
- the mapping must preserve the parent as controller
- review roles must remain read-only
- `parallel_explorer` must be the preferred mapping for independent read-only fanout
- config-level mapping must take precedence over ad hoc role guessing in skill docs

The exact TOML serialization should use the real child-mapping surface already supported by this workstation. Implementation must not invent a parallel undocumented schema and must not fall back to generic built-in names if the configurable mapping can be activated.

## Local Superpowers Hard-Cut Changes

### 1. `docs/README.codex.md`

Update the Codex installation and usage docs to reflect the real local contract:

- Codex integration is native skill discovery via symlink, not a Codex plugin manifest.
- `multi_agent = true` is required.
- `multi_agent_v2 = true` is required for both profiles in this workstation design.
- `agents.max_depth = 3` and `agents.job_max_runtime_seconds = 3600` are part of the authoritative agent contract.
- `enable_fanout` is optional and intended only for explicit parallel lanes.
- Document that v2 mapping takes precedence over legacy `multi_agent` mapping.
- Document that config-level child mapping is authoritative and tailored to the superpowers workflow.
- Document that failure to activate `multi_agent_v2` during implementation is a blocker to surface explicitly.
- Document the two-profile operating model and when to choose each profile.

### 2. `skills/using-superpowers/references/codex-tools.md`

Hard-cut this file to the user-directed v2 Codex contract and verify live activation against it:

- Document the v2 mapping first and treat it as authoritative for this workstation design.
- Keep legacy `multi_agent` mapping only as clearly labeled fallback or historical context if it must remain at all.
- Document the tailored config-level child mappings as the workflow contract.
- Document only the child roles and argument shapes that are supported under the chosen v2 contract and mapped in config.
- If a v2-only field or mapped role is not actually supported by the installed binary during implementation, record that as a blocker and update the runtime before weakening the docs.
- Keep the guidance that the parent session remains responsible for user clarification and synthesis.
- State explicitly that runtime probes beat source snapshots, but the user-directed target contract defines what implementation is trying to activate.

### 3. `skills/subagent-driven-development/SKILL.md`

Keep the workflow, but tighten the Codex mapping:

- Preserve one implementer child at a time.
- Preserve spec-compliance review before code-quality review.
- Preserve parent-owned escalation handling.
- Add an explicit Codex note that role selection must follow the tailored config-level child mapping.
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
- Reviewer uses the tailored config-level `spec_reviewer` mapping.
- Reviewer returns specific missing/extra items with file references.

### 6. `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

Preserve the two-stage review ladder:

- This review runs only after spec compliance passes.
- Reviewer packet is read-only.
- Reviewer uses the tailored config-level `code_quality_reviewer` mapping.
- Findings stay severity-based and actionable.

### 7. `skills/requesting-code-review/SKILL.md`

Bring the standalone review skill in line with the same mapping:

- A review child is read-only.
- Review uses the tailored config-level review mapping.
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
- Implementer child follows the tailored config-level `implementer` mapping.
- Review children are read-only and follow the tailored config-level review mappings.
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

- Use the tailored config-level review mapping or the parent review surface, depending on the activated runtime contract.
- Review remains mandatory after each task in `subagent-driven-development`.
- This stage should usually stay in `workflow_fidelity`, unless the entire session is a bounded parallel review wave.

### `finishing-a-development-branch`

- Parent only.
- Final verification, merge/PR/keep/discard decision, and cleanup remain outside the child swarm.
- This stage should use `workflow_fidelity`.

## Error Handling and Stop Rules

### Unsupported Runtime Contract

If the live runtime does not support a documented role or argument shape:

- stop and record blocker evidence immediately
- identify whether the failure is in v2 activation, child-mapping activation, or both
- update the runtime or config before weakening any local superpowers docs
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
zsh -lic 'which -a codex'
zsh -lic 'codex --version'
codex -p workflow_fidelity features list
codex -p parallel_readonly features list
rg -n '^\[agents\]|max_threads|max_depth|job_max_runtime_seconds' \
  ~/.codex/config.macos-source.toml ~/.codex/config.toml
```

Expected:

- the active login-shell binary still resolves to the intended npm-global Codex install
- both profiles expose `multi_agent_v2 = true`
- v2-capable mapping is the expected operational contract for both profiles
- `enable_fanout` is disabled in `workflow_fidelity` and enabled only in `parallel_readonly`
- both config surfaces preserve `max_depth = 3` and `job_max_runtime_seconds = 3600`

### Config-Level Child Mapping Verification

Inspect the source and live config for tailored superpowers child mappings:

```bash
rg -n 'implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer' \
  ~/.codex/config.macos-source.toml ~/.codex/config.toml
```

Expected:

- the tailored superpowers child mappings are present in both source and live config
- review roles are visibly distinct from implementer roles
- the mapping is stable enough that local superpowers docs can reference it directly

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

Check the Codex-facing superpowers files for v2-first Codex claims and for stale legacy wording:

```bash
rg -n 'multi_agent_v2|workflow_fidelity|parallel_readonly|implementer|spec_reviewer|code_quality_reviewer|parallel_explorer|final_reviewer|test-driven-development|read-only' \
  ~/.codex/superpowers/docs/README.codex.md \
  ~/.codex/superpowers/skills/using-superpowers/references/codex-tools.md \
  ~/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md \
  ~/.codex/superpowers/skills/subagent-driven-development \
  ~/.codex/superpowers/skills/requesting-code-review

! rg -n 'agent_type="worker"|agent_type="reviewer"|PLAN_REFERENCE|following TDD if task says to|send_message|assign_task|list_agents|multi_agent = true is sufficient' \
  ~/.codex/superpowers/docs/README.codex.md \
  ~/.codex/superpowers/skills/using-superpowers/references/codex-tools.md \
  ~/.codex/superpowers/skills/dispatching-parallel-agents/SKILL.md \
  ~/.codex/superpowers/skills/subagent-driven-development \
  ~/.codex/superpowers/skills/requesting-code-review

! rg -n 'legacy mapping is primary|v1 mapping is primary' \
  ~/.codex/superpowers/docs/README.codex.md \
  ~/.codex/superpowers/skills/using-superpowers/references/codex-tools.md
```

Expected after implementation:

- Codex-facing docs encode the v2-first contract the user requested
- stale dispatch wording and legacy-primary claims are removed or rewritten
- the absence checks fail immediately if legacy packet or dispatch wording is reintroduced

### Workflow Smoke Verification

Run targeted prompts and inspect transcripts or notifications for:

1. `brainstorming` stays parent-led
2. `dispatching-parallel-agents` dispatches bounded read-only children
3. `subagent-driven-development` uses one implementer child at a time
4. spec review happens before code-quality review
5. implementer packets for code changes explicitly require TDD
6. child selection follows the tailored config-level mapping rather than generic built-in guessing

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
- `multi_agent_v2` is enabled for both profiles
- the v2 tool mapping is the documented primary Codex mapping
- `max_depth = 3` and `job_max_runtime_seconds = 3600` remain part of the live authoritative agent contract
- config-level child mappings are tailored to superpowers and reflected in local docs
- the local superpowers Codex docs no longer drift from the verified runtime
- TDD is explicit in the Codex implementer lane
- review remains mandatory and read-only
- unsupported or unverified Codex contracts are either activated successfully or surfaced as explicit blockers instead of being silently weakened
