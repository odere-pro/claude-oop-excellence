---
name: detect-database-antipatterns
description: >-
  Use when reviewing data models, migrations, or query patterns to scan for database antipatterns
  (God Table, Inner-Platform Effect, EAV Abuse, N+1 Query).
argument-hint: '[path-or-glob]'
user-invocable: true
---

# Database Antipattern Detector

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection heuristics, ORM patterns, thresholds, false positive guidance
- [EXAMPLES.md](EXAMPLES.md) — Detected issues and report output samples

## Workflow

1. **Parse arguments**: Read `$ARGUMENTS` for a target path or glob pattern. If empty, default to scanning these directory patterns from the project root:
   - `**/migrations/**`
   - `**/models/**`
   - `**/repositories/**`
   - `**/dal/**`
   - `**/entities/**`
   - `**/schemas/**`

2. **Find database-related files**: Use Glob to locate files matching these extensions and patterns:
   - Migration files: `*.sql`, `*migration*`, `*migrate*`
   - Schema files: `*schema*`, `*model*`, `*entity*`
   - Query files: `*repository*`, `*query*`, `*dao*`, `*dal*`
   - ORM configs: `prisma/schema.prisma`, `*ormconfig*`, `*typeorm*`
   - Python: `models.py`, `*_model.py`, `*queries*`
   - Ruby: `*_migration.rb`, `app/models/**`

3. **Scan for each antipattern**: Apply the detection strategies from the table below. For each file, check all four antipatterns. Read [REFERENCE.md](REFERENCE.md) for detailed detection heuristics per ORM and SQL dialect.

4. **Record findings**: For each match, capture:
   - File path (absolute)
   - Line number or range
   - Antipattern name
   - Severity: `critical`, `warning`, or `info`
   - Evidence: the specific code or pattern that triggered the match

5. **Output structured report**: Format results using the report template below.

6. **Verification checklist** — confirm before reporting:
   - [ ] All target files scanned
   - [ ] Each finding has file, line, antipattern, severity, and evidence
   - [ ] False positives filtered using guidance in [REFERENCE.md](REFERENCE.md)
   - [ ] Recommendations are actionable and specific

## Detection strategies

| Antipattern           | Detection Strategy                                                                                                                 |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| God Table             | Migration/schema files with >20 columns in single table, many `nullable()` calls, generic column names (`field1`, `data`, `value`) |
| Inner-Platform Effect | Custom query builder classes, application-level indexing logic, custom transaction management wrapping DB transactions             |
| EAV Abuse             | Tables with `entity_id, attribute_name, attribute_value` pattern, all values stored as TEXT/VARCHAR                                |
| N+1 Query             | Queries inside loops (`for`/`forEach`/`map` containing `await db.query` or ORM `.find()`), missing `include`/`populate`/`JOIN`     |

## Severity classification

| Severity | Criteria                                                                                                        |
| -------- | --------------------------------------------------------------------------------------------------------------- |
| Critical | God Table >40 columns; N+1 inside hot-path or request handler; EAV replacing >5 typed columns                   |
| Warning  | God Table 20-40 columns; N+1 in background jobs; EAV with partial typing; Inner-Platform with partial DB bypass |
| Info     | God Table 15-20 columns with many nullable; potential EAV; query builder that may be justified                  |

## Report template

```
# Database Antipattern Report

**Scanned:** {file count} files
**Database files found:** {migrations} migrations, {models} models, {queries} query files
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {file}:{line} — {description}

## Warnings
- [{antipattern}] {file}:{line} — {description}

## Info
- [{antipattern}] {file}:{line} — {description}

## Recommendations
{prioritized fixes with query optimization suggestions}
```
