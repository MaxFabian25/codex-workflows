## Why

The current Superpowers for Codex package mixes agent-readable guidance with hidden code enforcement: validators, hook scripts, package checks, shell helpers, and fixture tests decide whether contract behavior is acceptable even when the actual agent-facing instructions live in Markdown. This change plans a hard cut to a natural-language-first operating model so agents can reason directly from visible playbooks, review ledgers, and migration notes instead of reverse-engineering Python, shell, JSON manifests, or fixture harnesses.

## What Changes

- **BREAKING**: Replace validator-backed process-family and public-fork contracts with natural-language review playbooks, acceptance ledgers, and explicit reviewer signoff records.
- **BREAKING**: Replace automatic SessionStart routing as a required behavior with a manual session-start playbook unless a later implementation explicitly retains a minimal executable hook outside the natural-language cutover.
- **BREAKING**: Retire package-level validation scripts, validator target manifests, fixture harnesses, and npm script gates as acceptance authorities.
- **BREAKING**: Reclassify runtime automation scripts into either natural-language manual workflows, separate companion-plugin ownership, or retired functionality.
- Introduce a single language-contract authority tree that explains routing, dispatch, package, release, and review obligations in agent-visible prose.
- Introduce evidence ledgers that capture who reviewed which contract, what artifacts were inspected, what deviations were accepted, and what follow-up work remains.
- Introduce migration maps from existing code-backed surfaces to replacement prose playbooks so agents can complete the cutover without guessing which old invariant each file enforced.
- Preserve OpenSpec artifacts as the implementation planning authority for this change; OpenSpec validation may still be used to check this planning package before implementation starts.

## Capabilities

### New Capabilities

- `language-contract-authority`: Defines the agent-visible contract tree that replaces code-backed contract, prompt, package, and dispatch checks.
- `prose-validation-playbooks`: Defines review playbooks, evidence ledgers, and signoff records that replace validator scripts and fixture tests.
- `manual-agent-automation`: Defines manual operating playbooks and retirement decisions for hooks, helper scripts, install automation, and feature runtime scripts.
- `cutover-governance`: Defines the phased migration, acceptance policy, rollback decision points, and package/release governance for the natural-language cutover.

### Modified Capabilities

None. This repo has no pre-existing OpenSpec specs to modify.

## Impact

- Affected contract files: `contract/process-family.md`, `contract/prompt-packet.md`, `contract/package-standards.md`, `contract/runtime-surfaces.md`, process-family skill cross-references, and subagent prompt templates.
- Affected validator files: `_shared/validators/validate_skill_library.py`, `_shared/validators/validate_codex_public_fork.py`, `_shared/validators/process_family_targets.txt`, `tests/codex-public-fork/run.sh`, and package validation scripts.
- Affected automation files: `hooks/hooks.json`, `hooks/session-start`, `skills/brainstorming/scripts/*`, `skills/writing-plans/references/validate_execplan.py`, package scripts, install docs, and already-deleted legacy `commands/*` and `scripts/*` surfaces in the dirty worktree.
- Affected documentation: `README.md`, `.codex/INSTALL.md`, `docs/README.codex.md`, `.github/PULL_REQUEST_TEMPLATE.md`, historical plans/specs that future agents might treat as authority, and any runtime-copy or marketplace sync instructions.
- Affected release behavior: npm package contents, plugin manifest hook declaration, plugin default prompt guidance, public-fork acceptance, and local marketplace/cache parity expectations.
