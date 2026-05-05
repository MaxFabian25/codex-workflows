# Agent-Browser Skill Truth Refresh Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use superpowers:using-git-worktrees to create the isolated workspace for this plan. Then use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the active `vercel:agent-browser` skill so it matches the current official `agent-browser.dev` docs, the local `agent-browser 0.25.3` CLI surface, and the `~/AGENTS.md` session contract.

**Architecture:** Do the real edits in the git-backed Vercel plugin source repo at `~/.codex/.tmp/plugins`, not directly in the generated cache. First import the fuller installed cache copy of `agent-browser/` into the source repo as a baseline, then refresh only the core `agent-browser` package there, and finally sync that one package back into the active cache with parity and live CLI verification. Because the active cache is not git-backed, source-repo commits are the durable history and cache sync is an explicit deployment step.

**Tech Stack:** Markdown skill packages, shell, `rg`, `rsync`, `diff`, `python3` standard library, `agent-browser 0.25.3`

---

## File Structure

Use these absolute paths during implementation:

- Source plugin repo root: `~/.codex/.tmp/plugins`
- Source `agent-browser` package: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser`
- Active cache `agent-browser` package: `~/.codex/plugins/cache/openai-curated/vercel/fb0a18376bcd9f2604047fbe7459ec5aed70c64b/skills/agent-browser`

Files that will exist after implementation:

- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/authentication.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/commands.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/configuration.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/debug-observability.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/diffing.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/profiling.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/proxy-support.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/security-and-confirmations.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/selectors.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/session-management.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/snapshot-refs.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/video-recording.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/authenticated-session.sh`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/capture-workflow.sh`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/form-automation.sh`

Do not modify `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser-verify/SKILL.md` in this plan.

Implementation commands below assume:

```bash
SRC_ROOT="$HOME/.codex/.tmp/plugins"
SRC_SKILL="$SRC_ROOT/plugins/vercel/skills/agent-browser"
CACHE_SKILL="$HOME/.codex/plugins/cache/openai-curated/vercel/fb0a18376bcd9f2604047fbe7459ec5aed70c64b/skills/agent-browser"
cd "$SRC_ROOT"
```

### Task 1: Import the Installed Cache Package into the Git-Backed Source Plugin

**Files:**
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser`
- Test: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references`
- Test: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates`

- [ ] **Step 1: Verify the source package is still the thin copy**

Run:

```bash
SRC_ROOT="$HOME/.codex/.tmp/plugins"
SRC_SKILL="$SRC_ROOT/plugins/vercel/skills/agent-browser"
cd "$SRC_ROOT"
test -d "$SRC_SKILL/references"
```

Expected: command exits with status `1` because the source package does not yet have a `references/` directory.

- [ ] **Step 2: Import the fuller installed cache package as the new baseline**

Run:

```bash
SRC_ROOT="$HOME/.codex/.tmp/plugins"
SRC_SKILL="$SRC_ROOT/plugins/vercel/skills/agent-browser"
CACHE_SKILL="$HOME/.codex/plugins/cache/openai-curated/vercel/fb0a18376bcd9f2604047fbe7459ec5aed70c64b/skills/agent-browser"
cd "$SRC_ROOT"
rsync -a --delete "$CACHE_SKILL/" "$SRC_SKILL/"
```

Expected: no output and the source package now contains `references/` and `templates/`.

- [ ] **Step 3: Verify the imported baseline exists in the source repo**

Run:

```bash
SRC_ROOT="$HOME/.codex/.tmp/plugins"
SRC_SKILL="$SRC_ROOT/plugins/vercel/skills/agent-browser"
cd "$SRC_ROOT"
test -f "$SRC_SKILL/references/commands.md"
test -f "$SRC_SKILL/templates/form-automation.sh"
```

Expected: both commands exit with status `0`.

- [ ] **Step 4: Commit the imported baseline**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add plugins/vercel/skills/agent-browser
git commit -m "chore: import agent-browser skill baseline"
```

