---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

Investigate the root cause before proposing or applying fixes.

**Core principle:** Evidence first, one hypothesis at a time, fix the cause rather than the symptom.

Use this for test failures, production bugs, unexpected behavior, performance problems, build failures, and integration issues.

## Required Flow

### Phase 1: Root-Cause Investigation

Before proposing a fix:

1. Read the full error output, stack trace, logs, and failure context.
2. Reproduce the issue or document why it is not reliably reproducible yet.
3. Check recent changes, environment differences, dependency changes, and configuration changes.
4. Trace the failing data path backward until you can identify where the bad state or behavior starts.
5. In multi-component systems, collect evidence at each boundary before choosing a component to change.

For multi-component failures, record:
- what enters each boundary;
- what exits each boundary;
- which config or environment values are present;
- which layer first diverges from the expected behavior.

Use `root-cause-tracing.md` for deeper backward tracing when the failure appears far from its origin.

### Phase 2: Pattern Analysis

Before implementing:

1. Find similar working code or configuration in the same codebase.
2. Compare the broken path against the working pattern.
3. Identify the meaningful differences.
4. Confirm required dependencies, state, configuration, and assumptions.

If no working pattern exists, state that explicitly and use the smallest reproducible case as the reference.

### Phase 3: Hypothesis Testing

Form one specific hypothesis:

- `I think <cause> produces <symptom> because <evidence>.`

Then test it with the smallest useful change or diagnostic. Change one variable at a time. If the hypothesis fails, update the evidence and form a new hypothesis instead of stacking fixes.

### Phase 4: Implementation and Verification

After the root cause is supported by evidence:

1. Create a failing automated test or smallest practical reproduction for the bug.
2. Implement one fix that addresses the identified root cause.
3. Run the reproduction and relevant regression tests.
4. Confirm the original symptom is resolved and no nearby behavior regressed.
5. Report the evidence and any remaining limitations.

Use `superpowers:test-driven-development` for the failing test and `superpowers:verification-before-completion` before claiming the fix is complete.

## Repeated-Failure Rule

If two fix attempts fail, pause before attempting another.

Before a third attempt:
- summarize what each attempt proved or disproved;
- reassess whether the architecture, ownership boundary, or original plan is wrong;
- decide whether to revise the approach before changing more code.

Do not keep adding fixes on top of failed hypotheses.

## Stop Conditions

Stop and return to investigation when:
- the issue cannot be reproduced or bounded;
- the proposed fix does not follow from the evidence;
- multiple variables are being changed at once;
- the fix would only mask the symptom;
- the failure moves to a different layer after each attempt;
- verification is manual-only when an automated reproduction is practical.

## Environmental or External Causes

If investigation points to timing, environment, or an external dependency:

1. Document the evidence and the boundary where local control ends.
2. Add appropriate handling such as retry, timeout, validation, or clearer errors.
3. Add logging or diagnostics that will make a future recurrence easier to prove.
4. Verify the handling path.

## Supporting Techniques

These references are available in this skill directory:

- `root-cause-tracing.md` - trace bugs backward through the call stack to find the original trigger
- `defense-in-depth.md` - add validation at multiple layers after finding the root cause
- `condition-based-waiting.md` - replace arbitrary timeouts with condition polling

## Bottom Line

Do not guess. Reproduce, trace, compare, test one hypothesis, then fix and verify.
