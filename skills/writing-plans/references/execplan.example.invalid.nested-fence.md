# Invalid ExecPlan Example

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

This file intentionally demonstrates a nested fence violation.

## Progress

- [ ] Remove the nested fence.

## Surprises & Discoveries

- Observation: Nested fences break chat-mode ExecPlan wrapping.
  Evidence: This file includes one below.

## Decision Log

- Decision: Keep a failing fixture.
  Rationale: Validator coverage.
  Date/Author: 2026-01-01 / Codex

## Outcomes & Retrospective

No outcomes yet.

## Context and Orientation

Fixture only.

## Plan of Work

Leave the nested fence in place.

## Concrete Steps

```bash
echo "nested fence"
```

## Validation and Acceptance

The validator should reject this because ExecPlan chat output must not contain nested triple-backtick fences.

## Idempotence and Recovery

Safe fixture.

## Artifacts and Notes

None.

## Interfaces and Dependencies

None.
