---
name: detect-testing-antipatterns
description: >-
  Use when reviewing test quality or diagnosing CI slowness to scan test suites for testing
  antipatterns (Ice Cream Cone, Flaky Tests, Testing Implementation Details, Slow Tests).
argument-hint: '[test-path-or-glob]'
user-invocable: true
---

# Testing Antipattern Detector

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection strategies, grep patterns, thresholds, false positive guidance
- [EXAMPLES.md](EXAMPLES.md) — Detected antipattern examples with report output

## Workflow

1. **Parse arguments** — Extract test path from `$ARGUMENTS`. If empty, default to common test locations: `tests/`, `__tests__/`, `*.test.*`, `*.spec.*`.
2. **Inventory test files** — Count unit vs integration vs E2E tests by filename conventions and directory structure.
3. **Scan each test file** — Check for antipattern indicators using the detection table below.
4. **Record findings** — Capture file, line, antipattern, severity, and evidence for each match.
5. **Output structured report** — Generate the report using the output template below with a test health score.
6. **Verification checklist** — Confirm findings are actionable, not false positives.

### Step 1: Parse arguments

Extract the test path or glob from `$ARGUMENTS`:

- If a path is provided, use it directly.
- If a glob is provided, expand it.
- If empty, scan for common test directories and patterns:
  - `tests/`, `__tests__/`, `test/`, `spec/`
  - `**/*.test.ts`, `**/*.test.js`, `**/*.spec.ts`, `**/*.spec.js`
  - `**/*.test.tsx`, `**/*.test.jsx`, `**/*.spec.tsx`, `**/*.spec.jsx`

### Step 2: Inventory test files

Classify each test file by type using filename and directory conventions:

| Type        | Indicators                                                                              |
| ----------- | --------------------------------------------------------------------------------------- |
| Unit        | Files in `unit/` dir, no `-integration`/`-e2e` suffix, no network/browser imports       |
| Integration | Files in `integration/` dir, `-integration` suffix, uses real DB/API fixtures           |
| E2E         | Files in `e2e/`/`cypress/`/`playwright/` dir, `-e2e` suffix, browser automation imports |

Count files per type. Compute the ratio for pyramid health assessment:

- **Healthy**: unit > integration > E2E
- **Inverted**: E2E >= unit (Ice Cream Cone)
- **Missing layer**: any type has zero files when others exist

### Step 3: Scan for antipattern indicators

Use the detection table to scan each file. Read [REFERENCE.md](REFERENCE.md) for detailed grep patterns and threshold values.

| Antipattern                    | Detection Strategy                                                                                                                         |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Ice Cream Cone                 | Ratio analysis: count files by test type (unit/integration/E2E). Flag if E2E > unit count                                                  |
| Flaky Tests                    | `setTimeout`, `sleep`, `waitFor` with hardcoded delays, `Math.random()`, `Date.now()` in assertions, shared `let` variables across tests   |
| Testing Implementation Details | Assertions on private/internal methods, `spy` on internal functions, checking call order with `toHaveBeenCalledBefore`                     |
| Slow Tests                     | Large `beforeAll`/`beforeEach` blocks, network calls without mocking (`fetch`, `axios`, `http`), file I/O in tests, no `--parallel` config |

### Step 4: Record findings

For each detected antipattern, record:

- **File**: path to the test file
- **Line**: line number where the indicator appears
- **Antipattern**: which of the four antipatterns
- **Severity**: `critical`, `warning`, or `info`
- **Evidence**: the code snippet or pattern that triggered detection

Severity classification:

| Severity | Criteria                                                                                                  |
| -------- | --------------------------------------------------------------------------------------------------------- |
| Critical | Direct cause of flaky CI, inverted pyramid with ratio > 2:1, unmocked network calls in unit tests         |
| Warning  | Hardcoded delays under 5s, spying on internal methods, large setup blocks > 20 lines                      |
| Info     | Minor pyramid imbalance, `Date.now()` usage that may be intentional, shared variables with proper cleanup |

### Step 5: Output structured report

Use this template for the final report:

```
# Testing Antipattern Report

**Test files scanned:** {n}
**Test distribution:** {unit} unit / {integration} integration / {e2e} E2E
**Pyramid health:** {healthy/inverted/missing-layer}
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {file}:{line} — {description}

## Warnings
- [{antipattern}] {file}:{line} — {description}

## Info
- [{antipattern}] {file}:{line} — {description}

## Test Health Score: {X}/10
{assessment and recommendations}
```

Scoring guide:

| Score | Meaning                                                                              |
| ----- | ------------------------------------------------------------------------------------ |
| 9-10  | Excellent — healthy pyramid, no flakiness indicators, tests focused on behavior      |
| 7-8   | Good — minor issues, a few implementation-coupled tests or small delays              |
| 5-6   | Needs attention — inverted pyramid or multiple flaky test indicators                 |
| 3-4   | Poor — significant antipatterns across multiple categories                           |
| 1-2   | Critical — test suite is unreliable, heavily coupled to internals, or extremely slow |

Deductions:

- Inverted pyramid: -3
- Missing test layer: -1
- Each critical finding: -1
- Each warning: -0.5 (cap at -2)
- No parallel test config: -1

### Step 6: Verification checklist

Before finalizing the report, verify:

- [ ] Each finding has a specific file and line reference
- [ ] False positives reviewed using guidance in [REFERENCE.md](REFERENCE.md)
- [ ] Severity levels are consistent with the classification table
- [ ] Recommendations are actionable (not generic advice)
- [ ] Test health score math is correct
- [ ] Report omits empty severity sections (skip sections with zero findings)
