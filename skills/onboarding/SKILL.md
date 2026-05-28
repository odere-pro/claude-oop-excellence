---
name: onboarding
description: >-
  Use when someone is new to claude-oop-excellence and asks how to use it, where to start, what
  /audit does, or which command to run next — a read-only orientation to the plugin. Explains the
  mental model (one read-only front door, /audit; three layers; two tracks — RISK and PATTERN) and
  the analyze → act flow that hands off to the gated /fix-risks and /implement-patterns commands.
  Points to the glossary and README for depth. Changes nothing.
user-invocable: true
---

# Getting started with claude-oop-excellence

This plugin **enforces good object-oriented design in any programming language**: you audit a
codebase, get one unified read-only report, then apply gated, test-verified fixes. It hunts God
Classes, Anemic Domain Models, Feature Envy and the rest, then refactors toward sound design with
proven patterns (Strategy, Facade, Decorator…) — no framework, stack, or paradigm lock-in.

This orientation **changes nothing**. It explains the mental model and the shortest path to value,
then points you at the deeper docs. Run a real audit when you are ready.

## The mental model

**One front door, three layers, two tracks.**

- **One front door** — `/audit` is the single, read-only analysis entry point. With no selector it
  runs everything and merges it into ONE unified report.
- **Three layers** — `/audit` resolves a selector against the glossary and zooms across
  **track → aspect → family / category / entity**:
  - **L1** — the full run (`/audit`, both tracks together).
  - **L2** — a single track or aspect.
  - **L3** — a single family, category, or entity id.
- **Two tracks** — every full audit runs both in parallel:
  - **RISK** — antipatterns, code smells, vulnerabilities, supply-chain risks.
  - **PATTERN** — two aspects: **scan** (design patterns already present) and **fit**
    (most-suitable pattern suggestions).

A full `/audit` is read-only end to end. The report closes with a **Recommended Actions** handoff
that prints the exact gated commands to run next — nothing is modified until you run one yourself.

## The 60-second path

1. **Analyze (read-only).** Run `/audit` for the whole project, or `/audit changed` for just the
   files changed versus the base branch.
2. **Read the unified report.** You get risk findings (matrix, hotspots, correlations, an aggregate
   score), **Patterns Present**, **Pattern Opportunities**, and a **Recommended Actions** section.
3. **Act (gated, your call).** Run the exact `/fix-risks` or `/implement-patterns` command the
   report prints, scoped to what it found. Add `--plan-only` to preview the change without writing.

Nothing changes until you run a gated action command yourself.

## Commands at a glance

| Command | What it does |
| --- | --- |
| `/audit [selector] [scope]` | Read-only analysis — both tracks by default; the single front door |
| `/fix-risks <selector> [scope]` | Gated fix — repairs risk findings entity by entity (OOP first), verified with the project's own detected commands |
| `/implement-patterns <selector> [scope]` | Gated implement — adopts suggested patterns via a safe parallel-change sequence + tests |
| `glossary` | Read-only lookup — resolve any entity by id, list a family or category, follow cross-references |

`/fix-risks` and `/implement-patterns` are `disable-model-invocation` (user-invoked only); both
accept `--plan-only` for a no-write preview.

## Selectors & scope (quick cheat sheet)

A **selector** tells `/audit` how far to zoom; a **scope** suffix limits where it looks.

- **Selectors** — `risks` (RISK track), `patterns` (PATTERN track: scan + fit), `pattern-scan`
  (patterns already present), `pattern-fit` (most-suitable suggestions), a `<category>` (e.g.
  `vulnerability`), a `<family>` (e.g. `oop`, `behavioral`), or a single `<entity-id>` (e.g.
  `god-class`, `strategy`).
- **Scope** — `full` (whole project, default), `changed` (files changed vs the base branch), or
  `component <path>` (a single subtree).

```
/audit                              # full run: both tracks in parallel, one unified report
/audit changed                      # full run, only files changed vs the base branch
/audit risks                        # RISK track only
/audit pattern-scan                 # design patterns already present
/audit god-class component src/     # one entity, scoped to a subtree
/audit strategy                     # one design pattern (present + fit)
```

For the full selector grammar see `skills/audit/SKILL.md`; for the selector → entity resolution see
`skills/glossary/SKILL.md`.

## Learn more

- **`README.md`** — Quick start, the full "How it works" diagram, and the complete command reference.
- **`glossary` skill** — the canonical vocabulary and lookup over `skills/glossary/glossary.json`,
  the single source of truth for all **102 entities (45 issues + 57 design patterns)**.
- **Recommended Actions** — the bottom of every `/audit` report is your real next step: it prints
  the exact gated commands, with real selectors and paths, to run when you choose to act.
