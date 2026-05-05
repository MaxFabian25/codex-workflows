---
name: using-git-worktrees
description: Use when implementation needs an isolated workspace
---

# Using Git Worktrees

**Contract alignment:** This skill owns the `isolate` phase only. Use it after planning is complete and before `subagent-driven-development` or `executing-plans` begin write-owning work.

**Contract references:** Follow `../../docs/language-contracts/process-family-playbook.md` and `../../docs/language-contracts/package-and-release-playbook.md` for phase ownership and package structure.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Use When

- Implementation is about to start and the work needs an isolated branch + filesystem path.
- The user has not explicitly approved doing the work on the current branch.

## Preconditions

- Planning is complete enough to name the feature branch and run an initial baseline check.
- You know whether the repo already defines a preferred worktree location.

## Workflow

1. Choose the location in this priority order: existing directory > AGENTS.md preference > root-thread `request_user_input`.
   - Check `.worktrees` first, then `worktrees`.
   - If neither exists, inspect `AGENTS.md` for a worktree-location rule.
   - Use `request_user_input` in the root thread for the directory choice only when no existing directory or AGENTS.md preference decides it.
2. For a project-local location, verify the directory is ignored before creation:

   ```bash
   git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
   ```

   If a project-local worktree directory is not ignored, add the ignore rule and commit that hygiene change before creating the worktree.
3. Create the worktree and branch:

   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   git worktree add "$path" -b "$BRANCH_NAME"
   cd "$path"
   ```

4. Run the repo-appropriate setup based on the detected project files.
5. Run baseline verification for the clean checkout. If baseline verification fails, report the failing command, exit status, and key failure lines, then use `request_user_input` in the root thread for the proceed-vs-investigate decision with `Investigate baseline first (Recommended)` and `Proceed with known-red baseline`.
6. Report the worktree path, branch name, and baseline state.

## Expected Output

- `Worktree ready at <full-path>`
- The branch name created for the isolated workspace
- Baseline verification status, including the command and result

## Hard Rules

- Priority: existing directory > AGENTS.md preference > root-thread `request_user_input`.
- Do not replace an eligible root-thread choice with a plain-text multiple-choice prompt.
- Do not create a project-local worktree without ignore verification.
- Do not proceed from a failing baseline without a root-thread decision.
- Do not skip the repo-appropriate dependency/setup step when the project requires one.
