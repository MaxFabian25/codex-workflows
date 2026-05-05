# Process-Family Elicitation Contract Design

Date: 2026-04-10
Status: Approved design for implementation planning

## Summary

Adopt a single process-family contract for user elicitation across the Codex-only superpowers fork.

The contract becomes:

- root-thread owned for all user decisions
- `request_user_input` first for discrete branching decisions during brainstorming
- read-only child agents only for decomposition and evidence gathering
- parent-mediated handoff whenever a child discovers an unresolved decision
- aligned to the active local Codex CLI alpha surface instead of older generic tool assumptions

This is a hard cutover in process guidance. The repo should stop describing brainstorming as a purely chat-first loop when the current Codex runtime already exposes a structured elicitation tool that fits the workflow better.

## Goals

- Make the process-family skill library describe one coherent elicitation model instead of mixing free-text questioning, stale tool maps, and ad hoc child escalation.
- Integrate `request_user_input` where it adds the most value during brainstorming without turning the whole design flow into a form-based workflow.
- Preserve the current ownership boundary where `brainstorming` owns design and `dispatching-parallel-agents` owns read-only decomposition.
- Align process docs and prompt contracts with the active local Codex runtime:
  - `codex-cli 0.121.0-alpha.1`
  - latest alpha source tag: `rust-v0.121.0-alpha.1`
  - `default_mode_request_user_input = true`
  - `multi_agent_v2 = true`
  - this local superpowers implementation requires explicit outer `agent_type` on every multi-agent dispatch
- Keep the parent agent responsible for arbitration, assumptions, and final synthesis.

## Non-Goals

- Make child agents interactive with the user.
- Turn every brainstorming turn into a `request_user_input` prompt.
- Rework implementation-phase or review-phase ownership outside the elicitation boundary.
- Add compatibility guidance for non-Codex platforms.
- Implement code changes in this design phase.

## Current-State Findings

The current repo already points toward structured elicitation, but the contract surface is incomplete and inconsistent.

### Brainstorming already prefers structured choices, but does not name the tool

`skills/brainstorming/SKILL.md` requires:

- one question at a time
- multiple choice preferred when possible
- early decomposition for overly broad requests
- explicit approval gates before plan handoff

That is already a strong fit for `request_user_input`, but the skill never mentions it. As a result, the highest-friction part of the design flow still depends on free-text questioning even when the runtime can collect structured answers directly.

### Dispatch is already Codex-v2 aware, but not connected to brainstorming

`skills/dispatching-parallel-agents/SKILL.md` already translates the fanout lane to:

- `spawn_agent(task_name=..., agent_type="parallel_explorer", message="...")`
- parent-owned synthesis
- long `wait_agent(...)` only when blocked

That is the correct Codex-native read-only decomposition lane. The missing piece is a process-family rule for what happens when a child finds an unresolved user decision. Right now the repo does not define a standard handoff from child ambiguity back to parent elicitation.

### The shared Codex tool map is stale

`skills/using-superpowers/references/codex-tools.md` documents:

- `spawn_agent(task_name=..., agent_type="...", message="...")`
- `wait_agent(...)`
- `close_agent(...)`
- `update_plan(...)`
- `apply_patch`
- `exec_command`

It does not document several currently active local tools that matter to process-family behavior:

- `request_user_input(...)`
- `send_message(...)`
- `followup_task(...)`
- `list_agents(...)`

That leaves process skills with an incomplete view of the actual runtime surface they are supposed to target.

### The prompt-packet contract lags the verified local dispatch contract

`contract/prompt-packet.md` still under-described the dispatch contract at the time of this design. On `codex-cli 0.121.0-alpha.1` / `rust-v0.121.0-alpha.1`, the surfaced Codex tool schema requires `task_name` and `message`, while the upstream handler still treats `agent_type` as optional metadata; the local superpowers layer intentionally requires explicit outer `agent_type` and already relies on richer roles such as:

- `parallel_explorer`
- `implementer`
- `spec_reviewer`
- `code_quality_reviewer`
- `final_reviewer`

The prompt-packet contract should match both the surfaced schema and the stricter local requirement the rest of the process-family skills now assume.

### Upstream runtime constraints shape the design

Inspection of the latest alpha `openai/codex` source tag `rust-v0.121.0-alpha.1` shows:

- `request_user_input` is root-thread only
- subagents cannot call it directly
- the tool expects structured options
- the tool is gated by collaboration mode and feature flags
- the local machine currently has Default-mode availability enabled
- the surfaced Codex tool schema requires `task_name` and `message`, while the upstream handler still leaves `agent_type` optional

This means the right integration is parent-mediated elicitation, not “let child agents ask the user questions,” while the local skill layer separately enforces explicit `agent_type`.

