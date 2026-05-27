---
name: risk-antipattern-scan
description: >-
  Use for health checks, pre-release audits, or onboarding to run a comprehensive project risk scan
  — dispatches 8 specialized agents (code, architecture, OOP, testing, concurrency, database,
  security, dependency) and produces a unified, severity-classified risk report.
argument-hint: '[path] [--domain code,arch,oop,test,concurrency,db,security,deps] [--parallel]'
user-invocable: true
---

# Project Risk Scanner

Orchestrate specialized scanner agents to produce a comprehensive risk assessment.

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Agent dispatch matrix, risk scoring formula, domain applicability rules

## Workflow

### 1. Parse arguments

Parse `$ARGUMENTS` for:

- **Target path** — directory or glob (default: project root)
- **`--domain`** — comma-separated list of domains to scan (default: all applicable)
- **`--parallel`** — launch all scanners concurrently (default: sequential)

### 2. Determine applicable scanners

Read the project structure to decide which scanners apply. Run these checks:

| Scanner                                 | Applicability check                                                  | Skip if                 |
| --------------------------------------- | -------------------------------------------------------------------- | ----------------------- |
| `risk-antipattern-code-scanner`         | Always                                                               | Never                   |
| `risk-antipattern-architecture-scanner` | Always                                                               | Never                   |
| `risk-antipattern-security-scanner`     | Always                                                               | Never                   |
| `risk-antipattern-oop-scanner`          | Grep for `class` declarations                                       | No classes found        |
| `risk-antipattern-test-scanner`         | Glob for `*.test.*`, `*.spec.*`, `tests/`                            | No test files found     |
| `risk-antipattern-concurrency-scanner`  | Grep for `async`, `await`, `Promise`, `Thread`, `goroutine`, `Mutex` | No concurrency patterns |
| `risk-antipattern-database-scanner`     | Grep for ORM imports, `*.sql`, migration dirs                        | No database patterns    |
| `risk-antipattern-dependency-scanner`   | Glob for `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`  | No dependency manifests |

If `--domain` is specified, restrict to those scanners only (skip applicability check).

### 3. Dispatch scanners

Launch applicable scanner agents using the Agent tool. Pass the target path to each.

- **Default:** sequential — pass prior scanner context to aid deduplication
- **With `--parallel`:** launch all concurrently, merge in step 4

Each scanner is a subagent:

| Domain      | Agent (`subagent_type`)                 | Model  | Skill reference                    |
| ----------- | --------------------------------------- | ------ | ---------------------------------- |
| code        | `risk-antipattern-code-scanner`         | sonnet | `detect-code-antipatterns`         |
| arch        | `risk-antipattern-architecture-scanner` | sonnet | `detect-architecture-antipatterns` |
| oop         | `risk-antipattern-oop-scanner`          | sonnet | `detect-oop-antipatterns`          |
| test        | `risk-antipattern-test-scanner`         | sonnet | `detect-testing-antipatterns`      |
| concurrency | `risk-antipattern-concurrency-scanner`  | sonnet | `detect-concurrency-antipatterns`  |
| db          | `risk-antipattern-database-scanner`     | sonnet | `detect-database-antipatterns`     |
| security    | `risk-antipattern-security-scanner`     | sonnet | _(self-contained)_                 |
| deps        | `risk-antipattern-dependency-scanner`   | sonnet | _(self-contained)_                 |

### 4. Aggregate results

After all scanners complete:

1. Collect findings from all scanner reports.
2. Deduplicate findings that appear in multiple outputs (e.g., God Object flagged by both code and OOP scanners). Keep the higher severity with more specific evidence.
3. Compute risk score (see [REFERENCE.md](REFERENCE.md) for formula).
4. Identify cross-domain correlations — antipatterns clustering in the same files or modules.

### 5. Output unified report

```
# Risk Assessment Report

**Target:** {scanned path}
**Scanners dispatched:** {count}/{total} ({skipped scanners with reason})
**Risk score:** {score} — {Low|Moderate|High|Critical} Risk

## Finding summary

| Severity | Count | Domains |
|----------|-------|---------|
| Critical | {n} | {domains} |
| High | {n} | {domains} |
| Medium | {n} | {domains} |
| Low | {n} | {domains} |
| **Total** | {n} | |

## Critical findings

| # | Domain | Finding | Location | Evidence | Remediation |
|---|--------|---------|----------|----------|-------------|

## High findings

| # | Domain | Finding | Location | Evidence | Remediation |
|---|--------|---------|----------|----------|-------------|

## Medium findings

| # | Domain | Finding | Location | Evidence |
|---|--------|---------|----------|----------|

## Low findings

| # | Domain | Finding | Location | Evidence |
|---|--------|---------|----------|----------|

## Cross-domain correlations

- **{module/file}:** {co-occurring antipatterns} — {implication}

## Recommendations

1. **{Action}** — Addresses {n} findings in {domain}. Effort: {low|medium|high}.
```

### 6. Verification checklist

- [ ] At least 3 scanners ran (code, architecture, security)
- [ ] Every finding has a location reference
- [ ] Duplicates between scanners are merged
- [ ] Risk score matches finding counts
- [ ] Skipped scanners are documented with reason

## Usage

```
/risk-antipattern-scan
/risk-antipattern-scan src/
/risk-antipattern-scan --domain code,security
/risk-antipattern-scan --parallel
/risk-antipattern-scan src/api --domain code,db,security --parallel
```
