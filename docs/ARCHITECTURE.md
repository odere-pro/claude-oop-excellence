# Architecture

The deep-dive companion to the README's [How it works](../README.md#how-it-works) section. Read this
when you need the full picture of how `/audit` resolves a selector, how the orchestrator fans out
workers, and how the standalone-worker contract lets you skip the orchestrator entirely.

## One front door, three layers, two tracks

There is a single read-only analysis entry point — `/audit`. With no selector it runs **both
analysis tracks in parallel** and merges everything into ONE unified report. Every layer is
individually callable through the same `/audit` selector, so you can zoom from the whole project
down to a single entity without learning a second command.

| Layer | What lives here |
| --- | --- |
| **L1 — front door** | `/audit` resolves the selector against `skills/glossary/glossary.json` (single source of truth: entities + shared vocabulary) |
| **L2 — tracks & aspects** | RISK track (antipatterns, code smells, vulnerabilities, supply-chain risks) and PATTERN track with two aspects — **scan** (patterns already present) and **fit** (most-suitable suggestions) |
| **L3 — workers** | One generic worker instance per in-scope entity, fanned out in parallel, batched by family: `entity-detector`, `pattern-scanner`, `pattern-suggester` |

The action layer is downstream of L3 and **gated** — Claude never refactors on its own. The report
closes with a **Recommended Actions** handoff that prints the exact
`/fix-risks <selector> [scope]` and `/implement-patterns <selector> [scope]` commands scoped to the
real findings. Both action commands are `disable-model-invocation`; only you can run them.

## Orchestrator fan-out

`oop-orchestrator` reads the glossary, resolves the caller's selection through the
**track → aspect → family/category/entity** layers, applies each entity's `applies_when`
smart-dispatch check, and fans out **one generic worker instance per in-scope entity** — always in
parallel, batched by family — then deduplicates, scores, and correlates into one unified report. In
a full audit it runs the RISK track and the PATTERN track concurrently. The workers are
glossary-driven: the entity's full record is injected into each worker prompt.

## Standalone-worker contract (single-entity direct dispatch)

For single-entity work the orchestrator is **skippable**. The five workers run **standalone by id**:
dispatched directly with just an entity id (no orchestrator, no injected record), each reads
`skills/glossary/glossary.json`, self-resolves the matching record, and runs identically to its
orchestrator-driven path.

See [`skills/audit/SKILL.md`](../skills/audit/SKILL.md) and
[`skills/glossary/SKILL.md`](../skills/glossary/SKILL.md) for the full direct-access contract and
selector grammar.

## Retired agents

The eight hardcoded `risk-antipattern-*-scanner` agents that used to live in `agents/` are
**retired**. Their detection knowledge — signs, severities, principles — now lives in the glossary
and is scanned by the generic workers (`entity-detector`, `pattern-scanner`, `pattern-suggester`).
Adding a new entity no longer requires writing a new agent file; see
[EXTENDING.md](EXTENDING.md).
