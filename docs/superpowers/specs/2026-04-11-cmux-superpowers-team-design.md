# Cmux Superpowers Team Launcher Design

Date: 2026-04-11
Status: Approved design for implementation planning

## Summary

Build a local cmux-side team launcher that replicates the documented `cmux omx` experience for plain Codex CLI plus the existing local Superpowers setup.

The core adaptation is architectural, not cosmetic:

- `cmux omx` works because cmux launches an external multi-agent orchestrator and turns its pane model into native cmux splits.
- the local Superpowers setup already injects Codex behavior through `SessionStart`, but it does not provide an external pane orchestrator
- the replacement therefore needs a new local conductor that launches multiple real `codex` CLI processes inside cmux splits while reusing the existing Superpowers and cmux hook layers

This design lives in `/Users/maxibon/.codex/superpowers` because that repo owns the local Superpowers hook/runtime contract and is the correct place to carry workstation-local launcher logic. The public `manaflow-ai/cmux` repo is an upstream external dependency, not the implementation home for this local adaptation.

## Goals

- Replicate the operator experience described by the official `cmux omx` docs:
  - a primary main pane
  - worker panes as native cmux splits
  - optional HUD/status pane
  - multi-worker orchestration launched from one command
- Use ordinary local `codex` CLI processes for the main pane and worker panes.
- Reuse the existing local Superpowers `SessionStart` hook so every launched Codex session gets the current skill-routing behavior automatically.
- Reuse the existing local cmux Codex hooks so worker panes participate in cmux status and notification updates.
- Keep the implementation local and operator-owned without requiring a custom cmux build.
- Add a concrete doctor/install surface so the setup is reproducible on this workstation.

## Non-Goals

- Patch or fork the cmux application to add a first-class built-in `cmux` subcommand.
- Emulate tmux for Superpowers in v1.
- Reproduce every OMX feature or CLI flag exactly.
- Promise token-usage extraction in the HUD when Codex does not expose a stable external surface for that.
- Support remote/SSH relay orchestration in v1.
- Replace Codex's native multi-agent surface. This design is about process-level pane orchestration, not about changing Codex internals.

## Current-State Findings

### 1. Official `cmux omx` is a launcher-plus-pane bridge, not a Codex hook feature

From the public `manaflow-ai/cmux` repo:

- `cmux omx` resolves the external `omx` executable
- creates a private shim directory under `~/.cmuxterm/omx-bin`
- synthesizes `TMUX`, `TMUX_PANE`, and cmux socket environment variables
- then `exec`s into `omx`
- OMX later issues `tmux` commands, and cmux translates those into native pane RPCs through `__tmux-compat`

That means the official integration depends on an external orchestrator process that owns pane creation and worker lifecycle.

### 2. The local workstation already has the two hook layers needed inside each Codex session

The current local state already keeps both hook surfaces active:

- Superpowers `SessionStart` hook injects the `using-superpowers` skill into each new or resumed Codex session
- cmux Codex hooks observe `SessionStart`, `UserPromptSubmit`, and `Stop` for cmux status and notifications

The missing piece is therefore not more hook work. The missing piece is the outer conductor that launches and arranges multiple Codex workers.

### 3. Local Codex can be launched as an interactive session with an initial prompt

The current local Codex CLI help reports:

- interactive usage: `codex [OPTIONS] [PROMPT]`
- non-interactive usage: `codex exec [OPTIONS] [PROMPT]`

That gives the launcher a clean bootstrap mechanism for each worker:

- start a real interactive `codex` process in a pane
- pass a concise worker prompt packet as the initial prompt argument

This is materially better than a brittle "launch empty Codex and then type into it later" design.

### 4. This repo has the right local surfaces for scripts, docs, and installers

This repo already contains:

- `hooks/`
- `scripts/`
- `docs/superpowers/specs/`
- local install helpers such as `scripts/install_codex_hooks.py`

It does not currently expose a packaged `bin/` lane or a first-class local launcher command. A launcher installed through a repo-owned helper script is the cleanest fit.

### 5. Multiple write-capable Codex workers in one repo need isolation

