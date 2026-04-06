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

## Global Rules

- Use `references/`, never `reference/`.
- Put reusable helpers in `_shared/`, never under a sibling skill.
- User-facing skills must have metadata.
- Cache artifacts such as `__pycache__` and `.DS_Store` are forbidden.
