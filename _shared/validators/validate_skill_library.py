#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path


MANIFEST_BY_FAMILY = {
    "process": "_shared/validators/process_family_targets.txt",
}

REQUIRED_MANIFEST_TARGETS = {
    "process": [
        "contract/package-standards.md",
        "contract/process-family.md",
        "contract/prompt-packet.md",
        "contract/runtime-surfaces.md",
        "skills/using-superpowers/SKILL.md",
        "skills/using-superpowers/references/codex-tools.md",
        "skills/brainstorming/SKILL.md",
        "skills/brainstorming/spec-document-reviewer-prompt.md",
        "skills/writing-plans/SKILL.md",
        "skills/writing-plans/plan-document-reviewer-prompt.md",
        "skills/using-git-worktrees/SKILL.md",
        "skills/dispatching-parallel-agents/SKILL.md",
        "skills/subagent-driven-development/SKILL.md",
        "skills/subagent-driven-development/implementer-prompt.md",
        "skills/subagent-driven-development/spec-reviewer-prompt.md",
        "skills/subagent-driven-development/code-quality-reviewer-prompt.md",
        "skills/executing-plans/SKILL.md",
        "skills/requesting-code-review/SKILL.md",
        "skills/requesting-code-review/code-reviewer.md",
        "skills/receiving-code-review/SKILL.md",
        "skills/verification-before-completion/SKILL.md",
        "skills/finishing-a-development-branch/SKILL.md",
        "skills/writing-skills/SKILL.md",
    ],
}

EXPECTED_DESCRIPTION_LINES = {
    "skills/brainstorming/SKILL.md": 'description: "Use when a request needs design exploration and explicit user approval before implementation planning."',
    "skills/writing-plans/SKILL.md": "description: Use when you have an approved spec for a multi-step task and need an implementation plan before touching code",
    "skills/using-git-worktrees/SKILL.md": "description: Use when implementation is about to start and the work needs an isolated workspace",
    "skills/dispatching-parallel-agents/SKILL.md": "description: Use when you have multiple independent investigation tasks that can run in parallel without shared write ownership",
    "skills/subagent-driven-development/SKILL.md": "description: Use when executing an implementation plan with write-owning task work in the current session",
    "skills/executing-plans/SKILL.md": "description: Use when executing a written implementation plan in a separate or sequential session with review checkpoints",
    "skills/using-superpowers/SKILL.md": "description: Use when starting a session so the agent routes through the skill system before responding",
    "skills/writing-skills/SKILL.md": "description: Use when creating or editing skills and validating that they satisfy the library contract before deployment",
}

PROMPT_TARGETS = [
    "skills/brainstorming/spec-document-reviewer-prompt.md",
    "skills/writing-plans/plan-document-reviewer-prompt.md",
    "skills/subagent-driven-development/implementer-prompt.md",
    "skills/subagent-driven-development/spec-reviewer-prompt.md",
    "skills/subagent-driven-development/code-quality-reviewer-prompt.md",
]

PROMPT_REQUIRED_SUBSTRINGS = [
    'Pass the following content directly as the `message` string in `spawn_agent(task_name="...", agent_type="...", message="...")`:',
    "Your task is to perform the following.",
    "Follow the instructions below exactly.",
    "<agent-instructions>",
    "</agent-instructions>",
    "Execute this now. Output ONLY the structured",
]

PROMPT_FORBIDDEN_STRINGS = [
    "Pass the following content directly as the `message` string in `spawn_agent(...)`:",
    "Codex subagent packet:",
    "items:",
    '- type: "text"',
    "text: |",
    "Task tool (general-purpose):",
    "task_name:",
    "agent_type:",
]

PROCESS_FAMILY_SKILL_CROSS_REFERENCES = [
    "../../contract/process-family.md",
    "../../contract/package-standards.md",
]

