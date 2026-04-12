# Superpowers for Codex

This public fork is the Codex-only packaging of `obra/superpowers`. It installs as a native Codex plugin and ships a skills library for design, planning, execution, debugging, and review.

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

### 3. Install the local cmux launcher

```bash
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
```

### 4. Restart Codex

Quit and relaunch Codex after the plugin registration change.

## Verify

Confirm the local launcher is installed and the workstation is ready:

```bash
command -v cmux-superpowers
cmux-superpowers doctor
```

Confirm the plugin manifest exists:

```bash
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
```

Confirm plugin support is enabled:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

This public fork does not depend on Codex hook bootstrap. Start new sessions with:

```text
Use superpowers:using-superpowers before we start.
```

## Recommended workflow order

1. `using-superpowers`
2. `brainstorming`
3. `writing-plans`
4. `using-git-worktrees`
5. `subagent-driven-development` or `executing-plans`

Use `subagent-driven-development` when the task benefits from bounded implementation slices with review gates. Use `executing-plans` when you want the same plan executed sequentially in one session.

For a pane-based local team session in cmux, use:

```bash
cmux-superpowers team --worker review --worker implement "Implement the approved plan in this repository"
```

## Updating

Pull the local clone:

```bash
git -C ~/plugins/superpowers-codex pull
```

Restart Codex after updating so the refreshed plugin and skill content are loaded into new sessions.

## Uninstalling

Remove the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`, then delete the local clone:

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

### Skills not routing as expected

Start a fresh session and use the explicit entry instruction:

```text
Use superpowers:using-superpowers before we start.
```