Expected: commit succeeds and records the imported package baseline.

### Task 2: Refresh the Top-Level `SKILL.md`

**Files:**
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md`
- Test: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md`

- [ ] **Step 1: Write the failing structural check for the missing official-doc routes and auth/session decision table**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
path = Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md").expanduser()
text = path.read_text(encoding="utf-8")
required = [
    "https://agent-browser.dev/quick-start",
    "https://agent-browser.dev/selectors",
    "https://agent-browser.dev/snapshots",
    "https://agent-browser.dev/diffing",
    "https://agent-browser.dev/profiler",
    "Which persistence mechanism should I use?",
    "Use the official core workflow by default",
]
missing = [item for item in required if item not in text]
assert not missing, missing
PY
```

Expected: `AssertionError` listing the missing strings.

- [ ] **Step 2: Replace the `metadata.docs` list with the approved official-doc set**

Update the YAML frontmatter in `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md` so the `docs:` block is exactly:

```yaml
  docs:
    - "https://agent-browser.dev/"
    - "https://agent-browser.dev/installation"
    - "https://agent-browser.dev/quick-start"
    - "https://agent-browser.dev/skills"
    - "https://agent-browser.dev/commands"
    - "https://agent-browser.dev/configuration"
    - "https://agent-browser.dev/selectors"
    - "https://agent-browser.dev/snapshots"
    - "https://agent-browser.dev/diffing"
    - "https://agent-browser.dev/sessions"
    - "https://agent-browser.dev/security"
    - "https://agent-browser.dev/dashboard"
    - "https://agent-browser.dev/streaming"
    - "https://agent-browser.dev/profiler"
    - "https://agent-browser.dev/next"
    - "https://agent-browser.dev/changelog"
```

- [ ] **Step 3: Insert the new auth and session decision table plus the narrowed `batch` guidance**

Add this section immediately after the authentication overview in `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md`:

```md
## Which persistence mechanism should I use?

Use the smallest persistence surface that matches the job:

| Need | Use |
| --- | --- |
| Isolate one task from another | `--session <name>` |
| Reopen the same authenticated browser state by name | `--session-name <name>` |
| Reuse an existing Chrome profile or keep a dedicated persistent browser profile | `--profile <name-or-path>` |
| Save or load auth state explicitly as a file | `state save` / `state load` or `--state <path>` |
| Log in without exposing the password to the model | auth vault: `auth save` / `auth login` |

