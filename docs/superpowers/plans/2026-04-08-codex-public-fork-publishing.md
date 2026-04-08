# Codex Public Fork Publishing Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use superpowers:using-git-worktrees to create the isolated workspace for this plan. Then use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert this repository into a public, Codex-only fork of `obra/superpowers` with a native Codex plugin manifest, fork-owned public metadata, and no non-Codex or private-operator public surfaces.

**Architecture:** Build the cutover around a new public-fork validator and a native `.codex-plugin/plugin.json` manifest, then rewrite the public docs/metadata and the Codex-facing skill entrypoints to match that contract. Remove non-Codex plugin surfaces, private rollout artifacts, and legacy hook-driven bootstrap files, then finish with a deterministic validation bundle that proves the public branch is fork-owned, plugin-first, and free of private workstation drift.

**Tech Stack:** Markdown docs, JSON manifests, shell validation, Python 3 structural validator, existing process-family validator

---

## File Structure

- `README.md`: public repo landing page and fork identity
- `.codex/INSTALL.md`: concise Codex install/update/uninstall guide
- `docs/README.codex.md`: detailed Codex usage and install guide
- `.codex-plugin/plugin.json`: native Codex plugin manifest for this fork
- `package.json`: repo/package metadata aligned to the new plugin identity
- `SECURITY.md`: fork-owned security reporting policy
- `.github/ISSUE_TEMPLATE/config.yml`: fork-owned issue/help/security routing
- `CODE_OF_CONDUCT.md`: fork-owned conduct enforcement route
- `CHANGELOG.md`: fork-scoped changelog
- `RELEASE-NOTES.md`: fork-scoped release notes
- `scripts/validate_codex_public_fork.py`: deterministic public-surface validator
- `tests/codex-public-fork/run.sh`: one-command validation bundle
- `skills/using-superpowers/SKILL.md`: Codex-only skill-routing entrypoint
- `skills/using-superpowers/references/codex-tools.md`: generic Codex tool mapping with no workstation-only config assumptions
- `skills/writing-skills/SKILL.md`: Codex-only contributor guidance for writing skills
- `skills/systematic-debugging/root-cause-tracing.md`: normalize example paths
- `skills/using-git-worktrees/SKILL.md`: normalize example paths

Files and directories to remove from the public branch:

- `.claude-plugin/`
- `.cursor-plugin/`
- `.opencode/`
- `hooks/`
- `docs/README.opencode.md`
- `docs/testing.md`
- `docs/windows/polyglot-hooks.md`
- `docs/plans/2025-11-22-opencode-support-design.md`
- `docs/plans/2025-11-22-opencode-support-implementation.md`
- `docs/superpowers/plans/2026-04-06-codex-cli-subagent-setup.md`
- `docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md`
- `GEMINI.md`
- `gemini-extension.json`
- `.github/FUNDING.yml`
- `skills/writing-skills/anthropic-best-practices.md`
- `scripts/sync_process_family_to_maxfa_wsl.sh`
- `tests/claude-code/`
- `tests/opencode/`
- `tests/explicit-skill-requests/`
- `tests/skill-triggering/`
- `tests/subagent-driven-dev/run-test.sh`

## Task 1: Add the public-fork validator and native Codex plugin manifest

**Files:**
- Create: `scripts/validate_codex_public_fork.py`
- Create: `tests/codex-public-fork/run.sh`
- Create: `.codex-plugin/plugin.json`
- Modify: `package.json`

- [ ] **Step 1: Create the public-fork validator**

