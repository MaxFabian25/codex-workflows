---
name: using-superpowers
description: Use when starting a session so the agent routes through the skill system before responding
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

# Session Router

Use this skill at session start to decide whether another skill should take over before you respond.

## Instruction Priority

1. User and repo instructions (`AGENTS.md`, direct requests, repo-local contracts)
2. Superpowers skills
3. Default system behavior

If a repo contract and a skill disagree, follow the user or repo contract.

## When To Load A Skill

- If the user explicitly requests a skill, load it before responding.
- If the task clearly matches a skill, load that `SKILL.md` before acting.
- If a skill is plausibly relevant and would change the workflow, check it first.
- Once a skill applies, follow it directly.

## Skill Routing Order

Follow `../../contract/process-family.md` when multiple process skills could apply.

1. Process skills first.
2. Implementation or domain skills second.

Use the narrowest skill that matches the current phase and ownership.

## Codex-Only Tool Surface

This fork is Codex-only. Skills live under `skills/`.

- Use `references/codex-tools.md` when a skill mentions a platform-specific Codex tool or surface.
- Use `../../contract/package-standards.md` for package-level conventions.
