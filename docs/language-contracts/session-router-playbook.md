# Session Router Playbook

Codex Workflows treats session routing as a harness contract. The source of truth is this playbook plus `skills/session-router/SKILL.md`.

Automatic SessionStart hook injection is retained as a lightweight adapter for that contract. Manual start remains the fallback when a host does not load plugin hooks.

## Manual Start

At the start of a relevant session:

1. Read `skills/session-router/SKILL.md`.
2. Apply the instruction priority from that file.
3. Decide whether a more specific Codex Workflows skill applies.
4. Load only the narrowest matching skill before acting.
5. If no skill applies, continue normally.

If the agent was dispatched as a bounded subagent, it skips the session router and follows its task packet.

## Instruction Priority

1. System, developer, user, direct repo instructions, and deeper `AGENTS.md` files.
2. The active task packet, when running as a child agent.
3. Codex Workflows playbooks and skills.
4. Default assistant behavior.

When a repo contract and a Codex Workflows skill disagree, follow the repo contract unless the user says otherwise.

## Adapter Boundary

The package ships:

- `.codex-plugin/plugin.json` hook declaration;
- `hooks/hooks.json`;
- `hooks/session-start`.

The adapter emits the same router instruction as the manual prompt. It must stay small and must not grow hidden workflow policy. User-level hook installation via `scripts/install_codex_hooks.py` is retired; plugin-native hooks are the supported automatic path.

## Expected Session Prompt

When the user wants the Codex Workflows router explicitly, a stable manual prompt is:

```text
Use codex-workflows:session-router before we start.
```

The agent should then load the router skill from the active plugin or local checkout and apply the routing rules. The hook output is a convenience adapter, not a separate authority.

## Review Checklist

- Front-door install docs describe the hook adapter and the manual router fallback.
- The plugin manifest advertises the hook path as an explicit lightweight adapter.
- Live package docs make clear that hooks are retained as adapters and manual start is fallback behavior.
- Retired user-level hook installer files are listed in `retired-automation-register.md`.
- If a future release changes hook behavior, `cutover-ledger.md` must record the adapter decision.
