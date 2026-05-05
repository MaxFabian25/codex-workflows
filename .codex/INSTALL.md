# Installing Codex Workflows

This fork installs as a native Codex plugin. It assumes you already have Codex CLI and Git.

## Install

1. Clone the repository into the local plugin path:

   ```bash
   mkdir -p ~/plugins
   git clone https://github.com/MaxFabian25/codex-workflows.git ~/plugins/codex-workflows
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
         "name": "codex-workflows",
         "source": {
           "source": "local",
           "path": "./plugins/codex-workflows"
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
     "name": "codex-workflows",
     "source": {
       "source": "local",
       "path": "./plugins/codex-workflows"
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
   Use codex-workflows:session-router before we start.
   ```

   The package ships a native SessionStart hook that injects this router instruction when the host loads plugin hooks. The explicit prompt is the manual fallback. See `docs/language-contracts/session-router-playbook.md`.

## Verify

Run:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
test -f ~/plugins/codex-workflows/hooks/hooks.json
test -x ~/plugins/codex-workflows/hooks/session-start
test -f ~/plugins/codex-workflows/docs/language-contracts/README.md
test -f ~/plugins/codex-workflows/docs/language-contracts/session-router-playbook.md
```

If automatic routing is unavailable, start a new session with:

```text
Use codex-workflows:session-router before we start.
```

## Update

```bash
git -C ~/plugins/codex-workflows pull
```

Restart Codex after updating.

If you moved the clone to a different path, update the plugin registration path and restart Codex.

## Uninstall

First remove the `codex-workflows` entry from `~/.agents/plugins/marketplace.json`.

Then delete the clone:

```bash
rm -rf ~/plugins/codex-workflows
```

The optional cmux team launcher is outside this core package unless a companion package explicitly owns it. Feature runtime should not be retired solely because it is executable; see `docs/language-contracts/runtime-automation-playbook.md`.
