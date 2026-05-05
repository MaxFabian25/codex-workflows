# Natural-Language Agent Harness

This directory defines the human-facing harness authority and agent-computer interface for Superpowers for Codex.

Agents and reviewers should be able to understand human-facing workflow authority by reading small, scoped harness artifacts. This does not mean every executable mechanic should be replaced with prose. Parsers, adapters, builds, tests, migrations, formatters, safety checks, reproducible calculations, low-level malformed-input validation, unsafe-write prevention, and real feature runtime should remain in code when code is the right tool.

Search, diff, package inspection, scripts, tests, hashes, generated manifests, and CI may be used as evidence. They decide human-facing states only when the repo explicitly declares them as code-gated authority.

## Authority Order

1. System, developer, user, and repo instructions still outrank this package.
2. These harness artifacts define Superpowers human-facing workflow authority.
3. Deterministic mechanics and safety checks remain authoritative for the behavior they implement.
4. `contract/*.md` files are compatibility pointers to these playbooks.
5. Historical plans and specs under `docs/plans/` and `docs/superpowers/` are archived context, not live acceptance rules.

## Playbooks

- [Harness Charter](harness-charter.md) defines the Natural-Language Agent Harness boundary.
- [Session Router Playbook](session-router-playbook.md) covers manual session-start routing.
- [Process Family Playbook](process-family-playbook.md) covers lifecycle ownership and root-owned elicitation.
- [Prompt Packet Playbook](prompt-packet-playbook.md) covers subagent dispatch packets and child handoffs.
- [Package And Release Playbook](package-and-release-playbook.md) covers package metadata, shipped files, changelog, npm payload review, and local marketplace/cache sync.
- [Public Fork Playbook](public-fork-playbook.md) covers public-path, issue-template, conduct, security, and public wording review.
- [Runtime Automation Playbook](runtime-automation-playbook.md) classifies hooks, helpers, tests, validators, package tasks, feature runtime, and companion ownership.

## Ledgers And Registers

- [Review Ledger Template](review-ledger-template.md) defines the evidence record for manual review.
- [Cutover Ledger](cutover-ledger.md) records historical cutover evidence plus current superseding boundary notes.
- [Legacy Code Gate Map](legacy-code-gate-map.md) maps old executable gates to refined dispositions.
- [Retired Automation Register](retired-automation-register.md) records removed, retained, demoted, moved, and unresolved automation surfaces.

## Minimal Context Rule

Keep `AGENTS.md`, skill frontmatter, and scoped instruction files short, scoped, and requirement-only. Do not paste broad workflow essays into every context file. Front doors should point to the smallest relevant harness artifact.

## Review Rule

For any future behavior-shaping change:

1. Identify the affected harness artifact.
2. Classify each tool, script, test, validator, hook, or helper as deterministic mechanic, implementation safety, evidence provider, explicit code authority, human-facing orchestration policy, historical record, or unresolved blocker.
3. Move only hidden human-facing orchestration policy into prose.
4. Record evidence and failures in a ledger entry.
5. Update front-door docs only after the harness artifact is coherent.

Do not recreate validators as compatibility shims. Restore or retain code only when it owns deterministic mechanics, safety, feature runtime, or an explicitly chosen code-gated authority.
