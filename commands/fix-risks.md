---
name: fix-risks
description: >-
  Use to fix risk findings via the fix verb (improve → oop-orchestrator fix mode) — the gated FIX
  action the /audit report's Recommended Actions hands off to. Resolves an entity selection against
  the glossary and applies the smallest corrective refactor per in-scope entity, OOP first, verified
  with the project's own test commands. Supports --plan-only. Modifies source, so user-invoked only.
disable-model-invocation: true
argument-hint: '[<entity-id> | <family> | all] [full | changed | component <path>] [--plan-only]'
---

The gated **FIX action front door** — the side-effecting command that the `/audit` report's
**Recommended Actions** section hands off to. Run the **fix** verb against this repository. Because it
**writes to your source tree**, it is user-invoked only. It resolves your selection against the
glossary (`skills/glossary/glossary.json`) and delegates to the `improve` skill, which drives the
`oop-orchestrator` in **fix** mode (one `entity-fixer` per in-scope entity, fanned out in parallel
batched by family). Each fixer detects instances of its one injected entity, applies the smallest
corrective refactor, and verifies with the project's own detected test/typecheck/lint commands.

## Selection grammar

```
[<entity-id> | <family> | all] [full | changed | component <path>] [--plan-only]
```

- **Selection** (default `all`) — a single glossary issue id (e.g. `god-class`, `feature-envy`,
  `shotgun-surgery`), an issue **family** (`oop`, `code`, `architecture`, `testing`, `concurrency`,
  `database`, `security`, `dependency`), or `all` issue entities.
- **Scope** (default `full`) — `full`, `changed` (vs the base branch), or `component <path>`.
- **`--plan-only`** (or a leading `plan` token) — produce the corrective plan (detected instances +
  intended diffs) and make **no edits**. Use it to preview the refactor before committing to it.

Only issue entities are in scope for the fix verb — design patterns belong to `/implement-patterns`.

## Phase 1 — Parse and acquire context

1. Parse `$ARGUMENTS` into a **selection** (default `all`), a **scope** (default `full`), and the
   optional `--plan-only` flag (set it when `--plan-only` or a leading `plan` token is present).

2. Check for the most recent saved `/audit` report for context (optional, not required):

   ```bash
   ls -t tmp/audit-report-*.md 2>/dev/null | head -1
   ```

   If one exists, read it to prioritise which entities have live findings — its **Recommended
   Actions** section is the handoff that points here. If none exists, proceed — the fix verb
   re-detects within scope; you do not need a report to run.

## Phase 2 — Resolve the selection and confirm the agenda

1. Resolve the selection against the glossary into the concrete set of in-scope issue entities,
   grouped by family. **OOP is the spine** — when the selection is `all` (or `oop`), OOP-family
   entities (God Class, Anemic Domain Model, Yo-Yo Problem, Refused Bequest, Feature Envy,
   Inappropriate Intimacy) are fixed first.

2. Present the fix agenda to the user before making any changes (skip the confirmation prompt and run
   automatically only when `--plan-only` is set, since that writes nothing):

   ```
   Fix agenda — selection: {selection}, scope: {scope}{, plan-only}
   Families (OOP first):
   1. oop  — {entity count} entities resolved
   2. code — {entity count} entities resolved
   ...
   Proceed? [all / select / skip]
   ```

   - **all** — fix every resolved family in listed order (OOP first).
   - **select** — ask y/n before each family.
   - **skip** — exit without any changes.

## Phase 3 — Delegate to the fix verb

1. For each approved selection, invoke the `improve` skill, passing the selection, scope, and the
   `--plan-only` flag when set:

   ```
   /improve <selection> <scope> [--plan-only]
   ```

   For example `/improve oop component src/`, `/improve feature-envy --plan-only`, or
   `/improve god-class changed`. The `improve` skill resolves applicability via each entity's
   `applies_when` (an explicit entity-id or family selection overrides smart-dispatch skips) and fans
   out one `entity-fixer` per entity through `oop-orchestrator` in fix mode. Wait for each invocation
   to complete before starting the next. Do not suppress typecheck errors or test failures — report
   them in the running log and continue to the next selection.

## Phase 4 — Summary

1. After all selections are processed, print:

   ```
   Fix run complete.

   Selection: {selection}  Scope: {scope}{  (plan-only)}
   Entities processed: {n}
   Entities with applied fixes: {n}   (or planned, in --plan-only mode)
   Entities with failures: {n}

   Details (by family, OOP first):
   - oop:  {n} fixed / {n} skipped / {n} reverted
   - code: {n} fixed / {n} skipped / {n} reverted
   ...

   Next steps:
   - Run `/audit <selection>` to re-scan and confirm risk scores dropped.
   - Commit: refactor: apply automated fixes for {selection}
   ```

## Arguments

`$ARGUMENTS` — `[<entity-id> | <family> | all] [full | changed | component <path>] [--plan-only]`.
With no arguments, fixes `all` applicable issue entities over the `full` project (OOP first). Pass any
prefix and the rest fall back to defaults (e.g. just `oop`, or `god-class component src/`). Add
`--plan-only` to preview without writing.
