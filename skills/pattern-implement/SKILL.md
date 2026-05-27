---
name: pattern-implement
description: >-
  Use after /audit pattern-fit surfaces an opportunity, or directly on a design-pattern id, to
  implement that pattern into a target scope with a safe parallel-change sequence and verify it with
  the project's own detected commands. Resolves the pattern against the glossary and delegates to the
  oop-orchestrator in pattern-implement mode, one pattern-implementer per pattern.
  Language-agnostic; supports plan / --plan-only. Modifies source, so user-invoked only.
argument-hint: '[plan] <pattern-id> [full | changed | component <path>] [--plan-only]'
user-invocable: true
disable-model-invocation: true
---

# Pattern Implementer

The IMPLEMENT action — the Layer 1 action of the PATTERN track. Locate → scaffold alongside →
migrate call sites → remove the old path + verify, one glossary design pattern at a time, in any
language. This is the action layer reached from the `/audit` report's **Recommended Actions**
handoff: audit recommends `/implement-patterns <selection>` for a high-confidence pattern
opportunity, and that command drives this implement flow. This skill resolves the requested pattern
against the glossary, then delegates the work to the `oop-orchestrator` in **pattern-implement**
mode, which fans out one `pattern-implementer` worker per in-scope pattern. It assumes nothing about
the language or stack.

Because this skill **writes to your source tree**, it is user-invoked only
(`disable-model-invocation: true`) and never auto-fires.

## Selection grammar

```
[plan] <pattern-id> [full | changed | component <path>] [--plan-only]
```

The recommended, primary use is **one pattern at a time** — name a single `<pattern-id>`. A leading
`plan` verb or a trailing `--plan-only` flag plans without writing any files. Batch selection by
family or `all` is also accepted, but prefer a single, deliberate pattern per run.

### Pattern selection (no default — name a pattern)

The unit of work is a **glossary design-pattern entity**, not a hardcoded catalog. Resolve the
selection against `skills/glossary/glossary.json`:

- **`<pattern-id>`** (primary) — a single design pattern (e.g. `strategy`, `facade`,
  `chain-of-responsibility`, `repository`).
- **`<family>`** — every design pattern in one pattern family (`creational`, `structural`,
  `behavioral`, `architectural`, `enterprise`, `functional`, `ddd`). Use sparingly — batch
  implementation changes many call sites at once.
- **`all`** — every design-pattern entity. Reserve for surveys; a single pattern is the safer unit.

Only design-pattern entities are in scope for the implement verb — issues (code smells,
antipatterns, vulnerabilities, supply-chain risks) are the province of `/improve`.

### Scope (default `full`)

- **`full`** — the whole project.
- **`changed`** — only files changed versus the base branch (`git diff`).
- **`component <path>`** — a directory or file set (e.g. `component src/data/`).

### Plan mode (`plan` verb or `--plan-only`)

A leading `plan` verb (`plan strategy src/`) or a trailing `--plan-only` flag plans **without
writing files**. The worker performs the read-only locate-and-confirm step, then emits the
specialized four-step sequence, the files it would create vs. modify, the diff shape (constructs
added / migrated / removed), the detected verification command that *would* run, and the principles
the pattern upholds. No files are written and no mutating commands run. Use it to preview the change
before committing to it.

## Workflow

### 1. Parse and resolve the pattern

Read `$ARGUMENTS` for the optional `plan` verb, the pattern selection, the scope, and the optional
`--plan-only` flag. Read `skills/glossary/glossary.json` and resolve the selection to the concrete
design-pattern entity (or entities), each with its full record — `id`, `name`, `category`
(`design-pattern`), `family`, `principles` (the principles it *upholds*, e.g. `ocp`, `dip`,
`composition-over-inheritance`), `signs` (language-neutral, plain-English descriptions of the
structure the implemented pattern should exhibit — never regex), `resolves` (ids of the issue
entities this pattern fixes — the problem to confirm is present before implementing), and
`applies_when`. The glossary is the single source of truth; do not invent patterns or fields.

If no pattern is named, ask the user which pattern to implement — there is no safe default for a
source-modifying verb.

### 2. Delegate to the orchestrator (pattern-implement mode)

Invoke the `oop-orchestrator` agent with the Agent tool in **pattern-implement** mode, passing the
resolved pattern, scope, and the plan / `--plan-only` flag when set. For example:

