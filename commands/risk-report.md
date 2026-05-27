---
description: >-
  Use when you want a saved, comprehensive risk assessment of the repository — runs the 8-domain
  antipattern scan and writes a timestamped Markdown report under tmp/ for review before any fix.
---

Run a comprehensive risk assessment of this repository and save the report to `tmp/`.

## Steps

1. Get the current timestamp by running `date +%Y-%m-%d-%H%M` and capture the output as TIMESTAMP.

2. Ensure `tmp/` exists at the repository root: `mkdir -p tmp`.

3. Invoke the `/audit` skill across all 8 domains (it delegates to the `risk-scanner`
   orchestrator, which scans every domain in parallel):

   ```
   /audit all
   ```

   The **oop** domain MUST be covered. It detects:
   - God Class (class with too many responsibilities)
   - Anemic Domain Model (classes with no domain logic, only getters/setters)
   - Refused Bequest (subclass ignores or empties inherited parent methods)
   - Feature Envy (method uses another class's data more than its own)
   - Yo-Yo Problem (deep inheritance chains >4 levels)
   - Inappropriate Intimacy (class accesses private internals of another)

4. Collect the full unified report produced by the audit. Do not truncate or summarise it.

5. Write the full report to `tmp/risk-report-{TIMESTAMP}.md` (substitute the actual timestamp).

6. Print confirmation:

   ```
   Risk report written to: tmp/risk-report-{TIMESTAMP}.md
   Risk score: {score} — {verdict}
   Findings: {critical} critical, {high} high, {medium} medium, {low} low
   ```

## Arguments

`$ARGUMENTS` — optional path to scope the scan (default: repository root). If provided, pass it to `/audit` as `component <path>`.
