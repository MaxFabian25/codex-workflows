# Agent-Browser Skill Refresh Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use superpowers:using-git-worktrees to create the isolated workspace for this plan. Then use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the Vercel plugin's `agent-browser` skill to the current official upstream package shape and rebuild `agent-browser-verify` as a slim local overlay with deterministic session hygiene, official-doc routing, and repeatable validation.

**Architecture:** Work in the git-backed plugin source repo at `~/.codex/.tmp/plugins`, not the generated cache. Add one deterministic validation harness at repo root, sync the core `plugins/vercel/skills/agent-browser/` package from upstream with local frontmatter and session-policy overrides, then rebuild `plugins/vercel/skills/agent-browser-verify/` as a small local package with focused references and templates. Finish by syncing the edited source plugin into the installed cache and proving parity with structural checks plus `agent-browser` smoke commands.

**Tech Stack:** Markdown skill packages, Python 3 standard library, shell scripts, `curl`, `rsync`, `diff`, official `agent-browser` CLI

---

## File Structure

- `scripts/validate_agent_browser_skill_refresh.py`: repo-root structural validator for the Vercel plugin browser-skill refresh, with `core`, `verify`, and `full` scopes.
- `scripts/run_agent_browser_skill_refresh_checks.sh`: repo-root execution wrapper for structural validation, optional cache sync, parity diff, and CLI smoke checks.
- `plugins/vercel/skills/agent-browser/SKILL.md`: core browser skill entrypoint with plugin discovery frontmatter plus upstream `0.25.x` body and local session-policy overrides.
- `plugins/vercel/skills/agent-browser/references/authentication.md`: copied upstream authentication guidance.
- `plugins/vercel/skills/agent-browser/references/commands.md`: copied upstream command reference.
- `plugins/vercel/skills/agent-browser/references/profiling.md`: copied upstream profiling guidance.
- `plugins/vercel/skills/agent-browser/references/proxy-support.md`: copied upstream proxy guidance.
- `plugins/vercel/skills/agent-browser/references/session-management.md`: copied upstream session-management reference.
- `plugins/vercel/skills/agent-browser/references/snapshot-refs.md`: copied upstream snapshot/ref guidance.
- `plugins/vercel/skills/agent-browser/references/video-recording.md`: copied upstream video-capture guidance.
- `plugins/vercel/skills/agent-browser/templates/authenticated-session.sh`: copied upstream auth-session template.
- `plugins/vercel/skills/agent-browser/templates/capture-workflow.sh`: copied upstream capture template.
- `plugins/vercel/skills/agent-browser/templates/form-automation.sh`: copied upstream form template.
- `plugins/vercel/skills/agent-browser-verify/SKILL.md`: local verify overlay with official-doc routing, modern wait strategy, and no `window.__consoleErrors`.
- `plugins/vercel/skills/agent-browser-verify/references/dev-server-smoke.md`: canonical smoke-check workflow.
- `plugins/vercel/skills/agent-browser-verify/references/framework-overlays.md`: framework overlay detection selectors and fallback checks.
- `plugins/vercel/skills/agent-browser-verify/references/console-network-diagnostics.md`: official `console`, `errors`, and `network` diagnostic lane.
- `plugins/vercel/skills/agent-browser-verify/references/session-hygiene.md`: deterministic owned-session policy from `~/AGENTS.md`.
- `plugins/vercel/skills/agent-browser-verify/references/vercel-sandbox-smoke.md`: deployed/Vercel-specific smoke guidance when localhost is not the right surface.
- `plugins/vercel/skills/agent-browser-verify/templates/dev-server-smoke.sh`: reusable one-URL smoke-check shell template.
- `plugins/vercel/skills/agent-browser-verify/templates/route-matrix-smoke.sh`: reusable multi-route smoke-check shell template.

Implementation repo root for all commands below: `~/.codex/.tmp/plugins`

## Task 1: Add the Validation Harness

**Files:**
- Create: `scripts/validate_agent_browser_skill_refresh.py`
- Create: `scripts/run_agent_browser_skill_refresh_checks.sh`
- Test: `scripts/validate_agent_browser_skill_refresh.py`

- [ ] **Step 1: Write the failing structural validator**

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERCEL = ROOT / "plugins" / "vercel"

