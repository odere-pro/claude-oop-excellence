---
name: improve
description: >-
  Use after /audit flags problem areas, or directly on a smell/antipattern/family, to apply the
  smallest corrective refactor and verify it with the project's own detected commands. The FIX action
  reached from the audit report's Recommended Actions handoff (/fix-risks <selection>). Resolves the
  selection against the glossary and delegates to the oop-orchestrator in fix mode, one entity-fixer
  per entity. Language-agnostic; supports --plan-only. Modifies source, so user-invoked only.
argument-hint: '[<entity-id> | <family> | all] [full | changed | component <path>] [--plan-only]'
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Agent(oop-orchestrator)
---

# Quality Improver

The FIX action — Layer 1, the side-effecting action of the RISK track. Detect → smallest corrective
refactor → verify, one glossary entity at a time, in any language. This skill resolves the caller's
selection against the glossary, then delegates the work to the `oop-orchestrator` in **fix** mode,
which fans out one `entity-fixer` worker per in-scope entity, in parallel, batched by family. It
assumes nothing about the language or stack.

This is the action an `/audit` report hands off to: the report's **Recommended Actions** section
emits `/fix-risks <selection> <scope>`, which drives exactly this fix flow against the selection it
recommends.

Because this skill **writes to your source tree**, it is user-invoked only
(`disable-model-invocation: true`) and never auto-fires.

## Selection grammar

```
[<entity-id> | <family> | all] [full | changed | component <path>] [--plan-only]
```

This mirrors the `/audit` selection + scope grammar exactly, plus a `--plan-only` mode.

### Selection (default `all`)

The unit of work is a **glossary entity**, not a hardcoded domain. Resolve the selection against
`skills/glossary/glossary.json`:

- **`<entity-id>`** — a single issue entity (e.g. `feature-envy`, `god-class`, `shotgun-surgery`).
- **`<family>`** — every issue entity in one family (e.g. `oop`, `code`, `architecture`, `testing`,
  `concurrency`, `database`, `security`, `dependency`).
- **`all`** — every issue entity of the relevant kind.

Only issue entities (code smells, antipatterns, vulnerabilities, supply-chain risks) are in scope for
the fix verb — design patterns are the province of `/implement-patterns`.

### Scope (default `full`)

- **`full`** — the whole project.
- **`changed`** — only files changed versus the base branch (`git diff`).
- **`component <path>`** — a directory or file set (e.g. `component src/`).

### `--plan-only`

Produce the corrective plan — detected instances and the intended diffs — and make **no edits**. No
files are written, no mutating commands run. Use it to preview the refactor before committing to it.

## Workflow

### 1. Parse and resolve the selection

Read `$ARGUMENTS` for the selection, scope, and the optional `--plan-only` flag. Read
`skills/glossary/glossary.json` and resolve the selection to the concrete set of in-scope issue
entities, each with its full record — `id`, `name`, `category`, `family`, `principles` (the
principles it *violates*), `signs` (language-neutral, plain-English descriptions — never regex),
`default_severity`, `applies_when`, and `corrective_patterns` (ids of the design patterns that fix
it). The glossary is the single source of truth; do not invent entities or fields.

If no selection is given, default to `all` issue entities (subject to applicability) — or ask the
user to narrow it when the surface is large.

### 2. Delegate to the orchestrator (fix mode)

Invoke the `oop-orchestrator` agent with the Agent tool in **fix** mode, passing the resolved
selection, scope, and the `--plan-only` flag when set. For example:

- Single entity: `"Mode: fix. Selection: feature-envy. Scope: full."`
- Family: `"Mode: fix. Selection: oop. Scope: component src/."`
- Plan only: `"Mode: fix. Selection: god-class. Scope: changed. --plan-only."`

`oop-orchestrator` resolves applicability (`applies_when`), builds a shared file manifest, and fans
out **one `entity-fixer` per in-scope entity**, in parallel, batched by family, injecting that
entity's full glossary record into each worker. Explicitly naming an entity id or family overrides
`applies_when` smart-dispatch skips.

### 3. What each `entity-fixer` does

For its one injected entity, the worker:

1. **Detects** instances within scope by the entity's `signs`, translated into the idioms of whatever
   language(s) are actually present (class/struct/interface/trait; function/method/closure — the
   intent holds across languages).
2. Applies the **smallest corrective refactor** that resolves each instance, guided by the entity's
   `corrective_patterns` and the `principles` it violates — least change, behavior-preserving,
   immutable, matching the codebase's existing idioms.
3. **Verifies** with the **project's own detected commands** (see below). On failure caused by an
   edit, it iterates or rolls back rather than leaving the tree broken. It never weakens, skips, or
   deletes a test to make verification pass.

In `--plan-only` mode the worker stops after step 1–2, emitting the intended diff without writing.

### 4. Verification uses the project's OWN detected commands

The typecheck / test / lint command is **detected from the project, never hardcoded to any one
language**. The worker reads the repo and resolves the canonical entrypoints from, in rough order:

- a package/script manifest — `package.json` scripts (`test`, `lint`, `typecheck`), `Makefile`
  targets, `pyproject.toml` / `tox.ini` / `noxfile.py`, `Taskfile.yml`, `justfile`, `composer.json`,
  `build.gradle` / `pom.xml`, `Cargo.toml`, `go.mod`, `*.csproj` / `*.sln`, `Gemfile` / `Rakefile`;
- CI workflow files (e.g. under `.github/workflows/`), which often name the canonical invocations;
- a documented command in `README` / `CONTRIBUTING` as a fallback.

It prefers the project's own wrapper (`npm test`, `make test`, `just check`, `go test ./...`,
`cargo test`, `pytest`, etc.) so the project's config is respected. There is **no** fixed type-checker
invocation, no extension-glob, and no single-language tooling assumption baked in. If no tests exist,
the worker says so and describes the manual verification it performed.

### 5. Return the result

Return the orchestrator's aggregated report verbatim. For each entity it covers: detected instances,
the corrective pattern applied (and why it fits the violated principle), a per-file diff summary, the
exact verification command(s) run and their pass/fail result, and a status (fixed / planned /
no-op / aborted). Then recommend next steps:

- `/audit <selection>` — re-scan to confirm the selection is clean.
- Commit the behavior-preserving refactor with a `refactor:` message.

## Usage

```
/improve                                # fix all applicable issue entities, full project
/improve oop                            # fix every OOP-family smell/antipattern
/improve feature-envy --plan-only       # preview the Feature Envy fix without writing
/improve god-class component src/        # fix God Class only under src/
/improve security changed                # fix security entities in changed files
/improve oop component src/              # fix OOP-family entities under src/
```
