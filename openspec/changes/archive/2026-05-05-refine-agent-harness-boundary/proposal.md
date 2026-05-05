## Why

The archived `replace-code-contracts-with-language-playbooks` change over-corrected: it frames the package as an absolute prose-only authority and encourages deleting validators, hooks, runtime helpers, tests, and feature scripts as a class. The research-backed correction is narrower and more useful: make the repo's agent-computer interface explicit, keep context files minimal, and move only human-facing orchestration authority into natural-language harness artifacts while deterministic mechanics remain in code.

## What Changes

- **BREAKING correction to the prior plan**: Replace the broad "convert code gates and automation to prose" framing with a Natural-Language Agent Harness boundary.
- Keep natural-language artifacts for human-facing workflow authority: charters, scoped instructions, specs, playbooks, runbooks, ledgers, ADRs, postmortems, and closeout records.
- Retain code when it performs deterministic mechanics: parsing, adapters, builds, tests, migrations, formatters, safety checks, reproducible calculations, low-level malformed-input validation, unsafe-write prevention, and real feature runtime.
- Add a minimal-context rule for `AGENTS.md` and instruction files: scoped, short, requirement-only, and free of duplicate broad advice.
- Treat commands, scripts, tests, CI, generated manifests, hashes, and helper dry-runs as evidence by default, not silent authority for human-facing readiness, unless the repo explicitly declares a code-gated authority.
- Add observe-act-feedback loops, failure ledgers, explicit tool contracts, protected-scope boundaries, and parallel-agent constraints.
- Update existing language-contract docs and specs so they stop claiming absolute prose-only readiness.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-contract-authority`: Narrow from "natural-language contract tree replaces scripts/validators/tests" to "minimal natural-language harness artifacts define human-facing orchestration authority and front-door routing."
- `prose-validation-playbooks`: Narrow from "ledgers replace validator output" to "ledgers decide human-facing statuses; tools and deterministic checks supply evidence or explicit code-gated authority."
- `manual-agent-automation`: Narrow from "automation has a manual replacement" to "scripts/tests/tools are classified as agent-computer interface contracts, deterministic mechanics, evidence providers, or human-facing decision gates before any deletion."
- `cutover-governance`: Narrow from "absolute prose-only cutover ready" to "repo adaptation is complete only when a new agent can identify authority, protected scopes, evidence roles, retained code gates, blocker records, verification, and handoff without hidden policy."

## Impact

- Affected OpenSpec specs: `openspec/specs/language-contract-authority/spec.md`, `openspec/specs/prose-validation-playbooks/spec.md`, `openspec/specs/manual-agent-automation/spec.md`, and `openspec/specs/cutover-governance/spec.md`.
- Affected language-contract docs: `docs/language-contracts/README.md`, `session-router-playbook.md`, `runtime-automation-playbook.md`, `package-and-release-playbook.md`, `process-family-playbook.md`, `legacy-code-gate-map.md`, `retired-automation-register.md`, and `cutover-ledger.md`.
- Affected front doors if implemented fully: `README.md`, `docs/README.codex.md`, `.codex/INSTALL.md`, `.codex-plugin/plugin.json`, package metadata, and any scoped instruction files.
- Existing broad deletion state remains a historical worktree fact for several surfaces. This change restores deterministic mechanics and the native SessionStart adapter where the refined policy supports retention, and records accepted retirement for old validators, the user-level hook installer, public-fork fixture harness, and stale subagent-driven-dev fixtures.