Locally, task ownership still comes from `--session <name>` and the local `~/AGENTS.md` session contract.
```

Replace the absolute `batch` rule with this text:

```md
Use the official core workflow by default: `open` -> `snapshot -i` -> interact -> re-snapshot only after the page changes. Use `batch` only when you do not need to inspect an intermediate command before deciding the next one.
```

- [ ] **Step 4: Update the wait strategy and deep-dive table**

Ensure the top-level wait guidance in `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md` says:

```md
**Default wait strategy:** `open` already waits for the page `load` event. Do not add an extra wait by default. Prefer `wait <selector>`, `wait --text`, `wait --fn`, or a short fixed wait for async content. Reserve `wait --load networkidle` for pages that you know will go idle cleanly.
```

Replace the deep-dive documentation table rows with this exact set:

```md
| Reference                                                                            | When to Use                                                            |
| ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| [references/commands.md](references/commands.md)                                     | Full command reference aligned to the current CLI help                 |
| [references/configuration.md](references/configuration.md)                           | Config precedence, env vars, safe defaults, and project config        |
| [references/selectors.md](references/selectors.md)                                   | Refs, semantic locators, CSS selectors, and when to use each          |
| [references/snapshot-refs.md](references/snapshot-refs.md)                           | Ref lifecycle, `snapshot -i --urls`, and snapshot troubleshooting     |
| [references/diffing.md](references/diffing.md)                                       | Verify state changes with `diff snapshot`, `diff screenshot`, and URL diffs |
| [references/authentication.md](references/authentication.md)                         | Auth vault, profiles, state files, SSO, and local persistence rules   |
| [references/session-management.md](references/session-management.md)                 | Deterministic session ownership and local reuse policy                |
| [references/security-and-confirmations.md](references/security-and-confirmations.md) | Content boundaries, allowlists, action policies, and confirmations    |
| [references/debug-observability.md](references/debug-observability.md)               | Console, errors, trace, profiler, recording, dashboard, and streaming |
| [references/profiling.md](references/profiling.md)                                   | Chrome DevTools profile capture details                               |
| [references/video-recording.md](references/video-recording.md)                       | Recording reproducible evidence                                        |
| [references/proxy-support.md](references/proxy-support.md)                           | Proxy configuration and geo-testing                                   |
```

- [ ] **Step 5: Run the structural check again to verify `SKILL.md` now passes**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
path = Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/SKILL.md").expanduser()
text = path.read_text(encoding="utf-8")
required = [
    "https://agent-browser.dev/quick-start",
    "https://agent-browser.dev/selectors",
    "https://agent-browser.dev/snapshots",
    "https://agent-browser.dev/diffing",
    "https://agent-browser.dev/profiler",
    "Which persistence mechanism should I use?",
    "Use the official core workflow by default",
    "references/security-and-confirmations.md",
    "references/debug-observability.md",
]
missing = [item for item in required if item not in text]
assert not missing, missing
assert "https://openai.com/index/introducing-codex/" not in text
PY
```

Expected: no output and exit status `0`.

- [ ] **Step 6: Commit the `SKILL.md` refresh**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add plugins/vercel/skills/agent-browser/SKILL.md
git commit -m "docs: refresh agent-browser skill entrypoint"
```

Expected: commit succeeds with only `SKILL.md` staged for this task.

### Task 3: Create `configuration.md`, `selectors.md`, and `diffing.md`

**Files:**
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/configuration.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/selectors.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/diffing.md`
- Test: same files

- [ ] **Step 1: Verify the new reference files do not exist yet**

Run:

```bash
SRC_SKILL="$HOME/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser"
test -f "$SRC_SKILL/references/configuration.md"
```

Expected: exit status `1`.

- [ ] **Step 2: Create `configuration.md`**

Write `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/configuration.md` with exactly:

````md
# Configuration

Persistent config, environment variables, and safe defaults for agent-browser.

**Related**: [commands.md](commands.md), [security-and-confirmations.md](security-and-confirmations.md), [SKILL.md](../SKILL.md)

## Config Precedence

Agent-browser resolves config in this order, lowest to highest priority:

1. `~/.agent-browser/config.json`
2. `./agent-browser.json`
3. environment variables
4. CLI flags

## Minimal Project Config

```json
{
  "headed": false,
  "screenshotFormat": "png",
  "downloadPath": "./downloads"
}
```

## Safer Agent Config

```json
{
  "contentBoundaries": true,
  "allowedDomains": "example.com,*.example.com",
  "maxOutput": 30000
}
```

## Boolean Override Rule

CLI boolean flags can override config values directly:

```bash
agent-browser --headed
agent-browser --headed false
```

## Useful Environment Variables

```bash
export AGENT_BROWSER_SESSION=docs-check
export AGENT_BROWSER_DOWNLOAD_PATH="$PWD/downloads"
export AGENT_BROWSER_CONTENT_BOUNDARIES=1
export AGENT_BROWSER_ALLOWED_DOMAINS="example.com,*.example.com"
export AGENT_BROWSER_MAX_OUTPUT=30000
```

## Common Check

Use this when config behavior seems wrong:

```bash
agent-browser --help
cat ./agent-browser.json
env | rg '^AGENT_BROWSER_'
```
````

- [ ] **Step 3: Create `selectors.md`**

