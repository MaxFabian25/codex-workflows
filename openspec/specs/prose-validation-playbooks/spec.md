# prose-validation-playbooks Specification

## Purpose
Define manual review playbooks, evidence ledgers, failure ledgers, and signoff expectations that separate human-facing decision authority from deterministic validation, implementation safety, and tool evidence.
## Requirements
### Requirement: Validator replacement playbooks exist
The package SHALL replace hidden human-facing decision policy with natural-language playbooks while retaining deterministic validation, implementation safety checks, and explicit code-gated authority when the repo deliberately chooses those roles.

#### Scenario: Human-facing validator is demoted
- **WHEN** a validator decides readiness, currentness, promotion, release, deployment, handoff, or other human-facing status
- **THEN** the replacement playbook defines the human decision and records supporting tool evidence in a ledger

#### Scenario: Safety validator is retained
- **WHEN** a validator prevents malformed inputs, missing files, unsafe paths, destructive writes, invalid migrations, credential leakage, production data corruption, or unsafe external side effects
- **THEN** the validator remains in code unless a separate explicit product decision replaces it with an equally safe mechanism

### Requirement: Evidence ledgers replace command transcripts
The package SHALL use Markdown evidence ledgers to decide human-facing statuses while preserving command transcripts, test output, hashes, manifests, and dry-runs as supporting observations.

#### Scenario: Reviewer completes a manual gate
- **WHEN** a reviewer finishes a manual contract, package, or runtime review
- **THEN** the reviewer records inspected files, commands or observations, old policy surface, replacement prose, retained code authority, accepted deviations, blockers, caveats, and a ready or not-ready conclusion

#### Scenario: Pull request references verification
- **WHEN** a change description references tests, CI, scripts, hashes, generated manifests, or helper dry-runs
- **THEN** it states whether each result is evidence, deterministic safety, or explicit code-gated authority

### Requirement: Search may assist but not decide
The package SHALL permit repository search, diff inspection, tests, package inspection, and focused commands as evidence-gathering aids while keeping the declared authority role explicit.

#### Scenario: Reviewer searches for stale references
- **WHEN** a reviewer uses `rg`, `git diff`, `git status`, tests, or package tooling to inspect the tree
- **THEN** the result is summarized in the ledger and the reviewer states whether the command is evidence only or an authoritative gate

### Requirement: Failure ledgers capture feedback loops
Major harness workflows SHALL include a short failure ledger when a command, observation, or manual review fails.

#### Scenario: Evidence check fails
- **WHEN** a check or observation fails during adaptation
- **THEN** the ledger records the failing command or observation, relevant files, likely cause, next smallest probe, stop condition, and whether human input is needed

#### Scenario: Failure is non-blocking
- **WHEN** a failed observation is classified as a caveat or non-issue
- **THEN** the ledger records why it does not block the current recommendation
