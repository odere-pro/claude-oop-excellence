---
name: risk-scan
description: >-
  Use when auditing project health, before releases, or during PR review to run a risk assessment
  across the project or a component via specialized scanner agents — supports selective scans by
  domain and scope.
argument-hint: '[security|errors|dependency|types|complexity|tests|config|docs|all] [full|changed|component <path>]'
user-invocable: true
---

# Risk Scan

Run risk assessment scans by delegating to the `risk-scanner` orchestrator agent.

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Scanner registry, argument mapping, output format

## Workflow

1. **Parse arguments** from `$ARGUMENTS`:

   **Scanner selection** (first token(s), space-separated, default: `all`):
   - `all` — run every `risk-*-scanner` agent discovered in `.claude/agents/`
   - One or more domain keywords — match against scanner names (e.g., `security dependency` runs `risk-security-scanner` and `risk-dependency-scanner`)

   **Scope** (last token, default: `full`):
   - `full` — scan the entire project
   - `changed` — scan files changed since the base branch
   - `component <path>` — scan a specific directory or file set

2. **Delegate** to the `risk-scanner` agent using the Agent tool. Pass a prompt containing:
   - The selected scanners (or `all` for dynamic discovery)
   - The scope
   - When no specific domains were requested (i.e., `all`): include `"Verbose mode: ON. Report all findings across every severity level (critical, high, medium, low). Do not cap or truncate any finding list."` in the prompt.
   - Example (targeted): `"Scan scope: full. Scanners: security, dependency."`
   - Example (default/all): `"Scan scope: full. Scanners: all. Verbose mode: ON. Report all findings across every severity level (critical, high, medium, low). Do not cap or truncate any finding list."`

3. **Return** the agent's report to the user verbatim.

## Usage

```
/risk-scan
/risk-scan all
/risk-scan security
/risk-scan security dependency changed
/risk-scan tests types component scripts/
/risk-scan all changed
```

Feedback Loop (max 1 iteration):

- [ ] Step 1: Delegate to risk-scanner agent
- [ ] Step 2: If agent reports scanner failures, note them in output
- [ ] Step 3: Return final report
