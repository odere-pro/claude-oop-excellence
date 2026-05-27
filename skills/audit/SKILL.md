---
name: audit
description: >-
  Use before releases, after large PRs, or during onboarding to run a single read-only analysis of a
  codebase's quality, risk, and design. The one analysis front door. Reads the glossary to resolve a
  selector that zooms across three layers — track, aspect, family/category/entity — then delegates to
  the oop-orchestrator in analyze mode (both the RISK track and the PATTERN track in parallel) or a
  narrower mode for a track/aspect selector. The orchestrator fans out one worker per in-scope entity
  in parallel, batched by family, and returns ONE unified report: risk findings (matrix, hotspots,
  correlations, score), Patterns Present, Pattern Opportunities, and a Recommended Actions handoff
  printing the exact gated commands to run next. Language-agnostic; select by track, aspect, category,
  family, or entity id, in any scope.
argument-hint: '[full | changed | component <path> | risks | patterns | pattern-scan | pattern-fit | <category> | <family> | <entity-id>] [full | changed | component <path>]'
user-invocable: true
---

# Quality, Risk & Design Audit

`/audit` is **THE** read-only analysis entry point for this plugin. It subsumes every separate
analysis path — there is one front door, one selector grammar, and one unified report. It resolves a
selector against the glossary, delegates the heavy lifting to the `oop-orchestrator`, and returns a
single merged report. It assumes nothing about the language or stack and never modifies code.

The plugin organizes analysis across **two tracks** and zooms through **three layers** —
**track → aspect → family / category / entity**:

- **RISK track** — find problems: code smells, antipatterns, vulnerabilities, supply-chain risks.
- **PATTERN track** — work with design patterns: detect patterns already present (`pattern-scan`)
  and suggest the most-suitable patterns where one would help (`pattern-fit`).

A full `/audit` runs **both tracks in parallel** and merges them into ONE report.

## Selector grammar

```
/audit [full | changed | component <path>]            → L1: both tracks, in parallel, one report
/audit risks [scope]                                  → L2: RISK track only
/audit patterns [scope]                               → L2: PATTERN track (scan + fit)
/audit pattern-scan [scope]                           → aspect: patterns already present
/audit pattern-fit [scope]                            → aspect: most-suitable pattern suggestions
/audit <category> [scope]                             → one issue/pattern category
/audit <family> [scope]                               → one family of issues or patterns
/audit <entity-id> [scope]                            → one entity or pattern
```

Every form takes an optional **scope** suffix — `full` (default), `changed`, or `component <path>`.

### What to look for (selector, default = both tracks)

The glossary is the single source of truth for what the plugin recognizes. A selector resolves
against it, zooming from the broadest layer (a whole track) to the narrowest (one entity):

- **`full` / `changed` / `component <path>` / none** — the **L1 full run**: the RISK track and the
  PATTERN track dispatched **in parallel**, merged into one unified report. (A bare scope word with
  no selector is the full run scoped accordingly.)
- **`risks`** — the **RISK track only** (its sole aspect is `risk-scan`): every issue family (`oop`,
  `code`, `architecture`, `testing`, `concurrency`, `database`, `security`, `dependency`).
- **`patterns`** — the **PATTERN track**: both aspects, `pattern-scan` + `pattern-fit`.
- **`pattern-scan`** — one aspect: design patterns **already present** in the code.
- **`pattern-fit`** — one aspect: the **most-suitable** patterns where one would help.
- **`<category>`** — one category of entities (e.g. `vulnerability`, `antipattern`, `code-smell`,
  `supply-chain-risk`, `design-pattern`).
- **`<family>`** — one family of issues or patterns (e.g. `oop`, `security`, `behavioral`). `oop` is
  the spine of this plugin — it surfaces whenever class/struct/interface declarations are present.
- **`<entity-id>`** — a single glossary entity or pattern, by its stable id (e.g. `god-class`,
  `feature-envy`, `strategy`).

### Where to look (scope, default `full`)

- **`full`** — the whole project (default).
- **`changed`** — only files changed versus the base branch.
- **`component <path>`** — a single subtree (a directory or file set).

## Direct layer access

Every layer is reachable on its own — you never have to run the whole pipeline to touch a single
slice. The selector zooms across the three layers, and each is a valid entry point:

- **L1 — the full run.** `/audit [full | changed | component <path>]` dispatches **both tracks in
  parallel** through the `oop-orchestrator` and merges them into one report.
