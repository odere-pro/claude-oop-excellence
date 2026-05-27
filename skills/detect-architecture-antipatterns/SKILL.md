---
name: detect-architecture-antipatterns
description: >-
  Use during architecture reviews or before major refactoring to scan a codebase for architecture
  antipatterns (Big Ball of Mud, Vendor Lock-In, Reinventing the Wheel, Architecture by Implication,
  Stovepipe).
argument-hint: '[path-or-glob]'
user-invocable: true
---

# Architecture Antipattern Detector

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection strategies, grep patterns, thresholds, severity rules
- [EXAMPLES.md](EXAMPLES.md) — Sample detection output for common scenarios

## Workflow

1. **Parse target path** from `$ARGUMENTS`. If empty, default to the project root directory.

2. **Analyze module structure.** Map the import/require graph across the target path. Identify directory boundaries, layer separation (or lack thereof), and shared contract locations.

3. **Check for each antipattern** using the detection heuristics below. Use Grep and Glob to gather evidence. Read files only when needed to confirm a finding.

4. **Record each finding** with: location (file or directory), antipattern name, severity (critical/warning/info), and supporting evidence.

5. **Output the structured report** using the report template below.

6. **Verification checklist** — confirm each item before finalizing the report:
   - [ ] All five antipatterns were checked
   - [ ] Every finding includes a file path and evidence
   - [ ] Severity levels are consistent with the rules in REFERENCE.md
   - [ ] False positives were filtered using the guidance in REFERENCE.md
   - [ ] Recommendations are actionable and prioritized

## Detection heuristics

| Antipattern                 | Detection Strategy                                                                                       |
| --------------------------- | -------------------------------------------------------------------------------------------------------- |
| Big Ball of Mud             | Import graph analysis: files importing from >5 different directories, no clear layer separation          |
| Vendor Lock-In              | Platform-specific imports (AWS SDK, GCP, etc.) used directly in business logic without abstraction layer |
| Reinventing the Wheel       | Custom implementations of: HTTP clients, date parsing, UUID generation, JSON schema validation, crypto   |
| Architecture by Implication | Missing ADR directory, no architecture docs, conflicting patterns (e.g., both MVC and CQRS)              |
| Stovepipe System            | Duplicate type definitions, similar data models in different modules, no shared contracts directory      |

## Detection procedure

For each antipattern in the heuristics table:

1. Use Grep/Glob with the patterns from [REFERENCE.md](REFERENCE.md) to gather evidence.
2. If evidence is found, Read files to confirm the finding and assess scope.
3. Apply the severity thresholds and false positive filters from REFERENCE.md.
4. Record each confirmed finding with: location, antipattern name, severity, and evidence.
5. If no evidence is found for an antipattern, skip it — an empty section means it was not detected.

If the codebase exceeds 500 files, sample representative directories and note the sampling strategy in the report. See REFERENCE.md for sampling guidance.

## Report template

```
# Architecture Antipattern Report

**Scanned:** {path}
**Module count:** {n}
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {location} — {description}

## Warnings
- [{antipattern}] {location} — {description}

## Info
- [{antipattern}] {location} — {description}

## Architecture Health Summary
{overall assessment and prioritized recommendations}
```

## Severity assignment

- **Critical** — Antipattern affects the entire codebase or a core module, blocks safe evolution, or creates systemic risk.
- **Warning** — Antipattern is localized to a subsystem or module but will worsen if not addressed.
- **Info** — Minor instance or edge case that may be acceptable in context. Document for awareness.

## Constraints

- Do not modify any source files. This skill is read-only analysis.
- Report findings even when uncertain. Mark uncertain findings as info severity with a note.
- If the codebase is too large to analyze fully, sample representative directories and note the sampling strategy in the report.
- Always check all five antipatterns. An empty section means the antipattern was not detected.
