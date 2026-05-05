# language-contract-authority Specification

## Purpose
Define the agent-readable harness authority that makes the package's agent-computer interface explicit while preserving deterministic mechanics, implementation safety, feature runtime, and explicit tool contracts in code when code is the right tool.
## Requirements
### Requirement: Natural-language contract tree is authoritative
The package SHALL provide minimal natural-language harness artifacts for human-facing orchestration authority while deterministic mechanics, implementation safety checks, and explicit tool interfaces remain in code when code is the right tool.

#### Scenario: Agent starts contract review
- **WHEN** an agent needs to understand routing, dispatch, package, release, protected scopes, evidence roles, or handoff obligations
- **THEN** the agent can find the smallest relevant harness artifact through the documented front doors

#### Scenario: Code gate has successor or retained authority
- **WHEN** a validator, target manifest, fixture test, hook script, install script, or automation helper is changed
- **THEN** the harness authority identifies whether it is replaced by prose, retained as deterministic mechanics, retained as implementation safety, demoted to evidence, preserved as historical, or unresolved

### Requirement: Contract authority is reachable from front doors
The package SHALL link minimal harness authority from user-facing front doors that future agents are likely to read first, without loading broad duplicate workflow prose into every context file.

#### Scenario: User reads README
- **WHEN** the user or an agent opens `README.md`
- **THEN** the file identifies where to find the harness charter and scoped playbooks without making README a giant instruction file

#### Scenario: User reads install docs
- **WHEN** the user or an agent opens `.codex/INSTALL.md` or `docs/README.codex.md`
- **THEN** the docs identify the relevant setup, session, verification, and handoff harness artifacts and state which commands are evidence or explicit authority

### Requirement: Prompt and dispatch obligations remain readable
The package SHALL express subagent dispatch, root-owned elicitation, child handoff, review ordering, and role-boundary obligations in concise prose that is clear enough for an agent to follow without bloating scoped instruction files.

#### Scenario: Child prompt is reviewed
- **WHEN** a reviewer inspects a subagent prompt template
- **THEN** the reviewer can determine from prose whether the child may ask the user, which status values it may return, and how unresolved decisions flow to the parent

#### Scenario: Dispatch guidance is reviewed
- **WHEN** a reviewer inspects dispatch guidance
- **THEN** the reviewer can determine the intended `spawn_agent` call shape, role selection rule, and parent arbitration rule without reading hidden controller policy

### Requirement: Context files stay minimal
`AGENTS.md` and equivalent instruction files SHALL be short, scoped, requirement-only, and free of duplicate broad workflow advice.

#### Scenario: Scoped instruction file is edited
- **WHEN** a maintainer edits an instruction file
- **THEN** the maintainer keeps only requirements that affect that scope and moves optional explanation to a linked harness artifact

#### Scenario: Broad guidance is proposed
- **WHEN** broad workflow prose is proposed for an instruction file
- **THEN** the maintainer rejects it unless it is necessary for that scope and cannot live in a smaller referenced artifact

### Requirement: Harness charter defines agent-computer interface
The harness charter SHALL define the repository's agent-computer interface in language-neutral terms.

#### Scenario: New agent enters the repo
- **WHEN** a new agent starts from a front door
- **THEN** it can identify writable scopes, protected scopes, authoritative docs/specs, tool boundaries, evidence commands, retained code authorities, blocker records, verification paths, and handoff locations