CORE_REQUIRED = [
    "skills/agent-browser/SKILL.md",
    "skills/agent-browser/references/authentication.md",
    "skills/agent-browser/references/commands.md",
    "skills/agent-browser/references/profiling.md",
    "skills/agent-browser/references/proxy-support.md",
    "skills/agent-browser/references/session-management.md",
    "skills/agent-browser/references/snapshot-refs.md",
    "skills/agent-browser/references/video-recording.md",
    "skills/agent-browser/templates/authenticated-session.sh",
    "skills/agent-browser/templates/capture-workflow.sh",
    "skills/agent-browser/templates/form-automation.sh",
]

VERIFY_REQUIRED = [
    "skills/agent-browser-verify/SKILL.md",
    "skills/agent-browser-verify/references/dev-server-smoke.md",
    "skills/agent-browser-verify/references/framework-overlays.md",
    "skills/agent-browser-verify/references/console-network-diagnostics.md",
    "skills/agent-browser-verify/references/session-hygiene.md",
    "skills/agent-browser-verify/references/vercel-sandbox-smoke.md",
    "skills/agent-browser-verify/templates/dev-server-smoke.sh",
    "skills/agent-browser-verify/templates/route-matrix-smoke.sh",
]

OFFICIAL_DOCS = [
    "https://agent-browser.dev/",
    "https://agent-browser.dev/commands",
    "https://agent-browser.dev/sessions",
]

BANNED_CORE = [
    "https://openai.com/index/introducing-codex/",
]

