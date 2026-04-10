# Agent-Browser Skill Refresh Design

Date: 2026-04-10
Status: Approved design for implementation planning

## Summary

Refresh the local `agent-browser` skill surface with a hard cut to the official `vercel-labs/agent-browser` package shape and current `0.25.x` command contract, then redesign `agent-browser-verify` as a thin local overlay for dev-server smoke checks instead of a second broad browser skill.

This design treats the official `agent-browser.dev` docs and upstream `skills/agent-browser/` package as the source of truth for the core browser lane. It does not attempt to preserve older patterns that have drifted from the current CLI. The local verification lane remains separate only where there is no official upstream equivalent.

No runtime upgrade is required at design time. The installed CLI already matches the current npm latest release observed during this design pass: `agent-browser 0.25.3`.

## Goals

- Align the local browser skill guidance to the official `agent-browser.dev` documentation and upstream skill package structure.
- Replace stale or non-official guidance in the current local skill copies.
- Add the missing `references/` and `templates/` needed for a usable guided lane.
- Keep `agent-browser` focused on general browser automation and move dev-server smoke policy into a smaller `agent-browser-verify` overlay.
- Encode the local session-ownership contract from `/Users/maxibon/AGENTS.md` so browser runs are deterministic and reusable.
- Define a validation bundle that can prove the skill refresh matches the current CLI and docs.

## Non-Goals

- Upgrade the installed `agent-browser` binary during this design phase.
- Implement the skill refresh in this design phase.
- Preserve backward-compatibility examples that contradict the current CLI contract.
- Turn `agent-browser-verify` into a full exploratory QA or dogfooding skill.
- Patch the generated plugin cache in this phase.

## Current-State Findings

### The local skill copies are materially thinner than upstream

The enabled local plugin skills are:

- `agent-browser/SKILL.md` at 255 lines
- `agent-browser-verify/SKILL.md` at 221 lines

The current upstream `skills/agent-browser/SKILL.md` is 828 lines and ships with additional supporting files:

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

The local plugin cache currently contains only `SKILL.md` for both browser skills and therefore omits the reference and template material that the official skill expects to route into.

### The installed runtime is already current

The local workstation reports:

- `agent-browser --version` -> `agent-browser 0.25.3`
- `npm view agent-browser version dist-tags --json` -> `latest: 0.25.3`

That means the upgrade need is documentation and skill packaging, not the CLI binary.

### The current local guidance has drifted from the official command contract

The current local skills still teach or imply patterns that should not remain first-class:

- routine `wait --load networkidle` after `open`
- console collection via `window.__consoleErrors`
- unconditional `agent-browser close` at the end of verification
- no use of `batch` as the preferred 2-plus-command sequence tool
- no guidance for auth vault, `--profile`, `--session-name`, dashboard, streaming, or security boundaries

These omissions and stale examples matter because the current official docs now emphasize:

- `batch` for sequential command execution
- `snapshot -i --urls` to reduce re-navigation
- auth vault and session persistence workflows
- content boundaries, domain allowlists, and action policies
- dashboard and runtime streaming
- broader command coverage including `console`, `errors`, `network`, `dialog`, `tab`, `clipboard`, `stream`, `dashboard`, and provider selection

### `agent-browser-verify` is not an official upstream skill

The official skills index includes:

- `agent-browser`
- `agentcore`
- `dogfood`
- `electron`
- `slack`
- `vercel-sandbox`

There is no official upstream `agent-browser-verify` package to sync from. The local verification lane should therefore be treated as a repo-specific overlay, not as a forked copy of an upstream skill that happens to be missing files.

### Local session policy overrides official close-on-exit examples

The official upstream skill recommends closing sessions when done. The local `/Users/maxibon/AGENTS.md` contract is stricter and more specific:

- one deterministic `--session <name>` per task
- `agent-browser session list` before new `open` or `connect`
- reuse the owned session when it already exists
- only close the owned named session when cleanup is explicitly required, the user asks for cleanup, or the session is stale or failed
- never close unrelated sessions

This conflict must be resolved explicitly in favor of the local AGENTS contract.

## Design Decisions

## 1. Use a hard-sync model for `agent-browser`

Future implementation should not patch the current 255-line local file in place.

Instead, the core design is:

- treat the upstream `vercel-labs/agent-browser` `skills/agent-browser/` package as the canonical source
- import its package structure wholesale
- keep only the smallest possible local adaptations required by the local AGENTS contract and the host plugin surface

This is a hard cutover. The local skill should stop teaching older patterns that predate the current CLI behavior.

## 2. Keep `agent-browser-verify` as a slim local overlay

`agent-browser-verify` should remain separate only because it serves a narrower workflow than the official core skill:

- dev-server smoke verification
- rapid gut checks on page load and obvious breakage
- escalation into deeper investigation when errors are found

It should not duplicate a general command reference, authentication catalog, or security catalog. Those belong in `agent-browser`.

The verify skill should instead:

