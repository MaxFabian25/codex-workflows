# Public Fork Playbook

This playbook defines public-fork review authority. Validator output, fixture harnesses, package inspection, and path checks are evidence unless a future change explicitly declares a bounded code-gated authority.

## Required Public Surfaces

Review these files before public release:

- `.codex-plugin/plugin.json`
- `hooks/hooks.json`
- `hooks/session-start`
- `assets/app-icon.png`
- `assets/codex-workflows-small.svg`
- `README.md`
- `.codex/INSTALL.md`
- `docs/README.codex.md`
- `docs/language-contracts/`
- `SECURITY.md`
- `CODE_OF_CONDUCT.md`
- `package.json`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `CHANGELOG.md`
- `RELEASE-NOTES.md`

## Removed Or Out-Of-Scope Surfaces

These paths should not be restored as part of this package:

- `.claude-plugin`
- `.cursor-plugin`
- `.opencode`
- `hooks/hooks-cursor.json`
- `hooks/run-hook.cmd`
- `.github/ISSUE_TEMPLATE/platform_support.md`
- `docs/README.opencode.md`
- `GEMINI.md`
- `gemini-extension.json`
- `scripts/install_cmux_superpowers_launcher.py`
- `scripts/cmux_superpowers_team.py`
- `scripts/install_codex_hooks.py`
- `scripts/validate_codex_public_fork.py`
- `_shared/validators/validate_skill_library.py`
- `_shared/validators/process_family_targets.txt`
- `tests/cmux-superpowers/`
- `tests/codex-public-fork/`
- `tests/subagent-driven-dev/`
- `commands/brainstorm.md`
- `commands/write-plan.md`
- `commands/execute-plan.md`

## Final Dispositions

These surfaces have current package decisions:

- Native SessionStart hook files are retained lightweight adapters.
- User-level hook installer, public-fork validator, process validator, and fixture harnesses are accepted retirements.
- Package metadata/path evidence comes from `npm pack --dry-run --json`, manifest inspection, docs inspection, focused searches, and ledger review.

## Wording Review

Public docs should use Codex-only wording. Watch for:

- upstream or private marketplace URLs presented as this fork's support path;
- non-Codex runtime names presented as active package surfaces;
- user-specific workstation paths;
- old hook bootstrap wording;
- old `superpowers:` namespace in live instructions;
- claims that cmux launcher behavior is included in this package.

Historical archive docs may mention old behavior when clearly non-authoritative.

## Issue, Security, And Conduct Review

- Bug reports ask for Codex Workflows version, Codex version, model, OS, shell, reproduction steps, and transcript or log evidence.
- Feature requests ask for problem, proposed solution, alternatives, and whether the request belongs in core Codex Workflows.
- Security and conduct reporting use the private GitHub Security Advisories route until a dedicated private channel exists.
- Pull requests require language-contract ledger links when they change behavior-shaping content.

## Review Checklist

- Required surfaces exist.
- Accepted-retirement surfaces stay removed.
- No conditional or unresolved surfaces remain in the public-fork review set.
- Package metadata and plugin metadata agree.
- Public docs do not promise absent validators or launcher automation as active features.
- Public docs describe the native SessionStart hook adapter and manual router fallback.
- The package payload excludes hidden human-facing decision gates and includes retained runtime only when documented.
- Release notes document breaking automation and validation changes.
- The final ledger entry states whether public-fork release is ready.
