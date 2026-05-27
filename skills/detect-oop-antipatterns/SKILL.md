---
name: detect-oop-antipatterns
description: >-
  Use when reviewing class design or refactoring object hierarchies to scan for OOP antipatterns
  (Anemic Domain Model, God Class, Yo-Yo Problem, Refused Bequest, Feature Envy, Inappropriate
  Intimacy).
argument-hint: '[path-or-glob]'
user-invocable: true
---

# OOP Antipattern Detector

Scan class definitions for six structural OOP antipatterns and produce a severity-ranked report with refactoring recommendations.

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection heuristics, thresholds, false positive guidance, language notes
- [EXAMPLES.md](EXAMPLES.md) — Before/after examples for each antipattern category

## Workflow

1. **Parse target path**: Read `$ARGUMENTS`. If provided, use it as the search root (file path, directory, or glob). If empty, default to the project source directory (e.g., `src/`, `lib/`, `scripts/`, or the project root if none exist).

2. **Find class definitions**: Use Grep to locate all class declarations in the target path. Search for patterns like `class \w+`, `extends`, and `implements`. Record file paths, line numbers, and class names. Filter to supported file types: `.ts`, `.js`, `.tsx`, `.jsx`, `.py`, `.java`.

3. **Analyze each class against detection heuristics**: For every class found, run the six checks below. Use the thresholds and strategies in [REFERENCE.md](REFERENCE.md) for detailed patterns and false positive filtering.

   | Antipattern            | Detection Strategy                                                                                                  |
   | ---------------------- | ------------------------------------------------------------------------------------------------------------------- |
   | Anemic Domain Model    | Classes with only getters/setters and no business methods; matching `*Service` classes that manipulate those models |
   | God Class              | Classes with >30 methods or >500 lines or importing >10 other modules                                               |
   | Yo-Yo Problem          | Inheritance depth >3 levels (trace `extends` chains)                                                                |
   | Refused Bequest        | Overridden methods containing `throw`, `NotImplementedError`, empty bodies, or `// not used`                        |
   | Feature Envy           | Methods calling >3 getters/properties on a single external object                                                   |
   | Inappropriate Intimacy | Chain calls with 3+ dots (a.b.c.d), accessing `_private` or `#private` fields from outside                          |

4. **Record findings**: For each detected antipattern, record:
   - File path and line number
   - Antipattern name
   - Severity: **critical** (God Class, Yo-Yo >5 levels), **warning** (Anemic Domain Model, Feature Envy, Refused Bequest), **info** (Inappropriate Intimacy with <5 occurrences, borderline thresholds)
   - Evidence: the specific code pattern that triggered detection

5. **Output structured report**: Format findings using the template below. Group by severity. Include file counts and class counts at the top.

6. **Verification checklist** -- confirm before presenting the report:
   - [ ] All six antipatterns were checked (even if none found)
   - [ ] Each finding includes file path, line number, and evidence
   - [ ] Severity levels are assigned consistently per the thresholds in REFERENCE.md
   - [ ] False positives from REFERENCE.md exclusion list were filtered out
   - [ ] Recommendations are actionable and reference specific classes

## Severity assignment

| Severity | Criteria                                                                                                       |
| -------- | -------------------------------------------------------------------------------------------------------------- |
| Critical | God Class (any threshold hit); Yo-Yo depth >5; Anemic Domain Model affecting >5 classes                        |
| Warning  | Anemic Domain Model (1-5 classes); Feature Envy (>3 external accesses); Refused Bequest (any); Yo-Yo depth 4-5 |
| Info     | Inappropriate Intimacy (<5 occurrences); borderline threshold hits (within 20% of limit)                       |

## Output template

```
# OOP Antipattern Report

**Scanned:** {file count} files
**Classes analyzed:** {n}
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {file}:{line} `{ClassName}` — {description}

## Warnings
- [{antipattern}] {file}:{line} `{ClassName}` — {description}

## Info
- [{antipattern}] {file}:{line} `{ClassName}` — {description}

## Recommendations
{prioritized refactoring suggestions}
```

## Notes

- When no classes are found in the target path, report "No class definitions found" and exit.
- When no antipatterns are detected, report a clean bill of health with class count.
- For monorepos, run against specific packages rather than the entire tree to keep analysis focused.
- Consult [REFERENCE.md](REFERENCE.md) for language-specific grep patterns and threshold justifications before adjusting any defaults.