- assume `agent-browser` is the general browser contract
- link into the shared browser references where possible
- add only the local verification-specific `references/` and `templates/` that upstream does not provide

## 3. Import the full upstream `references/` and `templates/` inventory for `agent-browser`

The following files should be added under the future refreshed `agent-browser` package:

| Path | Role in the package |
| --- | --- |
| `references/authentication.md` | Auth vault, profile reuse, `--auto-connect`, state files, OAuth/SSO, 2FA, cookie and token guidance |
| `references/commands.md` | Full command coverage for the current CLI surface |
| `references/profiling.md` | DevTools profile capture and analysis workflows |
| `references/proxy-support.md` | Proxy and geo-testing guidance |
| `references/session-management.md` | Parallel sessions, state persistence, cleanup, reuse |
| `references/snapshot-refs.md` | Snapshot structure, ref invalidation, region scoping, troubleshooting |
| `references/video-recording.md` | Evidence capture and repro videos |
| `templates/authenticated-session.sh` | Login-once and reuse-state scaffold |
| `templates/capture-workflow.sh` | Page capture scaffold |
| `templates/form-automation.sh` | Form automation scaffold |

These should be imported as a package set, not selectively recreated from memory.

## 4. Add new local `references/` for `agent-browser-verify`

Because there is no upstream verify package, the local verify lane needs a small focused reference set:

| Path | Purpose |
| --- | --- |
| `references/dev-server-smoke.md` | Canonical smoke flow for local dev servers and staging pages |
| `references/framework-overlays.md` | Detection patterns for common dev overlay surfaces and obvious error states |
| `references/console-network-diagnostics.md` | Use `console`, `errors`, `network requests`, and `network request <id>` instead of custom page globals |
| `references/session-hygiene.md` | Local owned-session policy from `/Users/maxibon/AGENTS.md` |
| `references/vercel-sandbox-smoke.md` | Optional Vercel/Sandbox browser path when the target is not a local host page |
| `templates/dev-server-smoke.sh` | One-page smoke template |
| `templates/route-matrix-smoke.sh` | Optional multi-route smoke template when several routes need the same checks |

This keeps the verify lane Tier-B-or-better without turning it into a second full command manual.

## 5. Replace stale verification mechanics with official commands

The current verify lane should stop teaching non-official console capture and default `networkidle` waits.

The refreshed verification contract should use:

- `agent-browser open <url>` as the initial navigation step
- `agent-browser batch ...` for 2-plus sequential steps when no intermediate parsing is needed
- `agent-browser snapshot -i` to confirm interactive structure
- `agent-browser screenshot --annotate` for quick visual evidence
- `agent-browser console` for browser console messages
- `agent-browser errors` for page errors
- `agent-browser network requests` and `agent-browser network request <id>` for request diagnosis
- `agent-browser wait --text`, `agent-browser wait <selector>`, `agent-browser wait --fn`, or short fixed waits for async UI settle

The verify lane should remove reliance on:

- `window.__consoleErrors`
- mandatory `wait --load networkidle` after every `open`
- unconditional session close on success

## 6. Default wait strategy must change

The new default guidance should be:

- `open` already covers page `load`
- no extra wait by default on ordinary pages
- use `wait 2000` or a targeted selector/text/function wait for slow SPAs
- reserve `wait --load networkidle` for pages known to go idle cleanly

This change is required because the official upstream skill now warns that `networkidle` can hang indefinitely on sites with analytics, ads, websockets, or background polling.

## 7. Encode deterministic session ownership in both skills

Both browser skills should explicitly teach the local session rules:

1. choose one deterministic session name per task
2. run `agent-browser session list` before opening or connecting
3. reuse the owned session if it already exists
4. if the owned session is stale or failed, close that same session before reopening
5. keep the owned session available for follow-up work by default
6. close only the owned session, never unrelated sessions

This is the local override to the official examples that say to close when done.

## 8. Add the modern security surface to the core skill

The refreshed core skill should explicitly teach the security features now documented officially:

- `--content-boundaries`
- `AGENT_BROWSER_ALLOWED_DOMAINS`
- `AGENT_BROWSER_ACTION_POLICY`
- `AGENT_BROWSER_MAX_OUTPUT`

These are especially relevant when the skill is used on arbitrary external pages or when page output could otherwise be injected into LLM context without clear boundaries.

The verify lane may reference these briefly, but the detailed guidance belongs in the core skill.

## 9. Expand the core skill to cover the current high-value surface area

The refreshed core skill should explicitly document or link to guidance for:

- `batch`
- `snapshot -i --urls`
- auth vault
- `--profile`
- `--session-name`
- `--auto-connect`
- dashboard
- stream enable or disable
- dialogs
- tabs
- downloads
- network inspection
- `--engine lightpanda`
- cloud providers only where officially supported in the upstream skill

The current local file does not cover enough of the current CLI surface to act as a reliable guided lane.

## 10. Update the doc metadata to point at the official browser docs

The current local `metadata.docs` field points at an OpenAI Codex announcement page, which is not the source of truth for the browser CLI itself.

