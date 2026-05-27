---
description: >-
  Use when you want saved design-pattern recommendations for the codebase — analyses the source for
  pattern opportunities and writes a timestamped Markdown report under tmp/ for review.
---

Analyse the repository source code for design-pattern opportunities and save a recommendation report to `tmp/`.

## Steps

1. Get the current timestamp by running `date +%Y-%m-%d-%H%M` and capture the output as TIMESTAMP.

2. Ensure `tmp/` exists at the repository root: `mkdir -p tmp`.

3. Determine the source root: use `src/` if it exists, otherwise the repository root.
   Invoke the `/pattern-detect` skill in `detect` mode on that path:

   ```
   /pattern-detect detect <source-root>
   ```

   This covers all 8 pattern categories. Pay special attention to OOP-heavy categories:
   - **Structural** — Adapter, Decorator, Proxy, Facade, Composite
   - **Behavioral** — Strategy, Observer, Command, State, Template Method, Chain of Responsibility
   - **Creational** — Factory Method, Builder, Prototype

   Evaluate OOP patterns against the codebase's existing class hierarchy. Any detected OOP
   antipatterns (from prior scan reports in `tmp/`) should inform which corrective patterns
   have the strongest signal.

4. Collect the full Pattern Analysis Report from the skill. Do not truncate it.

5. Prepend an executive summary (3–5 bullets) to the report covering:
   - Total count of patterns already present in the codebase
   - Count of strong-signal OOP pattern recommendations
   - Top 3 highest-priority patterns by effort/impact ratio (low effort + high impact first)
   - Any cross-cutting OOP concern visible from the pattern landscape (e.g., God Class signals
     in a core module suggesting a Strategy or Template Method extraction)

6. Write the combined report (executive summary + full skill output) to
   `tmp/pattern-recommendations-{TIMESTAMP}.md` (substitute the actual timestamp).

7. Print confirmation:

   ```
   Pattern recommendations written to: tmp/pattern-recommendations-{TIMESTAMP}.md
   Patterns present: {n}
   Strong signal (OOP): {n}
   Top recommendation: {pattern-name} — {one-line reason}
   ```

## Arguments

`$ARGUMENTS` — optional path override (default: the source root — `src/` if present, else the repository root). If provided, pass it as the path argument to `/pattern-detect detect` in place of the default.
