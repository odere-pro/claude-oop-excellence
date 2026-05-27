# Plan — close the two gaps: direct-layer bypass + doc/drift gating

> **Implementation contract.** The goal skill executes the checkboxes below — **one checkbox per
> agent, in a fresh context**. Each agent reads only this file plus the source files its checkbox
> names. On completion: make the edits, flip the box to `[x]`, stop. Phases are ordered; checkboxes
> within a phase are independent and may run in parallel (distinct files). Run the gate suite only in
> Phase 4. **Quit condition: every checkbox below is `[x]`.**

## Context

After the 3-layer rework an audit found two criteria only *partially* met:

1. **No direct L3 "bypass."** Every path funnels `/audit` (L1) → `oop-orchestrator` (L2) → workers
   (L3). The five workers are documented as *"the orchestrator injects one entity record"* and cannot
   run standalone — so an agent can't cleanly call a single worker, and a user has no documented
   per-layer entry beyond the `/audit` selector.
2. **Docs aren't gated against the glossary.** Gate 12 validates the JSON `vocabulary` and the numeric
   counts in README/CHANGELOG, but it does **not** verify that the human-readable *selector tables*
   (in `glossary/SKILL.md`, `audit/SKILL.md`, `README.md`) enumerate every track and aspect — so they
   can silently drift. Exploration also found stale **`risk-scanner`** references still in three worker
   bodies (the orchestrator was renamed to `oop-orchestrator`); no gate catches retired-name strings
   (only file absence).

This plan closes **both**: makes L3 directly callable (workers self-resolve from an id) with a
documented "Direct layer access" path, and adds gating that prevents selector-table and retired-name
drift.

## Goal
Make Layer 3 directly callable (the "bypass") with a documented direct-access path, and gate the
selector docs + retired-name drift so nothing silently rots.

## Marker-string contract (coordinated across phases)

So the doc/worker edits and the new gate agree on what to grep for:
- Each worker gets a `## Standalone invocation` section (the gate greps that exact heading).
- `audit/SKILL.md` and `glossary/SKILL.md` each get a `## Direct layer access` section (gate greps it).
- Retired-name scan targets **functional components only** (`skills/ commands/ agents/`, excluding docs
  and `*.json`), matching: the literal token `risk-scanner` (safe — does not match the `risk-scan`
  aspect or the `pattern-scanner` worker) and the slash-prefixed retired commands `/oop-excellence`,
  `/risk-report`, `/pattern-suggest`, `/pattern-detect` (slash-prefixed so they don't match the
  `pattern-suggester`/`pattern-scanner` worker names).

All five workers already have `Read` in `tools`, so self-resolving from `glossary.json` needs **no
tools change**.

## Implementation checkboxes

### Phase 1 — Workers become standalone (the L3 bypass core)
Each worker keeps its existing orchestrator-driven behavior; we ADD a fallback and FIX a stale name.
For each, in its "What the orchestrator injects" section: (a) replace any `risk-scanner` reference
with `oop-orchestrator`; (b) add a `## Standalone invocation` section stating that **if no entity
record is injected, the worker reads `skills/glossary/glossary.json` and self-resolves the record by
the `id` it was given** (then proceeds identically). No `tools` change (all five already have `Read`).
- [x] `agents/entity-detector.md` — fix `risk-scanner`→`oop-orchestrator`; add `## Standalone invocation`.
- [x] `agents/pattern-scanner.md` — same.
- [x] `agents/pattern-suggester.md` — same.
- [x] `agents/entity-fixer.md` — add `## Standalone invocation` (self-resolve by id); fix any stale name.
- [x] `agents/pattern-implementer.md` — add `## Standalone invocation` (self-resolve by id); fix any stale name.

### Phase 2 — Document direct layer access
- [x] Add a `## Direct layer access` section to `skills/audit/SKILL.md`: how to reach **L1** (`/audit`),
      **L2** (`/audit risks|patterns|pattern-scan|pattern-fit`), and **L3** (`/audit <family>|<entity-id>`
      for users; an agent may dispatch a single worker directly via the Task tool with just an id,
      which the worker self-resolves). State the orchestrator is skippable for single-entity work.
- [x] Add a matching `## Direct layer access` section to `skills/glossary/SKILL.md` tying the selector
      table to the three layers and noting workers are independently callable by id.

### Phase 3 — Gate the drift
- [x] Extend `tests/gates/12-glossary-conformance.sh` with a **retired-name content scan**: assert no
      file under `skills/`, `commands/`, `agents/` contains the literal `risk-scanner` or the
      slash-prefixed retired commands `/oop-excellence`, `/risk-report`, `/pattern-suggest`,
      `/pattern-detect` (do NOT match the `risk-scan` aspect, `pattern-scanner`/`pattern-suggester`
      workers — use the exact patterns from the marker-string contract). Keep all existing checks. Must
      pass shellcheck.
- [x] Add `tests/gates/13-layer-access-conformance.sh` (auto-discovered by `run-all.sh`'s
      `[0-9][0-9]-*.sh` glob): assert (a) every `vocabulary.tracks` + `vocabulary.aspects` value from
      `glossary.json` appears in the `glossary/SKILL.md` Selectors table AND the `audit/SKILL.md`
      selector grammar AND `README.md`; (b) a `## Direct layer access` section exists in both
      `skills/audit/SKILL.md` and `skills/glossary/SKILL.md`; (c) each of the five workers contains a
      `## Standalone invocation` section. `set -euo pipefail`, source `lib.sh`, executable, passes
      shellcheck, clear FAIL messages + final ok line.

### Phase 4 — Docs, manifest, verify
- [x] Update `README.md`: add a short "Direct layer access" note (every layer callable; workers run
      standalone by id) consistent with the new doc sections. Keep the "45 issues / 57 design patterns"
      phrasing (gate 12).
- [x] Update `CHANGELOG.md` (the `0.1.0` entry covers the direct-layer bypass + standalone workers +
      selector/retired-name gating); set `.claude-plugin/plugin.json` to `0.1.0`; refresh plugin.json /
      marketplace.json descriptions if warranted; update `CLAUDE.md` if the component story changed.
- [x] Verify: `claude plugin validate . --strict` passes; `bash tests/gates/run-all.sh` green incl. the
      new gate 13 and extended gate 12 (and gate 09 sees `v0.1.0`).
- [x] Manual TS + Python smoke (fixtures OUTSIDE the repo): dispatch a single worker **standalone** —
      give `entity-detector` only `god-class` + a path with **no injected record** and confirm it
      self-resolves from the glossary and detects; confirm `/audit god-class` (user L3) still works; spot
      the `## Direct layer access` docs read accurately for both languages.

## Verification summary
Done when: any single worker runs standalone from just an id (L3 bypass) and that path is documented in
`## Direct layer access`; the selector tables in `glossary/SKILL.md` / `audit/SKILL.md` / `README.md`
are gated to match `vocabulary` (no drift); no functional component references a retired name
(`risk-scanner` or the retired commands); `plugin validate --strict` and the full gate suite (incl.
new gate 13 + extended 12) pass; docs/manifest reflect `0.1.0`.
