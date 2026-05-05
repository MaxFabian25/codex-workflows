# Codex Workflows

Codex Workflows is a Codex-only fork of `obra/superpowers`. It packages the workflow as a native Codex plugin plus a skills library for design, planning, execution, debugging, and review.

The package now follows a Natural-Language Agent Harness model. Agents and reviewers should start from [docs/language-contracts/](docs/language-contracts/) for human-facing workflow authority, while deterministic mechanics and explicit tool interfaces remain in code when code is the right tool.

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

4. Start a new session with:

   ```text
   Use codex-workflows:session-router before we start.
   ```

The package ships a native SessionStart hook as a lightweight adapter for the same router instruction. Manual session start remains the fallback when a host does not load plugin hooks.

Detailed Codex setup and workflow guidance lives in [docs/README.codex.md](docs/README.codex.md).

## Verify

Confirm the plugin and language-contract surfaces exist:

```bash
test -f ~/plugins/codex-workflows/.codex-plugin/plugin.json
test -f ~/plugins/codex-workflows/hooks/hooks.json
test -x ~/plugins/codex-workflows/hooks/session-start
test -f ~/plugins/codex-workflows/docs/language-contracts/README.md
test -f ~/plugins/codex-workflows/docs/language-contracts/session-router-playbook.md
```

Confirm Codex plugin support is enabled:

```bash
codex features list | rg '^plugins[[:space:]]+stable[[:space:]]+true$'
```

## Updating

Pull the local plugin clone, then restart Codex:

```bash
git -C ~/plugins/codex-workflows pull
```

If you moved the clone to a different path, update the plugin registration path and restart Codex.

## Uninstalling

First remove the `codex-workflows` entry from `~/.agents/plugins/marketplace.json`.

Then delete the local clone:

```bash
rm -rf ~/plugins/codex-workflows
```

The optional cmux team launcher is outside this core package unless a companion package explicitly owns it. The visual brainstorming companion remains package feature runtime when the brainstorming skill offers it and the user accepts it.

## Support

- Issues: https://github.com/MaxFabian25/codex-workflows/issues
- Security advisories: https://github.com/MaxFabian25/codex-workflows/security/advisories/new

## Upstream origin

This fork derives from `obra/superpowers` and retains the MIT license.