BANNED_VERIFY = [
    "https://openai.com/index/introducing-codex/",
    "window.__consoleErrors",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def require_files(paths: list[str]) -> None:
    for rel in paths:
        path = VERCEL / rel
        if not path.exists():
            fail(f"missing required file {path.relative_to(ROOT)}")


def require_contains(path: Path, snippets: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for snippet in snippets:
        if snippet not in text:
            fail(f"{path.relative_to(ROOT)} missing required snippet {snippet!r}")


def require_not_contains(path: Path, snippets: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for snippet in snippets:
        if snippet in text:
            fail(f"{path.relative_to(ROOT)} still contains banned snippet {snippet!r}")


def validate_core() -> None:
    require_files(CORE_REQUIRED)
    skill = VERCEL / "skills/agent-browser/SKILL.md"
    session_ref = VERCEL / "skills/agent-browser/references/session-management.md"
    auth_template = VERCEL / "skills/agent-browser/templates/authenticated-session.sh"
    capture_template = VERCEL / "skills/agent-browser/templates/capture-workflow.sh"
    form_template = VERCEL / "skills/agent-browser/templates/form-automation.sh"
    require_contains(
        skill,
        OFFICIAL_DOCS
        + [
            "Local Session Contract",
            "agent-browser batch",
            "snapshot -i --urls",
            "AGENT_BROWSER_ALLOWED_DOMAINS",
            "AGENT_BROWSER_CONTENT_BOUNDARIES",
            "AGENT_BROWSER_ACTION_POLICY",
            "AGENT_BROWSER_MAX_OUTPUT",
        ],
    )
    require_not_contains(skill, BANNED_CORE)
    require_contains(
        session_ref,
        [
            "Local override: keep the owned session open by default.",
            "Do not use `close --all` unless the user explicitly asks for global teardown.",
        ],
    )
    require_contains(auth_template, ["Session remains open for follow-up work"])
    require_contains(capture_template, ["keep the owned session open by default"])
    require_contains(form_template, ["keep the owned session open by default"])


def validate_verify() -> None:
    require_files(VERIFY_REQUIRED)
    skill = VERCEL / "skills/agent-browser-verify/SKILL.md"
    require_contains(
        skill,
        OFFICIAL_DOCS
        + [
            "agent-browser session list",
            "agent-browser console",
            "agent-browser errors",
            "agent-browser network requests",
            "keep the owned session open",
        ],
    )
    require_not_contains(skill, BANNED_VERIFY)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", choices=["core", "verify", "full"], default="full")
    args = parser.parse_args()

    if args.scope in {"core", "full"}:
        validate_core()
    if args.scope in {"verify", "full"}:
        validate_verify()

    print(f"PASS: agent-browser skill refresh ({args.scope})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Write the verification wrapper**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCOPE="full"
SYNC_CACHE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --sync-cache)
      SYNC_CACHE=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

python3 scripts/validate_agent_browser_skill_refresh.py --scope "$SCOPE"

if [[ "$SYNC_CACHE" -eq 1 ]]; then
  CACHE_ROOT="$HOME/.codex/plugins/cache/openai-curated/vercel"
  CACHE_DIR="$(find "$CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

  if [[ -z "${CACHE_DIR:-}" || ! -d "$CACHE_DIR" ]]; then
    echo "FAIL: could not resolve installed Vercel plugin cache directory" >&2
    exit 1
  fi

  rsync -a --delete --exclude '.DS_Store' "plugins/vercel/" "$CACHE_DIR/"
  diff -rq --exclude '.DS_Store' "plugins/vercel" "$CACHE_DIR"
fi

if [[ "$SCOPE" == "full" ]]; then
  SESSION="agent-browser-skill-refresh-smoke"
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
fi

echo "PASS: agent-browser skill refresh checks"
```

- [ ] **Step 3: Make the wrapper executable**

Run: `chmod +x scripts/run_agent_browser_skill_refresh_checks.sh`
Expected: no output, executable bit set on `scripts/run_agent_browser_skill_refresh_checks.sh`

- [ ] **Step 4: Run the full baseline to prove failure before content changes**

Run: `bash scripts/run_agent_browser_skill_refresh_checks.sh --scope full`
Expected: FAIL from `scripts/validate_agent_browser_skill_refresh.py` because the new `references/` and `templates/` files do not exist yet and both current skill files still contain stale guidance

- [ ] **Step 5: Commit**

```bash
git add scripts/validate_agent_browser_skill_refresh.py scripts/run_agent_browser_skill_refresh_checks.sh
git commit -m "chore: add agent-browser skill refresh checks"
```

## Task 2: Sync the Core `agent-browser` Package from Upstream

**Files:**
- Modify: `plugins/vercel/skills/agent-browser/SKILL.md`
- Create: `plugins/vercel/skills/agent-browser/references/authentication.md`
- Create: `plugins/vercel/skills/agent-browser/references/commands.md`
- Create: `plugins/vercel/skills/agent-browser/references/profiling.md`
- Create: `plugins/vercel/skills/agent-browser/references/proxy-support.md`
- Create: `plugins/vercel/skills/agent-browser/references/session-management.md`
- Create: `plugins/vercel/skills/agent-browser/references/snapshot-refs.md`
- Create: `plugins/vercel/skills/agent-browser/references/video-recording.md`
- Create: `plugins/vercel/skills/agent-browser/templates/authenticated-session.sh`
- Create: `plugins/vercel/skills/agent-browser/templates/capture-workflow.sh`
- Create: `plugins/vercel/skills/agent-browser/templates/form-automation.sh`
- Test: `scripts/validate_agent_browser_skill_refresh.py`

- [ ] **Step 1: Copy the upstream references and templates into the core skill package**

```bash
mkdir -p \
  plugins/vercel/skills/agent-browser/references \
  plugins/vercel/skills/agent-browser/templates

for file in authentication.md commands.md profiling.md proxy-support.md session-management.md snapshot-refs.md video-recording.md; do
  curl -fsSL \
    "https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/references/${file}" \
    -o "plugins/vercel/skills/agent-browser/references/${file}"
done

for file in authenticated-session.sh capture-workflow.sh form-automation.sh; do
  curl -fsSL \
    "https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/templates/${file}" \
    -o "plugins/vercel/skills/agent-browser/templates/${file}"
done

chmod +x \
  plugins/vercel/skills/agent-browser/templates/authenticated-session.sh \
  plugins/vercel/skills/agent-browser/templates/capture-workflow.sh \
  plugins/vercel/skills/agent-browser/templates/form-automation.sh
```

- [ ] **Step 2: Rewrite `plugins/vercel/skills/agent-browser/SKILL.md` around the upstream body with local plugin metadata and session-policy overrides**

```python
from __future__ import annotations

import urllib.request
from pathlib import Path


target = Path("plugins/vercel/skills/agent-browser/SKILL.md")
upstream = urllib.request.urlopen(
    "https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/SKILL.md"
).read().decode("utf-8")

parts = upstream.split("---\n", 2)
if len(parts) != 3:
    raise SystemExit("unexpected upstream SKILL.md frontmatter layout")

body = parts[2]
body = body.replace(
    "Always close your browser session when done to avoid leaked processes:\n",
    "Keep the owned session open by default. Close only when cleanup is explicit, the session is stale or failed, or the user asks for cleanup:\n",
)
body = body.replace(
    "If a previous session was not closed properly, the daemon may still be running. Use `agent-browser close` to clean it up, or `agent-browser close --all` to shut down every session at once.\n",
    "If a previous owned session was not closed properly, inspect it first with `agent-browser session list`, then close only that named session. Do not use `close --all` unless the user explicitly asks for global teardown.\n",
)
body = body.replace(
    "## Session Management and Cleanup\n",
    """## Session Management and Cleanup

## Local Session Contract

Follow `~/AGENTS.md` when using this skill locally:

- Use one deterministic `--session <name>` per task.
- Run `agent-browser session list` before any new `open` or `connect`.
- Reuse the owned session if it already exists.
- Close only the owned session when cleanup is explicit, the user requests it, or the session is stale or failed.
- Do not close unrelated sessions.

This local contract overrides generic upstream examples that close the browser immediately when done.

""",
    1,
)

frontmatter = """---
name: agent-browser
description: Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating any browser task. Also triggers when a dev server starts so you can verify it visually.
metadata:
  priority: 3
  docs:
    - "https://agent-browser.dev/"
    - "https://agent-browser.dev/installation"
    - "https://agent-browser.dev/skills"
    - "https://agent-browser.dev/commands"
    - "https://agent-browser.dev/configuration"
    - "https://agent-browser.dev/sessions"
    - "https://agent-browser.dev/security"
    - "https://agent-browser.dev/dashboard"
    - "https://agent-browser.dev/streaming"
    - "https://agent-browser.dev/cdp-mode"
    - "https://agent-browser.dev/next"
    - "https://agent-browser.dev/changelog"
  pathPatterns:
    - 'agent-browser.json'
    - 'playwright.config.*'
    - 'e2e/**'
    - 'tests/e2e/**'
    - 'test/e2e/**'
    - 'cypress/**'
    - 'cypress.config.*'
  bashPatterns:
    - '\\bagent-browser\\b'
    - '\\bnext\\s+dev\\b'
    - '\\bnpm\\s+run\\s+dev\\b'
    - '\\bpnpm\\s+dev\\b'
    - '\\bbun\\s+run\\s+dev\\b'
    - '\\byarn\\s+dev\\b'
    - '\\bvite\\b'
    - '\\bnuxt\\s+dev\\b'
    - '\\bvercel\\s+dev\\b'
    - '\\blocalhost:\\d+'
    - '\\b127\\.0\\.0\\.1:\\d+'
    - '\\bcurl\\s+.*localhost'
    - '\\bopen\\s+https?://'
    - '\\bplaywright\\b'
    - '\\bcypress\\b'
retrieval:
  aliases:
    - browser automation
    - puppeteer
    - playwright
    - web scraping
  intents:
    - automate browser
    - take screenshot
    - test web app
    - fill form
    - click button
  entities:
    - Puppeteer
    - Playwright
    - screenshot
    - browser
    - headless
chainTo:
  -
    pattern: 'localhost:\\d+|127\\.0\\.0\\.1:\\d+'
    targetSkill: agent-browser-verify
    message: 'Dev server URL detected — loading browser verification skill to run a visual gut-check (page loads, console errors, key UI elements).'
  -
    pattern: 'playwright\\.config|cypress\\.config|\\.spec\\.(ts|js)|\\.test\\.(ts|js).*browser'
    targetSkill: nextjs
    message: 'End-to-end test configuration detected — loading Next.js guidance for framework-aware test setup and dev server integration.'
---
"""

target.write_text(frontmatter + "\n" + body, encoding="utf-8")
```

- [ ] **Step 3: Patch the imported session-management reference and templates so they honor the local owned-session contract**

```python
from pathlib import Path


root = Path("plugins/vercel/skills/agent-browser")

session_ref = root / "references/session-management.md"
session_text = session_ref.read_text(encoding="utf-8")
session_text = session_text.replace(
    "# Session Management\n\nMultiple isolated browser sessions with state persistence and concurrent browsing.\n",
    "# Session Management\n\nMultiple isolated browser sessions with state persistence and concurrent browsing.\n\n> Local override: keep the owned session open by default. Close only the owned named session when cleanup is explicit, the user asks for cleanup, or the session is stale or failed. Do not use `close --all` unless the user explicitly asks for global teardown.\n",
)
session_text = session_text.replace(
    "# Cleanup\nagent-browser --session site1 close\nagent-browser --session site2 close\nagent-browser --session site3 close\n",
    "# Cleanup\nagent-browser --session site1 close  # only when explicit cleanup is required\nagent-browser --session site2 close  # only for the owned named session\nagent-browser --session site3 close  # never close unrelated sessions\n",
)
session_ref.write_text(session_text, encoding="utf-8")

template_rewrites = {
    root / "templates/authenticated-session.sh": [
        (
            "agent-browser close 2>/dev/null || true\n",
            "echo \"Leaving the owned session open for follow-up work. Close it explicitly if cleanup is required.\"\n",
        ),
        (
            "agent-browser close\nexit 0\n",
            "echo \"Discovery complete. Session remains open for follow-up work; close it explicitly if cleanup is required.\"\nexit 0\n",
        ),
    ],
    root / "templates/capture-workflow.sh": [
        (
            "# Cleanup\nagent-browser close\n\necho \"\"\necho \"Capture complete:\"\n",
            "# Cleanup is explicit; keep the owned session open by default.\necho \"\"\necho \"Capture complete:\"\n",
        ),
    ],
    root / "templates/form-automation.sh": [
        (
            "# Cleanup\nagent-browser close\necho \"Done\"\n",
            "# Cleanup is explicit; keep the owned session open by default.\necho \"Done\"\n",
        ),
    ],
}

for path, replacements in template_rewrites.items():
    text = path.read_text(encoding="utf-8")
    for old, new in replacements:
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
```

- [ ] **Step 4: Run the core-only validator and make sure the core package now passes on its own**

Run: `bash scripts/run_agent_browser_skill_refresh_checks.sh --scope core`
Expected: PASS from `scripts/validate_agent_browser_skill_refresh.py --scope core`

- [ ] **Step 5: Confirm the core skill no longer points at the stale OpenAI docs and now includes the security surface plus the local session contract**

Run: `rg -n "introducing-codex|Local Session Contract|agent-browser.dev/commands|snapshot -i --urls|AGENT_BROWSER_ALLOWED_DOMAINS|AGENT_BROWSER_ACTION_POLICY|AGENT_BROWSER_MAX_OUTPUT" plugins/vercel/skills/agent-browser/SKILL.md`
Expected: no `introducing-codex` hits, positive hits for `Local Session Contract`, `agent-browser.dev/commands`, `snapshot -i --urls`, `AGENT_BROWSER_ALLOWED_DOMAINS`, `AGENT_BROWSER_ACTION_POLICY`, and `AGENT_BROWSER_MAX_OUTPUT`

- [ ] **Step 6: Commit**

```bash
git add \
  plugins/vercel/skills/agent-browser/SKILL.md \
  plugins/vercel/skills/agent-browser/references \
  plugins/vercel/skills/agent-browser/templates
git commit -m "feat: refresh core agent-browser skill from upstream"
```

## Task 3: Rebuild the Local `agent-browser-verify` Overlay and Prove the Full Refresh

**Files:**
- Modify: `plugins/vercel/skills/agent-browser-verify/SKILL.md`
- Create: `plugins/vercel/skills/agent-browser-verify/references/dev-server-smoke.md`
- Create: `plugins/vercel/skills/agent-browser-verify/references/framework-overlays.md`
- Create: `plugins/vercel/skills/agent-browser-verify/references/console-network-diagnostics.md`
- Create: `plugins/vercel/skills/agent-browser-verify/references/session-hygiene.md`
- Create: `plugins/vercel/skills/agent-browser-verify/references/vercel-sandbox-smoke.md`
- Create: `plugins/vercel/skills/agent-browser-verify/templates/dev-server-smoke.sh`
- Create: `plugins/vercel/skills/agent-browser-verify/templates/route-matrix-smoke.sh`
- Test: `scripts/validate_agent_browser_skill_refresh.py`
- Test: `scripts/run_agent_browser_skill_refresh_checks.sh`

- [ ] **Step 1: Create the verify references and templates**

```python
from __future__ import annotations

from pathlib import Path


root = Path("plugins/vercel/skills/agent-browser-verify")

files = {
    "references/dev-server-smoke.md": """# Dev Server Smoke Check

Use this reference for quick browser gut-checks on local dev servers and obvious UI breakage.

## Default Flow

1. Pick one deterministic session name for the task.
2. Run `agent-browser session list` before any new `open`.
3. Reuse the owned session if it already exists.
4. Open the target URL.
5. Take `screenshot --annotate`.
6. Run `snapshot -i`.
7. Run `console` and `errors`.
8. Use `network requests` only when the page looks stuck or partially rendered.
9. Keep the owned session open unless cleanup is explicit.

## Wait Strategy

- `open` already waits for page `load`.
- Do not default to `wait --load networkidle`.
- For slow SPAs, prefer `wait 2000`, `wait --text`, `wait <selector>`, or `wait --fn`.

## Success Report

Report:

- final URL
- whether meaningful page content rendered
- whether an overlay or blank-state signal was found
- whether console or page errors were present
- whether interactive elements were discovered
- whether the owned session remains open for follow-up
""",
    "references/framework-overlays.md": """# Framework Overlay Checks

Use `eval`, `snapshot`, and `screenshot --annotate` to detect common dev overlays.

## Known Selectors

- Next.js: `[data-nextjs-dialog]`
- Vite: `.vite-error-overlay`
- Webpack dev server: `#webpack-dev-server-client-overlay`

## Detection Command

```bash
agent-browser eval 'document.querySelector("[data-nextjs-dialog], .vite-error-overlay, #webpack-dev-server-client-overlay") ? "ERROR_OVERLAY" : "OK"'
```

## Blank-Screen Check

```bash
agent-browser eval 'document.body.innerText.trim().length > 0 ? "HAS_CONTENT" : "BLANK"'
```

If the selector check returns `OK` but the page still looks wrong, keep the screenshot, inspect `console`, inspect `errors`, and fall back to `network requests`.
""",
    "references/console-network-diagnostics.md": """# Console and Network Diagnostics

Use the official `agent-browser` diagnostics commands. Do not rely on custom page globals.

## Console and Page Errors

```bash
agent-browser console
agent-browser errors
```

Use `console` for warnings and developer logs. Use `errors` for uncaught page errors.

## Network Requests

```bash
agent-browser network requests
agent-browser network requests --type xhr,fetch
agent-browser network requests --status 4xx
agent-browser network request <requestId>
```

Use `network requests` when:

- the page spinner does not resolve
- UI renders partially
- navigation succeeds but data never appears
- console shows fetch failures

If you need a portable artifact for deeper debugging:

```bash
agent-browser network har start
agent-browser network har stop ./agent-browser-smoke.har
```
""",
    "references/session-hygiene.md": """# Session Hygiene

Follow `~/AGENTS.md` for local browser ownership.

## Rules

1. Use one deterministic `--session <name>` per task.
2. Run `agent-browser session list` before opening or connecting.
3. Reuse the owned session if it already exists.
4. If the owned session is stale or failed, close that same named session before reopening.
5. Keep the owned session open for follow-up work by default.
6. Never close unrelated sessions.

## Minimal Commands

```bash
agent-browser session list
agent-browser --session <name> session
agent-browser --session <name> get url
agent-browser --session <name> close
```
""",
    "references/vercel-sandbox-smoke.md": """# Vercel and Sandbox Smoke Checks

Use this reference when the target is a deployed environment or a Vercel-backed workflow rather than a plain localhost page.

## Browser Side

```bash
agent-browser open https://your-deployment.example.com
agent-browser screenshot --annotate
agent-browser snapshot -i
agent-browser console
agent-browser errors
```

## Server Side Correlation

```bash
vercel logs --follow
npx workflow inspect runs
npx workflow inspect run <run_id>
npx workflow health
```

Use the browser evidence first, then correlate with Vercel logs or Workflow state when the page is hanging, blank, or showing stale data.
""",
    "templates/dev-server-smoke.sh": """#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Usage: $0 <url> [session-name]}"
SESSION="${2:-$(echo "$URL" | tr ':/.?' '-' | tr -s '-')}"

agent-browser session list
agent-browser --session "$SESSION" close >/dev/null 2>&1 || true
agent-browser --session "$SESSION" open "$URL"
agent-browser --session "$SESSION" screenshot --annotate
agent-browser --session "$SESSION" snapshot -i
agent-browser --session "$SESSION" console
agent-browser --session "$SESSION" errors

echo "Smoke check completed for session: $SESSION"
echo "Session remains open for follow-up unless you close it explicitly."
""",
    "templates/route-matrix-smoke.sh": """#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:?Usage: $0 <base-url> <route> [<route> ...]}"
shift

SESSION="route-matrix-$(echo "$BASE_URL" | tr ':/.?' '-' | tr -s '-')"

agent-browser session list
agent-browser --session "$SESSION" close >/dev/null 2>&1 || true

for route in "$@"; do
  URL="${BASE_URL%/}/${route#/}"
  echo "Checking $URL"
  agent-browser --session "$SESSION" open "$URL"
  agent-browser --session "$SESSION" screenshot --annotate
  agent-browser --session "$SESSION" snapshot -i
  agent-browser --session "$SESSION" console
  agent-browser --session "$SESSION" errors
done

echo "Route matrix check completed for session: $SESSION"
echo "Close the session explicitly when cleanup is required."
""",
}

for rel, content in files.items():
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")

for rel in [
    "templates/dev-server-smoke.sh",
    "templates/route-matrix-smoke.sh",
]:
    (root / rel).chmod(0o755)
```

- [ ] **Step 2: Rewrite `plugins/vercel/skills/agent-browser-verify/SKILL.md` as a slim local overlay**

```python
from pathlib import Path


target = Path("plugins/vercel/skills/agent-browser-verify/SKILL.md")
target.write_text(
    """---
name: agent-browser-verify
description: Automated browser verification for dev servers. Use when a dev server starts or when the user asks for a fast visual gut-check that confirms page load, obvious overlay or blank-screen failures, console and page errors, and basic interactive render health before deeper work continues.
metadata:
  priority: 2
  docs:
    - "https://agent-browser.dev/"
    - "https://agent-browser.dev/commands"
    - "https://agent-browser.dev/sessions"
    - "https://agent-browser.dev/next"
    - "https://agent-browser.dev/changelog"
  pathPatterns: []
  bashPatterns:
    - '\\bnext\\s+dev\\b'
    - '\\bnpm\\s+run\\s+dev\\b'
    - '\\bpnpm\\s+dev\\b'
    - '\\bbun\\s+run\\s+dev\\b'
    - '\\byarn\\s+dev\\b'
    - '\\bvite\\s*(dev)?\\b'
    - '\\bnuxt\\s+dev\\b'
    - '\\bvercel\\s+dev\\b'
  promptSignals:
    phrases:
      - "check the page"
      - "check the browser"
      - "check the site"
      - "is the page working"
      - "is it loading"
      - "blank page"
      - "white screen"
      - "nothing showing"
      - "page is broken"
      - "screenshot the page"
      - "take a screenshot"
      - "check for errors"
      - "console errors"
      - "browser errors"
      - "page is stuck"
      - "page is hanging"
      - "page not loading"
      - "page frozen"
      - "spinner not stopping"
      - "page not responding"
      - "page won't load"
      - "page will not load"
      - "nothing renders"
      - "nothing rendered"
      - "ui is broken"
      - "screen is blank"
      - "screen is white"
      - "app won't load"
    allOf:
      - [check, page]
      - [check, browser]
      - [check, site]
      - [blank, page]
      - [white, screen]
      - [console, errors]
      - [page, broken]
      - [page, loading]
      - [not, rendering]
      - [page, stuck]
      - [page, hanging]
      - [page, frozen]
      - [page, timeout]
    anyOf:
      - "page"
      - "browser"
      - "screen"
      - "rendering"
      - "visual"
      - "spinner"
      - "loading"
    minScore: 6
retrieval:
  aliases:
    - browser verify
    - dev server check
    - visual check
    - page verification
  intents:
    - verify dev server
    - check page loads
    - find console errors
    - validate UI
  entities:
    - dev server
    - console errors
    - visual check
    - gut-check
chainTo:
  -
    pattern: 'console\\.(error|warn)\\s*\\(|Error:|TypeError:|ReferenceError:'
    targetSkill: investigation-mode
    message: 'Console errors detected during browser verification — loading investigation mode to debug root cause with structured error analysis.'
  -
    pattern: 'localhost:\\d+|127\\.0\\.0\\.1:\\d+|http://0\\.0\\.0\\.0:\\d+'
    targetSkill: agent-browser
    message: 'Dev server URL detected — loading browser automation skill for deeper interactive testing beyond the initial gut-check.'
---

# Dev Server Verification with agent-browser

Use this skill for fast browser smoke checks on dev servers and obvious page-breakage reports. It is intentionally narrower than `agent-browser`: verify the page loads, capture visual evidence, inspect official browser diagnostics, and stop once you have enough signal to continue or escalate.

## Default Flow

1. Pick one deterministic `--session <name>` for the task.
2. Run `agent-browser session list`.
3. Reuse the owned session if it already exists.
4. Open the page.
5. Take `screenshot --annotate`.
6. Run `snapshot -i`.
7. Run `console` and `errors`.
8. Use `network requests` only when the page is stuck, blank, or partially rendered.
9. Keep the owned session open for follow-up unless cleanup is explicit.

## Quick Verification Flow

```bash
agent-browser session list
agent-browser --session dev-smoke open http://localhost:3000
agent-browser --session dev-smoke screenshot --annotate
agent-browser --session dev-smoke snapshot -i
agent-browser --session dev-smoke console
agent-browser --session dev-smoke errors
```

## Verification Checklist

1. **Page loads** — `open` succeeds without timing out.
2. **No blank page** — the page contains meaningful content.
3. **No framework overlay** — known overlay selectors do not match.
4. **Console and page errors** — inspect `console` and `errors`.
5. **Key UI renders** — `snapshot -i` exposes the expected interactive surface.
6. **Session remains reusable** — keep the owned session open unless explicit cleanup is required.

## Wait Strategy

- `open` already waits for page `load`.
- Do not default to `wait --load networkidle`.
- For slow SPAs, prefer `wait 2000`, `wait --text`, `wait <selector>`, or `wait --fn`.

## Overlay and Blank-Screen Checks

```bash
agent-browser --session dev-smoke eval 'document.querySelector("[data-nextjs-dialog], .vite-error-overlay, #webpack-dev-server-client-overlay") ? "ERROR_OVERLAY" : "OK"'
agent-browser --session dev-smoke eval 'document.body.innerText.trim().length > 0 ? "HAS_CONTENT" : "BLANK"'
```

## Diagnosing a Stuck Page

When the page is stuck, correlate browser state with request data:

```bash
agent-browser --session dev-smoke network requests
agent-browser --session dev-smoke network requests --type xhr,fetch
agent-browser --session dev-smoke console
agent-browser --session dev-smoke errors
```

If the target is Vercel-backed rather than a plain local page, follow `references/vercel-sandbox-smoke.md` for the server-side correlation commands.

## Failure Handling

If verification fails:

1. Keep the annotated screenshot.
2. Capture `console` and `errors`.
3. Inspect `network requests` when the UI is hanging.
4. Keep the owned session open unless the user explicitly asked for cleanup.
5. Route to `investigation-mode` when the root cause is not obvious from the smoke check.

## References

| Reference | Use |
| --- | --- |
| `references/dev-server-smoke.md` | Default localhost smoke flow |
| `references/framework-overlays.md` | Known overlay selectors and blank-screen checks |
| `references/console-network-diagnostics.md` | Official diagnostics commands |
| `references/session-hygiene.md` | Local session ownership contract |
| `references/vercel-sandbox-smoke.md` | Deployed or Vercel-backed targets |
| `../agent-browser/references/session-management.md` | Broader session patterns |
| `../agent-browser/references/commands.md` | Full command surface |

## Templates

| Template | Use |
| --- | --- |
| `templates/dev-server-smoke.sh` | One-URL smoke check |
| `templates/route-matrix-smoke.sh` | Multi-route smoke check |
""",
    encoding="utf-8",
)
```

- [ ] **Step 3: Run the full validation bundle, sync the source plugin into the installed cache, and run the CLI smoke checks**

Run: `bash scripts/run_agent_browser_skill_refresh_checks.sh --scope full --sync-cache`
Expected: PASS from the structural validator, clean `diff -rq --exclude '.DS_Store'` between `plugins/vercel` and the installed cache directory, successful `agent-browser` smoke commands, and an explicit close of the owned smoke session only

- [ ] **Step 4: Spot-check the refreshed verify skill for the contract-cut markers**

Run: `rg -n "window.__consoleErrors|agent-browser console|agent-browser errors|agent-browser network requests|keep the owned session open|wait --load networkidle" plugins/vercel/skills/agent-browser-verify`
Expected: no `window.__consoleErrors` hit, positive hits for `agent-browser console`, `agent-browser errors`, `agent-browser network requests`, and `keep the owned session open`; any `wait --load networkidle` mentions must be cautionary rather than the default quick flow

- [ ] **Step 5: Commit**

```bash
git add \
  plugins/vercel/skills/agent-browser-verify/SKILL.md \
  plugins/vercel/skills/agent-browser-verify/references \
  plugins/vercel/skills/agent-browser-verify/templates
git commit -m "feat: rebuild agent-browser verify overlay"
```