- **L2 — one track or aspect.** `/audit risks`, `/audit patterns`, `/audit pattern-scan`, or
  `/audit pattern-fit` runs just that track/aspect (the RISK track's sole aspect is `risk-scan`). The
  orchestrator still resolves and fans out, but only over the selected slice.
- **L3 — one family, category, or entity.** `/audit <family>`, `/audit <category>`, or
  `/audit <entity-id>` (e.g. `/audit oop`, `/audit god-class`, `/audit strategy`) narrows to a single
  slice or a single record.

**The orchestrator is skippable for single-entity work.** For a single L3 entity, an agent can
dispatch one worker **directly** with the Task tool, passing only an entity **id** (and an optional
scope) — no orchestrator, no injected record. The worker self-resolves the full record from
`skills/glossary/glossary.json` (see each worker's `## Standalone invocation` section) and proceeds
identically:

- `entity-detector` — detect one issue (read-only).
- `pattern-scanner` — detect whether one design pattern is already present (read-only).
- `pattern-suggester` — evaluate fit for one design pattern (read-only).
- `entity-fixer` — fix one issue (gated, side-effecting).
- `pattern-implementer` — implement one design pattern (gated, side-effecting).

The user-facing path stays the `/audit` selector; the direct worker dispatch is the agent-facing
shortcut when only one entity is in play.

## Workflow

### 1. Parse arguments

Read `$ARGUMENTS` into a **selector** (a track, aspect, category, family, or entity id — default the
full run across both tracks) and a **scope** (`full`, `changed`, or `component <path>` — default
`full`).

### 2. Resolve the selector against the glossary

The glossary (`skills/glossary/glossary.json`, surfaced by the `glossary` skill) is the single source
of truth, and its selector table is canonical. Resolving means zooming down through the layers:

- a **track** (`risks` / `patterns`) implies its aspects, families, and entities,
- an **aspect** (`pattern-scan` / `pattern-fit`) implies its families and entities,
- a **category** maps to every entity of that category,
- a **family** maps to every entity in that family,
- an **`<entity-id>`** maps to that one entity record,
- the **full run** maps to every in-scope entity across both tracks.

You do not enumerate entities yourself — pass the selector through and let the `oop-orchestrator`
read the glossary and resolve it. Each entity carries language-neutral `signs` and an `applies_when`
precondition, so the analysis stays principle-driven rather than tied to file-extension globs or a
specific language's type-checker. The patterns catalog lives at `skills/glossary/PATTERNS.md`; the
glossary itself remains the canonical registry of every entity.

### 3. Delegate to the orchestrator (read-only)

Invoke the `oop-orchestrator` agent with the Agent tool. The selector chooses the mode:

- **Full run** (no selector, or just a scope) → **`analyze`** super-mode: both tracks in parallel.
- **`risks`** → **`validate`/`detect`** mode (RISK track).
- **`patterns`** → both pattern aspects.
- **`pattern-scan`** / **`pattern-fit`** → that single aspect.
- **`<category>` / `<family>` / `<entity-id>`** → the narrower mode for that track's aspect, scoped
  to the resolved entities.

Pass a prompt containing the mode, the selector, and the scope, for example:

- Full run: `"Mode: analyze. Selection: all. Scope: full. Verbose mode: ON — report all findings across every severity (critical, high, medium, low); do not cap or truncate."`
- Risk track: `"Mode: validate. Selection: risks. Scope: changed."`
- Pattern track: `"Mode: analyze (pattern track). Selection: patterns. Scope: component src/."`
- Single aspect: `"Mode: pattern-scan. Selection: pattern-scan. Scope: full."`
- Family: `"Mode: validate. Selection: oop. Scope: component src/domain."`
- Single entity: `"Mode: validate. Selection: god-class. Scope: component src/."`

The `oop-orchestrator` reads the glossary, resolves the selector to the in-scope entities per track,
applies each entity's `applies_when` smart-dispatch check (explicit selectors override skips),
dispatches **one worker per entity in parallel, batched by family**, then deduplicates, computes the
weighted risk score, and detects cross-domain correlations. The whole analysis path is read-only.

### 4. Return the unified report

Return the orchestrator's unified report to the user verbatim — scoring, dedup, correlation, and the
action handoff are already applied. In a full run the report carries:

- **Risk findings** — a severity matrix, hotspots (modules with findings from 3+ families),
  cross-domain correlations, and a weighted **risk score** with verdict.
- **Patterns Present** — design patterns already realized in the code (from the PATTERN track's scan).
- **Pattern Opportunities** — where adopting a pattern would help (from the PATTERN track's fit).
- **Recommended Actions** — the audit → action handoff: the exact **gated** commands to run next,
  scoped to the findings, printed with real selectors and real paths:
  - `/fix-risks <selector> [scope]` — fix a risk-finding cluster.
  - `/implement-patterns <selector> [scope]` — adopt a suggested pattern where it fits.

A narrower selector returns only the relevant sections (risk-only, scan-only, or fit-only), with
Recommended Actions scoped to whatever was found.

## Universality

This audit is principle- and sign-driven, never per-language. There is no per-language matrix and no
hardcoded type-checker: the orchestrator detects the languages in play from the file manifest, and
each worker applies its own language judgment to the language-neutral `signs` and design principles
carried in the entity record. The same selectors work on any stack.

## Usage

```
/audit                              # full run: both tracks in parallel, one unified report
/audit risks                        # RISK track only
/audit patterns                     # PATTERN track: scan + fit
/audit pattern-scan                 # design patterns already present
/audit oop                          # the OOP family of issues
/audit god-class component src/     # one entity, scoped to a subtree
/audit strategy                     # one design pattern (present + fit)
/audit changed                      # full run, only files changed vs the base branch
```
