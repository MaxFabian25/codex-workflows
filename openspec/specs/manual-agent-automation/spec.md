# manual-agent-automation Specification

## Purpose
Define how hooks, scripts, command aliases, install helpers, tests, validators, feature runtimes, utility automation, and external tools are classified as part of the package's agent-computer interface.
## Requirements
### Requirement: Automation surfaces are classified before removal
The package SHALL classify every hook, script, command alias, helper, package task, CI job, test, validator, generator, and external tool before deletion or demotion.

#### Scenario: Deterministic mechanic is classified
- **WHEN** automation parses data, adapts external APIs, builds artifacts, formats files, runs tests, performs migrations, validates malformed inputs, prevents unsafe writes, computes reproducible outputs, or implements feature runtime
- **THEN** the implementation retains it in code unless a specific retirement or move decision is recorded

#### Scenario: Human-facing policy is classified
- **WHEN** automation silently decides readiness, currentness, release status, deployment readiness, promotion suitability, traceability, approval, rollback, incident state, or handoff
- **THEN** the implementation moves that decision authority to a natural-language playbook and ledger while preserving useful evidence-producing mechanics where appropriate

#### Scenario: Runtime feature script is classified
- **WHEN** a script provides user-facing runtime behavior
- **THEN** the implementation records whether the feature is retained, retired, moved to a companion package, or unresolved

### Requirement: SessionStart automation has a manual alternative
The package SHALL define SessionStart hook behavior as a lightweight adapter option rather than broad hidden authority.

#### Scenario: Automatic hook is retired
- **WHEN** `hooks/hooks.json`, `hooks/session-start`, or the plugin manifest hook declaration is removed
- **THEN** install and usage docs instruct agents to start from the manual session-router playbook and record the loss of automatic adapter behavior

#### Scenario: Automatic hook is retained
- **WHEN** implementation retains a minimal executable SessionStart hook
- **THEN** the runtime automation playbook states that the hook is a lightweight adapter whose source of truth is the natural-language session-router contract

#### Scenario: User-level hook installer is retired
- **WHEN** native plugin hooks provide the supported SessionStart adapter path
- **THEN** any installer that mutates `~/.codex/hooks.json` is recorded as accepted retirement unless a later explicit product decision restores it

### Requirement: Feature runtime loss is explicit
The package SHALL not replace executable feature behavior with prose unless the feature is explicitly retired or moved.

#### Scenario: Visual brainstorming runtime is removed
- **WHEN** browser server, WebSocket, helper, frame, start, or stop scripts are removed
- **THEN** the retired-automation register states that visual companion runtime is no longer provided by this package or identifies its new owner and records the product rationale

#### Scenario: Install automation is removed
- **WHEN** install, launcher, cleanup, or hook bootstrap scripts are removed
- **THEN** manual install docs provide ordered steps and expected observations without claiming automatic repair behavior

### Requirement: Deprecated alias removals are registered
The package SHALL record removed command aliases and stale namespace surfaces so future agents do not recreate them as compatibility shims.

#### Scenario: Deprecated command is deleted
- **WHEN** a legacy command alias such as a `commands/*.md` stub is removed
- **THEN** the retired-automation register states the modern skill or playbook that replaces the alias

#### Scenario: Stale fixture harness is deleted
- **WHEN** a fixture harness encodes obsolete package, hook, cmux, or namespace expectations
- **THEN** the retired-automation register may record accepted retirement instead of requiring a replacement test

### Requirement: Tool contracts are explicit
Every retained tool or command SHALL document its inputs, outputs, write locations, external side effects, downstream consumers, evidence role, and authority role.

#### Scenario: Script remains in the package
- **WHEN** a script, test, generator, or package task remains after the harness adaptation
- **THEN** its playbook or nearby docs identify whether it is evidence only, deterministic safety, feature runtime, or explicit code-gated authority

#### Scenario: External side effect is possible
- **WHEN** a tool can mutate protected state, external systems, credentials, migrations, customer/partner files, production data, or canonical release artifacts
- **THEN** the harness requires a fail-closed stop condition or human approval point
