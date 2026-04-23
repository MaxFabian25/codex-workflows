---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for review ownership and package structure.

**Hard-cut review rule:** Unrequested compatibility shims, fallback surfaces, and dual-path behavior are regressions by default. Only preserve them when the request explicitly calls for that support contract.

## The Response Pattern

1. Read the full review before acting on any single point.
2. Restate the requirement or concern in technical terms.
3. Verify it against the code, tests, spec, and current branch state.
4. Decide whether to fix, push back, or escalate.
5. Implement one item at a time and verify each change.
6. Reply factually with the result.

## Handling Unclear Feedback

If any item is unclear, stop and clarify before implementing dependent changes. Partial understanding is how review feedback turns into a new bug.

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement required**
- **Skip to action** or give a brief technical acknowledgment

### From External Reviewers
- Verify the suggestion against this codebase, not against generic best practice.
- Check whether it breaks current behavior, support contracts, or explicit prior decisions.
- If it conflicts with the user's architecture or scope decisions, stop and escalate in the root thread before changing code.
- If you cannot verify it cheaply, say what is missing and ask how to proceed.

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Suggestion adds an unrequested shim, fallback path, or dual-path behavior
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

## Acknowledging Correct Feedback

When feedback IS correct:
- `Fixed in <file>` plus the key change
- `Verified and keeping current approach because <reason>`
- `Need clarification on item <n> before changing code`

Avoid blanket praise, gratitude padding, or agreement before verification. The important part is the technical disposition, not the social flourish.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
 - `Verified this and you're correct. Fixing now.`
 - `Checked <evidence>; my earlier read was wrong. Updated in <file>.`

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## Red Flags

- Implementing feedback you do not understand
- Treating review comments as automatically correct without checking
- Adding compatibility shims or fallback paths that were not requested
- Replying with social filler instead of a technical disposition
- Skipping verification after applying a fix

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

Keep the reply brief, technical, and tied to evidence.
