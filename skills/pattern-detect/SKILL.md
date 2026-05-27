---
name: pattern-detect
description: >-
  Use when starting a project, during architecture reviews, or when investigating refactoring
  opportunities to detect existing software patterns and recommend new ones — covers creational,
  structural, behavioral, architectural, concurrency, enterprise, functional, and DDD patterns.
argument-hint: '[detect|audit] [path]'
user-invocable: true
---

# Pattern Detection

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection heuristics, scoring methodology, signal indicators
- [EXAMPLES.md](EXAMPLES.md) — Example detection reports, good vs bad analysis
- [PATTERNS.md](PATTERNS.md) — Full 57-pattern catalog with structure, trade-offs, and use-when criteria

## Workflow

Determine the mode from `$ARGUMENTS`:

- **`detect [path]`** (default if no mode specified) — Full scan: identify existing patterns + recommend new ones
- **`audit [path]`** — Focus on existing pattern implementations: verify correctness, identify anti-patterns, misapplications

If `path` is omitted, use the current working directory.

### Mode: detect

1. Read [PATTERNS.md](PATTERNS.md) for the full pattern catalog (57 patterns, 8 categories).
2. Read [REFERENCE.md](REFERENCE.md) for detection heuristics and scoring methodology.
3. Explore the target codebase using Glob and Grep:
   - Map class hierarchies and inheritance chains
   - Identify interfaces, abstract classes, and their implementations
   - Trace object creation patterns (constructors, factory functions, builders)
   - Map dependency injection and composition relationships
   - Identify error handling strategies and error type hierarchies
   - Scan for common structural indicators (wrappers, adapters, facades)
   - Check for behavioral indicators (event emitters, state machines, middleware chains)
4. For each pattern category in [REFERENCE.md](REFERENCE.md), evaluate signal indicators against the codebase findings.
5. Classify each pattern into one of four buckets:
   - **Already present** — Pattern is implemented in the codebase (cite file paths and line numbers)
   - **Strong signal** — Clear opportunity; code structure matches the pattern's "use when" criteria
   - **Moderate signal** — Partial match; could benefit but not critical
   - **No signal** — Pattern does not apply to this codebase
6. For each "strong signal" pattern, document:
   - **Where**: Specific files and code sections that would benefit
   - **Why**: Which "use when" criteria from [PATTERNS.md](PATTERNS.md) are met
   - **Effort**: Low (< 1 hour), Medium (1-4 hours), High (> 4 hours)
   - **Impact**: How it improves the code (testability, extensibility, readability)
7. Output the report using the format in [EXAMPLES.md](EXAMPLES.md):

```
## Pattern Analysis Report

### Patterns Already Present
| Pattern | Category | Where | Evidence |
|---|---|---|---|

### Strong Signal — Recommended
| Priority | Pattern | Where | Why | Effort | Impact |
|---|---|---|---|---|---|

### Moderate Signal
| Pattern | Where | Notes |
|---|---|---|

### No Signal
| Category | Patterns | Reason |
|---|---|---|

### Recommended Implementation Order
{Numbered list with rationale for sequencing}
```

### Mode: audit

1. Read [PATTERNS.md](PATTERNS.md) and [REFERENCE.md](REFERENCE.md).
2. Explore the target codebase (same as detect steps 3-4).
3. For each pattern detected as "already present":
   - Verify it follows the canonical structure from [PATTERNS.md](PATTERNS.md)
   - Check for common anti-patterns and misapplications (see [REFERENCE.md](REFERENCE.md) anti-pattern checklist)
   - Rate correctness: correct, partial (missing elements), or misapplied (wrong pattern for the problem)
4. Output the audit report:

```
## Pattern Audit Report

### Patterns Found
| Pattern | Location | Correctness | Issues |
|---|---|---|---|

### Anti-Patterns Detected
| Anti-Pattern | Location | Recommendation |
|---|---|---|

### Summary
{Overall assessment and top-priority fixes}
```

## Feedback loop

- [ ] Verify report covers all 8 pattern categories
- [ ] Verify every "strong signal" entry has concrete file paths and line numbers
- [ ] Verify "already present" entries cite evidence (class names, method signatures)
- [ ] Verify no pattern is classified without checking its specific signal indicators from [REFERENCE.md](REFERENCE.md)
