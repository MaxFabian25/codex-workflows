# Package And Release Playbook

This playbook defines package/release authority and evidence roles. Package tooling may inspect payloads, run tests, or produce manifests, but human-facing release readiness lives in ledgers unless an explicit code-gated authority is declared.

## Package Identity

Manual package review reads `package.json` and `.codex-plugin/plugin.json` directly. Expected identity for this release line:

- npm package name: `@maximilianfabiankirchner/codex-workflows`;
- version: `6.0.6`;
- type: `module`;
- license: `MIT`;
- repository, homepage, and issues point to `https://github.com/MaxFabian25/codex-workflows`;
- Codex plugin manifest name is `codex-workflows`;
- plugin display name is `Codex Workflows`;
- skill root is `./skills/`.

## Shipped Files

The npm payload should ship only the package surfaces needed by users and agents:

- `skills/`
- `contract/`
- `assets/`
- `hooks/`
- `README.md`
- `LICENSE`
- `SECURITY.md`
- `CODE_OF_CONDUCT.md`
- `CHANGELOG.md`
- `RELEASE-NOTES.md`
- `package.json`
- `.codex-plugin/plugin.json`
- `.codex/INSTALL.md`
- `docs/README.codex.md`
- `docs/language-contracts/`

It should not ship hidden human-facing decision gates. It may ship tests, scripts, hooks, validators, or runtime helpers when they are classified as deterministic mechanics, implementation safety, evidence providers, feature runtime, lightweight adapters, or explicit code-gated authority.

For this release line, package payload review expects:

- include `hooks/hooks.json` and `hooks/session-start`;
- exclude `_shared/`;
- exclude `scripts/install_codex_hooks.py` and `scripts/validate_codex_public_fork.py`;
- exclude `tests/codex-public-fork/`, `tests/subagent-driven-dev/`, and `tests/cmux-superpowers/`.

Repository-only tests may remain outside the npm payload when they are useful verification evidence but not user-facing package content.

## Manual Npm Payload Review

Use package tooling only as an inspection aid:

```bash
npm pack --dry-run --json
```

Record in the ledger:

- command used;
- package files that matter;
- unexpected included or missing paths;
- reviewer decision.

Do not let this command silently decide human-facing release readiness. The ledger conclusion is the human-facing acceptance record unless the repo explicitly declares package inspection as a code-gated authority.

## Release Documentation

Before release:

- `CHANGELOG.md` documents breaking changes under `Unreleased` or the target version.
- `RELEASE-NOTES.md` explains the behavior users lose or must perform manually.
- The README and install docs link to `docs/language-contracts/`.
- Any local marketplace/cache sync is described as a manual release step.

## Local Marketplace And Cache Sync

When testing a local plugin build on this workstation:

1. Update the source checkout.
2. Update or reinstall the local marketplace registration if the path changed.
3. Restart Codex so a fresh session reads the updated package.
4. If a runtime cache copy must be refreshed, sync it manually and record the source path, destination path, and observed version or checksum in the ledger.

No sync script is part of this package contract.

## Review Checklist

- `package.json` has no validator scripts that silently decide human-facing readiness.
- Any `validate:*` script that remains has a documented role: deterministic safety, evidence provider, or explicit code-gated authority.
- `package.json.files` includes only surfaces with a documented package role.
- `.codex-plugin/plugin.json` has a `hooks` field only when the hook is an explicit lightweight adapter.
- Manifest UI metadata references only shipped assets.
- README, install docs, changelog, and release notes agree on the native SessionStart adapter, manual fallback, retained runtime, and retired automation.
- Public issue and conduct surfaces remain present and Codex-oriented.