Write `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/selectors.md` with exactly:

````md
# Selectors

Choose the smallest selector surface that keeps the interaction reliable.

**Related**: [snapshot-refs.md](snapshot-refs.md), [commands.md](commands.md), [SKILL.md](../SKILL.md)

## Default Order

1. `@e` refs from `snapshot -i`
2. semantic locators such as `find role`, `find label`, `find text`, `find placeholder`
3. CSS selectors only when the page already exposes a stable hook

## Refs First

```bash
agent-browser open https://example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
```

## Semantic Locators

```bash
agent-browser find role button click --name "Sign in"
agent-browser find label "Email" fill "user@example.com"
agent-browser find placeholder "Search" type "agent-browser"
```

## CSS Selectors

Use CSS only when the page already exposes something stable:

```bash
agent-browser click "#submit-button"
agent-browser wait "[data-testid='dashboard']"
```

## `snapshot -i --urls`

When you need to inspect links without clicking through and back:

```bash
agent-browser snapshot -i --urls
```

## Visual Fallback

When layout or unlabeled icon buttons matter:

```bash
agent-browser screenshot --annotate
```
````

- [ ] **Step 4: Create `diffing.md`**

Write `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/diffing.md` with exactly:

````md
# Diffing

Verify that an action actually changed the page instead of assuming success.

**Related**: [snapshot-refs.md](snapshot-refs.md), [commands.md](commands.md), [SKILL.md](../SKILL.md)

## Snapshot Diff

Use this after an interaction that should change the accessibility tree:

```bash
agent-browser snapshot -i
agent-browser click @e2
agent-browser diff snapshot
```

## Screenshot Diff

Use this for visual regressions:

```bash
agent-browser screenshot baseline.png
agent-browser diff screenshot --baseline baseline.png
```

## URL Diff

Use this when comparing two environments or routes:

```bash
agent-browser diff url https://staging.example.com https://prod.example.com --screenshot
```

## Recommended Rule

If the task says “verify”, do not stop at `click` or `fill`. Capture a baseline, perform the action, and use a diff or a targeted postcondition.
````

- [ ] **Step 5: Verify the new references exist and contain the expected anchors**

Run:

```bash
SRC_SKILL="$HOME/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser"
test -f "$SRC_SKILL/references/configuration.md"
test -f "$SRC_SKILL/references/selectors.md"
test -f "$SRC_SKILL/references/diffing.md"
rg -n "Config Precedence|snapshot -i --urls|diff snapshot" "$SRC_SKILL/references/configuration.md" "$SRC_SKILL/references/selectors.md" "$SRC_SKILL/references/diffing.md"
```

Expected: all three `test -f` commands exit `0`, and `rg` prints matching lines from all three files.

- [ ] **Step 6: Commit the new reference files**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add \
  plugins/vercel/skills/agent-browser/references/configuration.md \
  plugins/vercel/skills/agent-browser/references/selectors.md \
  plugins/vercel/skills/agent-browser/references/diffing.md
