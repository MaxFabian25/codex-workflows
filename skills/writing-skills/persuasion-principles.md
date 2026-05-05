# Structured Prompting Principles for Skill Design

## Overview

Current GPT-5-family prompting works best when skills define clear triggers, ordered steps, tool boundaries, stop conditions, verification loops, and output contracts. Prefer structure over intensity.

Use this reference when rewriting skills that previously relied on forceful persuasion language.

## Core Principles

### 1. Trigger

Descriptions explain when the skill applies. Keep them narrow enough that the model can decide whether to read the full skill.

### 2. Task Order

Use numbered steps when order matters. Separate reversible local actions from decisions that must return to the root thread.

### 3. Tool Boundary

Name the tool surface and call shape only where it changes behavior. Avoid duplicating generic tool instructions in every skill.

### 4. Stop Conditions

Define when to proceed, when to ask, when to return `NEEDS_CONTEXT`, and when to mark work `BLOCKED`.

### 5. Verification

State what evidence proves completion. Use the narrowest verification loop that catches the expected failure mode.

### 6. Output Contract

Specify the exact report sections, schemas, or decision objects when downstream work depends on them.

## Rewrite Pattern

Convert emphatic rules into scoped structural rules:

```markdown
Before:
You ABSOLUTELY MUST verify. This is not optional.

After:
Before reporting completion:
1. Run the verification command.
2. Read the exit code and failure count.
3. If verification fails, report the failing command and status.
4. If verification passes, cite the command and result.
```

## Quick Reference

When designing a skill, ask:

1. What task triggers this skill?
2. What ordered steps matter?
3. What tool boundaries or child-agent boundaries matter?
4. What blocks progress?
5. What evidence proves completion?
6. What exact output shape should the agent return?
