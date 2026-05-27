---
description: >-
  Use to act on an existing pattern-recommendation report and implement the top-priority design
  patterns via the safe refactoring sequence — OOP corrective patterns first. Modifies source, so
  user-invoked only.
disable-model-invocation: true
---

Find the latest pattern recommendation report in `tmp/` and implement the top-priority patterns using the safe refactoring sequence — OOP corrective patterns are always implemented first.

## Phase 1 — Acquire the recommendation report

1. Check for the most recent report:

   ```bash
   ls -t tmp/pattern-recommendations-*.md 2>/dev/null | head -1
   ```

2. If no file exists, invoke `/pattern-suggest` and wait for completion, then read the new file.

3. Read the full report.

## Phase 2 — Extract implementation targets

1. From the "Strong Signal — Recommended" table in the report, extract all entries and sort them
   by the following priority rules:

   1. **OOP corrective patterns first** — any pattern that directly resolves a detected OOP
      antipattern (God Class → Strategy or Facade; Anemic Domain Model → Command or Template
      Method; Feature Envy → Mediator or Move Method; Refused Bequest → composition over
      inheritance via Decorator or Proxy). Label each with the antipattern it resolves.
   2. Low effort + High impact.
   3. Low effort + Medium impact.
   4. Remaining entries in the order listed in the report.

   If the report's explicit "Recommended Implementation Order" section conflicts with this
   ranking, honour the report's order but promote OOP corrective patterns above it.

2. Present the implementation plan to the user before making any changes:

   ```
   Implementation plan ({n} patterns):
   1. Strategy — resolves God Class in {file}
      Effort: Low  Impact: High
      Where: {file}
   2. ...

   Refactoring safety sequence (applied to every pattern):
     A. Extract interface from existing concrete class — no behavior changes. Run tests.
     B. Create new classes alongside old ones — do not delete yet. Run tests.
     C. Redirect callers one at a time. Run tests after each redirect.
     D. Delete old code only after all callers have been migrated. Run tests.

   Proceed? [all / select / skip]
   ```

   - **all** — implement every listed pattern in order.
   - **select** — ask y/n before each pattern.
   - **skip** — exit without any changes.

## Phase 3 — Implement each pattern

1. Determine the source root: use `src/` if it exists, otherwise the repository root.
   For each approved pattern, invoke:

   ```
   /pattern-implement apply {pattern-name} <source-root>
   ```

   **Enforce the 4-step refactoring safety sequence for every pattern without exception**
   (run the project's test script — detected from `package.json` scripts + lockfile — at every
   checkpoint):

   - **Step A** — Extract the interface from the existing concrete class. Zero behavior changes.
     Run the tests. If tests fail, stop and report.
   - **Step B** — Create new classes alongside the old ones. Do not delete anything yet.
     Run the tests. If tests fail, stop and report.
   - **Step C** — Redirect callers one at a time. Run the tests after each individual redirect.
     If any redirect causes a failure, revert that redirect and report.
   - **Step D** — Delete the old code only after every caller has been successfully migrated.
     Run the tests. If tests fail, restore the deleted code and report.

   Never implement two patterns simultaneously — complete all four steps for one pattern before
   starting the next.

   If tests fail at any step: stop that pattern, report the failure with the exact error, and
   ask the user whether to continue to the next pattern or abort the entire run.

## Phase 4 — Summary

1. After all patterns are processed, print:

   ```
   Pattern implementation complete.

   Patterns implemented: {n}
   Patterns skipped:     {n}
   Patterns with failures: {n}

   Details:
   - Strategy (resolves God Class): applied to {file} — all tests green
   - Observer: failed at step B — {error summary}
   ...

   Next steps:
   - Run `/pattern-suggest` to confirm patterns now appear as "present".
   - Run the project's test script for a full regression check.
   - Commit each pattern separately:
       refactor: apply {PatternName} to {Component}
   ```

## Arguments

`$ARGUMENTS` — optional specific pattern name (e.g., `strategy`). When provided, implement only that pattern. The recommendation report is still read (or generated) for context, including the antipattern it resolves.

## Notes

- If the recommendation report lists a pattern as "moderate signal" only (not "strong signal"),
  warn the user and require explicit confirmation before implementing it.
- Never skip Step A even when interfaces already appear to exist — verify rather than assume.
