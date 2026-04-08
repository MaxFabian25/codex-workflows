# Codex-Only Public Fork Publishing Design

Date: 2026-04-08
Status: Approved design for implementation planning

## Summary

Prepare this repository for public publishing as a Codex-only fork of `obra/superpowers`.

The public contract must become:

- Codex-first and Codex-only
- native Codex plugin first where feasible
- fork-owned across docs, metadata, support, and release surfaces
- free of personal workstation rollout material and private operator topology

This is a hard cutover. Public users should not be routed to upstream install paths, Claude/OpenCode/Gemini-first workflows, or workstation-local instructions.

## Goals

- Publish a fork that clearly identifies itself as a Codex-specific derivative of `obra/superpowers`.
- Make the public installation and runtime story native to Codex CLI's plugin capabilities if the current runtime supports that path.
- Remove personal operator material and workstation-specific rollout artifacts from the public branch.
- Keep the Codex-facing process-family skill library coherent and validated after the cutover.

## Non-Goals

- Preserve multi-platform parity with Claude Code, Cursor, OpenCode, or Gemini.
- Keep personal workstation automation in the public repo.
- Publish a mixed “compatibility umbrella” repo that still treats non-Codex platforms as first-class.
- Implement the publishing cutover in this design phase.

## Current-State Findings

The current repo is not public-ready as a Codex-specific fork.

### Public surface mismatches

- `README.md` still presents upstream ownership, upstream sponsorship, upstream support/community links, and upstream install paths.
- `docs/README.codex.md` and `.codex/INSTALL.md` still route users through native skill discovery and local symlink setup instead of a native Codex plugin-first path.
- `.github/FUNDING.yml`, `.github/ISSUE_TEMPLATE/config.yml`, and `CODE_OF_CONDUCT.md` still delegate public ownership or community operations to upstream surfaces.
- `CHANGELOG.md` and `RELEASE-NOTES.md` still read as inherited upstream release surfaces rather than fork-scoped history.

### Runtime and branding mismatches

- `hooks/session-start` and several skill/docs surfaces still assume Claude-first runtime behavior.
- `skills/using-superpowers/SKILL.md` and `skills/writing-skills/*` still contain Claude/Anthropic-primary guidance that would mis-train contributors in a Codex-only fork.
- The current Codex install docs frame the repo as a workstation-specific setup rather than a public plugin distribution.

### Private/operator leakage

- `docs/superpowers/plans/2026-04-06-codex-cli-subagent-setup.md`
- `docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md`
- `scripts/sync_process_family_to_maxfa_wsl.sh`

These contain workstation-local paths, personal runtime topology, hostnames, or rollout-specific evidence that should not remain in the public branch.

## Design Decisions

## 1. Repo identity

This repo becomes a Codex-only public fork.

- Root messaging changes from multi-platform Superpowers to Codex-specific Superpowers.
- Public docs may acknowledge upstream origin, but the active runtime and support contract belongs to the fork.
- Codex becomes the normative runtime target for install docs, skill routing, and contributor guidance.

## 2. Installation contract

The public install story becomes native Codex plugin first where feasible.

- The repo should expose a real Codex plugin surface centered on `.codex-plugin/plugin.json`.
- `README.md`, `.codex/INSTALL.md`, and `docs/README.codex.md` should all describe the same plugin-first install/update path.
- Symlink-based native skill discovery is no longer the public default contract.
- If a fallback path must exist for development or older environments, it must be clearly secondary and not the first public recommendation.

## 3. Platform boundary

The public branch will be Codex-only.

- Remove non-Codex public install/runtime surfaces such as `.claude-plugin/`, `.cursor-plugin/`, `.opencode/`, `docs/README.opencode.md`, `GEMINI.md`, and unrelated platform-specific tests/docs unless a retained file is strictly required to support the Codex plugin implementation.
- Remove docs that define Codex as having no plugin system or otherwise contradict the new plugin-first contract.
- Keep only the Codex-facing skill, contract, and validation surfaces needed for this fork.

## 4. Private material policy

Personal/operator materials are removed from the public branch.

- Delete workstation rollout plans/specs that hardcode `/Users/maxibon`, `maxfa-*`, `.worktrees/...`, or local config evidence.
- Delete one-off sync scripts and infrastructure helpers tied to the maintainer’s machines.
- Normalize remaining examples that still contain personal paths or upstream contributor home directories.

## 5. Public metadata ownership

