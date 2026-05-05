# Superpowers Release Notes

## 5.0.6-codex.1

Highlights:

- Native `.codex-plugin/plugin.json` packaging for Codex.
- Codex-only installation and workflow documentation.
- Fork-owned issue tracking, security reporting, and release metadata.
- Published release metadata for the in-progress Codex-only fork transition.
- Natural-Language Agent Harness artifacts under `docs/language-contracts/`.
- Manual review ledgers decide human-facing statuses, while retained tools and checks provide evidence or explicit code-gated authority.

Breaking behavior changes:

- Prior broad prose-only retirement claims are superseded by the Natural-Language Agent Harness boundary.
- Native SessionStart routing is restored as a lightweight adapter to the playbook contract; manual router invocation remains the fallback.
- cmux launcher automation is outside this core package unless a companion package explicitly owns it.
- Visual brainstorming browser runtime and useful helper scripts are retained when classified as feature runtime, deterministic mechanics, or evidence providers.
- User-level hook installer, old validators, public-fork fixture harness, and stale subagent-driven-dev fixtures are accepted retirements under the runtime automation playbook.
- Executable helper scripts are evidence, deterministic mechanics, feature runtime, safety checks, or explicit code authority by classification; they are not removed merely because they are executable.

Upstream lineage:

This fork derives from `obra/superpowers`, but the public runtime and documentation contract is now Codex-only.
