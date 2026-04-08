## Execution-Planning

Use an ExecPlan (as described in `.agent/PLANS.md`) for multi-hour work, complex features, significant refactors, or milestone/sub-agent execution.

Treat the ExecPlan as a living document from design through implementation. Keep these required sections up to date at every stopping point: `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective`.

Execute milestone-by-milestone without asking for "next steps" between milestones.

Record verification evidence for milestone progress (command, expected result, observed result). Never claim verification you did not run.

Treat commits and destructive operations as policy-gated: default to additive, reversible changes unless user and repository instructions explicitly permit otherwise.
