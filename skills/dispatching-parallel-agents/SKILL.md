---
name: dispatching-parallel-agents
description: Use when independent read-only investigations can run in parallel
---

# Dispatching Parallel Agents

Dispatch read-only child agents for independent investigation domains. Keep synthesis, decisions, and later write-owning execution in the parent.

**Contract references:** Follow [../../docs/language-contracts/process-family-playbook.md](../../docs/language-contracts/process-family-playbook.md), [../../docs/language-contracts/package-and-release-playbook.md](../../docs/language-contracts/package-and-release-playbook.md), and [../../docs/language-contracts/prompt-packet-playbook.md](../../docs/language-contracts/prompt-packet-playbook.md) when writing or updating process-family dispatch guidance.

**Codex V2 dispatch:** Use `spawn_agent(task_name=..., agent_type="parallel_explorer", message="...")` for the default read-only fanout lane. Reserve write-capable child roles for explicitly approved non-overlapping implementation slices outside this investigation pass.

## Use When

- Two or more problem domains can be understood independently.
- Each child can stay read-only.
- Wall-clock matters and the domains do not share mutable state.

Do not use this skill when failures are probably related, require one full-system trace, or would cause agents to interfere with shared state.

## Workflow

1. **Identify independent domains.** Group by subsystem, failing test file, bug class, or artifact. If domains overlap materially, investigate together.

2. **Write focused child packets.** Each packet includes scope, goal, read-only constraint, and output contract. Minimal dispatch:

```text
spawn_agent(task_name="map_abort_failures", agent_type="parallel_explorer", message="Read src/agents/agent-tool-abort.test.ts and explain the root cause of the failing cases. Stay read-only and return file references.")
```

3. **Coordinate from the parent.**
- Read each summary.
- Use `wait_agent` only when blocked on a specific child.
- Synthesize root-cause findings in the parent.
- Resolve any `decision_needed` handoff before further dispatch or implementation.
- If implementation is later approved, keep write-owning work on explicitly non-overlapping slices.

### 4. Return unresolved decisions to the parent

Children operating under this skill stay read-only and parent-mediated.

- Do not ask the user directly or call `request_user_input`.
- If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.

Minimum handoff fields:
- `decision_needed`
- `decision_id`
- `recommended_option`
- `options`
- `evidence`

Children may recommend options but may not ask the user directly.
The parent decides whether to open a user decision or make a documented assumption before more dispatch or planning.

## Guardrails

- Do not dispatch vague "fix everything" packets.
- Do not omit read-only constraints.
- Do not use this as the execution lane for overlapping write ownership.
- Do not proceed to implementation until the parent has checked overlap and chosen the write-owning path.

## Verification

After children return, the parent verifies the synthesis against cited files before acting on it.