PROMPT_PACKET_SKILL_TARGETS = [
    "skills/brainstorming/SKILL.md",
    "skills/writing-plans/SKILL.md",
    "skills/dispatching-parallel-agents/SKILL.md",
    "skills/subagent-driven-development/SKILL.md",
    "skills/requesting-code-review/SKILL.md",
]

CHILD_ELICITATION_TARGETS = [
    *PROMPT_TARGETS,
    "skills/requesting-code-review/code-reviewer.md",
    "skills/dispatching-parallel-agents/SKILL.md",
]

CHILD_ELICITATION_REQUIRED_SUBSTRINGS = [
    "Do not ask the user directly or call `request_user_input`.",
    "If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.",
]

CHILD_ELICITATION_ALLOWED_LINES = {
    "- Do not ask the user directly or call `request_user_input`.",
    "- If you need clarification or hit ambiguity, return the question to the parent/root thread instead of the user.",
    "Children may recommend options but may not ask the user directly.",
}

CHILD_ELICITATION_PARTIES = r"(?:(?:the\s+)?(?:user|operator|human))"
CHILD_ELICITATION_FILLER = r"(?:\s+\w+){0,8}"

CHILD_ELICITATION_FORBIDDEN_LINE_PATTERNS = [
    re.compile(rf"\bask{CHILD_ELICITATION_FILLER}\s+{CHILD_ELICITATION_PARTIES}\b", re.IGNORECASE),
    re.compile(rf"\bget clarification{CHILD_ELICITATION_FILLER}\s+from\s+{CHILD_ELICITATION_PARTIES}\b", re.IGNORECASE),
    re.compile(rf"\bprompt{CHILD_ELICITATION_FILLER}\s+{CHILD_ELICITATION_PARTIES}\b", re.IGNORECASE),
    re.compile(
        rf"\b(?:check|confirm|clarify|consult){CHILD_ELICITATION_FILLER}(?:\s+with)?\s+{CHILD_ELICITATION_PARTIES}\b",
        re.IGNORECASE,
    ),
    re.compile(r"\brequest_user_input\b", re.IGNORECASE),
]

ROOT_OWNED_CONTRACT_ALLOWED_LINES = {
    "- Use `request_user_input` for discrete branch-point decisions.",
    "- Child agents never ask the user directly.",
    "- Child packets must not instruct the child to call `request_user_input`.",
}

ROOT_OWNED_CONTRACT_FORBIDDEN_LINE_PATTERNS = {
    "contract/process-family.md": [
        re.compile(
            rf"\b(?:ask{CHILD_ELICITATION_FILLER}|get clarification{CHILD_ELICITATION_FILLER}\s+from|prompt{CHILD_ELICITATION_FILLER}|(?:check|confirm|clarify|consult){CHILD_ELICITATION_FILLER}(?:\s+with)?)\s+{CHILD_ELICITATION_PARTIES}\b",
            re.IGNORECASE,
        ),
        re.compile(r"\brequest_user_input\b", re.IGNORECASE),
    ],
    "contract/prompt-packet.md": [
        re.compile(
            rf"\b(?:ask{CHILD_ELICITATION_FILLER}|get clarification{CHILD_ELICITATION_FILLER}\s+from|prompt{CHILD_ELICITATION_FILLER}|(?:check|confirm|clarify|consult){CHILD_ELICITATION_FILLER}(?:\s+with)?)\s+{CHILD_ELICITATION_PARTIES}\b",
            re.IGNORECASE,
        ),
        re.compile(r"\brequest_user_input\b", re.IGNORECASE),
    ],
}

BOUNDARY_REQUIREMENTS = {
    "skills/dispatching-parallel-agents/SKILL.md": ["read-only", "write-owning", "task_name=", 'message="'],
    "skills/subagent-driven-development/SKILL.md": ["write-owning"],
}

