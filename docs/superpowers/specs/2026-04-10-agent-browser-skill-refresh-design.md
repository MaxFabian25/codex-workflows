# Agent-Browser Skill Truth Refresh Design

Date: 2026-04-10
Status: Approved design for implementation planning

## Summary

Refresh the local `vercel:agent-browser` skill package against the current official `agent-browser.dev` docs and the installed `agent-browser 0.25.3` CLI surface.

This is a truth refresh, not a package redesign. The goal is to remove stale guidance, fill the current documentation coverage gaps, and make the skill internally consistent with the local `/Users/maxibon/AGENTS.md` session contract.

The design doc is stored in `/Users/maxibon/.codex/superpowers` because that repo contains the canonical `docs/superpowers/specs/` surface. The target `agent-browser` skill package under the plugin cache is not itself in a git repository.

## Goals

- Ground the local skill in the current official docs at `https://agent-browser.dev/`.
- Identify and remove stale or misleading guidance in `SKILL.md`, `references/`, and `templates/`.
- Add the missing `references/` needed to cover the current official surface area.
- Keep the package aligned with the current installed CLI behavior on this workstation.
- Preserve the local deterministic session-ownership contract from `/Users/maxibon/AGENTS.md`.

## Non-Goals

- Redesign the package structure beyond what is needed for documentation truthfulness.
- Invent new browser workflows that are not grounded in the official docs or local workstation policy.
- Treat migration-era “native mode” transition details as a first-class agent workflow surface.
- Implement the package refresh in this design phase.

## Current-State Findings

### 1. The current package is incomplete relative to the official docs surface

The local `agent-browser` package already contains:

- `SKILL.md`
- `references/authentication.md`
- `references/commands.md`
- `references/profiling.md`
- `references/proxy-support.md`
- `references/session-management.md`
- `references/snapshot-refs.md`
- `references/video-recording.md`
- `templates/authenticated-session.sh`
- `templates/capture-workflow.sh`
- `templates/form-automation.sh`

That is materially better than an earlier thinner local copy, but it is still missing coverage for current first-class doc surfaces:

- official Selectors guidance
- official Snapshots guidance beyond the local ref note
- official Diffing guidance
- official Security and confirmation flows
- official Configuration guidance
- official Dashboard and Streaming observability guidance as a coherent reference lane

### 2. The installed runtime is current enough for documentation alignment

The workstation reports:

- `agent-browser --version` -> `agent-browser 0.25.3`
- `agent-browser --help` exposes the current command groups and options expected for the refresh

This means the main problem is skill accuracy and coverage, not a missing binary upgrade.

### 3. The package has internal contradictions that will mislead future sessions

The most important contradiction is wait strategy:

- `SKILL.md` already warns against routine `wait --load networkidle`
- several references and templates still use `wait --load networkidle` as a default step

The package also teaches session persistence in ways that conflict with the local AGENTS contract:

- upstream-style examples still close sessions casually
- local policy requires deterministic named-session ownership and reuse

### 4. The current package under-documents the current CLI surface

The live `--help` output includes high-value commands or groups that are either thinly covered or not organized clearly enough in the current package:

- `confirm` / `deny`
- `console` / `errors`
- `trace`
- `stream`
- `dashboard`
- richer `state` management
- `chat`
- full security flags
- full configuration precedence and environment variables

### 5. The package should not overfit to transition-era native-mode framing

The official homepage now presents agent-browser as a native Rust browser automation CLI. The older “native mode” transition story remains visible in release history, but the current local CLI help does not expose `--native` as an active top-level option.

That means the skill should focus on the current command contract, not on preserving a migration narrative between Node and native paths.

## Design Decisions

## 1. Keep the current package structure and do a truth refresh in place

The refresh should update the existing `agent-browser` package rather than re-architect it.

This includes:

- revising `SKILL.md`
- refreshing stale `references/*.md`
- adding the missing `references/*.md`
- updating the existing templates

This does not include splitting the package into more sub-skills or adding new process layers.

## 2. Expand `metadata.docs` to match the official source surface

The docs list in `SKILL.md` should explicitly include the official pages that now matter for truthful routing and source-backed maintenance:

- `https://agent-browser.dev/`
- `https://agent-browser.dev/installation`
- `https://agent-browser.dev/quick-start`
- `https://agent-browser.dev/skills`
- `https://agent-browser.dev/commands`
- `https://agent-browser.dev/configuration`
- `https://agent-browser.dev/selectors`
- `https://agent-browser.dev/snapshots`
- `https://agent-browser.dev/diffing`
- `https://agent-browser.dev/sessions`
- `https://agent-browser.dev/security`
- `https://agent-browser.dev/dashboard`
- `https://agent-browser.dev/streaming`
- `https://agent-browser.dev/profiler`
- `https://agent-browser.dev/next`
- `https://agent-browser.dev/changelog`

Do not add pages to the skill metadata unless they are part of the current official docs surface.

## 3. Add the missing `references/` files

The following new references should be added:

| Path | Purpose |
| --- | --- |
| `references/selectors.md` | Refs vs CSS selectors vs semantic locators, grounded in the official Selectors and Commands docs |
| `references/diffing.md` | `diff snapshot`, `diff screenshot`, `diff url`, and “verify the action changed the page” workflows |
| `references/security-and-confirmations.md` | `--content-boundaries`, `--allowed-domains`, `--action-policy`, `--confirm-actions`, `--confirm-interactive`, and non-TTY auto-deny |
| `references/debug-observability.md` | `trace`, `profiler`, `record`, `console`, `errors`, `stream`, and `dashboard` as one observability lane |
| `references/configuration.md` | Config precedence, boolean overrides, common configs, AI-agent safety config, env vars |

These are the highest-value additions because they cover areas where the current package either has no local reference or spreads important guidance too thinly.

## 4. Refresh the existing references instead of treating them as already correct

The existing references should remain, but they must be updated against the current official docs and local CLI help:

- `references/commands.md`
- `references/authentication.md`
- `references/session-management.md`
- `references/snapshot-refs.md`
- `references/profiling.md`
- `references/video-recording.md`
- `references/proxy-support.md`

Specific refresh requirements:

- remove default `networkidle` patterns from normal flows
- align command examples to the current help text
- align security notes to the official Security page
- align dashboard and streaming statements to the current official behavior
- keep local session-policy overrides explicit where they diverge from upstream examples

## 5. Normalize the top-level `SKILL.md` around the official core workflow

The top-level skill should present the core workflow in this order:

1. `open`
2. `snapshot -i`
3. interact using refs or semantic locators
4. re-snapshot only when the page state changed

Then it should layer on local guidance:

- deterministic session ownership
- auth decision table
- targeted waits over blanket `networkidle`
- when to use `batch`
- when to use debug or observability commands
- when to add security boundaries

The skill should treat `batch` as a local orchestration optimization, not as a replacement for the official core workflow narrative.

## 6. Add a short auth and session decision table near the top of `SKILL.md`

Future sessions need a compact answer to “which persistence mechanism should I use?”

The decision table should distinguish:

- `--session`
  - isolate one task from another
- `--session-name`
  - auto-save and restore cookies and localStorage by name
- `--profile`
  - reuse an existing Chrome profile or persistent custom profile
- `--state`
  - explicit manual save/load file path
- auth vault
  - credential storage and login-by-name without exposing the password to the LLM

This reduces confusion between task isolation and auth persistence, which the current skill mixes too loosely.

## 7. Make the local AGENTS session contract a first-class override

Both `SKILL.md` and `references/session-management.md` should explicitly encode the local workstation rules:

1. use one deterministic `--session <name>` per task
2. run `agent-browser session list` before new `open` or `connect`
3. reuse the owned session if it already exists
4. close only the owned named session when cleanup is explicit, the session is stale or failed, or the user asks for cleanup
5. never close unrelated sessions

This override is necessary because some official examples assume close-on-exit behavior that is not valid under the local workstation contract.

## 8. Change the default wait strategy package-wide

The package-wide default should be:

- `open` already covers page `load`
- do not add an extra wait by default
- prefer `wait <selector>`, `wait --text`, `wait --fn`, or a short fixed delay for slow async content
- reserve `wait --load networkidle` for cases where the page is known to become idle cleanly

This change must be reflected consistently in:

- `SKILL.md`
- `references/authentication.md`
- `references/session-management.md`
- `references/profiling.md`
- `references/video-recording.md`
- `templates/authenticated-session.sh`
- `templates/capture-workflow.sh`
- `templates/form-automation.sh`

## 9. Remove or demote stale guidance

The following guidance is stale, misleading, or should no longer be taught as a default:

- mandatory `wait --load networkidle` after `open`
- casual session closing in local examples
- “always use batch” phrasing
- any implication that native-mode migration details are central to normal usage
- command coverage that omits `confirm` / `deny`, `console`, `errors`, `trace`, `dashboard`, `stream`, or current configuration precedence

Demotion is acceptable where a command remains valid but should no longer be taught as the normal first move.

## 10. Keep provider-specific and iOS guidance light unless backed by current docs

The official docs navigation clearly includes provider and iOS surfaces, but the current package does not need a large provider matrix to answer the most common local usage patterns.

The truth-refresh default should be:

- mention supported providers and iOS paths where the official docs and CLI help do
- keep core package focus on local browser automation, sessions, auth, observability, and safety
- add dedicated provider references only if there is an actual repeated local need

This keeps the skill from bloating into a catalog of rarely used advanced modes.

## Reference Inventory After Refresh

The target `references/` set should be:

- `authentication.md`
- `commands.md`
- `configuration.md`
- `debug-observability.md`
- `diffing.md`
- `profiling.md`
- `proxy-support.md`
- `security-and-confirmations.md`
- `selectors.md`
- `session-management.md`
- `snapshot-refs.md`
- `video-recording.md`

No separate `native-mode.md` is required for the initial truth refresh.

## Template Changes

The existing templates should stay, but with these changes:

### `templates/authenticated-session.sh`

- remove default `networkidle` waits
- keep the session open by default under the local AGENTS contract
- prefer targeted success checks such as URL, selector, or snapshot evidence

### `templates/capture-workflow.sh`

- remove unconditional `networkidle`
- keep capture flow grounded in `open`, `get title`, `get url`, `snapshot -i`, `screenshot`, and `pdf`
- leave session cleanup explicit

### `templates/form-automation.sh`

- remove unconditional `networkidle`
- preserve the snapshot-interact-verify pattern
- make post-submit waits targeted rather than blanket

No new templates are required for the truth-refresh scope.

## Validation Bundle

Implementation should be considered correct only if all of the following pass:

1. File inventory matches the designed `references/` set and existing `templates/` set.
2. `SKILL.md` frontmatter remains valid and the package still reads as one coherent skill.
3. Local examples do not conflict with `/Users/maxibon/AGENTS.md`.
4. Stale `networkidle` defaults are removed from the package except where explicitly justified.
5. The docs list in `SKILL.md` points only at current official docs pages.
6. The written command coverage is checked against the current `agent-browser --help` output on this workstation.
7. A quick `rg` scan confirms the removed stale patterns are actually gone from the package.

Suggested verification commands for implementation:

```bash
agent-browser --version
agent-browser --help
rg -n "networkidle|close --all|agent-browser close  #|always use batch|--native" \
  /path/to/skills/agent-browser
rg --files /path/to/skills/agent-browser
```

If a package-local validator exists at implementation time, it should be run as well. If none exists, the quick-check bundle above is the minimum acceptable evidence.

## Risks

- Official docs can continue to evolve, so the refresh should avoid overfitting to one release note unless the behavior is also present in the current docs or local help output.
- Provider- and iOS-specific details may drift faster than the local core browser surface; keep them secondary unless there is a strong usage signal.
- The plugin cache is not versioned, so implementation should be careful about where durable design and validation artifacts live.

## Outcome

The refreshed `vercel:agent-browser` skill should become:

- source-backed against the official docs
- internally consistent
- aligned to the current local CLI surface
- safer for agent use on arbitrary pages
- compliant with the local session-ownership contract

This is sufficient to move to implementation planning.