```python
#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ROOT / ".codex-plugin" / "plugin.json",
    ROOT / "README.md",
    ROOT / ".codex" / "INSTALL.md",
    ROOT / "docs" / "README.codex.md",
    ROOT / "SECURITY.md",
    ROOT / "package.json",
]

REMOVED_PATHS = [
    ROOT / ".claude-plugin",
    ROOT / ".cursor-plugin",
    ROOT / ".opencode",
    ROOT / "hooks",
    ROOT / "docs" / "README.opencode.md",
    ROOT / "GEMINI.md",
    ROOT / "gemini-extension.json",
]

SCAN_TARGETS = [
    ROOT / "README.md",
    ROOT / ".codex" / "INSTALL.md",
    ROOT / "docs" / "README.codex.md",
    ROOT / ".github" / "ISSUE_TEMPLATE" / "config.yml",
    ROOT / "CODE_OF_CONDUCT.md",
    ROOT / "CHANGELOG.md",
    ROOT / "RELEASE-NOTES.md",
    ROOT / "SECURITY.md",
    ROOT / "package.json",
    ROOT / ".codex-plugin" / "plugin.json",
    ROOT / "skills" / "using-superpowers" / "SKILL.md",
    ROOT / "skills" / "using-superpowers" / "references" / "codex-tools.md",
    ROOT / "skills" / "writing-skills" / "SKILL.md",
]

FORBIDDEN_SNIPPETS = [
    "https://github.com/obra/superpowers",
    "https://github.com/obra/superpowers-marketplace",
    "https://claude.com/plugins/superpowers",
    "discord.gg/Jd8Vphy9jq",
    "github.com/sponsors/obra",
    "/Users/maxibon",
    "maxfa-",
    ".worktrees/",
    "~/.claude/skills",
    "~/.config/opencode",
    "CLAUDE_PLUGIN_ROOT",
    "OpenCode",
    "Gemini CLI",
]

REQUIRED_MANIFEST = {
    "name": "superpowers-codex",
    "skills": "./skills/",
    "repository": "https://github.com/MaxFabian25/superpowers",
    "homepage": "https://github.com/MaxFabian25/superpowers",
    "license": "MIT",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    for path in REQUIRED_FILES:
        if not path.exists():
            fail(f"missing required file {path.relative_to(ROOT)}")

    for path in REMOVED_PATHS:
        if path.exists():
            fail(f"removed path still present: {path.relative_to(ROOT)}")

    manifest = json.loads((ROOT / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
    for key, expected in REQUIRED_MANIFEST.items():
        actual = manifest.get(key)
        if actual != expected:
            fail(f".codex-plugin/plugin.json field {key!r} expected {expected!r} but found {actual!r}")

    interface = manifest.get("interface")
    if not isinstance(interface, dict):
        fail(".codex-plugin/plugin.json is missing interface object")
    for key in ["displayName", "shortDescription", "longDescription", "developerName", "category", "capabilities"]:
        if not interface.get(key):
            fail(f".codex-plugin/plugin.json interface is missing {key!r}")

    for path in SCAN_TARGETS:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for snippet in FORBIDDEN_SNIPPETS:
            if snippet in text:
                fail(f"{path.relative_to(ROOT)} still contains forbidden snippet {snippet!r}")

    print("PASS: codex public fork validator")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Create the validation bundle wrapper**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

python3 scripts/validate_codex_public_fork.py
python3 _shared/validators/validate_skill_library.py --root "$ROOT" --family process
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'

echo "PASS: codex public fork validation bundle"
```

- [ ] **Step 3: Run the validation bundle to establish the failing baseline**

Run: `bash tests/codex-public-fork/run.sh`
Expected: FAIL with at least `.codex-plugin/plugin.json` missing and removed-path/public-surface violations

- [ ] **Step 4: Create `.codex-plugin/plugin.json`**

```json
{
  "name": "superpowers-codex",
  "version": "5.0.6",
  "description": "Codex-only workflow and skills library forked from obra/superpowers.",
  "author": {
    "name": "Max Fabian",
    "url": "https://github.com/MaxFabian25"
  },
  "homepage": "https://github.com/MaxFabian25/superpowers",
  "repository": "https://github.com/MaxFabian25/superpowers",
  "license": "MIT",
  "keywords": [
    "codex",
    "plugin",
    "skills",
    "workflow",
    "planning",
    "tdd",
    "debugging"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Superpowers for Codex",
    "shortDescription": "Codex-only workflow and skill library",
    "longDescription": "A Codex-specific fork of obra/superpowers focused on design, planning, execution, debugging, and review workflows.",
    "developerName": "Max Fabian",
    "category": "Developer Tools",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/MaxFabian25/superpowers",
    "brandColor": "#0F172A",
    "defaultPrompt": [
      "Use superpowers:using-superpowers before we start this task.",
      "Use superpowers:brainstorming to design this feature with me.",
      "Use superpowers:writing-plans to turn the approved design into a plan."
    ]
  }
}
```