## Design Decisions

## 1. Root thread owns all user elicitation

Add a process-family ownership rule:

- Only the root thread may ask the user for decisions.
- Child agents never ask the user directly.
- If a child discovers ambiguity, it returns a structured decision handoff to the parent.

This rule matches the upstream `request_user_input` constraint and keeps all user-facing arbitration in one place.

## 2. `request_user_input` becomes the default tool for discrete design decisions

When the active runtime exposes `request_user_input`, `brainstorming` should use it for discrete branch-point decisions that materially change the spec.

Use cases:

- choosing the first wedge when the request is too broad
- choosing among the required 2-3 approaches
- approving or revising a major design section when the response is naturally discrete
- approving the written spec as written, with edits, or with re-scope

Do not use it for:

- repo or runtime facts the agent can discover itself
- rich prose review where the user needs open-ended editorial feedback
- every conversational turn
- child-agent questions

## 3. Brainstorming stays conversational between branch points

The process should not collapse into a survey engine.

Between structured branch points, the parent continues using normal prose for:

- explaining tradeoffs
- presenting design sections
- absorbing nuanced user feedback
- clarifying editorial changes to the spec

The contract is “structured choices where they help, conversational flow everywhere else.”

## 4. Child agents return `decision needed` packets instead of asking questions

Add a standard child-to-parent ambiguity handoff for read-only decomposition.

Minimum shape:

- `decision_needed`: `yes` or `no`
- `decision_id`: stable short identifier
- `recommended_option`: one-line recommendation
- `options`: 2-3 concrete choices
- `evidence`: file references and why the decision matters

This lets `dispatching-parallel-agents` stay read-only while still contributing to fast design narrowing.

## 5. Process-family tools must describe the active Codex surface accurately

Update the shared Codex tool mapping to include the active elicitation and MultiAgentV2 surfaces:

- `request_user_input(...)`
- `spawn_agent(task_name=..., agent_type="...", message="...")`
- `send_message(...)`
- `followup_task(...)`
- `wait_agent(...)`
- `close_agent(...)`
- `list_agents(...)`

Also add a runtime note so process skills can verify feature-gated surfaces with `codex features list` when a relevant tool is absent from the surfaced session, while still treating this repo as V2-only on this machine:

- `default_mode_request_user_input` gates structured elicitation in Default mode
- `multi_agent_v2` gates the V2 child-agent surface
- the local superpowers layer still requires explicit `agent_type` on every dispatch even though upstream V2 leaves it optional

## 6. The prompt-packet contract must acknowledge the current role set

Update `contract/prompt-packet.md` so it no longer under-describes the role surface.

The contract should explicitly acknowledge the verified current roles used by this repo, while preserving the existing child-config rule:

- inherit config by default
- do not pass `model` or `reasoning_effort` unless the user explicitly asks

It should also add one new hard rule:

- prompt packets for child agents must not instruct the child to call `request_user_input`

## 7. The visual companion stays a special-case UX handoff in v1

Do not force the “offer visual companion” step through `request_user_input` in the first cut.

Reason:

- it is a special browser-consent handoff rather than a core design branch-point
- the current brainstorming skill requires it to be its own message
- keeping it as prose avoids unnecessary process churn while the elicitation contract is being tightened elsewhere

The browser lane should still be updated to describe Codex-native tool usage correctly, but it does not need to become a structured-elicitation step in v1.

## Revised Brainstorming Flow

The new canonical flow becomes:

1. Explore project context first.
2. If the request is too broad, either:
   - ask one wedge-lock `request_user_input` question, or
   - when the user asked for subagents and the surface decomposes cleanly, dispatch read-only `parallel_explorer` lanes to map the wedges before asking.
3. Parent synthesizes the read-only findings.
4. Parent asks the next discrete branch-point question with `request_user_input` only when the answer materially changes the spec.
5. Parent presents 2-3 approaches and locks the chosen approach.
6. Parent presents design sections, using structured approval only when the response is naturally discrete.
7. Parent writes the spec document.
8. Parent performs inline self-review.
9. Parent asks for user review of the written spec with a structured approval gate.
10. Only after approval does the workflow transition to `writing-plans`.

## Runtime Rules

## Eligibility

`request_user_input` is eligible only when all are true:

- the caller is the root thread
- the turn is interactive
- the decision cannot be resolved from repo or runtime context
- the answer materially changes the design or plan

## Question shape

Each invocation should normally contain one question with:

- a stable snake_case id
- 2-3 mutually exclusive options
- the recommended option first
- short human-readable labels
- descriptions that explain tradeoffs, not implementation internals

## Fallback behavior

This design does not preserve old multi-choice-in-plain-text workflows as a first-class compatibility path.