Public GitHub/repo surfaces become fork-owned or are intentionally removed.

- Rewrite funding, issue/contact links, support paths, contributing references, package metadata, and code-of-conduct enforcement contacts.
- Add missing public repo surfaces such as `SECURITY.md` if the fork will accept public issue/security traffic.
- Preserve upstream license attribution under MIT; do not erase upstream attribution from `LICENSE`.
- If inherited release history remains, label it explicitly as inherited upstream history rather than presenting it as fork-native.

## File Actions

## Delete from the public branch

- `docs/superpowers/plans/2026-04-06-codex-cli-subagent-setup.md`
- `docs/superpowers/specs/2026-04-06-codex-cli-subagent-setup-design.md`
- `scripts/sync_process_family_to_maxfa_wsl.sh`
- `.claude-plugin/`
- `.cursor-plugin/`
- `.opencode/`
- `docs/README.opencode.md`
- `GEMINI.md`
- `gemini-extension.json`
- Claude/OpenCode/Gemini-specific tests and docs that do not validate the Codex public contract

## Rewrite for the public Codex fork

- `README.md`
- `.codex/INSTALL.md`
- `docs/README.codex.md`
- `hooks/session-start` if it remains part of the Codex runtime
- `skills/using-superpowers/SKILL.md`
- `skills/writing-skills/SKILL.md`
- `skills/writing-skills/anthropic-best-practices.md` or its replacement/removal path
- `.github/FUNDING.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `CODE_OF_CONDUCT.md`
- `CHANGELOG.md`
- `RELEASE-NOTES.md`
- public examples containing maintainer-local paths or upstream-personal examples

## Add

- `.codex-plugin/plugin.json`
- `SECURITY.md`
- any minimal fork-owned plugin metadata or validation assets needed to support Codex CLI native plugins cleanly

## Keep, but normalize

- Codex-facing process-family contracts under `contract/`
- Codex-adapted skill content under `skills/`
- repo validators that still apply to the public Codex library

## Verification Gates

The public-first publishing surfaces are not ready until all of the following pass.

## 1. Public surface purity

- No public-first install, package, validation, or governance surface contains maintainer workstation paths, `maxfa-*` hostnames, stale worktree references, or private rollout evidence.
- No public install or support path points to `obra/superpowers`, upstream Discord/community, or upstream-only marketplace flows.

## 2. Codex plugin coherence

- `.codex-plugin/plugin.json` exists and matches the documented install/update/runtime flow.
- `README.md`, `.codex/INSTALL.md`, and `docs/README.codex.md` all describe the same Codex-first install path.
- The repo no longer describes symlink-only native skill discovery as the public default.

## 3. Metadata readiness

- GitHub/community/support files are fork-owned and non-deceptive.
- Package/repo metadata describes the fork accurately.
- Inherited upstream history is either removed from active release surfaces or explicitly labeled as inherited.

## 4. Validation bundle

- Run deterministic scans for public-first repo and package surfaces covering:
  - `obra/superpowers`
  - upstream community/support URLs
  - `Claude Code`, `Anthropic`, and removed-platform leftovers in public-first surfaces
  - `/Users/maxibon`, `maxfa-`, `.worktrees/`, and other private operator markers
- Run the process-family validator after the cutover to confirm the Codex-facing skill library still passes.
- Add and run one targeted validation check for the new Codex plugin surface so the plugin contract is not documentation-only.
- Require clean `git status` at the end of the publishing-prep branch.

## Risks And Mitigations

## Risk: Partial cutover leaves mixed public contract

Mitigation:
- Treat docs, metadata, runtime entrypoints, and GitHub/community files as one contract surface.
- Do not publish after metadata-only edits if runtime/docs still contradict them.

## Risk: Codex plugin support exists in runtime but is only partially understood in-repo

Mitigation:
- Validate the live Codex CLI surface directly during implementation planning.
- Prefer a minimal native plugin implementation that can be verified end to end over speculative plugin complexity.

## Risk: Useful Codex content is entangled with workstation-private docs

Mitigation:
- Extract reusable Codex guidance into public docs before deleting operator-specific files.
- Do not keep private rollout artifacts in public just because they contain some useful text.

## Acceptance Criteria

This design is successful when:

- the public repo reads as a Codex-only fork on first contact;
- the install path is plugin-first and fork-owned;
- no public surface depends on upstream support/install/community routing;
- no personal operator material remains in the public branch;
- the Codex-facing skill/contract library still validates after the cutover.