- [ ] **Step 5: Replace `package.json` with fork-owned metadata**

```json
{
  "name": "superpowers-codex",
  "version": "5.0.6",
  "description": "Codex-only workflow and skills library, forked from obra/superpowers.",
  "type": "module",
  "license": "MIT",
  "repository": "https://github.com/MaxFabian25/superpowers",
  "homepage": "https://github.com/MaxFabian25/superpowers",
  "bugs": {
    "url": "https://github.com/MaxFabian25/superpowers/issues"
  },
  "keywords": [
    "codex",
    "plugin",
    "skills",
    "workflow",
    "planning",
    "tdd",
    "debugging"
  ]
}
```

- [ ] **Step 6: Re-run the validation bundle**

Run: `bash tests/codex-public-fork/run.sh`
Expected: FAIL, but no longer for missing `.codex-plugin/plugin.json` or `package.json` metadata

- [ ] **Step 7: Commit Task 1**

```bash
git add .codex-plugin/plugin.json package.json scripts/validate_codex_public_fork.py tests/codex-public-fork/run.sh
git commit -m "feat: add codex public fork validation and manifest"
```

### Task 2: Rewrite the public install, release, and security surfaces

**Files:**
- Modify: `README.md`
- Modify: `.codex/INSTALL.md`
- Modify: `docs/README.codex.md`
- Modify: `CHANGELOG.md`
- Modify: `RELEASE-NOTES.md`
- Create: `SECURITY.md`

- [ ] **Step 1: Replace `README.md` with a Codex-only public landing page**

```markdown
# Superpowers for Codex

Superpowers for Codex is a Codex-only fork of [obra/superpowers](https://github.com/obra/superpowers). It packages the workflow as a native Codex plugin plus a skills library for design, planning, execution, debugging, and review.

## What this fork includes

- `brainstorming` for design exploration before implementation
- `writing-plans` for detailed implementation plans
- `subagent-driven-development` and `executing-plans` for plan execution
- `test-driven-development`, `systematic-debugging`, and review skills for disciplined delivery

## Install in Codex

1. Clone the repo into your local plugin directory:

   ```bash
   mkdir -p ~/plugins
   git clone https://github.com/MaxFabian25/superpowers.git ~/plugins/superpowers-codex
   ```

2. Create or update `~/.agents/plugins/marketplace.json` so Codex can discover the plugin:

   ```json
   {
     "name": "local-codex",
     "interface": {
       "displayName": "Local Codex Plugins"
     },
     "plugins": [
       {
         "name": "superpowers-codex",
         "source": {
           "source": "local",
           "path": "./plugins/superpowers-codex"
         },
         "policy": {
           "installation": "AVAILABLE",
           "authentication": "ON_INSTALL"
         },
         "category": "Developer Tools"
       }
     ]
   }
   ```

3. Restart Codex.

4. Start a new session and tell Codex:

   ```text
   Use superpowers:using-superpowers before we start.
   ```

## Detailed Codex guide

See [docs/README.codex.md](docs/README.codex.md) for installation, updates, validation, and usage guidance.

## Updating

```bash
git -C ~/plugins/superpowers-codex pull
```

## Uninstalling

Remove the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`, then delete the local clone:

```bash
rm -rf ~/plugins/superpowers-codex
```

## Support

- Issues: https://github.com/MaxFabian25/superpowers/issues
- Security: https://github.com/MaxFabian25/superpowers/security/advisories/new

## Upstream origin

This fork derives from `obra/superpowers` and retains the upstream MIT license. Public docs and runtime guidance in this fork are Codex-only.
```

- [ ] **Step 2: Replace `.codex/INSTALL.md` with the concise plugin-first install guide**

```markdown
# Installing Superpowers for Codex

Install this fork as a local Codex plugin.

## Prerequisites

- Codex CLI
- Git

## Installation

1. Clone the plugin locally:

   ```bash
   mkdir -p ~/plugins
   git clone https://github.com/MaxFabian25/superpowers.git ~/plugins/superpowers-codex
   ```