The refreshed design should point documentation routing toward the official browser docs:

- `https://agent-browser.dev/`
- `https://agent-browser.dev/installation`
- `https://agent-browser.dev/commands`
- `https://agent-browser.dev/configuration`
- `https://agent-browser.dev/sessions`
- `https://agent-browser.dev/security`
- `https://agent-browser.dev/dashboard`
- `https://agent-browser.dev/streaming`
- `https://agent-browser.dev/cdp-mode`
- `https://agent-browser.dev/next`
- `https://agent-browser.dev/changelog`

If the future target surface is a local overlay package rather than the plugin cache, the frontmatter should stay minimal and valid while any plugin-specific discovery metadata stays in the platform surface that actually consumes it.

## Package Shape

## Future `agent-browser` package shape

The future refreshed package should look like:

```text
agent-browser/
  SKILL.md
  references/
    authentication.md
    commands.md
    profiling.md
    proxy-support.md
    session-management.md
    snapshot-refs.md
    video-recording.md
  templates/
    authenticated-session.sh
    capture-workflow.sh
    form-automation.sh
```

## Future `agent-browser-verify` package shape

The future refreshed verify package should look like:

```text
agent-browser-verify/
  SKILL.md
  references/
    console-network-diagnostics.md
    dev-server-smoke.md
    framework-overlays.md
    session-hygiene.md
    vercel-sandbox-smoke.md
  templates/
    dev-server-smoke.sh
    route-matrix-smoke.sh
```

## Verification Flow Contract

The future verify skill should teach one canonical smoke path:

1. Determine the target URL and deterministic session name.
2. Run `agent-browser session list`.
3. Reuse the owned session if present, or close only that owned stale session before reopening.
4. Open the page.
5. Take an annotated screenshot.
6. Run `snapshot -i`.
7. Collect `console` and `errors`.
8. Check `network requests` when the page appears stuck or partially rendered.
9. Verify one or more key routes only when the app structure makes that obvious.
10. Keep the session open unless explicit cleanup is required.

The default success report should include:

- final URL
- whether meaningful content rendered
- whether an error overlay was detected
- whether console or page errors were present
- whether interactive elements were discovered
- whether the owned session remains open for follow-up

## Acceptance Criteria

The future implementation is acceptable only if all of the following are true:

- The core browser skill imports the upstream `references/` and `templates/` inventory instead of recreating a partial local approximation.
- The local browser skill examples align to the current `0.25.x` command contract.
- The verify skill no longer mentions `window.__consoleErrors`.
- The verify skill no longer treats `wait --load networkidle` as the default settle strategy.
- Both skills encode deterministic owned-session behavior aligned to `/Users/maxibon/AGENTS.md`.
- The core skill points to official `agent-browser.dev` docs instead of unrelated Codex announcement docs.
- The future validation bundle proves CLI parity before skill content is declared refreshed.

## Validation Bundle For Future Implementation

Before declaring the refresh complete, the implementation pass should gather:

- `which -a agent-browser`
- `agent-browser --version`
- `npm view agent-browser version dist-tags --json`
- a package-structure diff showing the local core skill matches the upstream `skills/agent-browser/` inventory
- a smoke run such as:
  - `agent-browser open about:blank`
  - `agent-browser snapshot -i`
  - `agent-browser screenshot --annotate`
  - `agent-browser console`
  - `agent-browser errors`
  - `agent-browser session list`
- a verify-lane smoke run against a disposable URL or local page using the new deterministic session flow

## Risks

### Plugin cache overwrite risk

If implementation patches the generated plugin cache directly, a plugin refresh may overwrite the work. A future implementation plan should therefore decide explicitly whether the target is:

- a controlled local overlay, preferred
- or the generated plugin cache, only if that is the authoritative enabled surface in this environment

### Upstream drift risk

Because the official upstream package is moving, future implementation should pin the content refresh to the observed CLI version and official package state used during that implementation wave.

### Session leak risk

The local AGENTS contract intentionally keeps owned sessions alive for follow-up work. That improves continuity but creates a higher risk of idle session buildup if session naming and ownership rules are not followed exactly. The refresh must therefore make `session list` and owned-session cleanup explicit, not optional.

## Source Index

The design is grounded in the official browser docs and upstream package:

- `https://agent-browser.dev/`
- `https://agent-browser.dev/installation`
- `https://agent-browser.dev/skills`
- `https://agent-browser.dev/commands`
- `https://agent-browser.dev/configuration`
- `https://agent-browser.dev/sessions`
- `https://agent-browser.dev/security`
- `https://agent-browser.dev/dashboard`
- `https://agent-browser.dev/streaming`
- `https://agent-browser.dev/cdp-mode`
- `https://agent-browser.dev/next`
- `https://agent-browser.dev/changelog`
- `https://github.com/vercel-labs/agent-browser/tree/main/skills/agent-browser`

## Transition

After user review of this spec, the next phase is `writing-plans`. No implementation edits belong in this brainstorming phase.
