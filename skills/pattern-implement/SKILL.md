---
name: pattern-implement
description: >-
  Use after pattern detection identifies an opportunity, or when refactoring code to apply a known
  design pattern — supports planning-only and full implementation modes with before/after
  verification. Modifies source, so user-invoked only.
argument-hint: '[plan|apply] <pattern-name> [target-path]'
user-invocable: true
disable-model-invocation: true
---

# Pattern Implementation

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Implementation checklists per category, common pitfalls, refactoring steps
- [EXAMPLES.md](EXAMPLES.md) — Before/after code for Builder, Chain of Responsibility, Decorator, Strategy
- [PATTERNS.md](PATTERNS.md) — Full 57-pattern catalog with structure, trade-offs, and use-when criteria

## Workflow

Determine the mode from `$ARGUMENTS`:

- **`plan <pattern-name> [target-path]`** (default) — Analyze target code, create implementation plan, do not modify files
- **`apply <pattern-name> [target-path]`** — Create plan, implement changes, run tests, verify

If `target-path` is omitted, use the current working directory.

`<pattern-name>` must match a pattern in [PATTERNS.md](PATTERNS.md) (case-insensitive, hyphenated: `chain-of-responsibility`, `factory-method`, `template-method`).

### Step 1: Validate pattern

1. Read [PATTERNS.md](PATTERNS.md).
2. Find the requested pattern by name. If not found, list the 57 available patterns and stop.
3. Extract the pattern's **Structure**, **Use when**, and **Trade-offs** sections.

### Step 2: Analyze target code

1. Read [REFERENCE.md](REFERENCE.md) for the pattern's implementation checklist.
2. Explore the target codebase:
   - Identify the specific classes, functions, and files where the pattern will be applied
   - Map existing interfaces, inheritance chains, and dependencies in the affected area
   - Identify existing tests covering the affected code
   - Check for code that will be replaced, extended, or wrapped
3. Verify the pattern is appropriate:
   - Confirm at least 2 "use when" criteria from [PATTERNS.md](PATTERNS.md) are met
   - If fewer than 2 criteria match, warn and ask the user to confirm before proceeding

### Step 3: Create implementation plan

1. Define the target architecture:
   - New interfaces or abstract classes to introduce
   - New concrete classes implementing the pattern
   - Existing classes to refactor (with specific changes)
   - Files to create vs. modify
2. Define the refactoring sequence (ordered to keep tests passing at each step):
   - Step A: Extract interface from existing concrete class
   - Step B: Create new classes implementing the interface
   - Step C: Refactor callers to use the interface
   - Step D: Update or add tests
3. Estimate effort and list trade-offs specific to this codebase.
4. Output the plan:

```
## Implementation Plan: {Pattern Name}

### Target
{Files and classes affected}

### Why
{Which "use when" criteria are met, with evidence}

### Architecture
{New interfaces, classes, and their relationships}

### Refactoring Sequence
1. {Step with specific file and code changes}
2. {Step...}

### Test Strategy
{Existing tests to update, new tests to add}

### Trade-offs
{Pattern-specific trade-offs in this context}
```

1. **(plan mode)**: Output the plan and stop.

### Step 4: Implement (apply mode only)

1. Follow the refactoring sequence from Step 3, one step at a time.
2. After each step:
   - Run existing tests to verify no regression
   - If tests fail, fix the issue before proceeding
3. Add new tests covering the pattern's behavior.
4. Run the full test suite.

### Step 5: Verify

1. Confirm all tests pass.
2. Verify the pattern follows the canonical structure from [PATTERNS.md](PATTERNS.md).
3. Check for common pitfalls from [REFERENCE.md](REFERENCE.md).
4. Output the summary:

```
## Implementation Summary

### Pattern Applied
{Pattern name} at {location}

### Files Changed
{List of files with change description}

### Tests
{Pass/fail count, new tests added}

### Verification
- [ ] Pattern structure matches canonical form
- [ ] No common pitfalls detected
- [ ] All existing tests pass
- [ ] New tests cover pattern behavior
```

## Feedback loop

- [ ] Pattern name resolved against PATTERNS.md catalog
- [ ] At least 2 "use when" criteria confirmed before implementation
- [ ] Refactoring sequence keeps tests green at each step
- [ ] No functionality changed (refactoring only, unless explicitly requested)