2. Create or update `~/.agents/plugins/marketplace.json`:

   ```json
   {
     "name": "local-codex",
     "interface": {
       "displayName": "Local Codex Plugins"
     },
     "plugins": [
       {
         "name": "superpowers-codex",
         "source": {
           "source": "local",
           "path": "./plugins/superpowers-codex"
         },
         "policy": {
           "installation": "AVAILABLE",
           "authentication": "ON_INSTALL"
         },
         "category": "Developer Tools"
       }
     ]
   }
   ```

3. Restart Codex.

4. Verify plugin support is enabled in the installed CLI:

   ```bash
   codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
   ```

5. Start a new Codex session and ask it to use `superpowers:using-superpowers`.

## Updating

```bash
git -C ~/plugins/superpowers-codex pull
```

## Uninstalling

Remove the `superpowers-codex` plugin entry from `~/.agents/plugins/marketplace.json`, then delete `~/plugins/superpowers-codex`.
```

- [ ] **Step 3: Replace `docs/README.codex.md` with the detailed Codex-only guide**

```markdown
# Superpowers for Codex

Detailed guide for using the `superpowers-codex` plugin with Codex CLI.

## Install

### 1. Clone the plugin

```bash
mkdir -p ~/plugins
git clone https://github.com/MaxFabian25/superpowers.git ~/plugins/superpowers-codex
```

### 2. Register the plugin in the local Codex marketplace

If `~/.agents/plugins/marketplace.json` does not exist yet, create it with:

```json
{
  "name": "local-codex",
  "interface": {
    "displayName": "Local Codex Plugins"
  },
  "plugins": [
    {
      "name": "superpowers-codex",
      "source": {
        "source": "local",
        "path": "./plugins/superpowers-codex"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
```

If the file already exists, append the same plugin object to `plugins[]` without changing unrelated entries.

### 3. Restart Codex

Restart the CLI after changing the local plugin catalog.

### 4. Verify the local install

```bash
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

Expected:

- the plugin manifest exists under `~/plugins/superpowers-codex/.codex-plugin/plugin.json`
- `codex features list` reports `plugins stable true`

## Starting a session

The current public fork does not depend on Codex hook bootstrap. Start a new session by explicitly invoking the entry skill:

```text
Use superpowers:using-superpowers before we start.
```

From there, the plugin’s process skills will route the rest of the workflow.

## Recommended workflow

1. `superpowers:using-superpowers`
2. `superpowers:brainstorming`
3. `superpowers:writing-plans`
4. `superpowers:using-git-worktrees`
5. `superpowers:subagent-driven-development` or `superpowers:executing-plans`

## Updating

```bash
git -C ~/plugins/superpowers-codex pull
```

## Troubleshooting

### Codex does not expose the plugin

Check:

```bash
test -f ~/.agents/plugins/marketplace.json
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

### Skills seem present but routing is weak

Start the session with:

```text
Use superpowers:using-superpowers before we start.
```

### Updating did not take effect

Restart Codex after pulling the plugin repo.
```

- [ ] **Step 4: Replace `CHANGELOG.md` with a fork-scoped changelog**

```markdown
# Changelog

All notable changes to the Codex-only fork are documented here.

## [Unreleased]

- Prepare the repository for public publishing as a native Codex plugin fork.

## [5.0.6-codex.1] - 2026-04-08

- Added `.codex-plugin/plugin.json` for the native Codex plugin surface
- Rewrote public docs and metadata for a Codex-only fork contract
- Removed non-Codex plugin surfaces and private operator material from the public path
```

- [ ] **Step 5: Replace `RELEASE-NOTES.md` with fork-scoped release notes**

```markdown
# Release Notes

## 5.0.6-codex.1

This release establishes the public Codex-only fork baseline.

### Highlights

- Native `.codex-plugin/plugin.json` manifest
- Codex-only installation and workflow docs
- Fork-owned issue, security, and release metadata
- Removal of non-Codex plugin surfaces and private operator rollout artifacts

### Upstream lineage

This fork derives from `obra/superpowers`, but the public runtime and documentation contract in this repository is now Codex-only.
```

- [ ] **Step 6: Create `SECURITY.md`**

```markdown
# Security Policy

## Supported branch

Security fixes are tracked on `main`.

## Reporting a vulnerability

For private security disclosures, use GitHub Security Advisories:

https://github.com/MaxFabian25/superpowers/security/advisories/new

