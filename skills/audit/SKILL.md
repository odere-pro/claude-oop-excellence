---
name: audit
description: >-
  Use before releases or after large PRs to run a full multi-domain quality audit — antipattern
  scanners (code, architecture, OOP, testing, concurrency, dependency) plus optional type-safety
  checks, producing one unified, severity-ranked report.
argument-hint: '[code|arch|oop|test|concurrency|deps|types|all]'
user-invocable: true
---

# Quality Audit

Comprehensive quality scan across multiple antipattern domains, producing one
unified severity-ranked report.

## Scope

Source root: the project source root — default `src/` if it exists, otherwise the
repository root. Exclude build output (`dist/`, `build/`, `out/`), `node_modules/`,
generated declarations (`*.d.ts`), and (except for the `test` domain) test files.

## Workflow

### 1. Parse arguments

Read `$ARGUMENTS`. Map to domain set:

| Argument | Domains activated |
|----------|------------------|
| `code` | code antipatterns |
| `arch` | architecture antipatterns |
| `oop` | OOP antipatterns |
| `test` | testing antipatterns (scan test files) |
| `concurrency` | concurrency antipatterns |
| `deps` | dependency hygiene |
| `types` | type safety (only if a `tsconfig.json` is present) |
| `all` or empty | all of the above |

### 2. Run domain scans in parallel

Launch each active domain as an independent scan:

#### Code antipatterns

Use the `detect-code-antipatterns` skill. Focus on:

- Long functions (Spaghetti Code)
- Oversized files (God Object)
- Magic numbers and strings outside dedicated constant/config modules
- Circular imports across feature modules

#### Architecture antipatterns

Use the `detect-architecture-antipatterns` skill. Focus on:

- Layer violations (lower layers importing from higher/entry-point layers)
- Modules reaching across boundaries they should not depend on
- Big Ball of Mud / Stovepipe signals in the import graph

#### OOP antipatterns

Use the `detect-oop-antipatterns` skill. Focus on:

- Classes that have grown too broad (God Class) — verify core types stay narrow
- Classes with only static methods (often better as plain functions)
- Subclasses that add no behaviour (note as info)

#### Testing antipatterns

Use the `detect-testing-antipatterns` skill against the project's test files. Focus on:

- Tests touching the real filesystem, env, network, or clock without isolation
- Tests asserting on fragile raw output instead of behaviour
- Missing negative / edge-case coverage for public APIs

#### Concurrency antipatterns

Use the `detect-concurrency-antipatterns` skill. Focus on:

- Shared mutable state accessed across async boundaries
- Singleton/global mutation in tests without reset between cases

#### Dependency hygiene

Read `package.json` (or the project's manifest) and check:

- Runtime deps pinned predictably (flag overly broad ranges where determinism matters)
- No dev-only dependencies declared as runtime `dependencies`
- A lock file is present and an engine/runtime version constraint is set

#### Type safety (only when a `tsconfig.json` exists)

Run `npx tsc --noEmit --strict 2>&1` (or the project's typecheck script). Check for:

- `any` usage outside intentional boundary casts
- Missing return types on exported functions
- Non-null assertions (`!`) without a guard comment explaining why

### 3. Compile unified report

```
# Quality Audit

**Scanned:** {file count} source files
**Date:** {date}
**Domains:** {active domains}

## Summary

| Domain | Critical | Warning | Info |
|--------|----------|---------|------|
| Code   | ...      | ...     | ...  |
| ...    |          |         |      |
| **Total** | ... | ...     | ...  |

## Critical findings
- [{domain}/{antipattern}] {file}:{line} — {description}

## Warnings
- [{domain}/{antipattern}] {file}:{line} — {description}

## Info
- [{domain}/{antipattern}] {file}:{line} — {description}

## Recommended next steps
1. ...
```

Sort all findings within each severity by domain, then file path.

### 4. Recommended next steps

After the report, suggest:

- Run `/improve <domain>` to fix the highest-severity domain
- Run the project's test suite to confirm no regressions after fixes
