---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Do not claim success until a fresh command proves the claim.

**Core principle:** Evidence before claims, always.

**Contract alignment:** This skill ends at verified evidence. It does not decide merge, cleanup, or branch-finish actions; those belong to `finishing-a-development-branch`.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for lifecycle ownership and package structure.

## Required Flow

Before claiming a result:

1. Identify the command or checklist that proves the claim.
2. Run it fresh for the current code state.
3. Read the output, exit code, and failure counts.
4. State the actual result, not the hoped-for result.
5. If you did not verify, say that directly.

Old output, partial output, or a child's success report do not count as fresh proof.

## Minimum Evidence

| Claim | Fresh proof required | Not enough |
|-------|----------------------|------------|
| Tests pass | Full test command with zero failures | Previous run, partial subset, "should pass" |
| Linter/typecheck clean | Relevant linter/typecheck command exits cleanly | Passing tests only |
| Build succeeds | Build/package command exits 0 | Linter passing |
| Bug fixed | Reproduction no longer fails, or regression test now passes | Code changed, manual confidence |
| Requirements met | Plan/spec checklist reviewed against implementation | "Tests pass" alone |
| Child work completed | Parent verifies diff plus required commands | Child says "done" |

## Special Cases

### Regression fixes

- For bug fixes, verify the original symptom is covered by an automated test when practical.
- If you claim a regression test exists, confirm the red/green evidence or say that the test was added after the fix and therefore is coverage, not TDD proof.

### Requirements coverage

- Re-read the plan, ticket, or spec before final completion claims.
- Report gaps explicitly instead of collapsing them into a generic "done."

### Delegated work

- Inspect the resulting diff and run the required verification yourself in the parent thread.
- Treat a child review or implementation summary as input, not proof.

## Reporting Pattern

When you report status, include:
- the command or checklist you ran;
- the result, including exit status or pass/fail counts when relevant;
- the most important evidence line(s);
- any remaining gaps or unverified areas.

## Red Flags

- Using "should", "probably", or "seems fixed" as a substitute for evidence
- Reporting success from memory instead of a fresh run
- Claiming a build passed after only running lint or tests
- Moving to commit/PR/closeout without a current verification pass
- Trusting delegated work without parent-side checks

## Bottom Line

Run the command, read the result, and report the actual state. If verification did not happen, say so plainly.