If that route is unavailable, open a minimal public issue without secrets and note that a private follow-up is needed.
```

- [ ] **Step 7: Re-run the validation bundle**

Run: `bash tests/codex-public-fork/run.sh`
Expected: FAIL, but README/install/release/security failures should be gone

- [ ] **Step 8: Commit Task 2**

```bash
git add README.md .codex/INSTALL.md docs/README.codex.md CHANGELOG.md RELEASE-NOTES.md SECURITY.md
git commit -m "docs: rewrite public codex install and release surfaces"
```

### Task 3: Rewrite the Codex-facing skill entrypoints and fork-owned governance metadata

**Files:**
- Modify: `.github/ISSUE_TEMPLATE/config.yml`
- Modify: `CODE_OF_CONDUCT.md`
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/using-superpowers/references/codex-tools.md`
- Modify: `skills/writing-skills/SKILL.md`
- Delete: `.github/FUNDING.yml`
- Delete: `skills/writing-skills/anthropic-best-practices.md`

- [ ] **Step 1: Replace `.github/ISSUE_TEMPLATE/config.yml`**

```yaml
blank_issues_enabled: false
contact_links:
  - name: Codex installation guide
    url: https://github.com/MaxFabian25/superpowers/blob/main/.codex/INSTALL.md
    about: Use the Codex-only install guide before opening setup questions.
  - name: Private security report
    url: https://github.com/MaxFabian25/superpowers/security/advisories/new
    about: Report security issues privately through GitHub Security Advisories.
```

- [ ] **Step 2: Delete the upstream funding file**

Run: `rm -f .github/FUNDING.yml`
Expected: `.github/FUNDING.yml` no longer exists

- [ ] **Step 3: Patch `CODE_OF_CONDUCT.md` to use a fork-owned enforcement route**

```diff
@@
-Instances of abusive, harassing, or otherwise unacceptable behavior may be
-reported to the community leaders responsible for enforcement at
-jesse@primeradiant.com.
+Instances of abusive, harassing, or otherwise unacceptable behavior may be
+reported through the repository issue intake at
+https://github.com/MaxFabian25/superpowers/issues/new/choose.
```

- [ ] **Step 4: Replace `skills/using-superpowers/SKILL.md` with the Codex-only version**

```markdown
---
name: using-superpowers
description: Use when starting a session so the agent routes through the skill system before responding
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
</EXTREMELY-IMPORTANT>

## Instruction Priority

1. User instructions and repository instructions
2. Superpowers skills
3. Default system behavior

## How to Access Skills in Codex

This fork is Codex-only. Skills are packaged through the native plugin surface and live in this repository under `skills/`.

When a skill applies:

1. Read the relevant `SKILL.md`
2. Follow it directly
3. Use `references/codex-tools.md` for Codex tool mapping when the skill mentions a platform-specific tool name

**Contract references:** Follow `../../contract/process-family.md` for lifecycle routing and `../../contract/package-standards.md` for package structure.

## The Rule

Invoke relevant or requested skills before any response or action.

## Skill Priority

When multiple process skills seem relevant, follow `../../contract/process-family.md` first and choose the skill that owns the current lifecycle phase.

1. Process skills first
2. Implementation skills second

## Red Flags

- "This is simple enough to skip skill routing"
- "I can inspect files first and check skills later"
- "I already remember what this skill says"

Those are all reasons to stop and read the actual skill.
```

- [ ] **Step 5: Replace `skills/using-superpowers/references/codex-tools.md`**

```markdown
# Codex Tool Mapping

Use this file as the Codex-native translation layer for skill instructions.

| Skill references | Codex equivalent |
|---|---|
| `Task` tool (dispatch subagent) | `spawn_agent(task_name=..., agent_type="worker" | "explorer" | "implementer" | "spec_reviewer" | "code_quality_reviewer" | "parallel_explorer" | "final_reviewer", message="...")` |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent(...)` calls |
| Wait for child result | `wait_agent(...)` |
| Close completed child | `close_agent(...)` |
| `TodoWrite` | `update_plan` |
| `Skill` tool | Read the relevant `SKILL.md` from the plugin and follow it |
| File edits | `apply_patch` |
| Shell commands | `exec_command` |

## Runtime checks

Before relying on plugin or subagent workflows, verify the live runtime:

