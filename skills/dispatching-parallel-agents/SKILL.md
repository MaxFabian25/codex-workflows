---
name: dispatching-parallel-agents
description: Use when you have multiple independent investigation tasks that can run in parallel without shared write ownership
---

# Dispatching Parallel Agents

## Overview

Dispatch read-only child agents to investigate independent problem domains in parallel. Keep synthesis, decisions, and any later write ownership in the parent.

Prefer bounded child packets. Use full-history fork mode only when a child genuinely needs the same working context.

**Core principle:** One read-only child per independent investigation domain.

**Contract references:** Follow [../../contract/process-family.md](../../contract/process-family.md), [../../contract/package-standards.md](../../contract/package-standards.md), and [../../contract/prompt-packet.md](../../contract/prompt-packet.md) when writing or updating process-family dispatch guidance.

**Codex V2 dispatch:** Use `spawn_agent(task_name=..., agent_type="parallel_explorer", message="...")` for the default read-only fanout lane. Reserve write-capable child roles for explicitly approved non-overlapping implementation slices outside this investigation pass.

## When to Use

- 2+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- Investigations can stay read-only and do not require shared mutable state

Do not use this skill when failures are likely related, require one full-system trace, or would cause agents to interfere with shared state.

## Required Flow

### 1. Identify Independent Domains

Group work by subsystem, failing test file, bug class, or artifact. Each domain must be independently understandable and safe to inspect in parallel.

If the domains overlap materially, investigate them together or return to controller-first planning.

### 2. Write Focused Child Packets

Each agent gets:
- specific scope: one file, subsystem, or failure group;
- clear goal: map root cause or evidence, not "fix it";
- constraints: stay read-only;
- output contract: summary, evidence, file references, and unresolved decisions.

Minimal dispatch shape:

```text
spawn_agent(task_name="map_abort_failures", agent_type="parallel_explorer", message="Read src/agents/agent-tool-abort.test.ts and explain the root cause of the failing cases. Stay read-only and return file references.")
```

### 3. Coordinate From the Parent

- Read each summary
- Use `wait_agent` only when blocked on a specific child, then prefer the canonical `task_name` for any follow-up
- Synthesize root-cause findings in the parent
- Resolve any `decision_needed` handoff before further dispatch or implementation
- If implementation is later approved, keep write-owning work on explicitly non-overlapping slices

### 4. Return unresolved decisions to the parent

Children operating under this skill stay read-only and parent-mediated.

- Do not ask the user directly or call `request_user_input`.
- If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.

Minimum handoff:

```text
decision_needed: yes
decision_id: choose_abort_contract
recommended_option: Keep partial output capture and update the abort-path expectation.
options:
- Preserve partial output capture semantics
- Drop partial output capture from the abort contract
evidence:
- src/agents/agent-tool-abort.test.ts: failing expectation depends on this choice
- src/agents/tool-runner.ts: current event ordering preserves partial output before abort
```

Required fields:
- `decision_id`: stable short identifier the parent can reference later
- `recommended_option`: the child's best current recommendation
- `options`: 2-3 concrete choices the parent can arbitrate
- `evidence`: file references and why the decision matters

Children may recommend options but may not ask the user directly.
The parent decides whether to open a user decision or make a documented assumption before more dispatch or planning.

## Guardrails

- Do not dispatch vague "fix everything" packets.
- Do not omit read-only constraints.
- Do not ask the user directly or call `request_user_input`.
- Do not use this as the execution lane for overlapping write ownership.
- Do not proceed to implementation until the parent has checked overlap and chosen the write-owning path.

## Verification

After children return, the parent verifies the synthesis against the cited files before acting on it. If follow-up implementation happens later, verify that work through the implementation skill that owns it.
