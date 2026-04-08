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

3. Restart Codex.

4. Start a new session with:

   ```text
   Use superpowers:using-superpowers before we start.
   ```

Detailed Codex setup and workflow guidance lives in [docs/README.codex.md](docs/README.codex.md).

## Updating

Pull the local plugin clone, then restart Codex:

```bash
git -C ~/plugins/superpowers-codex pull
```

## Uninstalling

Remove the `superpowers-codex` plugin entry from `~/.agents/plugins/marketplace.json`, then delete the local clone:

```bash
rm -rf ~/plugins/superpowers-codex
```

## Support

- Issues: https://github.com/MaxFabian25/superpowers/issues
- Security advisories: https://github.com/MaxFabian25/superpowers/security/advisories/new

## Upstream origin

This fork derives from `obra/superpowers` and retains the MIT license.
