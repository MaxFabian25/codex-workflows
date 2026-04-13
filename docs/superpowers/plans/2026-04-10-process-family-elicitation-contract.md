# Process-Family Elicitation Contract Implementation Plan

> **For agentic workers:** REQUIRED FLOW: First use superpowers:using-git-worktrees to create the isolated workspace for this plan. Then use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the process-family contracts, tool map, and design-phase skills so the Codex-only superpowers fork uses one root-owned elicitation model built around `request_user_input` and parent-mediated read-only subagent decomposition.

**Architecture:** Implement this as a validator-first docs cutover. First extend the existing process-family validator so it fails when the new elicitation contract is absent, then update the contract docs and skills in three focused waves: root-owned contract surfaces, structured-elicitation design guidance, and parent-mediated dispatch plus visual-companion runtime wording. Finish with deterministic validation and residual string sweeps so the resulting contract is enforced rather than advisory.

**Tech Stack:** Markdown docs, Python 3 validator updates, shell verification, existing process-family validator

---

## File Structure

- `_shared/validators/validate_skill_library.py`: structural validator for process-family contract targets; extend it with elicitation-specific required text and stale-guidance guards.
- `contract/process-family.md`: canonical phase ownership; add the root-owned elicitation rule and clarify that child agents return unresolved decisions to the parent.
- `contract/prompt-packet.md`: verified Codex dispatch packet shape; update the documented role surface and add a no-child-elicitation rule.
- `skills/using-superpowers/references/codex-tools.md`: shared Codex tool map; add the active local elicitation and MultiAgentV2 tools plus runtime preflight guidance.
- `skills/brainstorming/SKILL.md`: design-phase behavior; distinguish discrete structured decisions from prose discussion, add fallback and overuse rules, and connect broad-scope decomposition to `dispatching-parallel-agents`.
- `skills/dispatching-parallel-agents/SKILL.md`: read-only fanout lane; add the `decision_needed` handoff shape and prohibit child-side user elicitation.
- `skills/brainstorming/visual-companion.md`: browser helper guide; update Codex-specific launch and file-write wording to match the current runtime surface.

## Task 1: Enforce the root-owned elicitation contract

**Files:**
- Modify: `_shared/validators/validate_skill_library.py`
- Modify: `contract/process-family.md`
- Modify: `contract/prompt-packet.md`

- [ ] **Step 1: Add failing validator requirements for the contract surfaces**

```python
BOUNDARY_REQUIREMENTS = {
    "skills/dispatching-parallel-agents/SKILL.md": ["read-only", "write-owning", "task_name=", 'message="'],
    "skills/subagent-driven-development/SKILL.md": ["write-owning"],
}

TARGETED_REQUIRED_SUBSTRINGS = {
    "contract/process-family.md": [
        "## Root-Owned Elicitation",
        "The root thread owns all user decisions.",
        "When available, use `request_user_input` for discrete branch-point decisions.",
        "Child agents return unresolved decisions to the parent using a `decision_needed` handoff.",
    ],
    "contract/prompt-packet.md": [
        "`parallel_explorer`",
        "`implementer`",
        "`spec_reviewer`",
        "`code_quality_reviewer`",
        "`final_reviewer`",
        "Child packets must not instruct the child to call `request_user_input`.",
        "If a child discovers ambiguity, it must return a `decision_needed` handoff to the parent.",
    ],
}

NO_BACKWARD_COMPAT_TARGETS = [
    "skills/requesting-code-review/SKILL.md",
    "skills/requesting-code-review/code-reviewer.md",
    "skills/receiving-code-review/SKILL.md",
]
```

Add this exact loop inside `validate_family()` after the existing `BOUNDARY_REQUIREMENTS` check:

```python
    for rel_path, required_phrases in TARGETED_REQUIRED_SUBSTRINGS.items():
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for phrase in required_phrases:
            if phrase not in text:
                issues.append(f"{rel_path} must mention `{phrase}`")
```

- [ ] **Step 2: Run the validator to confirm the new contract checks fail**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `FAIL` with missing required text for `contract/process-family.md` and `contract/prompt-packet.md`

