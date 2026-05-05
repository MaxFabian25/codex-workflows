## ADDED Requirements

### Requirement: Natural-language contract tree is authoritative
The package SHALL provide a natural-language contract authority that agents can read directly without executing repository-specific validators, tests, or scripts.

#### Scenario: Agent starts contract review
- **WHEN** an agent needs to understand routing, dispatch, package, release, or review obligations
- **THEN** the agent can find the governing instructions through the documented language-contract authority tree

#### Scenario: Old code gate has successor
- **WHEN** a validator, target manifest, fixture test, hook script, install script, or automation helper is removed
- **THEN** the contract authority identifies the replacement prose location or the retired-surface register entry

### Requirement: Contract authority is reachable from front doors
The package SHALL link the language-contract authority from user-facing front doors that future agents are likely to read first.

#### Scenario: User reads README
- **WHEN** the user or an agent opens `README.md`
- **THEN** the file identifies the natural-language contract authority and does not require a validator command to discover acceptance rules

#### Scenario: User reads install docs
- **WHEN** the user or an agent opens `.codex/INSTALL.md` or `docs/README.codex.md`
- **THEN** the docs identify manual operating playbooks for install, session start, release, and verification behavior

### Requirement: Contract map preserves old invariant intent
The package SHALL maintain a migration map from old code-backed gates to the natural-language requirements that replace them.

#### Scenario: Validator is deleted
- **WHEN** `_shared/validators/validate_skill_library.py` or `_shared/validators/validate_codex_public_fork.py` is removed
- **THEN** the migration map lists the old file, the old behavior category, the replacement playbook, and any accepted loss of machine enforcement

#### Scenario: Runtime automation is deleted
- **WHEN** a hook, shell script, Node helper, Python helper, or command alias is removed
- **THEN** the migration map states whether the behavior is manual, retired, or moved to another package

### Requirement: Prompt and dispatch obligations remain readable
The package SHALL express subagent dispatch, root-owned elicitation, child handoff, review ordering, and role-boundary obligations in prose that is clear enough for an agent to follow without validator-enforced exact strings.

#### Scenario: Child prompt is reviewed
- **WHEN** a reviewer inspects a subagent prompt template
- **THEN** the reviewer can determine from prose whether the child may ask the user, which status values it may return, and how unresolved decisions flow to the parent

#### Scenario: Dispatch guidance is reviewed
- **WHEN** a reviewer inspects dispatch guidance
- **THEN** the reviewer can determine the intended `spawn_agent` call shape, role selection rule, and parent arbitration rule without reading validator code
