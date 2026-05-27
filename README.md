# claude-oop-excellence

<!-- REPLACE the odere-pro/claude-oop-excellence slug below with your repo if it differs. The CI badge
     tracks .github/workflows/ci.yml. The OpenSSF badges are commented out because they need a PUBLIC
     repo (Scorecard) and a registered project id (Best Practices) — see 14-supply-chain-and-governance. -->

[![CI](https://github.com/odere-pro/claude-oop-excellence/actions/workflows/ci.yml/badge.svg)](https://github.com/odere-pro/claude-oop-excellence/actions/workflows/ci.yml)
[![plugin validate --strict](https://img.shields.io/badge/claude%20plugin%20validate-strict-brightgreen)](https://docs.claude.com/en/docs/claude-code/plugins)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)](https://docs.claude.com/en/docs/claude-code/plugins)

<!-- Uncomment once the repo is public / the project is registered (see 14-supply-chain-and-governance):
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/odere-pro/claude-oop-excellence/badge)](https://scorecard.dev/viewer/?uri=github.com/odere-pro/claude-oop-excellence)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/REPLACE-ME/badge)](https://www.bestpractices.dev/projects/REPLACE-ME)
-->

> A Claude Code plugin that **enforces good object-oriented design in any programming language** —
> audit a codebase, get one unified report, and apply gated, test-verified fixes.

It hunts God Classes, Anemic Domain Models, Feature Envy and the rest, then refactors toward sound
design with GoF patterns (Strategy, Facade, Decorator…). Around that OOP spine sits a complete
**analyze → act** pipeline: one read-only front door, one unified report, and guided changes verified
against your project's own tests. No framework, stack, or paradigm lock-in.

Two properties make it work:

- **Glossary-driven.** A single canonical file — `skills/glossary/glossary.json` — is the source of
  truth for every entity the plugin recognizes and for the shared vocabulary every skill and agent
  reads at runtime. It defines **102 entities: 45 issues** (code smells, antipatterns, vulnerabilities,
  supply-chain risks) and **57 design patterns**.
- **Principle-based, not a per-language matrix.** Detection lives as universal design principles
  (SOLID, encapsulation, cohesion/coupling, the Law of Demeter, DRY/KISS/YAGNI,
  composition-over-inheritance, tell-don't-ask) plus language-neutral signs — so it works in any
  language the model can read. See [Language coverage](#language-coverage).

## Contents

- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Using `/audit`](#using-audit)
- [Direct layer access](#direct-layer-access)
- [Taking action](#taking-action)
- [Looking things up](#looking-things-up)
- [Agents](#agents)
- [Extending](#extending)
- [Language coverage](#language-coverage)
- [Notes](#notes)

## Quick start

Install from the bundled single-plugin marketplace:

```text
/plugin marketplace add odere-pro/claude-oop-excellence
/plugin install claude-oop-excellence@odere-pro
```

Or load it locally while developing:

```bash
claude --plugin-dir /path/to/claude-oop-excellence
# then, in-session:
/reload-plugins
```

Then run your first audit — it is **read-only** and never changes code:

```
/audit                 # whole project: both tracks in parallel, one unified report
/audit changed         # only files changed vs the base branch
/audit god-class       # a single entity
```

The report ends with a **Recommended Actions** section that prints the exact `/fix-risks` and
`/implement-patterns` commands to run next, scoped to what it found. Nothing is modified until you run
one of those yourself.

## How it works

**One front door, three layers, two tracks.** There is a single read-only analysis entry point,
`/audit`. With no selector it runs **both analysis tracks in parallel** and merges everything into ONE
unified report. Every layer is individually callable through the same `/audit` selector, so you can
zoom from the whole project down to a single entity without learning a second command.

```
  L1  /audit  (the single read-only front door)
        │  resolves a selector against skills/glossary/glossary.json
        │  (single source of truth: entities + shared vocabulary)
        ▼
  L2  ┌──────────────────────────┬──────────────────────────────────────┐
      │ RISK track               │ PATTERN track                         │
      │ antipatterns, code        │ two aspects:                          │
      │ smells, vulnerabilities,  │  · scan  — patterns already present   │
      │ supply-chain risks        │  · fit   — most-suitable suggestions  │
      └──────────────────────────┴──────────────────────────────────────┘
        │ oop-orchestrator fans out one worker per in-scope entity,
        │ ALL tracks/aspects in parallel, batched by family
        ▼
  L3  entity-detector · pattern-scanner · pattern-suggester   (read workers)
        │
        ▼
      ONE unified report → ends with Recommended Actions, printing the exact
      gated commands to run next:  /fix-risks <sel>   ·   /implement-patterns <sel>
                                   └─────────── the action layer (gated, user-invoked) ──────────┘
```

A full `/audit` is read-only end to end. The report closes with a **Recommended Actions** handoff that
prints the exact gated commands — `/fix-risks <selector> [scope]` and
`/implement-patterns <selector> [scope]` — scoped to the real findings. The action layer is itself
parallel and layered, but it stays **gated and user-invoked** (`/fix-risks` and `/implement-patterns`
are `disable-model-invocation`); Claude never refactors on its own.

## Using `/audit`

`/audit` resolves a **selector** against the glossary and zooms across the three layers —
**track → aspect → family / category / entity**. Every layer is reachable with the same command:

| Selector | Layer | Resolves to |
| --- | --- | --- |
| `/audit [scope]` | L1 (full) | **both tracks in parallel**, one unified report |
| `/audit risks` | L2 track | RISK track only — every issue family |
| `/audit patterns` | L2 track | PATTERN track — both aspects (scan + fit) |
| `/audit pattern-scan` | aspect | design patterns **already present** (via `pattern-scanner`) |
| `/audit pattern-fit` | aspect | **most-suitable** pattern suggestions (via `pattern-suggester`) |
| `/audit <category>` | entities | one category (e.g. `vulnerability`, `design-pattern`) |
| `/audit <family>` | entities | one family (e.g. `oop`, `security`, `behavioral`) |
| `/audit <entity-id>` | one entity | a single entity or pattern (e.g. `god-class`, `strategy`) |

The PATTERN track has **two aspects**: **scan** — patterns already realized in the code, detected by
`pattern-scanner` — and **fit** — the most-suitable patterns where one would help, suggested by
`pattern-suggester`. `/audit patterns` runs both; `/audit pattern-scan` or `/audit pattern-fit` runs
just one.

Each selector takes an optional **scope** suffix:

- **`full`** — the whole project (default).
- **`changed`** — only files changed versus the base branch.
- **`component <path>`** — a single subtree (a directory or file set).

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

`oop` is the spine — it surfaces in every full audit whenever class/struct/interface declarations are
present, and it is fixed before other families.

## Direct layer access

Every layer is independently callable — you never have to run the whole pipeline to reach one slice:

- **L1** — the full run: `/audit` (optionally with a scope).
- **L2** — one track or aspect: `/audit risks` / `/audit patterns`, or a single aspect
  (`risk-scan`, `pattern-scan`, `pattern-fit`).
- **L3** — one family, category, or entity: `/audit oop`, `/audit god-class`, `/audit strategy`.

For single-entity work the orchestrator is **skippable**. The five workers run **standalone by id**:
dispatched directly with just an entity id (no orchestrator, no injected record), each reads
`skills/glossary/glossary.json`, self-resolves the matching record, and runs identically to its
orchestrator-driven path. See `skills/audit/SKILL.md` and `skills/glossary/SKILL.md` for the full
direct-access contract.

## Taking action

The `/audit` report hands off to two side-effecting commands. Both are `disable-model-invocation`
(user-invoked only) and both are parallel and layered like the analysis side:

| Command | What it does |
| --- | --- |
| `/fix-risks <selector> [scope]` | Fixes risk findings entity by entity via `entity-fixer` (OOP first), verified with the project's own detected commands |
| `/implement-patterns <selector> [scope]` | Adopts suggested patterns via `pattern-implementer`, applied through a safe parallel-change sequence + tests |

Run them straight from the **Recommended Actions** section at the end of an audit — the report prints
them with real selectors and real paths.

## Looking things up

| Skill | What it does |
| --- | --- |
| `glossary` | Read-only lookup over `skills/glossary/glossary.json` — resolve any entity by id, list a family or category, or follow the cross-references (which patterns fix an issue, which issues a pattern resolves). The design-pattern catalog lives at `skills/glossary/PATTERNS.md` |

## Agents

Six agents back the work — no per-domain scanner files. One orchestrator, `oop-orchestrator`, reads
the glossary, resolves the caller's selection through the **track → aspect → family/category/entity**
layers, applies each entity's `applies_when` smart-dispatch check, and fans out **one generic worker
instance per in-scope entity** — always in parallel, batched by family — then deduplicates, scores, and
correlates into one unified report. In a full audit it runs the RISK track and the PATTERN track
concurrently. The workers are glossary-driven — the entity's full record is injected into each worker
prompt:

| Agent | Role |
| --- | --- |
| `oop-orchestrator` | Orchestrator — resolves the selection across both tracks and fans out workers, in parallel, into one unified report |
| `entity-detector` | Detect one issue entity (read-only) |
| `pattern-scanner` | Detect one design pattern already present (read-only) |
| `pattern-suggester` | Evaluate fit for one design pattern (read-only) |
| `entity-fixer` | Fix one issue entity, verified with the project's own detected commands |
| `pattern-implementer` | Implement one pattern via a safe parallel-change sequence + tests |

The eight hardcoded `risk-antipattern-*-scanner` agents are **retired**: their detection knowledge
(signs, severities, principles) now lives in the glossary and is scanned by the generic workers above.

## Extending

To add an entity — a new code smell, antipattern, vulnerability, supply-chain risk, or design pattern —
**append a record to `skills/glossary/glossary.json`**; no new agent file is needed. Give it a stable
kebab-case `id`, a `category` and `family` from the fixed vocabulary, the `principles` it violates
(issues) or upholds (patterns), language-neutral `signs`, an `applies_when` precondition, and
`default_severity` (issues) plus `corrective_patterns` / `resolves` cross-references. The generic
workers pick it up on the next run; the strict glossary gate keeps the file conformant.

## Language coverage

Universality comes from **principles + language-neutral signs + design patterns**, not from a
per-language matrix. The orchestrator detects the stack from the file manifest, and each worker applies
its own language judgment to the injected entity record — there are no extension globs and no
per-language type-checker in the architecture. TypeScript/JavaScript and Python are the *exercised*
targets, not a hardcoded language tier. Fix and implement verify with the project's **own detected**
test/typecheck/lint command rather than any hardcoded tooling.

## Notes

- `/audit` is read-only end to end; it never modifies code. Review its unified report — and the
  **Recommended Actions** it prints — before running a gated action command.
- The audit → action hand-off is explicit: `/audit` prints the exact `/fix-risks` and
  `/implement-patterns` commands (with real selectors and scopes) to run next.
- `/fix-risks` and `/implement-patterns` run the project's **own detected** test/typecheck/lint command
  (e.g. `npm test`, `pytest`, `make test`, `go test ./...`) and verify each change before moving on —
  there is no single-language tooling assumption.