- [ ] **Step 3: Update `contract/process-family.md` with the root-owned elicitation rule**

```diff
@@
- `dispatching-parallel-agents` is for read-only or non-owning parallel investigation, not write-owning execution.
+ `dispatching-parallel-agents` is for read-only or non-owning parallel investigation, not write-owning execution or direct user elicitation.
@@
+## Root-Owned Elicitation
+
+- The root thread owns all user decisions.
+- When available, use `request_user_input` for discrete branch-point decisions.
+- Child agents never ask the user directly.
+- Child agents return unresolved decisions to the parent using a `decision_needed` handoff.
```

- [ ] **Step 4: Update `contract/prompt-packet.md` with the current role surface and no-child-elicitation rule**

```diff
@@
-  agent_type: "worker|explorer|default"
+  agent_type: "worker|explorer|parallel_explorer|implementer|spec_reviewer|code_quality_reviewer|final_reviewer|default"
@@
 ## Child Config Rule
 
 - Preserve inherited child config by default.
 - Do not set `model` or `reasoning_effort` unless the user explicitly asks.
+
+## Child Elicitation Rule
+
+- Child packets must not instruct the child to call `request_user_input`.
+- If a child discovers ambiguity, it must return a `decision_needed` handoff to the parent.
+- Keep parent-owned arbitration and user-facing clarification in the root thread.
```

- [ ] **Step 5: Re-run the validator to verify the contract surfaces pass**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `PASS: 23 validated targets`

- [ ] **Step 6: Commit Task 1**

```bash
git add _shared/validators/validate_skill_library.py contract/process-family.md contract/prompt-packet.md
git commit -m "docs: add root-owned elicitation contract"
```

## Task 2: Encode structured elicitation in the shared tool map and brainstorming skill

**Files:**
- Modify: `_shared/validators/validate_skill_library.py`
- Modify: `skills/using-superpowers/references/codex-tools.md`
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Extend the validator to require the new tool-map and brainstorming language**

```python
TARGETED_REQUIRED_SUBSTRINGS.update({
    "skills/using-superpowers/references/codex-tools.md": [
        "`request_user_input(...)`",
        "`send_message(...)`",
        "`followup_task(...)`",
        "`list_agents(...)`",
        "default_mode_request_user_input",
        "multi_agent_v2",
        "The root thread owns user elicitation.",
    ],
    "skills/brainstorming/SKILL.md": [
        "## Structured Elicitation In Codex",
        "When `request_user_input` is available, use it for discrete branch-point decisions instead of writing a plain-text multiple-choice question.",
        "Use it for wedge-lock questions, approach selection, section approval, and the written-spec approval gate.",
        "If the user asked for subagents and the request decomposes cleanly into read-only lanes, use `dispatching-parallel-agents` to map the slices before asking the next wedge-lock question.",
        "Do not issue back-to-back structured questions unless the previous answer unlocked a genuinely new branch.",
    ],
})
```

- [ ] **Step 2: Run the validator and confirm it now fails on the shared tool map and brainstorming skill**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `FAIL` with missing required text for `skills/using-superpowers/references/codex-tools.md` and `skills/brainstorming/SKILL.md`

- [ ] **Step 3: Expand `skills/using-superpowers/references/codex-tools.md` to reflect the active local tool surface**

```markdown
| `Task` tool or subagent dispatch | `spawn_agent(task_name=..., agent_type="<required local role such as default|worker|explorer|parallel_explorer|implementer|spec_reviewer|code_quality_reviewer|final_reviewer>", message="...")` |
| Multiple `Task` calls | Multiple `spawn_agent(task_name=..., agent_type="...", message="...")` calls |
| Structured user decision | `request_user_input(questions=[...])` |
| Add message to live child | `send_message(...)` |
| Wake a live child with new work | `followup_task(...)` |
| Wait for child result | `wait_agent(...)` |
| Close completed child | `close_agent(...)` |
| List live child agents | `list_agents(...)` |

codex features list | rg '^(plugins|multi_agent_v2|default_mode_request_user_input)[[:space:]]+'

- Use latest-alpha feature preflight only when a relevant gated tool is absent from the surfaced session.
- This local implementation assumes the V2 child-agent surface on this machine.
- This local implementation requires explicit `agent_type` on every multi-agent dispatch.
- The parent owns clarification, escalation, and final synthesis.
- The root thread owns user elicitation.
```

