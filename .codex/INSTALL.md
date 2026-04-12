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

3. Install the local cmux launcher.

   ```bash
   python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
   ```

4. Install the Superpowers SessionStart hook.

   ```bash
   python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
   ```

5. Install the cmux Codex hooks.

   ```bash
   cmux codex install-hooks
   ```

6. Enable Codex hooks.

   Persistent config:

   ```toml
   [features]
   codex_hooks = true
   ```

   One-shot launch:

   ```bash
   codex --enable codex_hooks
   ```

7. Restart Codex.

## Verify

Confirm the local launcher is installed and the workstation is ready:

```bash
command -v cmux-superpowers
cmux-superpowers doctor
```

Run:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
codex features list | rg '^codex_hooks[[:space:]]+under development'
test -f ~/.codex/hooks.json
rg 'loading superpowers|session-start' ~/.codex/hooks.json
```

Then start a new session with:

```text
Use superpowers:using-superpowers before we start.
```

## Update

```bash
git -C ~/plugins/superpowers-codex pull
```

Restart Codex after updating.

If you moved the clone to a different path, rerun:

```bash
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
```

## Uninstall

Remove the installed Superpowers hook, remove the cmux Codex hooks, remove the launcher wrapper, then delete the clone and plugin entry:

```bash
python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py --remove
cmux codex uninstall-hooks
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py --remove
rm -rf ~/plugins/superpowers-codex
```
