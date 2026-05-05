## MODIFIED Requirements

### Requirement: Cutover proceeds in reviewable phases
The package SHALL adapt to the Natural-Language Agent Harness pattern in reviewable phases that preserve history, protect deterministic mechanics, and avoid mixing unrelated dirty-worktree edits into the correction.

#### Scenario: Implementation begins
- **WHEN** the implementation phase starts
- **THEN** it records current state, existing deletions, writable scopes, protected scopes, canonical outputs, external systems, verification surfaces, and instruction precedence

#### Scenario: Phase completes
- **WHEN** a phase changes a tool, script, validator, hook, test, spec, or instruction surface
- **THEN** the implementation updates the relevant harness artifact, evidence ledger, and disposition record before moving to the next phase

### Requirement: Breaking changes are documented
The package SHALL document every loss of automatic validation, runtime hook behavior, package validation, feature runtime, compatibility alias, or deterministic safety mechanism as a breaking change, accepted retirement, retained adapter, or unresolved blocker.

#### Scenario: Validator command is removed
- **WHEN** a package script or validator command is removed
- **THEN** changelog or release notes explain whether acceptance now depends on ledgers, whether deterministic safety moved elsewhere, and whether any code-gated authority remains

#### Scenario: Hook behavior is removed
- **WHEN** automatic session-router injection is removed
- **THEN** changelog or release notes explain that users or agents must apply the manual session-start workflow and identify the adapter behavior that was lost

### Requirement: Final acceptance is ledger-backed
The package SHALL require final acceptance to cite completed evidence ledgers and explicit retained-code authority decisions.

#### Scenario: Adaptation is ready
- **WHEN** all surfaces in scope have a disposition of retained deterministic mechanic, retained safety, evidence provider, explicit code authority, prose-controlled human decision, historical record, or accepted retirement
- **THEN** the closeout ledger states that the Natural-Language Agent Harness adaptation is complete and identifies remaining risks

#### Scenario: Adaptation is incomplete
- **WHEN** any surface lacks a disposition or a deleted deterministic mechanic lacks accepted rationale
- **THEN** the closeout ledger states that implementation is not ready and names the blocking surface

## ADDED Requirements

### Requirement: Historical evidence is preserved
The package SHALL preserve old evidence, archived specs, changelogs, prior validator output, and postmortems as historical records unless they contain sensitive material that must be removed for another policy reason.

#### Scenario: Historical doc has stale workflow
- **WHEN** an archived plan or spec mentions old validators, hooks, or command gates
- **THEN** the implementation adds or relies on a current boundary note instead of rewriting the historical record to erase the old workflow

#### Scenario: Current doc conflicts with history
- **WHEN** a live front door conflicts with archived historical evidence
- **THEN** the live front door names the current authority and the historical file remains archive context

### Requirement: Parallel-agent policy is narrow
The harness SHALL define a read-only default for parallel agents and prohibit broad duplicate investigation lanes.

#### Scenario: Parent uses parallel agents
- **WHEN** parallel agents are dispatched
- **THEN** each child receives one narrow question, stays read-only unless explicitly assigned non-overlapping write ownership, returns cited evidence, and leaves synthesis to the parent
