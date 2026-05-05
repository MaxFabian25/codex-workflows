## ADDED Requirements

### Requirement: Validator replacement playbooks exist
The package SHALL replace each retired validator or fixture harness with a natural-language playbook that describes how to inspect the same behavior manually.

#### Scenario: Process-family validator is retired
- **WHEN** the process-family validator is removed
- **THEN** the replacement playbook covers target inventory, skill discovery text, prompt packet shape, child no-elicitation behavior, root-owned decision behavior, stale dispatch formats, cross-references, and stale artifact review

#### Scenario: Public-fork validator is retired
- **WHEN** the public-fork validator is removed
- **THEN** the replacement playbook covers required paths, removed paths, package metadata, package payload, manifest fields, hook policy, install docs, release docs, issue templates, security policy, conduct policy, and forbidden private or non-Codex wording

### Requirement: Evidence ledgers replace command transcripts
The package SHALL require Markdown evidence ledgers where validator command transcripts were previously used as acceptance proof.

#### Scenario: Reviewer completes a manual gate
- **WHEN** a reviewer finishes a manual contract, package, or runtime review
- **THEN** the reviewer records inspected files, old code gate replaced, evidence notes, accepted deviations, runtime losses, follow-up tasks, and a ready or not-ready conclusion

#### Scenario: Pull request references verification
- **WHEN** a change description would previously cite `npm run validate:process-family` or `npm run validate:public-fork`
- **THEN** it cites the relevant evidence ledger entries instead

### Requirement: Manual checks preserve explicit acceptance decisions
The package SHALL require reviewers to state whether each old machine-enforced invariant is retained, changed, or removed.

#### Scenario: Invariant is changed
- **WHEN** an old validator rule is intentionally weakened or removed
- **THEN** the ledger states the rationale and records the risk accepted by the change

#### Scenario: Invariant is retained
- **WHEN** an old validator rule remains important
- **THEN** the replacement playbook expresses it as a direct prose checklist item

### Requirement: Search may assist but not decide
The package SHALL permit basic repository search and diff inspection as evidence-gathering aids while keeping the written playbook and ledger as the final acceptance authority.

#### Scenario: Reviewer searches for stale references
- **WHEN** a reviewer uses `rg`, `git diff`, or `git status` to inspect the tree
- **THEN** the result is summarized in the ledger and the acceptance decision remains a prose judgment