git commit -m "docs: add agent-browser config selector and diff refs"
```

Expected: commit succeeds with the three new reference files.

### Task 4: Create `security-and-confirmations.md` and `debug-observability.md`

**Files:**
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/security-and-confirmations.md`
- Create: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/debug-observability.md`
- Test: same files

- [ ] **Step 1: Verify the new security reference does not exist yet**

Run:

```bash
SRC_SKILL="$HOME/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser"
test -f "$SRC_SKILL/references/security-and-confirmations.md"
```

Expected: exit status `1`.

- [ ] **Step 2: Create `security-and-confirmations.md`**

Write `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/security-and-confirmations.md` with exactly:

````md
# Security And Confirmations

Protect the model from untrusted page output and gate actions that should not run silently.

**Related**: [configuration.md](configuration.md), [commands.md](commands.md), [SKILL.md](../SKILL.md)

## Content Boundaries

Wrap page output in explicit markers when page content is untrusted:

```bash
export AGENT_BROWSER_CONTENT_BOUNDARIES=1
agent-browser snapshot
```

## Domain Allowlist

Restrict navigation and subresource access:

```bash
export AGENT_BROWSER_ALLOWED_DOMAINS="example.com,*.example.com"
agent-browser open https://example.com
```

## Action Policy

Gate destructive actions with an explicit policy file:

```json
{ "default": "deny", "allow": ["navigate", "snapshot", "click", "scroll", "wait", "get"] }
```

```bash
export AGENT_BROWSER_ACTION_POLICY=./policy.json
```

## Confirmations

Require confirmation for sensitive categories:

```bash
agent-browser --confirm-actions "download,clipboard" click @e4
agent-browser confirm <id>
agent-browser deny <id>
```

Use interactive confirmations only in a real TTY:

```bash
agent-browser --confirm-interactive click @e4
```
````

- [ ] **Step 3: Create `debug-observability.md`**

Write `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/debug-observability.md` with exactly:

````md
# Debug And Observability

Use the lightest inspection surface that answers the current question.

**Related**: [commands.md](commands.md), [profiling.md](profiling.md), [video-recording.md](video-recording.md), [SKILL.md](../SKILL.md)

## Recommended Order

1. `snapshot -i`
2. `console`
3. `errors`
4. `network requests`
5. `trace` or `profiler`
6. `record`
7. `dashboard` and `stream`

## Console And Page Errors

```bash
agent-browser console
agent-browser errors
```

## Network Inspection

```bash
agent-browser network requests
agent-browser network request <requestId>
```

## Trace And Profiler

```bash
agent-browser trace start
agent-browser trace stop trace.zip
agent-browser profiler start
agent-browser profiler stop profile.json
```

## Video Recording

```bash
agent-browser record start flow.webm
agent-browser record stop
```

## Dashboard And Streaming

```bash
agent-browser dashboard start
agent-browser stream status
```
````

- [ ] **Step 4: Verify both new references now exist**

Run:

```bash
SRC_SKILL="$HOME/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser"
test -f "$SRC_SKILL/references/security-and-confirmations.md"
test -f "$SRC_SKILL/references/debug-observability.md"
rg -n "AGENT_BROWSER_CONTENT_BOUNDARIES|agent-browser console|agent-browser trace start" \
  "$SRC_SKILL/references/security-and-confirmations.md" \
  "$SRC_SKILL/references/debug-observability.md"
```

Expected: `test -f` exits `0` for both files and `rg` prints the three expected anchors.

- [ ] **Step 5: Commit the security and observability references**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add \
  plugins/vercel/skills/agent-browser/references/security-and-confirmations.md \
  plugins/vercel/skills/agent-browser/references/debug-observability.md
git commit -m "docs: add agent-browser security and observability refs"
```

Expected: commit succeeds with the two new reference files.

### Task 5: Refresh the Existing Reference Files

**Files:**
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/authentication.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/commands.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/profiling.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/proxy-support.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/session-management.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/snapshot-refs.md`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/video-recording.md`
- Test: same files

