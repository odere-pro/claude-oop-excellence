---
description: >-
  Use when you want a saved, unified code-smell audit across all quality domains — runs the audit
  skill and writes a timestamped Markdown report under tmp/ for review before any fix.
---

Run a full code-smell audit across all quality domains and save the report to `tmp/`.

## Steps

1. Get the current timestamp by running `date +%Y-%m-%d-%H%M` and capture the output as TIMESTAMP.

2. Ensure `tmp/` exists at the repository root: `mkdir -p tmp`.

3. Invoke the `/audit` skill with these six domains:

   ```
   /audit code arch oop test concurrency types
   ```

   The **oop** domain MUST always be included. It scans for all six OOP antipatterns:
   - **God Class** — class with >10 public methods or >500 LOC taking on too many roles
   - **Anemic Domain Model** — classes whose methods are mostly getters/setters with no domain logic
   - **Yo-Yo Problem** — inheritance chains deeper than 4 levels making code hard to follow
   - **Refused Bequest** — subclasses that override parent methods only to empty or no-op them
   - **Feature Envy** — methods that reference another class's data more than their own fields
   - **Inappropriate Intimacy** — classes that reach into private members of other classes

4. Collect the full unified audit report. Do not truncate or summarise it.

5. Write the full report to `tmp/smell-report-{TIMESTAMP}.md` (substitute the actual timestamp).

6. Print confirmation:

   ```
   Smell report written to: tmp/smell-report-{TIMESTAMP}.md
   Findings: {critical} critical, {warning} warning, {info} info
   Top domain by severity: {domain}
   ```

## Arguments

`$ARGUMENTS` — optional domain name (`code`, `arch`, `oop`, `test`, `concurrency`, `types`). If provided, scan only that domain. If omitted, scan all six listed above.
