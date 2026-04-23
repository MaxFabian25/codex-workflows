---
name: using-git-worktrees
description: Use when implementation is about to start and the work needs an isolated workspace
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Contract alignment:** This skill owns the `isolate` phase only. Use it after planning is complete and before `subagent-driven-development` or `executing-plans` begin write-owning work.

**Contract references:** Follow `../../contract/process-family.md` and `../../contract/package-standards.md` for phase ownership and package structure.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

Follow this priority order:

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check AGENTS.md

```bash
rg -n -i "worktree" AGENTS.md 2>/dev/null
```

**If preference specified:** Use it without asking.

### 3. Root-Thread Directory Choice

If no directory exists and no AGENTS.md preference: Use `request_user_input` in the root thread for this directory choice.

Offer:
- `.worktrees (Recommended)` - project-local and hidden inside the repository
- `Global worktrees` - `~/.config/superpowers/worktrees/<project-name>/`

Do not write a plain-text numbered menu for this decision.

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

1. Add the matching ignore rule to `.gitignore` or the repository's canonical ignore file.
2. Commit that repo-hygiene change before creating the worktree.
3. Proceed with worktree creation.

**Why critical:** Prevents accidentally committing worktree contents to repository.

### For Global Directory (~/.config/superpowers/worktrees)

No .gitignore verification needed - outside project entirely.

## Creation Steps

### 1. Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

```bash
# Determine full path
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. Verify Clean Baseline

Run tests to ensure worktree starts clean:

```bash
# Examples - use project-appropriate command
npm test
cargo test
pytest
go test ./...
```

**If tests fail:** Report the failing command, exit status, and key failure lines. Then use `request_user_input` in the root thread for the proceed-vs-investigate choice.

Offer:
- `Investigate baseline first (Recommended)` - fix or understand the existing failure before implementation
- `Proceed with known-red baseline` - continue while explicitly carrying the pre-existing failure forward

**If tests pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Hidden `.worktrees` dir exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees` |
| Neither exists | Check AGENTS.md → use `request_user_input` |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + use `request_user_input` |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Using a plain-text menu for the directory choice

- **Problem:** Breaks the structured root-thread decision contract
- **Fix:** Follow priority: existing > AGENTS.md > `request_user_input`

### Proceeding with failing tests silently

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures and use `request_user_input` for the next-step decision

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (package.json, etc.)

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Replace an eligible root-thread decision with a plain-text multiple-choice prompt
- Proceed with failing tests without a root-thread decision
- Assume directory location when ambiguous
- Skip AGENTS.md check

**Always:**
- Follow directory priority: existing > AGENTS.md > ask
- Use `request_user_input` for eligible discrete choices in the root thread
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**
- **writing-plans** - Use after the plan is approved and implementation is about to start
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