- [ ] **Step 1: Write the failing check for stale wait strategy and missing command coverage**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
files = {
    "auth": Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/authentication.md").expanduser(),
    "commands": Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/commands.md").expanduser(),
    "session": Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references/session-management.md").expanduser(),
}
auth = files["auth"].read_text(encoding="utf-8")
commands = files["commands"].read_text(encoding="utf-8")
session = files["session"].read_text(encoding="utf-8")
assert "wait --load networkidle" not in auth
assert "agent-browser confirm <id>" in commands
assert "agent-browser console" in commands
assert "agent-browser chat <message>" in commands
assert "Do not use `close --all` unless the user explicitly asks for global teardown." in session
PY
```

Expected: `AssertionError`.

- [ ] **Step 2: Refresh `authentication.md` and `session-management.md`**

Make these exact content changes:

```diff
--- a/references/authentication.md
+++ b/references/authentication.md
@@
-# Navigate to login page
-agent-browser open https://app.example.com/login
-agent-browser wait --load networkidle
+# Navigate to login page
+agent-browser open https://app.example.com/login
+agent-browser snapshot -i
@@
-# Submit
-agent-browser click @e3
-agent-browser wait --load networkidle
+# Submit
+agent-browser click @e3
+agent-browser wait --url "**/dashboard"
@@
-agent-browser --session-name twitter open https://twitter.com
-# ... login flow ...
-agent-browser close  # state saved to ~/.agent-browser/sessions/
+agent-browser --session-name twitter open https://twitter.com
+# ... login flow ...
+# Close only when you are intentionally ending the owned session and want state persisted at shutdown.
+agent-browser close
```

```diff
--- a/references/session-management.md
+++ b/references/session-management.md
@@
-# Continue with authenticated session
-agent-browser open https://app.example.com/dashboard
+# Continue with authenticated session
+agent-browser open https://app.example.com/dashboard
@@
-    agent-browser click @e3
-    agent-browser wait --load networkidle
+    agent-browser click @e3
+    agent-browser wait --url "**/dashboard"
@@
+## Local override
+
+Do not use `close --all` unless the user explicitly asks for global teardown.
@@
-# These use the same default session
-agent-browser open https://example.com
-agent-browser snapshot -i
-agent-browser close  # Closes default session
+# These use the same default session
+agent-browser open https://example.com
+agent-browser snapshot -i
+# Keep the owned session open by default locally.
```

- [ ] **Step 3: Refresh `snapshot-refs.md` and `commands.md`**

Make these exact content changes:

```diff
--- a/references/snapshot-refs.md
+++ b/references/snapshot-refs.md
@@
 # Interactive snapshot (-i flag) - RECOMMENDED
 agent-browser snapshot -i
+
+# Interactive snapshot plus link URLs
+agent-browser snapshot -i --urls
@@
 ### 4. Snapshot Specific Regions
 @@
 # Snapshot just the form by selector
 agent-browser snapshot -s "#signup-form"
+
+# Snapshot only the results region by selector
+agent-browser snapshot -s "#results"
+
+### 5. Use annotated screenshots when text snapshots are not enough
+
+```bash
+agent-browser screenshot --annotate
+```
```

```diff
--- a/references/commands.md
+++ b/references/commands.md
@@
 ## Dialogs
@@
 agent-browser dialog status         # Check if a dialog is currently open
 ```
+
+## Confirmation
+
+```bash
+agent-browser confirm <id>          # Approve a pending action
+agent-browser deny <id>             # Deny a pending action
+```
+
+## Console And Errors
+
+```bash
+agent-browser console               # View console messages
+agent-browser console --clear       # Clear captured console messages
+agent-browser errors                # View page errors
+agent-browser errors --clear        # Clear captured page errors
+```
+
+## Chat
+
+```bash
+agent-browser chat <message>        # Single-shot natural-language instruction
+agent-browser chat                  # Interactive REPL chat
+```
+
+## Session And State
+
+```bash
+agent-browser session               # Show current session name
+agent-browser session list          # List active sessions
+agent-browser state save auth.json  # Save cookies and storage
+agent-browser state load auth.json  # Restore cookies and storage
+```
+
+## Dashboard
+
+```bash
+agent-browser dashboard start
+agent-browser dashboard stop
+```
```

- [ ] **Step 4: Refresh `profiling.md`, `video-recording.md`, and `proxy-support.md`**

Make these exact content changes:

```diff
--- a/references/profiling.md
+++ b/references/profiling.md
@@
-agent-browser navigate https://app.example.com
-agent-browser wait --load networkidle
+agent-browser open https://app.example.com
+agent-browser wait --text "Dashboard"
```