- Single pattern: `"Mode: pattern-implement. Selection: strategy. Scope: component src/."`
- Plan only: `"Mode: pattern-implement. Selection: strategy. Scope: full. --plan-only."`
- Family: `"Mode: pattern-implement. Selection: structural. Scope: changed."`

`oop-orchestrator` resolves applicability (`applies_when`), builds a shared file manifest, and fans
out **one `pattern-implementer` per in-scope pattern**, batched by family, injecting that pattern's full
glossary record into each worker. Explicitly naming a pattern id or family overrides `applies_when`
smart-dispatch skips.

### 3. The safe four-step parallel-change sequence

For its one injected pattern, each `pattern-implementer` runs a **parallel change** ("expand then
contract") — it adds the new path beside the old one, migrates to it, and only then removes the old
path, so the project's tests stay meaningful at every step:

1. **Locate & confirm** — use the scope and the pattern's `applies_when` to find the insertion
   point, and **confirm at least one `resolves` issue is actually present** (e.g. branching-on-type
   for `strategy`, a god-class for `facade`). If the problem the pattern fixes is not present, the
   worker reports `N/A — resolved issue not found` and stops. A pattern is never forced where it
   earns nothing.
2. **Scaffold alongside** — introduce the pattern's types/abstractions/concrete pieces *next to* the
   existing code without removing the old path, then run the detected tests (they must still pass —
   nothing is rewired yet).
3. **Migrate call sites** — repoint call sites to the new pattern one at a time or in small coherent
   batches, running the detected tests after each migration and fixing the implementation (never the
   test) on failure.
4. **Remove old path + verify** — once every call site uses the new pattern, remove the now-dead old
   path, run the project's full detected command, and confirm the implemented structure matches the
   pattern's `signs` and upholds its `principles`.

In plan / `--plan-only` mode the worker performs only step 1 read-only, then emits the plan and diff
shape and writes nothing.

### 4. Verification uses the project's OWN detected commands

The test / typecheck / lint command is **detected from the project, never hardcoded to any one
language**. The worker reads the repo and resolves the canonical entrypoints from, in rough order:

- a package/script manifest — `package.json` scripts (`test`, `lint`, `typecheck`), `Makefile`
  targets, `pyproject.toml` / `tox.ini` / `noxfile.py`, `Taskfile.yml`, `justfile`, `composer.json`,
  `build.gradle` / `pom.xml`, `Cargo.toml`, `go.mod`, `*.csproj` / `*.sln`, `Gemfile` / `Rakefile`;
- CI workflow files (e.g. under `.github/workflows/`), which often name the canonical invocations;
- a documented command in `README` / `CONTRIBUTING` as a fallback.

It prefers the project's own wrapper (`npm test`, `make test`, `just check`, `go test ./...`,
`cargo test`, `pytest`, etc.) so the project's config is respected. There is **no** fixed
`tsc --noEmit`, no extension-glob, and no single-type-checker assumption. If no tests exist, the
worker says so and describes the manual verification it performed — it never fabricates a result.

### 5. Return the result

Return the orchestrator's aggregated report verbatim. For the pattern it covers: the confirmed
insertion point and `resolves` issue, the four steps taken, a per-file change summary, the principles
upheld (with one line each on how the implementation honors them), the exact verification command(s)
run and their pass/fail result, and a status (implemented / planned / N/A / aborted). Then recommend
next steps:

- `/audit pattern-scan <path>` — re-scan to confirm the pattern now reads as present.
- `/audit <selection>` — confirm the resolved issue is gone.
- Commit the behavior-preserving change with a `refactor:` message.

## Gating discipline

- Source-modifying, so **user-invoked only** (`disable-model-invocation: true`); it never auto-fires.
- Always a **parallel change**: scaffold, migrate, then remove — never delete the old path before the
  new one carries every call site.
- **Confirm the `resolves` issue is present first.** If it is absent, report `N/A` and stop — no
  speculative rewrites.
- Behavior-preserving and immutable: the smallest viable change that introduces the pattern, new
  values over mutated shared state.
- Never weaken, skip, or delete a test to make verification pass — fix the implementation.
- In plan / `--plan-only` mode, write no files.

## Usage

```
/pattern-implement plan strategy src/             # plan Strategy under src/ — write nothing
/pattern-implement strategy component src/         # implement Strategy under src/
/pattern-implement repository component src/data/  # implement Repository under src/data/
/pattern-implement facade changed                  # implement Facade in changed files
/pattern-implement chain-of-responsibility --plan-only   # preview the plan, write nothing
/pattern-implement structural changed              # batch: structural-family patterns in changes
```