Unlike OMX's tmux-only concerns, a Superpowers replacement must account for actual code edits from multiple Codex workers.

If multiple workers share the same writable repo root, they will collide on files and branch state. The design must therefore include a worktree and sandbox policy from the start, not as an afterthought.

## Design Decisions

## 1. Use a standalone local launcher, not a custom cmux build

The user-facing command should be a standalone launcher installed from this repo, not a patch to the upstream cmux app.

Recommended command surface:

- `cmux-superpowers doctor`
- `cmux-superpowers team [OPTIONS] [TASK]`
- `cmux-superpowers cleanup --session <id>`

Why:

- this is a local operator setup, not an upstream cmux feature contribution
- the cmux binary is externally installed and versioned independently
- a standalone launcher can still be "cmux-native" by driving cmux directly through its CLI and socket-backed command surface

The command should be installed into a user-owned executable location such as `~/.local/bin/` by a repo-owned installer script, using the same absolute-path pattern already used for the local Codex hooks installer.

## 2. Use native cmux orchestration, not tmux emulation

The replacement should not preserve the official OMX tmux shim architecture.

Reasoning:

- OMX needs tmux emulation because OMX itself speaks tmux
- Superpowers does not speak tmux
- if this launcher owns both the orchestration layer and the worker-launch layer, adding a fake tmux boundary only increases complexity and failure modes

The launcher should use the local cmux CLI directly for:

- workspace creation
- split creation
- surface focus and naming
- text injection where needed
- status pane management

This preserves the official user-facing outcome while removing an unnecessary compatibility layer.

## 3. Launch real interactive Codex sessions in every pane

Every pane should run a real interactive `codex` CLI process.

That includes:

- one main pane session
- zero or more worker sessions
- optional HUD pane that is not a Codex process

The launcher should bootstrap each Codex process with:

- `-C <cwd>` for its effective working directory
- `-p <profile>` when a profile override is requested
- a concise initial prompt packet as `[PROMPT]`

The prompt packet should stay intentionally short because the heavy skill-routing context is already injected by the Superpowers `SessionStart` hook.

Each worker packet should define:

- worker role
- task scope
- whether it is read-only or write-capable
- reporting contract
- whether the worker may ask for user input directly

The main pane should also be a real Codex session, but its prompt packet should make it clear that pane lifecycle is owned by the external conductor, not by the main Codex process.

## 4. Compose the existing hooks rather than replacing them

The new launcher should assume both current hook layers stay active.

Responsibilities:

- Superpowers `SessionStart` hook:
  - injects `using-superpowers`
  - ensures every launched worker starts in the current Superpowers skill system
- cmux Codex hooks:
  - register session and PID state
  - set Running/Idle status
  - emit notifications on stop
- launcher:
  - creates the panes
  - decides worker prompt packets
  - assigns working directories and isolation
  - manages team session metadata

This keeps responsibilities crisp:

- hooks change in-session behavior and status reporting
- the launcher owns process orchestration

## 5. Add explicit team-session state under `~/.cmuxterm/`

The launcher should create a dedicated session directory:

- `~/.cmuxterm/superpowers-team/<session-id>/`

Recommended contents:

- `manifest.json`
  - canonical session metadata
- `workers/<worker-id>.json`
  - per-worker launch metadata and current state
- `packets/<worker-id>.md`
  - prompt packet actually sent to each worker
- `hud.json`
  - compact read model for the optional HUD pane

The manifest should track:

- session id
- creation time
- target repository root
- workspace id
- main pane and worker pane ids
- worker role map
- sandbox mode per worker
- worktree path per worker when applicable
- cleanup status

This state directory is the conductor-owned equivalent of the compatibility store used by OMX/tmux integration.

## 6. Make worktree and sandbox policy explicit in v1

This design must fail closed for write ownership.

Policy:

- read-only workers may share the original repo root and should launch with a read-only or non-writing contract
- write-capable workers must not share the same writable repo root
- when the target directory is a git repository, the launcher should create a per-worker worktree for every write-capable worker
- when the target directory is not a git repository, v1 should refuse multi-writer mode rather than guess

Recommended worktree layout:

