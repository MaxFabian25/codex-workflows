## ADDED Requirements

### Requirement: Cutover proceeds in reviewable phases
The package SHALL migrate from code-backed gates to natural-language alternatives in phases that preserve traceability and avoid mixing unrelated dirty-worktree edits into the cutover.

#### Scenario: Implementation begins
- **WHEN** the implementation phase starts
- **THEN** it records the current worktree state, identifies unrelated existing edits, and limits each change slice to a documented part of the cutover

#### Scenario: Phase completes
- **WHEN** a phase retires a code gate or automation surface
- **THEN** the implementation updates the migration map, relevant playbook, and evidence ledger before moving to the next phase

### Requirement: Breaking changes are documented
The package SHALL document every loss of automatic validation, runtime hook behavior, package validation, feature runtime, or compatibility alias as a breaking change.

#### Scenario: Validator command is removed
- **WHEN** a package script or validator command is removed
- **THEN** changelog or release notes explain that acceptance now depends on natural-language playbooks and ledgers

#### Scenario: Hook behavior is removed
- **WHEN** automatic session-router injection is removed
- **THEN** changelog or release notes explain that users or agents must apply the manual session-start workflow

### Requirement: Rollback is decision-based
The package SHALL define rollback decisions in prose instead of hidden scripts.

#### Scenario: Manual cutover fails review
- **WHEN** reviewers cannot confidently accept a prose replacement for a high-risk gate
- **THEN** the ledger marks the phase not ready and lists whether to restore the old code gate, keep a minimal exception, or narrow scope

#### Scenario: Runtime feature loss is unacceptable
- **WHEN** a user-facing runtime feature cannot be retired
- **THEN** the runtime playbook marks it as a retained exception or moves it to a companion package plan

### Requirement: Final acceptance is ledger-backed
The package SHALL require final acceptance to cite completed evidence ledgers rather than validator output.

#### Scenario: Cutover is ready
- **WHEN** all code-backed gates in scope have prose replacements, retired entries, or companion-owner entries
- **THEN** the cutover ledger states that the natural-language authority is complete and identifies remaining risks

#### Scenario: Cutover is incomplete
- **WHEN** any old gate lacks a prose successor or accepted retirement entry
- **THEN** the cutover ledger states that implementation is not ready and names the blocking surface
