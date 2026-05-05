## ADDED Requirements

### Requirement: Automation surfaces are classified before removal
The package SHALL classify every hook, script, command alias, helper, and package script as policy-only, install/convenience, runtime bridge, feature runtime, or deprecated alias before removing or rewriting it.

#### Scenario: Policy script is classified
- **WHEN** a script only enforces repository policy
- **THEN** the implementation replaces it with a playbook and ledger entry

#### Scenario: Runtime feature script is classified
- **WHEN** a script provides user-facing runtime behavior
- **THEN** the implementation records whether the feature is retired, moved to a companion package, or explicitly kept outside the prose-only cutover

### Requirement: SessionStart automation has a manual alternative
The package SHALL document a manual session-start workflow if native SessionStart hook automation is removed or made non-authoritative.

#### Scenario: Automatic hook is retired
- **WHEN** `hooks/hooks.json`, `hooks/session-start`, or the plugin manifest hook declaration is removed
- **THEN** install and usage docs instruct agents to start by reading the session-router playbook and applying its routing rules manually

#### Scenario: Automatic hook is retained as an exception
- **WHEN** implementation retains a minimal executable SessionStart hook
- **THEN** the runtime automation playbook states that the hook is an explicit exception to the complete prose-only goal and explains why it remains

### Requirement: Feature runtime loss is explicit
The package SHALL not silently replace executable feature behavior with prose if the behavior cannot actually run without code.

#### Scenario: Visual brainstorming runtime is removed
- **WHEN** browser server, WebSocket, helper, frame, start, or stop scripts are removed
- **THEN** the retired-automation register states that visual companion runtime is no longer provided by this package or identifies its new owner

#### Scenario: Install automation is removed
- **WHEN** install, launcher, cleanup, or hook bootstrap scripts are removed
- **THEN** manual install docs provide ordered steps and expected observations without claiming automatic repair behavior

### Requirement: Deprecated alias removals are registered
The package SHALL record removed command aliases and stale namespace surfaces so future agents do not recreate them as compatibility shims.

#### Scenario: Deprecated command is deleted
- **WHEN** a legacy command alias such as a `commands/*.md` stub is removed
- **THEN** the retired-automation register states the modern skill or playbook that replaces the alias
