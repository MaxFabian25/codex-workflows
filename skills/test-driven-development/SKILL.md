---
name: test-driven-development
description: Use when writing implementation code for features or bug fixes
---

# Test-Driven Development

Write the test first. Watch it fail. Write the minimum code that makes it pass.

## Use When

- New features, bug fixes, refactors, and behavior changes.
- Skip only for pure docs, pure data/config changes with no meaningful automated check, or generated output where the generator is the unit under test.
- If you skip TDD, say why and state the alternate verification path.

## Required Loop

1. **RED:** write one behavior-focused failing test.
2. **Verify RED:** run it and confirm it fails for the expected missing behavior, not a typo or harness problem.
3. **GREEN:** write the smallest production change that passes the test.
4. **Verify GREEN:** rerun the focused test and the relevant broader check.
5. **REFACTOR:** improve structure only after green; rerun the relevant tests.
6. Repeat for the next behavior.

## Test Design

- Prefer real code paths over mocks when practical.
- Use mocks only for boundaries you do not own.
- For bugs, start with a regression test that reproduces the symptom.
- If the test is hard to write, treat that as design feedback and simplify the interface where possible.

## Existing Code

- Tests written after already-passing production code are coverage, not TDD proof.
- If production code was written first, do not claim the later test was red for that same change.
- Re-enter the loop by writing the next failing test before further production edits.

## Completion Evidence

Report:
- the failing test command and expected failure;
- the passing focused test command;
- the broader verification command;
- any behavior that was not covered by automated tests.

## Supporting Reference

When adding mocks or test utilities, read `testing-anti-patterns.md` for common failure modes.
