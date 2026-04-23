---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over performance or politeness theater.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for review ownership and package structure.

**Hard-cut review rule:** Unrequested compatibility shims, fallback surfaces, and dual-path behavior are regressions by default. Only preserve them when the request explicitly calls for that support contract.

## Use When

- You receive review feedback and need to decide whether to fix it, push back, or escalate.
- The feedback may change behavior, interfaces, support contracts, or architecture.

## Workflow

1. Read the full review before acting on any individual point.
2. Verify each review item against the code, tests, spec, and current branch state before changing code.
3. If any item is unclear, clarify it before implementing dependent changes.
4. Decide whether to fix, push back, or escalate.
5. Implement one item at a time and verify each change before moving to the next.
6. Reply factually with the result and the supporting evidence.

## Reviewer Source

- From the user or repo owner: implement once understood, but still clarify scope or intent when needed.
- From external reviewers: verify the suggestion against this codebase, not against generic best practice.
- If feedback conflicts with the user's architecture, scope, or support contract, escalate in the root thread before changing code.
- If a suggestion cannot be verified cheaply, say what evidence is missing and how that affects the decision.

## Response Style

- Prefer `Fixed in <file>` plus the key change.
- Use `Verified and keeping current approach because <reason>` when the review point does not apply.
- Use `Need clarification on item <n> before changing code` when the issue is still ambiguous.
- If you pushed back and later proved yourself wrong, state that plainly and move on.

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## Hard Rules

- Do not implement feedback you do not understand.
- Do not treat review comments as automatically correct without checking.
- Do not add compatibility shims or fallback paths that were not requested.
- Do not reply with social filler instead of a technical disposition.
- Do not skip verification after applying a fix.
