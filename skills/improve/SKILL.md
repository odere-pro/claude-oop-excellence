---
name: improve
description: >-
  Use after /audit flags problem areas, or directly on a domain, to detect issues, produce a
  prioritized fix plan, and apply fixes with confirmation — chains detect → plan → fix. Modifies
  source, so user-invoked only.
argument-hint: '[code|arch|oop|test|types] [--plan-only] [path]'
user-invocable: true
disable-model-invocation: true
---

# Quality Improver

Detect → plan → fix quality issues in a codebase, one domain at a time.

## Workflow

### 1. Parse arguments

Read `$ARGUMENTS`:

- **Domain** (required): `code`, `arch`, `oop`, `test`, `types`
- **`--plan-only`**: produce the fix plan but do not edit files
- **Path**: optional subdirectory or file to scope the scan (default: the source
  root — `src/` if present, otherwise the repository root)

If no domain is given, ask the user which domain to improve before continuing.

### 2. Detect

Delegate detection to the matching read-only scanner agent (via the Agent tool), scoped to the
target path:

| Domain | Scanner agent / check |
|--------|----------------------|
| `code` | `risk-antipattern-code-scanner` on the source root |
| `arch` | `risk-antipattern-architecture-scanner` on the source root |
| `oop` | `risk-antipattern-oop-scanner` on the source root |
| `test` | `risk-antipattern-test-scanner` on the project's test files |
| `types` | `tsc --noEmit --strict` (only if a `tsconfig.json` exists) + grep for `any`, `!`, missing return types |

Collect all findings from the agent's report, grouped by severity (critical → warning → info).

### 3. Plan

For each critical and warning finding, produce a concrete fix entry:

```
### Fix {n}: [{severity}] {antipattern} — {file}:{line}

**Problem:** {one-sentence description}
**Before:**
\`\`\`
{offending code snippet, ≤20 lines}
\`\`\`
**After:**
\`\`\`
{proposed fix}
\`\`\`
**Risk:** {low|medium|high} — {reason}
**Tests affected:** {list test files that cover this code, or "none found"}
```

Sort fixes: critical first, then warning. Within each group, order by risk (low first — safer to apply).

Present the full plan to the user. If `--plan-only` is set, stop here.

### 4. Confirm and apply

Ask: **"Apply {n} fixes? [all / select / skip]"**

- **all** — apply every fix in order
- **select** — show each fix one at a time and ask y/n
- **skip** — exit without changes

For each approved fix:

1. Read the file to confirm the current state matches the "Before" snapshot.
2. Apply the edit using the Edit tool.
3. Run the project's typecheck script after each edit (detect from `package.json`
   scripts + lockfile — npm/pnpm/yarn/bun). If it fails, revert that edit and note
   the failure.
4. Mark the fix as applied in the running log.

### 5. Verify

After all fixes are applied:

1. Run the project's test script — confirm all tests pass.
2. Run the project's lint script (if one exists) — confirm no new lint errors.
3. Report: fixes applied, fixes skipped, any reversions.

### 6. Output summary

```
# Improve: {domain}

**Fixes applied:** {n}
**Fixes skipped:** {n}
**Reverted:** {n} (typecheck failed)

## Applied
- {file}:{line} — {antipattern} — fixed

## Skipped
- {file}:{line} — {antipattern} — user skipped

## Reverted
- {file}:{line} — {antipattern} — typecheck error: {message}

## Next steps
- Run `/audit` to confirm the domain is clean
- Commit with: `refactor({domain}): fix {n} {antipattern} issues`
```
