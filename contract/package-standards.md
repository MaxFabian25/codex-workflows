# Package Standards

## Package Tiers

### Tier A: thin entrypoint

- `SKILL.md`
- metadata when user-facing
- no hidden shared logic

### Tier B: guided lane

- `SKILL.md`
- metadata
- `references/` for routing or workflow details

### Tier C: executable lane

- `SKILL.md`
- metadata
- `references/`
- `scripts/` for executable helpers
- optional `assets/`, `examples/`, `tests/`

## Metadata Surface

Accepted metadata surfaces are exactly:

- `SKILL.md` frontmatter with `name` and `description`
- per-skill files such as `agents/openai.yaml` when the runtime expects them
- repo-level or platform-level manifests when skills are discovered natively from the repository or plugin bundle

## Global Rules

- Use `references/`, never `reference/`.
- Put reusable helpers in `_shared/`, never under a sibling skill.
- User-facing skills must have `SKILL.md` frontmatter with `name` and `description`.
- Other accepted metadata surfaces are additive, not substitutes for missing user-facing `SKILL.md` frontmatter.
- Cache artifacts such as `__pycache__` and `.DS_Store` are forbidden.
