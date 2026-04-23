---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## When to Use

**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Explicit exceptions:**
- Pure documentation changes
- Pure configuration/data changes with no meaningful automated check
- Generated output where the generator itself is the thing under test

If you skip TDD, say why and state the alternative verification path.

## Required Loop

### 1. RED

Write the next failing automated test for one behavior.

Requirements:
- name the behavior clearly;
- test one thing at a time;
- prefer real code paths over mocks when practical.

### 2. Verify RED

Run the focused test and confirm it fails for the expected reason.

Do not continue until the failure is meaningful:
- failing because the behavior is missing is good;
- failing because of a typo, bad fixture, or broken test harness is not.

### 3. GREEN

Write the smallest production change that makes the failing test pass.

Do not bundle extra features, refactors, or speculative abstractions into this step.

### 4. Verify GREEN

Run the focused test again, then run the relevant broader suite for the touched area. Confirm the new behavior passes without introducing regressions.

### 5. REFACTOR

Only after green:
- remove duplication;
- improve naming or structure;
- keep behavior unchanged;
- rerun the relevant tests.

Then repeat with the next failing test.

## Test Design Rules

- Prefer behavior-oriented tests over implementation-detail assertions.
- Use mocks to isolate boundaries you do not own, not to avoid testing your own logic.
- For bug fixes, start with a regression test that reproduces the bug.
- If the right automated test is hard to write, treat that as design feedback and simplify the seam where possible.

## Existing Code and Partial Implementations

- Tests written after already-passing production code are coverage, not TDD proof.
- If you already wrote production code first, do not pretend the later test was "red" for that same change.
- Re-enter the cycle by writing the next failing test before further production edits. If needed, revert or isolate the earlier code so the red/green loop is real again.

## Red Flags

- Production code before a failing test for the next behavior
- A new test that passes on the first run when it was supposed to drive the implementation
- Fixing the test to match the buggy implementation instead of fixing the code
- Manual-only verification for behavior that could be automated
- Claiming TDD while skipping the red step

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check these boxes? Report that directly instead of claiming TDD evidence you do not have.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Debugging Integration

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

Never fix bugs without a test.

## Testing Anti-Patterns

When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:
- Testing mock behavior instead of real behavior
- Adding test-only methods to production classes
- Mocking without understanding dependencies

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.
