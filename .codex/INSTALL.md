# Installing Superpowers for Codex

This fork installs as a native Codex plugin. It assumes you already have Codex CLI and Git.

## Install

1. Clone the repository into the local plugin path:

   ```bash
   mkdir -p ~/plugins
   git clone https://github.com/MaxFabian25/superpowers.git ~/plugins/superpowers-codex
   ```

2. Register the local plugin.

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

3. Restart Codex.

4. Start with the router.

   ```text
   Use superpowers-codex:using-superpowers before we start.
   ```

   The package ships a native SessionStart hook that injects this router instruction when the host loads plugin hooks. The explicit prompt is the manual fallback. See `docs/language-contracts/session-router-playbook.md`.

## Verify

Run:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
test -f ~/plugins/superpowers-codex/hooks/hooks.json
test -x ~/plugins/superpowers-codex/hooks/session-start
test -f ~/plugins/superpowers-codex/docs/language-contracts/README.md
test -f ~/plugins/superpowers-codex/docs/language-contracts/session-router-playbook.md
```

If automatic routing is unavailable, start a new session with:

```text
Use superpowers-codex:using-superpowers before we start.
```

## Update

```bash
git -C ~/plugins/superpowers-codex pull
```

Restart Codex after updating.

If you moved the clone to a different path, update the plugin registration path and restart Codex.

## Uninstall

First remove the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`.

Then delete the clone:

```bash
rm -rf ~/plugins/superpowers-codex
```

The optional `cmux-superpowers` launcher is outside this core package unless a companion package explicitly owns it. Feature runtime should not be retired solely because it is executable; see `docs/language-contracts/runtime-automation-playbook.md`.
