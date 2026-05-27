---
name: audit
description: >-
  Use before releases, after large PRs, or during onboarding to run a full multi-domain quality and
  risk audit. Delegates to the risk-scanner orchestrator, which fans out the antipattern scanners
  (code, architecture, OOP, testing, concurrency, database, security, dependency), deduplicates,
  scores, and returns one unified, severity-ranked report. Language-agnostic; supports selecting
  domains and scope.
argument-hint: '[code arch oop test concurrency db security deps | all] [full | changed | component <path>]'
user-invocable: true
---

# Quality & Risk Audit

The single entry point for scanning a codebase. This skill delegates the heavy lifting to the
`risk-scanner` orchestrator agent (which runs each domain scanner in its own context, in parallel)
and returns one unified, severity-ranked report. It assumes nothing about the language or stack.

## Workflow

### 1. Parse arguments

Read `$ARGUMENTS`:

- **Domains** (default `all`): any of `code`, `arch`, `oop`, `test`, `concurrency`, `db`,
  `security`, `deps`. OOP is always included when classes/structs/interfaces are present — it is the
  spine of this plugin.
- **Scope** (default `full`): `full` (whole project), `changed` (files changed vs the base branch),
  or `component <path>` (a directory or file set).

### 2. Delegate to the orchestrator

Invoke the `risk-scanner` agent with the Agent tool. Pass a prompt containing the selected domains
and scope, for example:

- Default / all: `"Scan scope: full. Scanners: all. Verbose mode: ON — report all findings across every severity (critical, high, medium, low); do not cap or truncate."`
- Targeted: `"Scan scope: component src/api. Scanners: oop, security."`

`risk-scanner` handles applicability filtering, parallel dispatch, deduplication, weighted scoring,
and cross-domain correlation.

### 3. Return the report

Return the orchestrator's unified report to the user verbatim. Then recommend next steps:

- `/improve <domain>` — fix the highest-severity domain (OOP first when present).
- `/risk-report` — save a timestamped copy of this report under `tmp/` before changing anything.
- `/fix-risks` — work through a saved report domain by domain.

## Usage

```
/audit
/audit all
/audit oop security
/audit code oop changed
/audit oop component src/domain
```