Instead:

- if `request_user_input` is unavailable but the session is still interactive, ask one concise plain-text question only when the decision is truly blocking
- if the session is non-interactive or child-scoped, return a blocker or make a documented assumption only when the risk is acceptable

That keeps the cutover hard while still handling runtime boundaries safely.

## Overuse guardrails

Add explicit anti-pattern guidance:

- do not issue back-to-back structured questions unless the previous answer unlocked a genuinely new design branch
- do not use `request_user_input` when rich prose is the real need
- do not let child agents become proxy questioning surfaces
- do not re-ask the same branch-point under a different wrapper once it has been accepted

## File Changes

## `contract/process-family.md`

Add a new ownership rule for root-owned elicitation and a cross-reference note that `dispatching-parallel-agents` returns decisions to the parent rather than eliciting directly.

## `contract/prompt-packet.md`

Update the Codex packet contract to:

- reflect the current verified role surface
- keep the child config inheritance rule
- add the child no-elicitation rule

## `skills/using-superpowers/references/codex-tools.md`

Expand the tool map to document:

- `request_user_input`
- `send_message`
- `followup_task`
- `list_agents`

Add a runtime preflight section covering `default_mode_request_user_input` and `multi_agent_v2`.

## `skills/brainstorming/SKILL.md`

Rewrite the questioning sections so the skill explicitly distinguishes between:

- structured branch-point decisions handled with `request_user_input`
- conversational explanation and editorial discussion handled in prose

Add explicit rules for:

- wedge-lock questions
- approach selection
- section approval
- written-spec approval gate

## `skills/dispatching-parallel-agents/SKILL.md`

Add the parent-mediated ambiguity handoff and clarify that read-only children may recommend options but may not question the user.

## `skills/brainstorming/visual-companion.md`

Update Codex-specific tool wording so it reflects the actual Codex runtime path for launching and maintaining the browser helper. Keep the consent step as prose in v1.

## What Does Not Change

- `brainstorming` still owns the design phase only.
- `dispatching-parallel-agents` remains a read-only or non-owning lane only.
- `writing-plans` remains the only next process skill after approved brainstorming.
- Child agents remain bounded and context-specific.
- The parent still owns final synthesis, assumptions, and user-facing arbitration.

## Verification Gates

The implementation plan should not call this design complete unless all of the following are true.

## 1. Contract coherence

- `process-family.md`, `prompt-packet.md`, and `codex-tools.md` all describe the same elicitation ownership model.
- No process-family skill still implies that a child agent may elicit user input directly.

## 2. Brainstorming behavior

- `brainstorming/SKILL.md` clearly distinguishes structured branch-point questioning from prose discussion.
- The skill explicitly names `request_user_input` in the places where it now expects structured choices.
- The skill does not encourage overuse of structured prompts.

## 3. Dispatch behavior

- `dispatching-parallel-agents/SKILL.md` defines a child ambiguity handoff instead of leaving escalation implicit.
- The skill still keeps synthesis and arbitration with the parent.

## 4. Runtime accuracy

- `codex-tools.md` matches the active local Codex tool surface that this repo intends to target.
- The docs mention preflight for `default_mode_request_user_input` and `multi_agent_v2`.
- The repo no longer treats the older partial tool map as sufficient guidance.

## Risks And Mitigations

## Risk: Over-structuring the design conversation

Mitigation:

- limit `request_user_input` to discrete branch points
- keep prose as the default between decisions
- add explicit anti-pattern guidance in the brainstorming skill

## Risk: Child agents still drift into interactive behavior

Mitigation:

- make the no-elicitation rule part of both the process-family contract and the prompt-packet contract
- define one explicit `decision needed` handoff shape instead of leaving escalation informal

## Risk: Repo docs target a runtime shape that drifts

Mitigation:

- document runtime preflight
- scope the design to the active local Codex alpha surface first
- fail closed when the required tool surface is absent instead of preserving stale compatibility guidance

## Risk: The visual-companion lane remains partially stale

Mitigation:

- update its Codex tool wording in the same wave
- keep the v1 change focused on runtime wording, not on redesigning the browser-consent step

## Acceptance Criteria

This design is successful when:

- the process-family contract clearly says user elicitation is root-owned;
- `brainstorming` uses `request_user_input` only for the branch points where it improves clarity;
- `dispatching-parallel-agents` returns unresolved decisions to the parent instead of questioning the user;
- the shared Codex tool map describes the active local elicitation and MultiAgentV2 surface accurately;
- prompt packets no longer under-describe the role surface or imply child-side elicitation;
- the repo reads as one coherent Codex-native process family rather than a mix of old chat-only habits and newer tool surfaces.