```bash
codex features list | rg '^(plugins|multi_agent|multi_agent_v2)[[:space:]]+'
```

## Dispatch rules

- Always pass a stable lowercase `task_name`.
- Keep the parent session responsible for user clarification, escalation, and synthesis.
- Use read-only roles for review and exploration.
- Do not pass `model` or `reasoning_effort` unless the user explicitly requests an override.
- Keep child packets narrow and self-contained.
```

- [ ] **Step 6: Replace `skills/writing-skills/SKILL.md` with the Codex-only contributor guide**

```markdown
---
name: writing-skills
description: Use when creating or editing skills and validating that they satisfy the library contract before deployment
---

# Writing Skills

## Overview

Writing skills is test-driven documentation for Codex.

**Contract references:** Process-family skill edits must align with `../../contract/process-family.md`, and every skill package must satisfy `../../contract/package-standards.md`.

Personal skills for Codex live under `~/.agents/skills/`.

## Core principle

If you did not observe the baseline failure without the skill, you do not know whether the skill teaches the right behavior.

## What a skill is

A skill is a reusable reference guide for a proven technique, workflow, or tool contract.

## When to create a skill

- The technique is reusable across projects
- The workflow is non-obvious
- Another Codex session would benefit from the guidance

Do not create skills for one-off repo conventions or purely mechanical rules that should be automated instead.

## Required structure

Every skill package needs:

- `SKILL.md`
- valid YAML frontmatter with `name` and `description`
- only the supporting files that are actually needed

## Discovery guidance

Descriptions should explain when to use the skill, not summarize the workflow. Future Codex sessions decide what to load by scanning those trigger descriptions.

## Validation

After editing a skill package, run the relevant validator or quick-check script for that package before publishing it.
```

- [ ] **Step 7: Delete the Anthropic-only reference file**

Run: `rm -f skills/writing-skills/anthropic-best-practices.md`
Expected: `skills/writing-skills/anthropic-best-practices.md` no longer exists

- [ ] **Step 8: Re-run both validators**

Run: `bash tests/codex-public-fork/run.sh`
Expected: FAIL, but the public-surface failures for issue/config/skill docs should be gone

Run: `python3 _shared/validators/validate_skill_library.py --root /Users/maxibon/.codex/superpowers --family process`
Expected: PASS

- [ ] **Step 9: Commit Task 3**

```bash
git add .github/ISSUE_TEMPLATE/config.yml CODE_OF_CONDUCT.md skills/using-superpowers/SKILL.md skills/using-superpowers/references/codex-tools.md skills/writing-skills/SKILL.md
git rm .github/FUNDING.yml skills/writing-skills/anthropic-best-practices.md
git commit -m "docs: hard cut codex skill and governance surfaces"
```

### Task 4: Remove non-Codex plugin surfaces and private operator artifacts

**Files:**
- Delete: `.claude-plugin/`
- Delete: `.cursor-plugin/`
- Delete: `.opencode/`
- Delete: `hooks/`
- Delete: `docs/README.opencode.md`
- Delete: `docs/testing.md`
- Delete: `docs/windows/polyglot-hooks.md`
- Delete: `docs/plans/2025-11-22-opencode-support-design.md`
- Delete: `docs/plans/2025-11-22-opencode-support-implementation.md`
- Delete: `docs/superpowers/plans/2026-04-06-codex-cli-subagent-setup.md`
- Delete: `docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md`
- Delete: `GEMINI.md`
- Delete: `gemini-extension.json`
- Delete: `scripts/sync_process_family_to_maxfa_wsl.sh`
- Delete: `tests/claude-code/`
- Delete: `tests/opencode/`
- Delete: `tests/explicit-skill-requests/`
- Delete: `tests/skill-triggering/`
- Delete: `tests/subagent-driven-dev/run-test.sh`

- [ ] **Step 1: Remove the non-Codex plugin/runtime directories**

```bash
rm -rf .claude-plugin .cursor-plugin .opencode hooks
```

Expected: none of those directories exist

- [ ] **Step 2: Remove non-Codex docs and workstation rollout artifacts**

```bash
rm -f docs/README.opencode.md \
      docs/testing.md \
      docs/windows/polyglot-hooks.md \
      docs/plans/2025-11-22-opencode-support-design.md \
      docs/plans/2025-11-22-opencode-support-implementation.md \
      docs/superpowers/plans/2026-04-06-codex-cli-subagent-setup.md \
      docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md \
      GEMINI.md \
      gemini-extension.json \
      scripts/sync_process_family_to_maxfa_wsl.sh