- `<repo>/.worktrees/cmux-superpowers/<session-id>-<worker-id>/`
  - if `.worktrees/` already exists and is ignored
- otherwise follow the existing local worktree conventions and refuse unsafe creation if the directory is not ignored

The launcher should also record sandbox intent per worker:

- read-only review workers
- write-capable implementation workers in isolated worktrees

This is mandatory because the whole point of the pane model is concurrent work, and concurrent write ownership without isolation is not acceptable.

## 7. Keep the initial command surface narrow

V1 should support only the minimum surface required to reproduce the documented OMX experience locally:

### `doctor`

Validate:

- `cmux` binary is callable
- `codex` binary is callable
- `codex_hooks` feature is enabled
- Superpowers `SessionStart` hook is installed
- cmux Codex hooks are installed
- current shell can locate the installed launcher wrapper

### `team`

Create:

- one cmux workspace for the session
- one main Codex pane
- one or more worker Codex panes
- optional HUD/status pane

Launch:

- main and workers with prompt packets and declared working directories

Record:

- full team session metadata under `~/.cmuxterm/superpowers-team/<session-id>/`

### `cleanup`

Perform owned cleanup only:

- close the owned HUD pane if present
- optionally close owned worker panes
- optionally remove owned session metadata
- never close unrelated cmux sessions or panes

## 8. HUD scope is intentionally limited in v1

The optional HUD pane should be presentable and useful, but it should not claim unsupported metrics.

V1 HUD fields:

- session id
- worker id
- role
- cwd or worktree path
- git branch
- pane or surface id
- current launcher-known state
- last known cmux Running/Idle state when available

V1 HUD should not promise:

- exact token usage
- deep transcript summaries
- model-internal reasoning state

If token accounting ever becomes available from a stable Codex surface, it should be introduced only through a separate follow-on design.

## 9. The launcher should be implemented in this repo as a local operator extension

Planned implementation surface:

- `scripts/cmux_superpowers_team.py`
  - main conductor
- `scripts/install_cmux_superpowers_launcher.py`
  - install wrapper into `~/.local/bin/`
- `docs/README.codex.md`
  - add launcher usage
- `.codex/INSTALL.md`
  - add local install/update flow
- `docs/superpowers/specs/2026-04-11-cmux-superpowers-team-design.md`
  - this spec
- `tests/cmux-superpowers/doctor.sh`
  - launcher doctor coverage
- `tests/cmux-superpowers/team_smoke.sh`
  - workspace, pane, and manifest smoke coverage
- `tests/cmux-superpowers/install.sh`
  - launcher install/uninstall coverage

The launcher should be CLI-first and shell-friendly. Python is the preferred implementation language because the repo already uses Python for local Codex hook installation and validation helpers.

## Verification Gates

This design is not ready for implementation planning unless the resulting plan can prove all of the following.

### 1. Doctor truth

`cmux-superpowers doctor` must correctly detect:

- missing `cmux`
- missing `codex`
- missing Superpowers hook install
- missing cmux Codex hook install
- disabled `codex_hooks`

### 2. Launch truth

A local `team` launch must create:

- one new cmux workspace
- a main Codex pane
- the requested worker panes
- prompt packet artifacts on disk
- manifest state on disk

### 3. Hook composition truth

New worker sessions must still show the expected local behavior:

- Superpowers context injection on `SessionStart`
- cmux Running/Idle updates and stop notifications

### 4. Isolation truth

Write-capable workers must either:

- get unique isolated worktrees, or
- fail closed before launch

### 5. Cleanup truth

Cleanup must only touch:

- owned panes
- owned session metadata
- owned worktrees if explicitly requested

It must never delete or close unrelated cmux state.

## Acceptance Criteria

This design is successful when:

- a single local launcher command reproduces the key documented OMX experience for Codex plus Superpowers;
- workers are ordinary Codex CLI sessions, not custom shells pretending to be Codex;
- the existing Superpowers and cmux hooks remain active and complementary;
- multi-worker write ownership is isolated instead of implicit;
- the launcher remains local and operator-owned without requiring an upstream cmux patch.
