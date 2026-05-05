# Superpowers for Codex

This public fork is the Codex-only packaging of `obra/superpowers`. It installs as a native Codex plugin and ships a skills library for design, planning, execution, debugging, and review.

The package follows a Natural-Language Agent Harness model. Use [language-contracts/](language-contracts/) for human-facing routing, package, public-fork, runtime, and review obligations. Tools, tests, scripts, and package tasks provide evidence by default and become code-gated authority only when explicitly declared.

## Install

### 1. Clone the plugin

```bash
mkdir -p ~/plugins
git clone https://github.com/MaxFabian25/superpowers.git ~/plugins/superpowers-codex
```

### 2. Register the local plugin

If `~/.agents/plugins/marketplace.json` does not exist yet, create it with this full file content:

```json
{
  "name": "local-codex",
  "interface": {
    "displayName": "Local Codex Plugins"
  },
  "plugins": [
    {
      "name": "superpowers-codex",
      "source": {
        "source": "local",
        "path": "./plugins/superpowers-codex"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
```

If `~/.agents/plugins/marketplace.json` already exists, append this object inside its `plugins` array without changing unrelated entries:

```json
{
  "name": "superpowers-codex",
  "source": {
    "source": "local",
    "path": "./plugins/superpowers-codex"
  },
  "policy": {
    "installation": "AVAILABLE",
    "authentication": "ON_INSTALL"
  },
  "category": "Developer Tools"
}
```

### 3. Restart Codex

Quit and relaunch Codex after plugin registration or package updates.

### 4. Start with the router

The package ships a native SessionStart hook that injects the router instruction when the host loads plugin hooks. If automatic routing is unavailable, start sessions explicitly:

```text
Use superpowers-codex:using-superpowers before we start.
```

The routing contract is [language-contracts/session-router-playbook.md](language-contracts/session-router-playbook.md).

## Verify

Confirm the plugin manifest and language-contract authority exist:

```bash
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
test -f ~/plugins/superpowers-codex/hooks/hooks.json
test -x ~/plugins/superpowers-codex/hooks/session-start
test -f ~/plugins/superpowers-codex/docs/language-contracts/README.md
test -f ~/plugins/superpowers-codex/docs/language-contracts/session-router-playbook.md
```

Confirm plugin support is enabled:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

If automatic routing is unavailable, start new sessions with:

```text
Use superpowers-codex:using-superpowers before we start.
```

## Recommended workflow order

1. `using-superpowers`
2. `brainstorming`
3. `writing-plans`
4. `using-git-worktrees`
5. `subagent-driven-development` or `executing-plans`

Use `subagent-driven-development` when the task benefits from bounded implementation slices with review gates. Use `executing-plans` when you want the same plan executed sequentially in one session.

Pane-based local team sessions in cmux are outside this core package unless a companion package explicitly owns them.

## Updating

Pull the local clone:

```bash
git -C ~/plugins/superpowers-codex pull
```

Restart Codex after updating so the refreshed plugin and skill content are loaded into new sessions.

If you moved the clone to a different path, update the plugin registration path and restart Codex.

## Uninstalling

First remove the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`.

Then delete the local clone:

```bash
rm -rf ~/plugins/superpowers-codex
```

## Troubleshooting

### Plugin not discovered

Check that the local clone exists and the manifest is present:

```bash
test -d ~/plugins/superpowers-codex
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
```

Then confirm `~/.agents/plugins/marketplace.json` still contains the `superpowers-codex` entry and restart Codex.

### Plugins feature not enabled

Run:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

If that command prints nothing, update Codex to a build with stable plugin support before relying on the plugin install.

### Session routing not happening automatically

First confirm the hook files are present in the installed plugin. If the host still does not load plugin hooks, start a new session with the explicit router instruction and read [language-contracts/session-router-playbook.md](language-contracts/session-router-playbook.md). The hook is a lightweight adapter whose contract remains the playbook.

### Skills not routing as expected

Start a fresh session and use the explicit entry instruction:

```text
Use superpowers-codex:using-superpowers before we start.
```
