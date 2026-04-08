---
name: using-superpowers
description: Use when starting a session so the agent routes through the skill system before responding
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## Instruction Priority

Codex follows this priority order:

1. **User and repo instructions** (`AGENTS.md`, direct requests, repo-local contracts)
2. **Superpowers skills**
3. **Default system behavior**

If a repo contract and a skill disagree, follow the user/repo instruction.

## Codex-Only Surface

This fork is Codex-only. Skills are packaged through the native plugin surface and live under `skills/`.

When a skill applies:
- read the relevant `SKILL.md`
- follow it directly
- use `references/codex-tools.md` if the skill mentions a platform-specific tool name

Contract references:
- `../../contract/process-family.md`
- `../../contract/package-standards.md`

# Using Skills

## The Rule

Invoke relevant or requested skills before any response or action. If there is even a small chance a skill applies, read it first.

## Red Flags

Stop if you catch yourself thinking:
- "This is simple enough to skip."
- "I should inspect files first."
- "I already remember what the skill says."

## Skill Priority

Follow `../../contract/process-family.md` when multiple process skills could apply.

1. Process skills first
2. Implementation skills second

Instructions say what to do. Skills define how to do it.
