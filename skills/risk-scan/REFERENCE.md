# Reference

Scanner registry, argument mapping, and output format for risk scans.

## Scanner discovery

The `risk-scanner` orchestrator discovers available scanners dynamically by globbing `.claude/agents/risk-*-scanner.md`. Any agent matching this pattern is eligible for inclusion.

## Argument-to-scanner mapping

Keywords in `$ARGUMENTS` are matched against scanner filenames:

| Keyword                    | Matches agent                     |
| -------------------------- | --------------------------------- |
| `security`                 | `risk-security-scanner`           |
| `errors`, `error-handling` | `risk-error-handling-scanner`     |
| `dependency`, `deps`       | `risk-dependency-scanner`         |
| `types`, `type-safety`     | `risk-type-safety-scanner`        |
| `complexity`               | `risk-complexity-scanner`         |
| `tests`, `test`            | `risk-test-scanner`               |
| `config`, `configuration`  | `risk-configuration-scanner`      |
| `docs`, `documentation`    | `risk-documentation-scanner`      |
| `architecture`             | `risk-architecture-scanner`       |
| `code`                     | `risk-code-scanner`               |
| `concurrency`              | `risk-concurrency-scanner`        |
| `database`, `db`           | `risk-database-scanner`           |
| `oop`                      | `risk-oop-scanner`                |
| `all`                      | every `risk-*-scanner` discovered |

Unknown keywords are passed through to the orchestrator, which attempts fuzzy matching against discovered scanner names.

## Scope options

| Token              | Meaning                                  |
| ------------------ | ---------------------------------------- |
| `full` (default)   | Scan entire project                      |
| `changed`          | Scan files changed since the base branch |
| `component <path>` | Scan a specific directory or file set    |

## Output format

The orchestrator returns a structured risk report. See the `risk-scanner` agent definition for the full output template including risk matrix, severity-grouped findings, scanner status, and recommendations.
