# Superpowers for Codex

Superpowers for Codex is a Codex-only fork of `obra/superpowers`. It packages the workflow as a native Codex plugin plus a skills library for design, planning, execution, debugging, and review.

## Included workflow skills

- `brainstorming`
- `writing-plans`
- `subagent-driven-development`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `requesting-code-review`
- `receiving-code-review`
- `verification-before-completion`

## Install in Codex

1. Clone the plugin locally:

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

3. Install the local cmux launcher:

   ```bash
   python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
   ```

4. Install the Superpowers SessionStart hook:

   ```bash
   python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
   ```

5. Install the cmux Codex hooks:

   ```bash
   cmux codex install-hooks
   ```

6. Enable Codex hooks in persistent config.

   The launcher and `cmux-superpowers doctor` read the persisted setting from `~/.codex/config.toml`, so set it there instead of relying on a one-shot flag.

   Persistent config:

   ```toml
   [features]
   codex_hooks = true
   ```

7. Restart Codex.

8. Start a new session with:

   ```text
   Use superpowers:using-superpowers before we start.
   ```

Detailed Codex setup and workflow guidance lives in [docs/README.codex.md](docs/README.codex.md).

## Verify

Confirm the local launcher is installed and the workstation is ready:

```bash
command -v cmux-superpowers
cmux-superpowers doctor
```

Confirm the plugin and hook surfaces exist:

```bash
test -f ~/plugins/superpowers-codex/.codex-plugin/plugin.json
test -f ~/.codex/hooks.json
rg 'loading superpowers|session-start' ~/.codex/hooks.json
```

Confirm Codex plugin and hook support is enabled:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
codex features list | rg '^codex_hooks[[:space:]]+under development[[:space:]]+true$'
```

## Updating

Pull the local plugin clone, then restart Codex:

```bash
git -C ~/plugins/superpowers-codex pull
```

If you moved the clone to a different path, rerun:

```bash
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py
python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py
```

## Uninstalling

First remove the `superpowers-codex` entry from `~/.agents/plugins/marketplace.json`.

Then remove the installed Superpowers hook, remove the cmux Codex hooks, remove the launcher wrapper, and delete the local clone:

```bash
python3 ~/plugins/superpowers-codex/scripts/install_codex_hooks.py --remove
cmux codex uninstall-hooks
python3 ~/plugins/superpowers-codex/scripts/install_cmux_superpowers_launcher.py --remove
rm -rf ~/plugins/superpowers-codex
```

## Support

- Issues: https://github.com/MaxFabian25/superpowers/issues
- Security advisories: https://github.com/MaxFabian25/superpowers/security/advisories/new

## Upstream origin

This fork derives from `obra/superpowers` and retains the MIT license.
