---
name: writing-skills
description: Use when creating or editing skills and validating that they satisfy the library contract before deployment
---

# Writing Skills

Writing skills is test-driven documentation for Codex.

**Contract references:** Process-family skill edits must align with `../../contract/process-family.md`, and every skill package must satisfy `../../contract/package-standards.md`.

Personal skills for Codex live under `~/.agents/skills/`.

Core principle: if you did not observe the baseline failure without the skill, you do not know whether the skill teaches the right behavior.

## What a Skill Is

A skill is a reusable reference guide for a proven technique, workflow, or tool contract.

## When to Create a Skill

Create a skill when:
- the guidance is reusable across projects
- the workflow is non-obvious
- another Codex session would benefit from it

Do not create a skill for:
- one-off repo conventions
- purely mechanical rules that should be automated instead

## Required Structure

Every skill package needs:
- `SKILL.md`
- valid YAML frontmatter with `name` and `description`
- only the supporting files actually needed

## Discovery Guidance

Descriptions explain when to use the skill, not the workflow summary. Future Codex sessions decide what to load by scanning trigger descriptions.

## Validation

After editing a skill package, run the relevant validator or quick-check script for that package before publishing it.