TARGETED_REQUIRED_SUBSTRINGS = {
    "contract/process-family.md": [
        "## Root-Owned Elicitation",
        "The root thread owns all user decisions.",
        "Use `request_user_input` for discrete branch-point decisions.",
        "not write-owning execution or direct user elicitation.",
        "Child agents never ask the user directly.",
        "Child agents return unresolved decisions to the parent using a `decision_needed` handoff.",
    ],
    "contract/prompt-packet.md": [
        "passed directly as the outer `message=` string on `spawn_agent(task_name=..., agent_type=\"...\", message=\"...\")`",
        "Do not wrap the message in an inner YAML packet",
        "Do not wrap the message in an inner YAML packet, nested `items:` list, or inner `agent_type:` field.",
        "On the latest alpha V2 surface, `task_name` and `message` are the required dispatch fields in the raw schema, but this local superpowers implementation additionally requires explicit outer `agent_type`",
        "Pass the message body directly to `spawn_agent(task_name=\"...\", agent_type=\"...\", message=\"...\")`.",
        "For this local implementation, always set `agent_type` explicitly on multi-agent dispatch.",
        "The current built-in roles on this machine include",
        "Child packets must not instruct the child to call `request_user_input`.",
        "If a child discovers ambiguity, it must return a `decision_needed` handoff to the parent.",
        "Keep parent-owned arbitration and user-facing clarification in the root thread.",
    ],
    "skills/using-superpowers/references/codex-tools.md": [
        "The surfaced tool list in the active session is the runtime truth for the current turn.",
        "This reference is aligned to the latest alpha Codex CLI surface on this machine",
        "It intentionally assumes the V2 multi-agent surface on this machine",
        "`request_user_input(...)`",
        "`request_user_input(questions=[...])`",
        "`send_message(...)`",
        "`followup_task(...)`",
        "`list_agents(...)`",
        "`update_plan(...)`",
        "`multi_tool_use.parallel(...)`",
        "For latest-alpha preflight on this machine, verify feature-gated surfaces with `codex features list`",
        "`request_user_input` is root-thread only and enabled in this local runtime for root-thread elicitation.",
        "Treat it as the local structured-decision surface for eligible discrete branch-point questions.",
        "This reference intentionally targets the V2 child-agent surface gated by `multi_agent_v2`.",
        "On `codex-cli 0.121.0-alpha.1` / `rust-v0.121.0-alpha.1`, this surfaced Codex tool schema requires `task_name` and `message`; the upstream handler still treats `agent_type` as optional metadata.",
        "This local superpowers implementation requires explicit `agent_type` on every multi-agent dispatch because role selection is part of the contract.",
        "The built-in `image_generation` tool is a real Codex CLI surface, but it is still gated by runtime feature/model/auth checks and may not appear in every session.",
        "The root thread owns user elicitation.",
    ],
    "skills/brainstorming/spec-document-reviewer-prompt.md": [
        'Dispatch this packet with `agent_type="parallel_explorer"` in the local V2-only contract.',
    ],
    "skills/writing-plans/plan-document-reviewer-prompt.md": [
        'Dispatch this packet with `agent_type="parallel_explorer"` in the local V2-only contract.',
    ],
    "skills/brainstorming/SKILL.md": [
        "3. **Ask clarifying questions / branch-point questions** — one at a time; use `request_user_input` for discrete decisions and prose when the user needs rich feedback",
        '"Ask clarifying questions / branch-point questions" [shape=box];',
        "## Structured Elicitation In Codex",
        "The root thread owns user decisions and user-facing elicitation.",
        "Use `request_user_input` for discrete branch-point decisions instead of writing a plain-text multiple-choice question.",
        "Use it for wedge-lock questions, approach selection, section approval, and the written-spec approval gate.",
        "Keep it to one decision per tool call unless two choices are inseparable and the user cannot answer one without the other.",
        "If the user asked for subagents and the request decomposes cleanly into read-only lanes, use `dispatching-parallel-agents` to map the slices before asking the next wedge-lock question.",
        "Use normal prose for explanatory discussion, editorial feedback, and rich free text that does not fit a discrete branch.",
        "## Local Runtime Rule",
        "In this local runtime, use `request_user_input` for every eligible discrete branch-point decision in the root thread.",
        "Do not replace an eligible branch-point question with a plain-text fallback or plain-text multiple-choice prompt.",
        "## Overuse Guardrails",
        "Do not issue back-to-back structured questions unless the previous answer unlocked a genuinely new branch.",
        "Do not use `request_user_input` when rich prose is the real need.",
        "Do not re-ask an accepted branch-point under a different wrapper.",
        "- **Structured decisions preferred** - Use `request_user_input` for discrete branches and prose when the user needs nuance",
    ],
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
}

