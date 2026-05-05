---
name: systematic-debugging
description: Use when bugs, test failures, or unexpected behavior need fixes
---

# Systematic Debugging

Evidence first, one hypothesis at a time, fix the cause rather than the symptom.

Use this for test failures, production bugs, unexpected behavior, performance problems, build failures, and integration issues.

## Required Flow

1. Read the full error output, stack trace, logs, and failure context.
2. Reproduce the issue or document why it is not reproducible yet.
3. Check recent code, environment, dependency, and configuration changes.
4. Trace the failing data path backward until the bad state or behavior starts.
5. In multi-component systems, collect evidence at each boundary before choosing a component to change.
6. Compare against similar working code or configuration.
7. Test one hypothesis at a time: `I think <cause> produces <symptom> because <evidence>.`
8. After the cause is supported, add the smallest reproduction or failing test, fix the cause, and verify the original symptom plus nearby regressions.

## Multi-Component Evidence

In multi-component systems, collect evidence at each boundary before choosing a component to change.

Record:
- what enters and exits each boundary;
- relevant config and environment values;
- the first layer that diverges from expected behavior.

Use `root-cause-tracing.md` for deeper backward tracing when the failure appears far from its origin.

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
- verification is manual-only when an automated reproduction is practical.

## Supporting References

- `root-cause-tracing.md` - backward tracing through call stacks and state changes
- `defense-in-depth.md` - validation after the root cause is known
- `condition-based-waiting.md` - replacing arbitrary timeouts with condition polling
