---
name: detect-code-antipatterns
description: >-
  Use when reviewing code quality or before refactoring to scan a codebase for code design
  antipatterns (God Object, Spaghetti Code, Lava Flow, Copy-Paste, Magic Numbers, Circular
  Dependencies, and more); pass --fix to apply safe corrections.
argument-hint: '[path-or-glob] [--fix]'
user-invocable: true
---

# Code Design Antipattern Detector

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detailed detection strategies, thresholds, false positive guidance
- [EXAMPLES.md](EXAMPLES.md) — Before/after examples with expected report output

## Antipattern catalog

| #   | Antipattern            | Severity | Detection Strategy                                                                  |
| --- | ---------------------- | -------- | ----------------------------------------------------------------------------------- |
| 1   | God Object             | critical | Files >500 lines with >15 exported functions/methods                                |
| 2   | Spaghetti Code         | critical | Functions >80 lines or nesting depth >4                                             |
| 3   | Lava Flow              | warning  | Comments matching `TODO.*remove`, `FIXME`, `HACK`, `XXX`, commented-out code blocks |
| 4   | Boat Anchor            | warning  | Unused exports (grep for exports, check for consumers)                              |
| 5   | Copy-Paste Programming | critical | Identical or near-identical blocks (>5 lines) across files                          |
| 6   | Magic Numbers/Strings  | warning  | Numeric literals in conditionals/assignments (excluding 0, 1, -1)                   |
| 7   | Primitive Obsession    | info     | Function params with 3+ string/number params for domain concepts                    |
| 8   | Poltergeist            | warning  | Classes with 1-2 methods that only delegate                                         |
| 9   | Circular Dependency    | critical | Import/require cycles (A->B->A)                                                     |
| 10  | Golden Hammer          | info     | Same pattern used >5 times where alternatives exist                                 |

## Workflow

### 1. Parse arguments

Parse `$ARGUMENTS` for:

- **Target path** — file path or glob pattern (default: project root)
- **`--fix` flag** — when present, propose fixes for critical and warning findings
- **`--severity <level>`** — filter output to critical, warning, or info (default: all)

If `$ARGUMENTS` is empty, scan the entire project. Exclude `node_modules/`, `dist/`, `build/`, `.git/`, vendor directories, and lock files.

### 2. Determine file scope

Use Glob to collect target files:

```
**/*.ts, **/*.tsx, **/*.js, **/*.jsx, **/*.py, **/*.go, **/*.rs, **/*.java
```

Filter by the target path if one was provided. Record the total file count for the report header.

### 3. Run detection passes

For each antipattern in the catalog table (in order, 1–10):

1. Use Grep/Glob with the patterns from [REFERENCE.md](REFERENCE.md) to find candidates.
2. If candidates are found, Read the file to confirm the finding.
3. Apply the severity thresholds from [REFERENCE.md](REFERENCE.md) — use the **warning** threshold from the catalog table as the default, and the **critical** threshold from REFERENCE.md for escalation.
4. Filter false positives using the exclusion rules in REFERENCE.md (test files, generated code, vendor directories).
5. Record each confirmed finding with: file path, line number, antipattern name, severity, and one-line evidence.

If no candidates are found for an antipattern, skip it — an empty section means the antipattern was not detected.

### 4. Compile report

Produce the report in this format:

```
# Code Antipattern Report

**Scanned:** {file count} files in {path}
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {file}:{line} — {description}

## Warnings
- [{antipattern}] {file}:{line} — {description}

## Info
- [{antipattern}] {file}:{line} — {description}

## Recommendations
{prioritized fix suggestions, grouped by antipattern}
```

Sort findings within each severity group by antipattern name, then by file path.

### 5. Propose fixes (when `--fix` is set)

For each critical and warning finding:

1. Read the surrounding code context (20 lines before and after).
2. Propose a concrete refactoring with before/after code snippets.
3. Group related fixes (e.g., multiple magic numbers in the same file).
4. Ask for user confirmation before applying any edits.

Fix strategies per antipattern:

| Antipattern         | Fix Strategy                                                    |
| ------------------- | --------------------------------------------------------------- |
| God Object          | Extract cohesive method groups into separate modules            |
| Spaghetti Code      | Extract nested blocks into named functions; apply early returns |
| Lava Flow           | Remove dead code; convert valid TODOs to tracked issues         |
| Boat Anchor         | Remove unused exports; flag for team review if public API       |
| Copy-Paste          | Extract shared logic into a utility function                    |
| Magic Numbers       | Extract to named constants with descriptive names               |
| Primitive Obsession | Introduce type aliases or value objects                         |
| Poltergeist         | Inline delegation; remove unnecessary wrapper                   |
| Circular Dependency | Introduce interface or move shared types to a common module     |
| Golden Hammer       | Suggest alternative patterns for specific misuse cases          |

### 6. Verification checklist

After the scan completes, verify:

- [ ] All target files were scanned (compare against Glob results)
- [ ] No false positives from test files, generated code, or vendor dependencies
- [ ] Severity levels are correctly assigned per the classification in REFERENCE.md
- [ ] Critical findings have actionable descriptions
- [ ] Report totals match individual finding counts
