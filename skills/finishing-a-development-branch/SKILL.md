---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

**Contract alignment:** This skill starts after review and verification have already passed. It owns closeout and branch-finish decisions, not earlier quality gates.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for lifecycle ownership and package structure.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Use When

- The implementation, review, and verification passes are complete.
- The remaining task is merge, PR, keep-as-is, or discard closeout.

## Preconditions

- You know the relevant verification command for the final code state.
- You can identify the target base branch for merge or PR creation.

## Workflow

1. Run the final verification command before offering any closeout choice. If it fails, stop and report the failing command, exit status, and key failure lines.
2. Determine the base branch. If `main` and `master` are both plausible, confirm the intended base branch in the root thread before continuing.
3. Use `request_user_input` for the standard non-destructive closeout choice in the root thread.
   - `Merge locally`
   - `Push and create PR`
   - `Keep branch as-is`
4. Execute the chosen path:
   - `Merge locally`: switch to the base branch, pull, merge the feature branch, rerun verification on the merged result, then delete the feature branch.
   - `Push and create PR`: push the branch, create the PR, and keep the worktree for follow-up.
   - `Keep branch as-is`: report the preserved branch and worktree path without cleanup.
5. Treat discard as a separate destructive path. Only use it when the user explicitly asks to discard the branch or chooses an equivalent free-form path. For discard, require typed `discard` confirmation before deleting the branch or worktree.
6. Cleanup the worktree only after `Merge locally` or discard.

## Expected Output

- The chosen closeout path and the branch/base branch involved
- Final verification status
- The resulting branch/worktree state
- PR URL if a PR was created

## Hard Rules

- Do not proceed with failing tests.
- Do not merge locally without rerunning verification on the merged result.
- Do not force-push without explicit request.
- Do not delete work without typed `discard` confirmation.
- Do not replace the root-thread closeout choice with a plain-text menu.
