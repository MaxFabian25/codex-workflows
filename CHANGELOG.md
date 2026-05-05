# Changelog

All notable changes to the Codex-only fork are documented here.

## Unreleased

- Repository preparation for public publishing as a native Codex plugin fork.
- Corrected the broad prose-only cutover into a Natural-Language Agent Harness
  boundary: human-facing orchestration authority lives in scoped harness
  artifacts, while deterministic mechanics and explicit tool interfaces stay in
  code when code is the right tool.
- Restored the native SessionStart hook as a lightweight adapter whose source
  of truth remains `docs/language-contracts/session-router-playbook.md`.
- Restored or retained feature/runtime and helper surfaces where they provide
  deterministic behavior or evidence; accepted retirement for the user-level
  hook installer, old validators, public-fork fixture harness, and stale
  subagent-driven-dev fixtures.

## 5.0.6-codex.1 - 2026-04-08

- Added `.codex-plugin/plugin.json` for native Codex plugin packaging.
- Rewrote public documentation and release metadata to the Codex-only fork contract.
- Rewrote the published release metadata for the in-progress Codex-only fork transition.