```diff
--- a/references/video-recording.md
+++ b/references/video-recording.md
@@
-agent-browser click @e3
-agent-browser wait --load networkidle
+agent-browser click @e3
+agent-browser wait --url "**/dashboard"
@@
-    agent-browser close 2>/dev/null || true
+    # Keep the owned session open by default locally.
```

```diff
--- a/references/proxy-support.md
+++ b/references/proxy-support.md
@@
+> Local override: if an example closes a session, treat it as explicit cleanup only for the owned named session. Do not use `close --all` unless the user explicitly asks for global teardown.
```

- [ ] **Step 5: Verify the refreshed references now match the required contract**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
root = Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/references").expanduser()
auth = (root / "authentication.md").read_text(encoding="utf-8")
commands = (root / "commands.md").read_text(encoding="utf-8")
session = (root / "session-management.md").read_text(encoding="utf-8")
snapshot = (root / "snapshot-refs.md").read_text(encoding="utf-8")
profiling = (root / "profiling.md").read_text(encoding="utf-8")
video = (root / "video-recording.md").read_text(encoding="utf-8")
proxy = (root / "proxy-support.md").read_text(encoding="utf-8")
assert "wait --load networkidle" not in auth
assert "agent-browser confirm <id>" in commands
assert "agent-browser console" in commands
assert "agent-browser chat <message>" in commands
assert "snapshot -i --urls" in snapshot
assert "snapshot @e9" not in snapshot
assert "agent-browser screenshot --annotate" in snapshot
assert "wait --text \"Dashboard\"" in profiling
assert "wait --url \"**/dashboard\"" in video
assert "Do not use `close --all` unless the user explicitly asks for global teardown." in session
assert "Local override:" in proxy
PY
```

Expected: no output and exit status `0`.

- [ ] **Step 6: Commit the refreshed reference files**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add plugins/vercel/skills/agent-browser/references
git commit -m "docs: refresh agent-browser references"
```

Expected: commit succeeds with only the reference-file changes from this task.

### Task 6: Refresh Templates, Verify the Source Package, Sync to the Active Cache, and Smoke-Test It

**Files:**
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/authenticated-session.sh`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/capture-workflow.sh`
- Modify: `~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates/form-automation.sh`
- Modify: `~/.codex/plugins/cache/openai-curated/vercel/fb0a18376bcd9f2604047fbe7459ec5aed70c64b/skills/agent-browser/**` via `rsync`
- Test: source package and active cache package

- [ ] **Step 1: Write the failing template check**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
root = Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser/templates").expanduser()
auth = (root / "authenticated-session.sh").read_text(encoding="utf-8")
capture = (root / "capture-workflow.sh").read_text(encoding="utf-8")
form = (root / "form-automation.sh").read_text(encoding="utf-8")
assert "wait --load networkidle" not in auth
assert "wait --load networkidle" not in capture
assert "wait --load networkidle" not in form
assert "keep the owned session open by default" in capture
assert "keep the owned session open by default" in form
PY
```

Expected: `AssertionError`.

- [ ] **Step 2: Refresh the three templates**

Make these exact content changes:

```diff
--- a/templates/authenticated-session.sh
+++ b/templates/authenticated-session.sh
@@
-        agent-browser wait --load networkidle
-
         CURRENT_URL=$(agent-browser get url)
