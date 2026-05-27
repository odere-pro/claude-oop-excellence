---
name: detect-concurrency-antipatterns
description: >-
  Use when reviewing async code, worker pools, or multi-threaded systems to scan for concurrency
  antipatterns (Race Conditions, Deadlocks, Busy Waiting, Thread Starvation).
argument-hint: '[path-or-glob]'
user-invocable: true
---

# Concurrency Antipattern Detector

## Table of contents

- [REFERENCE.md](REFERENCE.md) — Detection heuristics per antipattern, language-specific patterns, grep patterns, thresholds, false positive guidance
- [EXAMPLES.md](EXAMPLES.md) — Sample detections with input code and report output

## Workflow

1. **Parse target path**: Read `$ARGUMENTS` for the target path or glob. If empty, default to the project source directory (e.g., `src/`, `lib/`, `scripts/`, or project root). Validate the path exists.

2. **Identify concurrency model**: Scan target files for concurrency primitives to determine the model in use.

   Primitives to look for:
   - **async/await**: `async function`, `await`, `Promise.all`, `Promise.race`
   - **Workers**: `new Worker`, `worker_threads`, `parentPort`, `postMessage`
   - **Threads**: `Thread`, `threading`, `pthread`, `goroutine`, `go func`
   - **Locks/Mutexes**: `Mutex`, `Lock`, `synchronized`, `lock()`, `acquire()`, `release()`
   - **Channels**: `chan`, `Channel`, `queue.Queue`, `BlockingQueue`

   Classify as: `async/await`, `workers`, `threads`, `mixed`, or `none detected`.
   If `none detected`, report that no concurrency patterns were found and exit.

3. **Scan for each antipattern**: Apply the detection strategies from the table below. Read [REFERENCE.md](REFERENCE.md) for language-specific patterns and grep heuristics.

   | Antipattern       | Detection Strategy                                                                                                                    |
   | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
   | Race Condition    | Shared `let`/`var` modified in async callbacks, global mutable state accessed from workers, missing `await` on shared resource access |
   | Deadlock          | Multiple `lock()`/`acquire()` calls in different orders across functions, nested `synchronized` blocks, `await` inside lock scope     |
   | Busy Waiting      | `while` loops with condition checks and no `await`/`sleep`/`yield`, `setInterval` polling without cleanup                             |
   | Thread Starvation | Unbounded task queues, `await` of long operations inside thread pool handlers, no pool size limits                                    |

   For each antipattern:
   - Use Grep to find candidate patterns (see [REFERENCE.md](REFERENCE.md) for grep patterns per language).
   - Read surrounding context (10-20 lines) to confirm the finding.
   - Check for false positives using the guidance in [REFERENCE.md](REFERENCE.md).
   - Assign severity: `critical` (confirmed risk), `warning` (likely risk), `info` (potential concern).

4. **Record findings**: For each confirmed finding, record:
   - File path and line number
   - Antipattern category
   - Severity level
   - Evidence (the code pattern that triggered detection)
   - Brief description of the risk

5. **Output structured report**: Format the findings using the report template below.

6. **Verification checklist**: After producing the report, verify:

   ```
   - [ ] All target files were scanned
   - [ ] Each antipattern category was checked
   - [ ] False positives were filtered using REFERENCE.md guidance
   - [ ] Severity levels are consistent across findings
   - [ ] Recommendations are actionable and prioritized
   ```

## Report template

```
# Concurrency Antipattern Report

**Scanned:** {file count} files
**Concurrency model:** {async/await, workers, threads, mixed}
**Findings:** {critical} critical, {warning} warnings, {info} info

## Critical
- [{antipattern}] {file}:{line} — {description}

## Warnings
- [{antipattern}] {file}:{line} — {description}

## Info
- [{antipattern}] {file}:{line} — {description}

## Recommendations
{prioritized fixes}
```

## Severity guide

| Severity | Criteria                                                                                    |
| -------- | ------------------------------------------------------------------------------------------- |
| Critical | Confirmed data corruption risk, proven deadlock potential, or unbounded resource exhaustion |
| Warning  | Likely race condition or starvation under realistic load, but not yet proven                |
| Info     | Code smell that could become a problem under scale or refactoring                           |