- [ ] **Step 4: Update `skills/brainstorming/SKILL.md` to distinguish structured decisions from prose discussion**

```diff
@@
-3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+3. **Ask clarifying questions / branch-point questions** — one at a time; use `request_user_input` for discrete decisions and prose when the user needs rich feedback
@@
+## Structured Elicitation In Codex
+
+- The root thread owns all user decisions.
+- When `request_user_input` is available, use it for discrete branch-point decisions instead of writing a plain-text multiple-choice question.
+- Keep one decision per tool call unless two decisions are inseparable.
+- Use it for wedge-lock questions, approach selection, section approval, and the written-spec approval gate.
+- Stay in normal prose for explanatory discussion, editorial feedback, and any response that needs rich free text.
+
+## Fallback Ladder
+
+- If `request_user_input` is unavailable but the session is interactive, ask one concise plain-text question only when the answer is truly blocking.
+- If the session is non-interactive or child-scoped, return a blocker or make a documented assumption only when the risk is acceptable.
+
+## Overuse Guardrails
+
+- Do not issue back-to-back structured questions unless the previous answer unlocked a genuinely new branch.
+- Do not use `request_user_input` when rich prose is the real need.
+- Do not re-ask an accepted branch-point under a different wrapper.
@@
+- If the user asked for subagents and the request decomposes cleanly into read-only lanes, use `dispatching-parallel-agents` to map the slices before asking the next wedge-lock question.
```

- [ ] **Step 5: Re-run the validator to verify the tool map and brainstorming skill now satisfy the contract**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `PASS: 23 validated targets`

- [ ] **Step 6: Commit Task 2**

```bash
git add _shared/validators/validate_skill_library.py skills/using-superpowers/references/codex-tools.md skills/brainstorming/SKILL.md
git commit -m "docs: add structured elicitation guidance"
```

## Task 3: Encode parent-mediated dispatch and Codex-native visual-companion wording

**Files:**
- Modify: `_shared/validators/validate_skill_library.py`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `skills/brainstorming/visual-companion.md`

- [ ] **Step 1: Extend the validator for the dispatch handoff and stale visual-companion wording**

```python
TARGETED_REQUIRED_SUBSTRINGS.update({
    "skills/dispatching-parallel-agents/SKILL.md": [
        "### 5. Return unresolved decisions to the parent",
        "`decision_needed`",
        "`decision_id`",
        "`recommended_option`",
        "Children may recommend options but may not ask the user directly.",
    ],
    "skills/brainstorming/visual-companion.md": [
        "Launch this with `exec_command` and keep the session alive.",
        "no extra background flag is required",
        "Use `apply_patch` or another non-heredoc file-write path",
    ],
})

TARGETED_CONTENT_GUARDS.setdefault("skills/brainstorming/visual-companion.md", []).extend([
    (
        re.compile(r"run_in_background: true"),
        "contains stale `run_in_background: true` guidance",
    ),
    (
        re.compile(r"Use Write tool"),
        "contains stale `Use Write tool` guidance",
    ),
    (
        re.compile(r"Bash tool call"),
        "contains stale `Bash tool call` guidance",
    ),
])
```

- [ ] **Step 2: Run the validator and confirm the remaining targets fail before the docs are updated**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `FAIL` with missing required text for `skills/dispatching-parallel-agents/SKILL.md` and `skills/brainstorming/visual-companion.md`

- [ ] **Step 3: Update `skills/dispatching-parallel-agents/SKILL.md` with the parent-mediated ambiguity handoff**

