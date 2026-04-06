# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery on this workstation.

## Quick Install

Use the `Manual Installation` steps in this README. They are authoritative for this workstation because they include the config source edit, live mirror sync, profile split, and child-role contract instead of sending maintainers through the generic upstream install path.

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. Edit the workstation config source at `~/.codex/config.macos-source.toml`.

4. Sync the live mirror:
   ```bash
   cp ~/.codex/config.macos-source.toml ~/.codex/config.toml
   ```

5. Restart Codex.

## How Codex Sees Superpowers

Codex discovers Superpowers through native skill discovery, not through a plugin manifest:

```text
~/.agents/skills/superpowers -> ~/.codex/superpowers/skills
```

The `using-superpowers` skill is discovered from that symlink and remains the workflow entrypoint.

## Required Agent Contract

For this workstation, the configured local contract is:

```toml
profile = "workflow_fidelity"

[features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = false

[agents]
max_threads = 32
max_depth = 3
job_max_runtime_seconds = 3600
```

Parallel override for bounded read-only fanout:

```toml
[profiles.parallel_readonly.features]
multi_agent = true
multi_agent_v2 = true
enable_fanout = true
```

Rules:

- `multi_agent_v2 = true` is required for both `workflow_fidelity` and `parallel_readonly`.
- `max_depth = 3` and `job_max_runtime_seconds = 3600` are authoritative.
- `enable_fanout` stays off in the default controller profile and is enabled only for the explicit `parallel_readonly` lane.
- Current proof on this workstation covers login-shell binary/version verification, profile feature-state verification, and matching role mappings present in both config surfaces.
- Disposable `codex exec` smoke currently resolves the live root checkout at `~/.codex/superpowers/skills`, not this branch worktree, so branch-local verification does not by itself prove active end-to-end custom-role dispatch.
- Custom child-role dispatch behavior should be verified after integrating this branch into the live checkout if runtime behavior is in doubt.
- If either `codex -p workflow_fidelity features list` or `codex -p parallel_readonly features list` does not show `multi_agent_v2 = true`, stop and treat that as a runtime blocker instead of weakening the docs.

## Profiles

- `workflow_fidelity`: default controller-first profile for `brainstorming`, `using-git-worktrees`, `writing-plans`, `subagent-driven-development`, `executing-plans`, `requesting-code-review`, and `finishing-a-development-branch`
- `parallel_readonly`: explicit profile for bounded read-only fanout such as `dispatching-parallel-agents`

Do not use `parallel_readonly` as the default implementation profile.

## Child Role Mapping

This workstation is configured for a v2-first child-role mapping. The configured local contract is declared in `~/.codex/config.macos-source.toml`, mirrored into `~/.codex/config.toml`, and backed by `~/.codex/agents/*.toml`:

| Role | Workflow use | Access mode |
|---|---|---|
| `implementer` | One bounded code-changing task in `subagent-driven-development` | Write-capable |
| `spec_reviewer` | Spec-compliance review after each task | Read-only |
| `code_quality_reviewer` | Code-quality review after spec passes | Read-only |
| `parallel_explorer` | Independent parallel exploration and audit work | Read-only |
| `final_reviewer` | Final whole-change review pass | Read-only |

Superpowers workflow docs refer to these configured local role names. Profile feature-state verification proves the profile flags; if role-dispatch behavior is in doubt, it should be verified separately. The parent session remains responsible for user clarification, arbitration, and final synthesis.

## Updating

```bash
cd ~/.codex/superpowers && git pull
cp ~/.codex/config.macos-source.toml ~/.codex/config.toml
```

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.codex/superpowers/skills`
3. Restart Codex

### v2 not activating

Run:

```bash
codex -p workflow_fidelity features list
codex -p parallel_readonly features list
```

If either profile reports `multi_agent_v2 = false`, stop and fix the runtime or config before trusting any subagent workflow docs.