NO_BACKWARD_COMPAT_TARGETS = [
    "skills/requesting-code-review/SKILL.md",
    "skills/requesting-code-review/code-reviewer.md",
    "skills/receiving-code-review/SKILL.md",
]

STALE_DISPATCH_GUIDANCE = {
    "skills/requesting-code-review/SKILL.md": [
        (re.compile(r'`assign_task`'), "assign_task"),
        (re.compile(r'agent_type="reviewer"'), 'agent_type="reviewer"'),
        (re.compile(r'"reviewer"\s+or\s+"worker"'), '"reviewer" or "worker"'),
    ],
    "skills/using-superpowers/references/codex-tools.md": [
        (re.compile(r'`assign_task`'), "assign_task"),
        (re.compile(r'`reviewer`'), "reviewer"),
        (re.compile(r'`planner`'), "planner"),
        (re.compile(r'`verifier`'), "verifier"),
    ],
}

TARGETED_CONTENT_GUARDS = {
    "skills/dispatching-parallel-agents/SKILL.md": [
        (
            re.compile(r'spawn_agent\([\s\S]{0,200}?agent_type="worker"'),
            'contains write-owning `spawn_agent(... agent_type="worker" ...)` example guidance',
        ),
        (
            re.compile(r'items=\['),
            'contains stale `items=[...]` dispatch guidance instead of `message=`',
        ),
    ],
    "skills/requesting-code-review/code-reviewer.md": [
        (
            re.compile(r"\{PLAN_REFERENCE\}"),
            'contains stale `{PLAN_REFERENCE}` placeholder; use `{PLAN_OR_REQUIREMENTS}` consistently',
        ),
    ],
    "skills/brainstorming/SKILL.md": [
        (
            re.compile(r'"Ask clarifying questions"\s*\[shape=box\]'),
            'contains stale plain-text-only diagram node for clarifying questions',
        ),
        (
            re.compile(r'"Ask clarifying questions"\s*->'),
            'contains stale plain-text-only diagram edge for clarifying questions',
        ),
        (
            re.compile(r'->\s*"Ask clarifying questions"'),
            'contains stale plain-text-only diagram edge target for clarifying questions',
        ),
        (
            re.compile(r"\*\*Multiple choice preferred\*\*"),
            'contains stale `Multiple choice preferred` guidance after the structured elicitation cutover',
        ),
        (
            re.compile(r"When `request_user_input` is available, use it for discrete branch-point decisions instead of writing a plain-text multiple-choice question\."),
            'contains stale request_user_input availability fallback guidance',
        ),
        (
            re.compile(r"## Fallback Ladder"),
            'contains stale request_user_input fallback section heading',
        ),
        (
            re.compile(r"If `request_user_input` is unavailable but the session is interactive, ask one concise plain-text question only when the answer is truly blocking\."),
            'contains stale request_user_input fallback guidance `- If `request_user_input` is unavailable but the session is interactive, ask one concise plain-text question only when the answer is truly blocking.`',
        ),
    ],
    "skills/brainstorming/visual-companion.md": [
        (
            re.compile(r"run_in_background:\s*true"),
            'contains stale `run_in_background: true` guidance',
        ),
        (
            re.compile(r"Use Write tool"),
            'contains stale `Use Write tool` guidance',
        ),
        (
            re.compile(r"Bash tool call"),
            'contains stale `Bash tool call` guidance',
        ),
    ],
    "contract/process-family.md": [
        (
            re.compile(r"When available, use `request_user_input` for discrete branch-point decisions\."),
            'contains stale request_user_input availability fallback text `- When available, use `request_user_input` for discrete branch-point decisions.`',
        ),
    ],
    "skills/using-superpowers/references/codex-tools.md": [
        (
            re.compile(r"`request_user_input` is root-thread only, and Default-mode availability depends on `default_mode_request_user_input`\."),
            'contains stale request_user_input availability guidance ``request_user_input` is root-thread only, and Default-mode availability depends on `default_mode_request_user_input`.``',
        ),
    ],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate skill-library structural contracts.")
    parser.add_argument("--root", required=True, help="Repository root to validate")
    parser.add_argument(
        "--family",
        required=True,
        choices=sorted(MANIFEST_BY_FAMILY),
        help="Skill family contract to validate",
    )
    return parser.parse_args()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def read_manifest(path: Path) -> list[str]:
    return [line.strip() for line in read_text(path).splitlines() if line.strip()]


def read_frontmatter(path: Path) -> list[str] | None:
    lines = read_text(path).splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[1:index]
    return None


def find_frontmatter_line(frontmatter: list[str] | None, key: str) -> str | None:
    if frontmatter is None:
        return None
    prefix = f"{key}:"
    for line in frontmatter:
        if line.startswith(prefix):
            return line.strip()
    return None


def require_target(root: Path, rel_path: str, issues: list[str], *, context: str) -> Path | None:
    target = root / rel_path
    if target.exists():
        return target
    issues.append(f"{context} target missing from repo: {rel_path}")
    return None


def validate_family(root: Path, family: str) -> list[str]:
    issues: list[str] = []
    manifest_path = root / MANIFEST_BY_FAMILY[family]

    if not manifest_path.exists():
        return [f"Missing manifest: {manifest_path.relative_to(root)}"]

    entries = read_manifest(manifest_path)
    entry_set = set(entries)

    for rel_path in REQUIRED_MANIFEST_TARGETS[family]:
        if rel_path not in entry_set:
            issues.append(f"Manifest missing required target: {rel_path}")

    for rel_path in entries:
        if "/reference/" in rel_path:
            issues.append(f"Manifest entry uses forbidden /reference/ path: {rel_path}")
        if (root / rel_path).exists():
            continue
        issues.append(f"Manifest target missing from repo: {rel_path}")

    for rel_path in [entry for entry in entries if entry.endswith("/SKILL.md")]:
        target = root / rel_path
        if not target.exists():
            continue
        frontmatter = read_frontmatter(target)
        if frontmatter is None:
            issues.append(f"{rel_path} is missing SKILL.md frontmatter")
            continue
        if find_frontmatter_line(frontmatter, "name") is None:
            issues.append(f"{rel_path} frontmatter is missing name:")
        if find_frontmatter_line(frontmatter, "description") is None:
            issues.append(f"{rel_path} frontmatter is missing description:")

    for rel_path, expected_line in EXPECTED_DESCRIPTION_LINES.items():
        target = root / rel_path
        if not target.exists():
            continue
        actual_line = find_frontmatter_line(read_frontmatter(target), "description")
        if actual_line != expected_line:
            issues.append(
                f"{rel_path} description mismatch: expected `{expected_line}` but found `{actual_line or 'missing'}`"
            )

    for rel_path in PROMPT_TARGETS:
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for required in PROMPT_REQUIRED_SUBSTRINGS:
            if required not in text:
                issues.append(f"{rel_path} is missing required prompt text `{required}`")
        for forbidden in PROMPT_FORBIDDEN_STRINGS:
            if forbidden in text:
                issues.append(f"{rel_path} contains forbidden prompt text `{forbidden}`")

    for rel_path in CHILD_ELICITATION_TARGETS:
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for required in CHILD_ELICITATION_REQUIRED_SUBSTRINGS:
            if required not in text:
                issues.append(f"{rel_path} must mention `{required}`")
        for line in text.splitlines():
            stripped = line.strip()
            if stripped in CHILD_ELICITATION_ALLOWED_LINES:
                continue
            for pattern in CHILD_ELICITATION_FORBIDDEN_LINE_PATTERNS:
                if pattern.search(stripped):
                    issues.append(f"{rel_path} contains forbidden child elicitation text `{stripped}`")
                    break

    for rel_path, required_phrases in BOUNDARY_REQUIREMENTS.items():
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for phrase in required_phrases:
            if phrase not in text:
                issues.append(f"{rel_path} must mention `{phrase}`")

    for rel_path, required_phrases in TARGETED_REQUIRED_SUBSTRINGS.items():
        target = require_target(root, rel_path, issues, context="Targeted required-substrings")
        if target is None:
            continue
        text = read_text(target)
        for phrase in required_phrases:
            if phrase not in text:
                issues.append(f"{rel_path} must mention `{phrase}`")

    for rel_path, patterns in ROOT_OWNED_CONTRACT_FORBIDDEN_LINE_PATTERNS.items():
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for line in text.splitlines():
            stripped = line.strip()
            if stripped in ROOT_OWNED_CONTRACT_ALLOWED_LINES:
                continue
            for pattern in patterns:
                if pattern.search(stripped):
                    issues.append(f"{rel_path} contains forbidden root-owned elicitation text `{stripped}`")
                    break

    for rel_path, guards in TARGETED_CONTENT_GUARDS.items():
        target = require_target(root, rel_path, issues, context="Targeted content-guard")
        if target is None:
            continue
        text = read_text(target)
        for pattern, message in guards:
            if pattern.search(text):
                issues.append(f"{rel_path} {message}")

    for rel_path in [entry for entry in entries if entry.endswith("/SKILL.md")]:
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for required_reference in PROCESS_FAMILY_SKILL_CROSS_REFERENCES:
            if required_reference not in text:
                issues.append(f"{rel_path} must mention `{required_reference}`")

    for rel_path in PROMPT_PACKET_SKILL_TARGETS:
        if rel_path not in entry_set:
            continue
        target = root / rel_path
        if not target.exists():
            continue
        if "../../contract/prompt-packet.md" not in read_text(target):
            issues.append(f"{rel_path} must mention `../../contract/prompt-packet.md`")

    for rel_path in NO_BACKWARD_COMPAT_TARGETS:
        target = root / rel_path
        if not target.exists():
            continue
        if "backward compatibility" in read_text(target).lower():
            issues.append(f"{rel_path} contains forbidden phrase `backward compatibility`")

    for rel_path, stale_rules in STALE_DISPATCH_GUIDANCE.items():
        target = root / rel_path
        if not target.exists():
            continue
        text = read_text(target)
        for pattern, label in stale_rules:
            if pattern.search(text):
                issues.append(f"{rel_path} contains stale dispatch guidance `{label}`")

    for path in root.rglob(".DS_Store"):
        issues.append(f"Forbidden artifact present: {path.relative_to(root)}")
    for path in root.rglob("__pycache__"):
        if path.is_dir():
            issues.append(f"Forbidden artifact present: {path.relative_to(root)}")

    return issues


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    if not root.exists():
        raise SystemExit(f"Root does not exist: {root}")

    manifest_path = root / MANIFEST_BY_FAMILY[args.family]
    issues = validate_family(root, args.family)
    manifest_entries = read_manifest(manifest_path) if manifest_path.exists() else []

    if issues:
        print("FAIL")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print(f"PASS: {len(manifest_entries)} validated targets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
