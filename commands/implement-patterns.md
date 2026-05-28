---
name: implement-patterns
description: >-
  Use to apply design patterns via the implement verb (pattern-implement → oop-orchestrator
  pattern-implement mode) — the gated IMPLEMENT front door the /audit report's Recommended Actions
  hands off to. Resolves a pattern selection against the glossary and applies each via the
  safe 4-step refactoring sequence with before/after verification, OOP-corrective patterns first.
  Supports --plan-only. Modifies source, so user-invoked only.
disable-model-invocation: true
argument-hint: '[<pattern-id> | <category> | all] [full | changed | component <path>] [--plan-only]'
---

Run the **implement** verb against this repository. This is the gated IMPLEMENT action front door —
the command the `/audit` report's **Recommended Actions** section hands off to for a high-confidence
pattern opportunity (`/implement-patterns <selection> <scope>`). It **writes to your source tree**, so
it is user-invoked only. It resolves your selection against the glossary
(`skills/glossary/glossary.json`) and delegates to the `pattern-implement` skill, which drives the
`oop-orchestrator` in **pattern-implement** mode (one `pattern-implementer` per in-scope design
pattern). Each implementer applies its one injected pattern through the safe 4-step refactoring
sequence, running the project's own detected tests at every checkpoint.

## Selection grammar

```
[<pattern-id> | <category> | all] [full | changed | component <path>] [--plan-only]
```

- **Selection** (default `all`) — a single design-pattern id (e.g. `strategy`, `facade`,
  `repository`), a pattern **category** (`creational`, `structural`, `behavioral`, `architectural`,
  `concurrency`, `enterprise`, `functional`, `ddd`), or `all` design patterns.
- **Scope** (default `full`) — `full`, `changed` (vs the base branch), or `component <path>`.
- **`--plan-only`** (or a leading `plan` token) — produce the implementation plan and make **no
  edits**. Use it to preview the change set before committing to it.

Only design-pattern entities are in scope for this verb — issue entities belong to `/fix-risks`.

## Phase 1 — Parse and acquire context

1. Parse `$ARGUMENTS` into a **selection** (default `all`), a **scope** (default `full`), and the
   optional `--plan-only` flag (set it when `--plan-only` or a leading `plan` token is present).

2. If this run was handed off from an `/audit` report's **Recommended Actions** (the selection and
   scope came straight from a named `Pattern Opportunities` row), use that opportunity's fit
   confidence to prioritise which patterns have the strongest signal. If you arrived here directly,
   proceed — the implement verb evaluates fit within scope. For a fresh read of which patterns would
   help, run `/audit pattern-fit <scope>` first.

## Phase 2 — Resolve the selection and confirm the plan

1. Resolve the selection against the glossary into the concrete set of in-scope design-pattern
   entities, grouped by family. Prioritise so that **OOP-corrective patterns go first** — any pattern
   whose `resolves` link targets an OOP issue (God Class → Facade/Strategy; Anemic Domain Model →
   Command/Template Method; Feature Envy → Mediator/Move Method; Refused Bequest → composition via
   Decorator/Proxy). Then low-effort + high-impact, then the remainder.

2. Present the implementation plan to the user before making any changes (skip the confirmation
   prompt and run automatically only when `--plan-only` is set, since that writes nothing):

   ```
   Implementation plan — selection: {selection}, scope: {scope}{, plan-only}
   1. Strategy — resolves God Class in {file}   Effort: Low  Impact: High
   2. ...

   Refactoring safety sequence (applied to every pattern):
     A. Extract interface from existing concrete class — no behavior changes. Run tests.
     B. Create new classes alongside old ones — do not delete yet. Run tests.
     C. Redirect callers one at a time. Run tests after each redirect.
     D. Delete old code only after all callers have been migrated. Run tests.

   Proceed? [all / select / skip]
   ```

   - **all** — implement every resolved pattern in order (OOP-corrective first).
   - **select** — ask y/n before each pattern.
   - **skip** — exit without any changes.

## Phase 3 — Delegate to the implement verb

1. For each approved selection, invoke the `pattern-implement` skill, passing the selection, scope,
   and the `--plan-only` flag when set:

   ```
   /pattern-implement <selection> <scope> [--plan-only]
   ```

   For example `/pattern-implement strategy component src/`, `/pattern-implement behavioral`, or
   `/pattern-implement repository --plan-only`. The skill fans out one `pattern-implementer` per
   pattern through `oop-orchestrator` in pattern-implement mode, and **enforces the 4-step refactoring
   safety sequence for every pattern without exception**, running the project's own detected test
   command (from its package/script manifest, CI workflow, or docs — never hardcoded) at every
   checkpoint:

   - **Step A** — Extract the interface from the existing concrete class. Zero behavior changes. Run
     the tests. If they fail, stop and report.
   - **Step B** — Create new classes alongside the old ones. Do not delete anything yet. Run the
     tests. If they fail, stop and report.
   - **Step C** — Redirect callers one at a time. Run the tests after each individual redirect. If a
     redirect causes a failure, revert that redirect and report.
   - **Step D** — Delete the old code only after every caller has been migrated. Run the tests. If
     they fail, restore the deleted code and report.

   Never implement two patterns simultaneously — complete all four steps for one pattern before
   starting the next. If tests fail at any step, stop that pattern, report the failure with the exact
   error, and ask whether to continue to the next pattern or abort the run. In `--plan-only` mode,
   each implementer emits its plan and writes nothing.

## Phase 4 — Summary

1. After all selections are processed, print:

   ```
   Pattern implementation complete.

   Selection: {selection}  Scope: {scope}{  (plan-only)}
   Patterns implemented: {n}   (or planned, in --plan-only mode)
   Patterns skipped:     {n}
   Patterns with failures: {n}

   Details:
   - Strategy (resolves God Class): applied to {file} — all tests green
   - Observer: failed at step B — {error summary}
   ...

   Next steps:
   - Run `/audit pattern-scan <selection>` to confirm patterns now appear as "present".
   - Run the project's test script for a full regression check.
   - Commit each pattern separately:
       refactor: apply {PatternName} to {Component}
   ```

## Arguments

`$ARGUMENTS` — `[<pattern-id> | <category> | all] [full | changed | component <path>] [--plan-only]`.
With no arguments, implements across `all` applicable design patterns over the `full` project
(OOP-corrective first). Pass any prefix and the rest fall back to defaults (e.g. just `strategy`, or
`behavioral component src/`). Add `--plan-only` to preview without writing.

## Notes

- If the glossary or a prior recommendation report marks a pattern's fit as weak/moderate signal
  only, warn the user and require explicit confirmation before implementing it.
- Never skip Step A even when interfaces already appear to exist — verify rather than assume.
