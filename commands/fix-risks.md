---
description: >-
  Use to act on an existing risk/smell report (or generate one first) and fix the findings domain by
  domain — applies code changes via the improve skill, OOP antipatterns first. Modifies source, so
  user-invoked only.
disable-model-invocation: true
argument-hint: '[domains]'
---

Find existing risk and code-smell reports in `tmp/`, then fix the identified issues domain by domain using the improve skill.

## Phase 1 — Acquire reports

1. Check for the most recent risk and smell reports:

   ```bash
   ls -t tmp/risk-report-*.md 2>/dev/null | head -1
   ls -t tmp/smell-report-*.md 2>/dev/null | head -1
   ```

2. If either file is missing, generate it first:
   - Missing risk report → invoke `/risk-report` and wait for completion.
   - Missing smell report → invoke `/smell-report` and wait for completion.

3. Read both files in full.

## Phase 2 — Build the fix agenda

1. Parse both reports and extract all domains that have at least one **Critical**, **High**, or **Warning** finding. Map each to the correct `/improve` domain argument:

   | Report domain        | `/improve` argument |
   |----------------------|---------------------|
   | code / Code          | `code`              |
   | arch / Architecture  | `arch`              |
   | oop / OOP            | `oop`               |
   | test / Testing       | `test`              |
   | concurrency          | `code`              |
   | types / TypeScript   | `types`             |

   **OOP is mandatory in the agenda** when either report lists any finding related to:
   God Class, Anemic Domain Model, Yo-Yo Problem, Refused Bequest, Feature Envy, or
   Inappropriate Intimacy — even at Medium severity. The `/improve oop` run will invoke
   `detect-oop-antipatterns` and apply targeted refactors: extract base classes, introduce
   interfaces, and break up God Classes.

2. Sort the agenda: Critical findings first by domain, then High/Warning findings.
   Deduplicate domains that appear in both reports.

3. Present the fix agenda to the user before making any changes:

   ```
   Fix agenda ({n} domains):
   1. [critical] oop  — {finding count} OOP antipattern findings
   2. [high]     code — {finding count} findings
   ...
   Proceed? [all / select / skip]
   ```

   - **all** — run all domains in listed order.
   - **select** — ask y/n before each domain.
   - **skip** — exit without any changes.

## Phase 3 — Apply fixes

1. For each approved domain, invoke:

   ```
   /improve {domain}
   ```

   Wait for each invocation to complete before starting the next. Do not suppress typecheck errors
   or test failures — report them in the running log and continue to the next domain.

## Phase 4 — Summary

1. After all domains are processed, print:

   ```
   Fix run complete.

   Domains processed: {n}
   Domains with applied fixes: {n}
   Domains with failures: {n}

   Details:
   - oop:  {n} fixes applied / {n} skipped / {n} reverted
   - code: {n} fixes applied / {n} skipped / {n} reverted
   ...

   Next steps:
   - Run `/risk-report` to confirm risk scores dropped.
   - Run `/smell-report` to confirm smell counts dropped.
   - Commit: refactor: apply automated fixes across {domains}
   ```

## Arguments

`$ARGUMENTS` — optional comma-separated domain list (e.g., `oop,code`) to restrict processing to those domains only. Reports are still acquired first even when the domain list is restricted.
