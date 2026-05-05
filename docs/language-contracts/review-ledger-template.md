# Review Ledger Template

Copy this template into `cutover-ledger.md` or a future change-specific ledger when reviewing behavior-shaping package changes.

```md
## Review Entry: <short scope>

- Date:
- Reviewer:
- Scope:
- Files inspected:
- Old code gate or automation surface:
- Replacement prose:
- Classification:
- Tool/evidence role:
- Retained code authority:
- Invariants retained:
- Invariants changed:
- Invariants removed:
- Accepted deviations:
- Failing command or observation:
- Likely cause:
- Next smallest probe:
- Stop condition:
- Human input needed:
- Runtime behavior lost:
- Runtime behavior moved:
- Runtime behavior retained as exception:
- Search or inspection evidence:
- Follow-up tasks:
- Readiness conclusion: Ready | Not ready
- Rationale:
```

## Field Guidance

- `Scope` names the phase or surface being reviewed.
- `Files inspected` should include both changed files and old gates that informed the prose.
- `Classification` uses the categories from `runtime-automation-playbook.md`.
- `Tool/evidence role` states whether commands, scripts, tests, manifests, hashes, or dry-runs are evidence only, deterministic safety, feature runtime, or explicit code authority.
- Failure fields may be `none` when no failure occurred.
- `Runtime behavior lost` must be explicit when prose replaces code that previously executed.
- `Readiness conclusion` is the human-facing acceptance record. Cite tool output as evidence, not as a hidden replacement for reviewer judgment unless explicit code authority is declared.