```

Expected: all listed files are removed

- [ ] **Step 3: Remove non-Codex test suites**

```bash
rm -rf tests/claude-code tests/opencode tests/explicit-skill-requests tests/skill-triggering
rm -f tests/subagent-driven-dev/run-test.sh
```

Expected: only Codex-relevant test surfaces remain under `tests/`

- [ ] **Step 4: Re-run the public validator**

Run: `bash tests/codex-public-fork/run.sh`
Expected: FAIL only for remaining path/example drift or any missed public-surface references

- [ ] **Step 5: Commit Task 4**

```bash
git add -A
git commit -m "refactor: remove non-codex plugin and private rollout surfaces"
```

### Task 5: Normalize remaining path drift and finish the publish-ready validation bundle

**Files:**
- Modify: `skills/systematic-debugging/root-cause-tracing.md`
- Modify: `skills/using-git-worktrees/SKILL.md`
- Delete: `skills/systematic-debugging/CREATION-LOG.md`
- Modify: `tests/codex-public-fork/run.sh` only if a missed validator command needs correction after the earlier tasks

- [ ] **Step 1: Normalize the example path in `skills/systematic-debugging/root-cause-tracing.md`**

```diff
@@
-/Users/jesse/project/packages/core
+/Users/example/project/packages/core
```

- [ ] **Step 2: Normalize the example worktree path in `skills/using-git-worktrees/SKILL.md`**

```diff
@@
-/Users/jesse/myproject/.worktrees/auth
+/Users/example/myproject/.worktrees/auth
```

- [ ] **Step 3: Delete the creation log**

Run: `rm -f skills/systematic-debugging/CREATION-LOG.md`
Expected: `skills/systematic-debugging/CREATION-LOG.md` no longer exists

- [ ] **Step 4: Run the complete validation bundle**

Run: `bash tests/codex-public-fork/run.sh`
Expected: PASS: `codex public fork validator`, `PASS: 23 validated targets`, `plugins stable true`, `PASS: codex public fork validation bundle`

- [ ] **Step 5: Run a final residual-string sweep across the public surfaces**

Run:

```bash
! rg -n 'https://github.com/obra/superpowers|https://github.com/obra/superpowers-marketplace|claude.com/plugins/superpowers|discord.gg/Jd8Vphy9jq|/Users/maxibon|maxfa-|~/.claude/skills|~/.config/opencode|CLAUDE_PLUGIN_ROOT|Gemini CLI|OpenCode' \
  README.md .codex/INSTALL.md docs/README.codex.md .github package.json CHANGELOG.md RELEASE-NOTES.md SECURITY.md .codex-plugin skills contract commands
```

Expected: no matches

- [ ] **Step 6: Verify the repo is ready for closeout**

Run:

```bash
git status --short
```

Expected: only the intended implementation diff remains before the final commit, and nothing is left untracked except deliberate new files that belong to the cutover

- [ ] **Step 7: Commit Task 5**

```bash
git add -A
git commit -m "chore: finalize codex public fork publishing cutover"
```

## Self-Review

- Spec coverage: This plan covers the native Codex plugin manifest, plugin-first install docs, fork-owned public metadata, Codex-facing skill rewrites, non-Codex/private surface removal, and the final validation bundle.
- Placeholder scan: No `TODO`, `TBD`, or undefined follow-up tasks remain in the execution steps.
- Type consistency: The plugin identifier is consistently `superpowers-codex`, the repo URL is consistently `https://github.com/MaxFabian25/superpowers`, and the validator/verification commands all point at the same public-surface contract.

## References in this plan

- `docs/superpowers/specs/2026-04-08-codex-public-fork-publishing-design.md`
- `skills/using-superpowers/references/codex-tools.md`
- `_shared/validators/validate_skill_library.py`

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-08-codex-public-fork-publishing.md`. Two execution options:

Required next step before execution: Use `superpowers:using-git-worktrees` to create the isolated workspace for this plan.

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
