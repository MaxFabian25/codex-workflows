# Changelog

All notable changes to the Codex-only fork are documented here.

## Unreleased

## 6.0.6 - 2026-05-05

- Rebranded the live package, plugin, and skill namespace to Codex Workflows:
  `@maximilianfabiankirchner/codex-workflows`, `codex-workflows`, and
  `codex-workflows:session-router`.
- Updated public repository metadata for the `MaxFabian25/codex-workflows`
  GitHub repository rename.
- Renamed the session router skill directory from `skills/using-superpowers/`
  to `skills/session-router/`.
- Renamed current brainstorming runtime storage from `.superpowers/` to
  `.codex-workflows/`.
- Moved old `docs/superpowers/` plans and specs under `docs/archive/superpowers/`
  as historical records.
- Planned deprecation for the old
  `@maximilianfabiankirchner/superpowers-codex@6.0.5` package after the new
  package verifies.

## 6.0.5 - 2026-05-05

- Moved the npm package identity to
  `@maximilianfabiankirchner/superpowers-codex` for publication from the
  `maximilianfabiankirchner` npm account.
- Kept the Codex plugin manifest name and skill namespace as
  `superpowers-codex`, so installed skill references such as
  `superpowers-codex:using-superpowers` remain stable.
- Preserved the `v6.0.4` GitHub tag and release as historical metadata for the
  unscoped package publication attempt.

## 6.0.4 - 2026-05-05

- Normalized npm package repository metadata to the structured git repository
  form before public npm publication.
- Preserved the `v6.0.3` GitHub tag and release as historical release
  metadata; npm publication continues from this metadata-correct patch line.

## 6.0.3 - 2026-05-05

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