@@
-agent-browser open "$LOGIN_URL"
-agent-browser wait --load networkidle
+agent-browser open "$LOGIN_URL"
@@
-# agent-browser wait --load networkidle
+# agent-browser wait --url "**/dashboard"
@@
-# agent-browser wait --load networkidle
+# agent-browser wait --url "**/dashboard"
```

```diff
--- a/templates/capture-workflow.sh
+++ b/templates/capture-workflow.sh
@@
-# Navigate to target
-agent-browser open "$TARGET_URL"
-agent-browser wait --load networkidle
+# Navigate to target
+agent-browser open "$TARGET_URL"
@@
+# Keep the owned session open by default. Close only when explicit cleanup is required.
```

```diff
--- a/templates/form-automation.sh
+++ b/templates/form-automation.sh
@@
-# Step 1: Navigate to form
-agent-browser open "$FORM_URL"
-agent-browser wait --load networkidle
+# Step 1: Navigate to form
+agent-browser open "$FORM_URL"
@@
-# agent-browser wait --load networkidle
-# agent-browser wait --url "**/success"  # Or wait for redirect
+# agent-browser wait --url "**/success"
+# agent-browser wait --text "Thanks"
@@
+# Keep the owned session open by default. Close only when explicit cleanup is required.
```

- [ ] **Step 3: Verify the source package structurally and scan for stale patterns before committing**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
root = Path("~/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser").expanduser()
required = [
    root / "SKILL.md",
    root / "references" / "configuration.md",
    root / "references" / "selectors.md",
    root / "references" / "diffing.md",
    root / "references" / "security-and-confirmations.md",
    root / "references" / "debug-observability.md",
    root / "templates" / "authenticated-session.sh",
    root / "templates" / "capture-workflow.sh",
    root / "templates" / "form-automation.sh",
]
for path in required:
    assert path.exists(), path
skill = (root / "SKILL.md").read_text(encoding="utf-8")
assert "https://openai.com/index/introducing-codex/" not in skill
assert "https://agent-browser.dev/selectors" in skill
assert "https://agent-browser.dev/diffing" in skill
templates = [p.read_text(encoding="utf-8") for p in (root / "templates").glob("*.sh")]
assert all("wait --load networkidle" not in text for text in templates)
texts = [p.read_text(encoding="utf-8") for p in list(root.rglob("*.md")) + list(root.rglob("*.sh"))]
assert all("agent-browser wait --load networkidle" not in text for text in texts)
assert all("always use batch" not in text for text in texts)
assert all("--native" not in text for text in texts)
assert all("agent-browser close --all" not in text for text in texts)
PY
```

Expected: no output and exit status `0`.

- [ ] **Step 4: Commit the refreshed templates and any remaining source-package changes**

Run:

```bash
cd ~/.codex/.tmp/plugins
git add plugins/vercel/skills/agent-browser
git commit -m "docs: finalize agent-browser truth refresh"
```

Expected: commit succeeds and leaves the source repo clean.

- [ ] **Step 5: Sync the refreshed source package into the active cache**

Run:

```bash
SRC_SKILL="$HOME/.codex/.tmp/plugins/plugins/vercel/skills/agent-browser"
CACHE_SKILL="$HOME/.codex/plugins/cache/openai-curated/vercel/fb0a18376bcd9f2604047fbe7459ec5aed70c64b/skills/agent-browser"
rsync -a --delete "$SRC_SKILL/" "$CACHE_SKILL/"
diff -ru "$SRC_SKILL" "$CACHE_SKILL"
```

Expected: `rsync` completes without output and `diff -ru` prints nothing.

- [ ] **Step 6: Smoke-test the active cache package with the live CLI**

Run:

```bash
SESSION="agent-browser-truth-refresh-smoke"
agent-browser --version
agent-browser --help
agent-browser session list
agent-browser --session "$SESSION" close >/dev/null 2>&1 || true
agent-browser --session "$SESSION" batch \
  "open about:blank" \
  "snapshot -i" \
  "screenshot --annotate"
agent-browser --session "$SESSION" console
agent-browser --session "$SESSION" errors
agent-browser session list
agent-browser --session "$SESSION" close
```

Expected:

- `agent-browser --version` prints `agent-browser 0.25.3`
- `agent-browser --help` prints the current command groups
- `batch` against `about:blank` completes successfully
- `console` and `errors` return clean output for the smoke page
- the owned smoke session appears in `session list` before the final close and is gone after the final close
