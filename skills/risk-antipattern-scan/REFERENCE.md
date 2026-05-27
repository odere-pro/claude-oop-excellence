# Reference

Risk scoring formula, domain applicability rules, and agent dispatch details.

## Table of contents

- [Risk scoring](#risk-scoring)
- [Risk verdicts](#risk-verdicts)
- [Domain applicability rules](#domain-applicability-rules)
- [Deduplication rules](#deduplication-rules)
- [Cross-domain correlation patterns](#cross-domain-correlation-patterns)

## Risk scoring

Compute an aggregate risk score from findings:

| Severity | Weight |
| -------- | ------ |
| Critical | 10     |
| High     | 5      |
| Medium   | 2      |
| Low      | 1      |

**Risk score** = sum of (finding count per severity x weight).

Example: 2 critical + 3 high + 5 medium + 8 low = 20 + 15 + 10 + 8 = 53.

## Risk verdicts

| Score range | Verdict           | Meaning                                      |
| ----------- | ----------------- | -------------------------------------------- |
| 0-5         | **Low risk**      | Codebase is in good health                   |
| 6-20        | **Moderate risk** | Targeted improvements recommended            |
| 21-50       | **High risk**     | Significant issues require attention         |
| 51+         | **Critical risk** | Systemic problems requiring immediate action |

The risk score is a communication tool, not a precise metric. Use it to set expectations.

## Domain applicability rules

### Always run (minimum scan)

- **Code** — applies to any codebase with source files
- **Architecture** — applies to any codebase with module boundaries
- **Security** — applies to any codebase

### Conditional scanners

| Scanner     | Check                                                                                | Skip condition          |
| ----------- | ------------------------------------------------------------------------------------ | ----------------------- |
| OOP         | `Grep: 'class '` in source files                                                     | Zero matches            |
| Test        | `Glob: '**/*.{test,spec}.*'` or `tests/` directory                                   | No test files           |
| Concurrency | `Grep: 'async\|await\|Promise\|Thread\|Mutex\|goroutine\|go func'`                   | No concurrency patterns |
| Database    | `Grep: 'prisma\|typeorm\|sequelize\|sqlalchemy\|activerecord'` or `Glob: '**/*.sql'` | No DB patterns          |
| Dependency  | `Glob: 'package.json\|requirements.txt\|go.mod\|Cargo.toml\|pom.xml'`                | No dependency manifests |

### Domain shortcodes

For `--domain` argument:

| Shortcode     | Scanner                     |
| ------------- | --------------------------- |
| `code`        | `risk-code-scanner`         |
| `arch`        | `risk-architecture-scanner` |
| `oop`         | `risk-oop-scanner`          |
| `test`        | `risk-test-scanner`         |
| `concurrency` | `risk-concurrency-scanner`  |
| `db`          | `risk-database-scanner`     |
| `security`    | `risk-security-scanner`     |
| `deps`        | `risk-dependency-scanner`   |
| `all`         | All applicable scanners     |

## Deduplication rules

When two scanners report the same finding:

1. **Same file + same line + same antipattern** — merge, keep higher severity
2. **Same file + overlapping antipatterns** (e.g., God Object from code scanner + God Class from OOP scanner) — merge into one finding, note both domains
3. **Same antipattern in related files** (e.g., circular dependency A→B from both sides) — merge into one finding with both file references

Priority for conflicts: security > code > architecture > OOP > concurrency > database > test > dependency.

## Cross-domain correlation patterns

Flag these combinations when they cluster in the same module or file:

| Combination                                   | Implication                                                 |
| --------------------------------------------- | ----------------------------------------------------------- |
| God Object + Circular Dependency              | Module is a central bottleneck with tangled dependencies    |
| God Table + N+1 Query                         | Database layer has both schema and query problems           |
| Big Ball of Mud + Architecture by Implication | No architecture ownership, drift will accelerate            |
| Vendor Lock-In + Stovepipe                    | Teams picked vendors independently without coordination     |
| Flaky Tests + Race Condition                  | Non-deterministic behavior in both test and production code |
| Spaghetti Code + Feature Envy                 | Business logic is scattered and cross-cutting               |
| Secret Exposure + Security Misconfiguration   | Multiple security layers are weak simultaneously            |
| Unused Dependencies + Known Vulnerabilities   | Attack surface expanded with no benefit                     |

Correlations involving security findings should be escalated one severity level.
