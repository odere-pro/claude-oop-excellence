# Pattern Detection Examples

## Table of contents

- [Good detection report](#good-detection-report) — Complete example with all required sections
- [Bad detection report](#bad-detection-report) — Common mistakes and why they fail
- [Audit report example](#audit-report-example) — Pattern correctness verification

## Good detection report

A high-quality detection report covers all categories, cites specific code, and provides actionable recommendations.

### Input

Target: A TypeScript CLI tool with a generator pipeline, setup workflow, and PR validator (~20 source files).

### Output

```markdown
## Pattern Analysis Report

### Patterns Already Present

| Pattern         | Category   | Where                                   | Evidence                                                                                                                         |
| --------------- | ---------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Template Method | Behavioral | `generators/generator.ts:5-29`          | Abstract `Generator.generate()` with `TemplateGenerator` implementing load-render skeleton; subclasses override `getVars()` hook |
| Factory Method  | Creational | `generators/generator.ts:5`             | `generate(config)` returns different content representations per subclass                                                        |
| Facade          | Structural | `setup-workflow.ts:10`, `pipeline.ts:6` | `SetupWorkflow.run()` hides 10-step orchestration; `GeneratorPipeline.run()` hides manifest-generate-write cycle                 |
| Strategy        | Behavioral | `generators/generator.ts:10`            | `getVars: (config) => Record<string, string>` injected as constructor parameter                                                  |
| Gateway         | Enterprise | `command-runner.ts:4`                   | `CommandRunner` isolates shell execution behind `run()`/`capture()` interface                                                    |
| Registry        | Enterprise | `registry.ts:15`                        | `buildFileManifest()` collects all generators into a central `FileEntry[]` manifest                                              |

### Strong Signal — Recommended

| Priority | Pattern                 | Where                                 | Why                                                                                                                                   | Effort | Impact                                                                                      |
| -------- | ----------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------- |
| P1       | Chain of Responsibility | `pr-validator.ts:66-107`              | 5 independent validation steps hardcoded as method calls; each pushes to shared result; adding checks requires modifying orchestrator | Medium | Extensibility: new checks via addition, not modification                                    |
| P2       | Builder                 | `settings.ts:6-173`                   | 170-line nested JSON object literal; repetitive hook structures; impossible to test subsections independently                         | Low    | Readability: each hook becomes one fluent call; Testability: sections testable in isolation |
| P3       | Decorator               | `file-writer.ts`, `command-runner.ts` | No dry-run mode; no logging wrapper; pipeline tests require filesystem; concrete classes with no interface                            | Medium | Testability: DryRunWriter enables pure tests; Extensibility: composable behaviors           |

### Moderate Signal

| Pattern             | Where               | Notes                                                             |
| ------------------- | ------------------- | ----------------------------------------------------------------- |
| Strategy (enhanced) | `helpers.ts:23-47`  | `permissionsForPackageManager()` switch could be a strategy map   |
| Composite           | `registry.ts:15-48` | Flat manifest array could support category grouping and filtering |

### No Signal

| Category      | Patterns                                   | Reason                                                                                |
| ------------- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| Concurrency   | All 5 patterns                             | Single-threaded synchronous CLI; `execSync` used throughout                           |
| DDD           | All 6 patterns                             | Code generator, not a domain model; no entities, aggregates, or bounded contexts      |
| Architectural | MVC, MVVM, Hexagonal, Clean, Microservices | CLI tool; no UI layer; single process; ~20 files doesn't warrant architectural layers |

### Recommended Implementation Order

1. **Builder** — Lowest effort, immediate readability win in SettingsGenerator
2. **Decorator** — Enables dry-run mode and testability across pipeline
3. **Chain of Responsibility** — Most architectural impact; benefits from Decorator (uses Runner interface)
```

## Bad detection report

A low-quality report lacks specifics, makes generic recommendations, and misclassifies patterns.

### Problems

```markdown
## Pattern Analysis

The codebase could benefit from several patterns:

- **Singleton**: The Logger class should be a singleton to ensure consistent logging.
- **Observer**: Components could use events to communicate.
- **MVC**: The project should adopt MVC architecture for better separation of concerns.
- **Repository**: Data access should go through repositories.
```

### Why this is bad

1. **No evidence cited** — No file paths, no line numbers, no code analysis
2. **Generic recommendations** — "Could benefit" without explaining which "use when" criteria match
3. **Misapplied patterns** — Singleton for Logger is an anti-pattern (hides dependency); MVC for a CLI tool is wrong; Repository for a code generator with no data store is wrong
4. **No signal scoring** — No distinction between strong/moderate/weak signals
5. **Missing categories** — Skipped creational, structural, behavioral analysis; jumped to conclusions
6. **No effort/impact** — No actionable prioritization

## Audit report example

### Input

Target: Codebase with a Decorator pattern applied to a FileWriter.

### Good audit output

```markdown
## Pattern Audit Report

### Patterns Found

| Pattern                     | Location              | Correctness | Issues                                                                                                                                                                |
| --------------------------- | --------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Decorator (FileWriter)      | `file-writer.ts:1-37` | Partial     | Missing interface extraction: `DryRunWriter` wraps `FileWriter` directly instead of a `Writer` interface. Decorators cannot be composed without the shared interface. |
| Template Method (Generator) | `generator.ts:5-29`   | Correct     | Abstract `generate()` with concrete `TemplateGenerator` skeleton. Hook point `getVars()` allows step customization. No issues found.                                  |

### Anti-Patterns Detected

| Anti-Pattern | Location                    | Recommendation                                                                                                                |
| ------------ | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Leaky Facade | `setup-workflow.ts:270-280` | `updateProjectId()` writes directly to config file — subsystem detail leaking through facade. Encapsulate in a ConfigManager. |

### Summary

2 patterns found. Template Method is correctly implemented. Decorator is partially implemented — extract a `Writer` interface to enable composition. 1 anti-pattern (Leaky Facade) found in SetupWorkflow.
```