```diff
@@
 ### 4. Review and Integrate
@@
 - Synthesize the root-cause map in the parent
 - Decide whether implementation is needed later
+- If a child returns `decision_needed`, resolve that branch in the parent before further dispatch or planning
@@
+### 5. Return unresolved decisions to the parent
+
+If a child finds ambiguity it cannot resolve safely:
+
+- do not call `request_user_input`
+- return `decision_needed: yes`
+- include `decision_id`, `recommended_option`, `options`, and `evidence`
+- let the parent decide whether to ask the user or make a documented assumption
+
+Children may recommend options but may not ask the user directly.
```

- [ ] **Step 4: Update `skills/brainstorming/visual-companion.md` so the Codex wording matches the current runtime**

```diff
@@
 **Terminal agents (Windows):**
 ```bash
-# Windows auto-detects and uses foreground mode, which blocks the tool call.
-# Use run_in_background: true on the Bash tool call so the server survives
-# across conversation turns.
-scripts/start-server.sh --project-dir /path/to/project
+scripts/start-server.sh --project-dir /path/to/project --foreground
 ```
-When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
+If your runtime reaps detached processes, keep the foreground session alive and read `$STATE_DIR/server-info` on the next turn.
@@
 **Codex:**
 ```bash
 # Codex reaps background processes. The script auto-detects CODEX_CI and
 # switches to foreground mode. Run it normally — no extra flags needed.
 scripts/start-server.sh --project-dir /path/to/project
 ```
+Launch this with `exec_command` and keep the session alive. The script auto-foregrounds under `CODEX_CI`, so no extra background flag is required.
@@
-  - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
+  - Use `apply_patch` or another non-heredoc file-write path — **never use cat/heredoc** (dumps noise into terminal)
```

- [ ] **Step 5: Re-run the process-family validator**

Run: `python3 _shared/validators/validate_skill_library.py --root . --family process`
Expected: `PASS: 23 validated targets`

- [ ] **Step 6: Run the residual stale-guidance scan**

Run:

```bash
! rg -n 'run_in_background: true|Use Write tool|Bash tool call' skills/brainstorming/visual-companion.md
```

Expected: no matches

- [ ] **Step 7: Run the final contract-surface scan**

Run:

```bash
rg -n 'request_user_input|decision_needed|send_message|followup_task|list_agents|Root-Owned Elicitation|Structured Elicitation In Codex' \
  contract/process-family.md \
  contract/prompt-packet.md \
  skills/using-superpowers/references/codex-tools.md \
  skills/brainstorming/SKILL.md \
  skills/dispatching-parallel-agents/SKILL.md \
  skills/brainstorming/visual-companion.md
```

Expected: hits in each intended file, with `request_user_input` in the contract/tool-map/brainstorming surfaces and `decision_needed` in the contract/dispatch surfaces

- [ ] **Step 8: Run the final diff hygiene checks**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors, and only the intended validator/docs files remain modified before the final commit

- [ ] **Step 9: Commit Task 3**

```bash
git add _shared/validators/validate_skill_library.py skills/dispatching-parallel-agents/SKILL.md skills/brainstorming/visual-companion.md
git commit -m "docs: finish elicitation contract cutover"
```

## Self-Review

- Spec coverage: This plan covers the contract updates, the shared tool-map update, the brainstorming structured-elicitation rules, the parent-mediated dispatch handoff, the visual-companion runtime wording cleanup, and deterministic validator enforcement.
- Placeholder scan: No `TODO`, `TBD`, or undefined “follow-up later” steps remain; each task names exact files, snippets, commands, and commit boundaries.
- Type consistency: The plan uses the same key terms throughout: `request_user_input`, `decision_needed`, `default_mode_request_user_input`, `multi_agent_v2`, root-thread owned elicitation, and parent-mediated ambiguity handoff.

## References in this plan

- `docs/superpowers/specs/2026-04-10-process-family-elicitation-contract-design.md`
- `_shared/validators/validate_skill_library.py`
- `skills/using-superpowers/references/codex-tools.md`

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-10-process-family-elicitation-contract.md`. Two execution options:

Required next step before execution: Use `superpowers:using-git-worktrees` to create the isolated workspace for this plan.

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
