---
name: using-superpowers
description: Use when starting a session to route through applicable skills
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

# Session Router

Use this skill at session start to decide whether another Superpowers skill should take over before you respond.

## Instruction Priority

1. User, system, developer, and repo instructions (`AGENTS.md`, direct requests, repo-local contracts)
2. Superpowers skills
3. Default assistant behavior

If a repo contract and a skill disagree, follow the user or repo contract.

## Routing Rules

- Load a skill when the user explicitly requests it.
- Load a skill when the current task clearly matches its description.
- Check a plausibly relevant skill when it would materially change the workflow, tool choice, or stop conditions.
- If no skill applies, continue normally.
- Once a skill applies, follow that `SKILL.md` directly.

## Skill Routing Order

Follow `../../docs/language-contracts/process-family-playbook.md` when multiple process skills could apply.

1. Process skills first.
2. Implementation or domain skills second.

Use the narrowest skill that matches the current phase and ownership.

## Codex-Only Surface

This fork is Codex-only. Skills live under `skills/`.

- Use `references/codex-tools.md` when a skill mentions a platform-specific Codex tool or surface.
- Use `../../docs/language-contracts/package-and-release-playbook.md` for package-level conventions.
