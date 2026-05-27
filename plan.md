# Plan — `claude-oop-excellence`: a 3-layer, single-front-door flow

> **Implementation contract.** The goal skill executes the checkboxes below — **one checkbox per
> agent, in a fresh context**. Each agent reads **only** this file plus the source files its checkbox
> names. On completion: make the edits, flip the box to `[x]`, stop. Phases are ordered (a later phase
> may reference what an earlier one created); checkboxes within a phase are independent unless noted.
> Run the gate suite only in Phase 6. **Quit condition: every checkbox below is `[x]`.**

## Context

The plugin previously exposed **four separate single-mode verbs** (`validate` / `suggest` / `fix` /
`implement`), each its own command, each running one mode per invocation — with **no single command
that analyzes patterns and risks together** and only implicit layering. This rebuild collapses the
analysis side to **one read-only front door, `/audit`**, that fans out **two analysis tracks in
parallel** (RISK + PATTERN), makes **every layer and aspect independently callable**, and layers the
**action side (fix/implement)** the same way with an **audit→action handoff**. Goal: extreme
simplicity + flexibility, on top of the existing glossary single-source-of-truth.

## Target architecture (3 layers)

```
L1  /audit  ──────────── single READ-ONLY front door (skill: skills/audit/SKILL.md)
                          no selector → full run: BOTH tracks dispatched in parallel,
                          merged into ONE unified report ending in a gated-action handoff
                              │ delegates to
L2  oop-orchestrator  ──── the orchestrator (agents/oop-orchestrator.md, ex-risk-scanner)
       RISK track          issues:   antipatterns · code smells · vulnerabilities · supply-chain
       PATTERN track       patterns: scan (already present) + fit (most-suitable suggestions)
       (+ action modes:    fix · implement — parallel fan-out, batched by family)
                              │ one instance PER ENTITY, in parallel, batched by family
L3  workers (agents/) ──── entity-detector · pattern-scanner(NEW) · pattern-suggester
                            entity-fixer · pattern-implementer        (all individually callable)

           skills/glossary/glossary.json — single source of truth (unchanged: 102 entities)
```

**Every layer is reachable from the one `/audit` selector** (the simplicity/flexibility interface):

| Call                                       | Layer | Meaning                                          |
| ------------------------------------------ | ----- | ------------------------------------------------ |
| `/audit [full\|changed\|component <p>]`    | L1    | full run — RISK + PATTERN tracks **in parallel** |
| `/audit risks`                             | L2    | RISK track only                                  |
| `/audit patterns`                          | L2    | PATTERN track (scan + fit)                        |
| `/audit pattern-scan` / `pattern-fit`      | L2    | one pattern aspect                               |
| `/audit <category>` (e.g. `vulnerability`) | L3    | one issue category                               |
| `/audit <family>` (e.g. `oop`, `behavioral`) | L3  | one family of issues or patterns                 |
| `/audit <entity-id>` (e.g. `god-class`, `strategy`) | L3 | one entity                              |
| `/fix-risks <sel> [scope] [--plan-only]`   | L1 action (gated) | parallel `entity-fixer` fan-out      |
| `/implement-patterns <sel> [scope] [--plan-only]` | L1 action (gated) | parallel `pattern-implementer` fan-out |

`/audit` is read-only and auto-invocable; it **recommends** the exact gated `/fix-risks` /
`/implement-patterns` commands (scoped to its findings) rather than auto-running them (gating
preserved).

### Component inventory

- **NEW:** `agents/pattern-scanner.md` — read-only worker that detects design patterns **already
  present** (full realization) using each pattern's glossary `signs`. Distinct from
  `pattern-suggester` (which finds where a pattern **would help** / partial presence + `resolves`).
- **RENAMED + REFRAMED:** `agents/risk-scanner.md` → `agents/oop-orchestrator.md` — gains an
  `analyze` super-mode that launches the RISK track + PATTERN-scan + PATTERN-fit as **parallel
  tracks** and merges them; adds report sections (Patterns Present, Pattern Opportunities,
  Recommended Actions); keeps `fix`/`implement` modes and all scoring/dedup/correlation; `tools`
  gains `Agent(pattern-scanner)`.
- **REWRITTEN (L1 front door):** `skills/audit/SKILL.md` — the single analysis entry; absorbs the
  pattern-analysis role; selector grammar zooms L1→L2→L3; full run = both tracks in parallel.
- **UPDATED (L1 actions, stay gated):** `skills/improve/SKILL.md`, `skills/pattern-implement/SKILL.md`,
  `commands/fix-risks.md`, `commands/implement-patterns.md` — framed as the action layer reachable
  from the audit handoff (already fan out in parallel; make the 3-layer wiring explicit).
- **RETIRED:** `commands/oop-excellence.md`, `commands/risk-report.md`, `commands/pattern-suggest.md`
  (subsumed by `/audit`); `skills/pattern-detect/SKILL.md` (folded into `/audit`).
  `skills/pattern-detect/PATTERNS.md` relocates to `skills/glossary/PATTERNS.md` (supporting ref;
  glossary stays the canonical registry).
- **KEPT:** `skills/glossary/` (source of truth), the 4 existing workers, gated action skills/commands.
- **GLOSSARY:** add canonical `tracks` + `aspects` selector registry to `vocabulary` (additive,
  gate-safe).

### Gate impact (must stay green)

- **Gate 06 / 11** — `pattern-scanner` must declare explicit `tools:` + pinned `model:`.
- **Gate 07 (side-effect-gating)** — its hardcoded list (`skills/improve`, `skills/pattern-implement`,
  `commands/fix-risks`, `commands/implement-patterns`) is **unchanged** since those files are kept;
  verify no retired file is referenced.
- **Gate 12 (glossary-conformance)** — extend to: validate new `tracks`/`aspects` vocab keys; assert
  retired commands/skill are **absent**; assert the single-front-door + orchestrator-references-all-5-
  workers wiring. README/CHANGELOG counts stay 102 (45 issues + 57 patterns) — unchanged.

## Implementation checkboxes

### Phase 0 — Glossary selector registry
- [x] Add a `tracks` and an `aspects` array to `vocabulary` in `skills/glossary/glossary.json`
      (canonical L2 selectors): `tracks: ["risk","pattern"]`,
      `aspects: ["risk-scan","pattern-scan","pattern-fit"]`. Document the selector→track/aspect/family/
      entity resolution table in `skills/glossary/SKILL.md`. Do not touch existing entities/counts.

### Phase 1 — L3 workers (`agents/`)
- [x] Add `agents/pattern-scanner.md` — generic, glossary-driven, READ-ONLY worker that detects a
      design pattern **already implemented** in scope (uses the injected pattern record's `signs` for
      full-presence detection; reports location + confidence). Explicit `tools: Read, Grep, Glob`;
      pinned `model: sonnet`; trigger-first `description`; no hooks/mcpServers/permissionMode.
- [x] Update `agents/pattern-suggester.md` to disambiguate its role as the **fit** aspect (where a
      pattern *would help*: partial `signs` + `resolves` issues present) vs. `pattern-scanner`'s
      **presence** aspect. Keep tools/model.

### Phase 2 — L2 orchestrator (`agents/`)
- [x] Rename `agents/risk-scanner.md` → `agents/oop-orchestrator.md` and reframe it: (a) add an
      `analyze` super-mode that dispatches the **RISK track** (`entity-detector` per issue) **and**
      the **PATTERN track** (`pattern-scanner` + `pattern-suggester` per pattern) **in parallel**,
      batched by family, then merges into one report; (b) add report sections **Patterns Present**,
      **Pattern Opportunities**, **Recommended Actions** (emits the exact gated `/fix-risks` /
      `/implement-patterns` commands scoped to findings); (c) keep `fix`/`implement` modes and all
      existing scoring/dedup/correlation/report sections; (d) update `tools:` to add
      `Agent(pattern-scanner)` and keep the other four worker `Agent(...)` entries; keep `model: opus`.
      Resolve selections (`risks`|`patterns`|`pattern-scan`|`pattern-fit`|`<category>`|`<family>`|
      `<entity-id>`|`<pattern-id>`|`all`) against the glossary; apply each entity's `applies_when` as
      the skip filter for `all`.

### Phase 3 — L1 entries (`skills/`)
- [x] Rewrite `skills/audit/SKILL.md` as the **single read-only analysis front door**: document the
      full selector grammar (L1→L2→L3 above); delegate to `oop-orchestrator` in `analyze` mode; full
      run = both tracks in parallel; report ends with the gated-action handoff. Absorb the
      pattern-analysis role. Read-only, auto-invocable (no `disable-model-invocation`). Trigger-first
      `description`. Remove all references to retired components.
- [x] Update `skills/improve/SKILL.md` (FIX action) — keep `disable-model-invocation: true`; frame as
      the action layer reachable from the audit handoff; delegate to `oop-orchestrator` fix mode
      (parallel `entity-fixer` fan-out, batched by family); project's own detected commands; rename
      orchestrator reference.
- [x] Update `skills/pattern-implement/SKILL.md` (IMPLEMENT action) — keep
      `disable-model-invocation: true`; frame as action layer from the handoff; delegate to
      `oop-orchestrator` implement mode (parallel `pattern-implementer` fan-out); keep safe 4-step
      sequence; project's own detected commands; rename orchestrator reference.
- [x] Retire `skills/pattern-detect/SKILL.md` (folded into `/audit`); move
      `skills/pattern-detect/PATTERNS.md` → `skills/glossary/PATTERNS.md`; update any references to it.
      (Also relocated the skill's `EXAMPLES.md`/`REFERENCE.md` → `skills/glossary/PATTERN-EXAMPLES.md`
      and `PATTERN-REFERENCE.md` to fully retire the skill dir.)

### Phase 4 — Commands cleanup (`commands/`)
- [x] Delete `commands/oop-excellence.md`, `commands/risk-report.md`, `commands/pattern-suggest.md`
      (subsumed by `/audit`).
- [x] Rewire `commands/fix-risks.md` (KEEP `disable-model-invocation: true`) as the thin gated L1 fix
      front door → `improve` skill / `oop-orchestrator` fix mode; entity-selectable; trigger-first.
- [x] Rewire `commands/implement-patterns.md` (KEEP `disable-model-invocation: true`) as the thin
      gated L1 implement front door → `pattern-implement` skill / `oop-orchestrator` implement mode;
      pattern-selectable; trigger-first.

### Phase 5 — Gates
- [x] Update `tests/gates/12-glossary-conformance.sh`: validate the new `vocabulary.tracks` +
      `vocabulary.aspects` arrays; assert retired files ABSENT
      (`commands/oop-excellence.md`, `commands/risk-report.md`, `commands/pattern-suggest.md`,
      `skills/pattern-detect/SKILL.md`, `agents/risk-scanner.md`); assert wiring
      (`skills/audit/SKILL.md` references `oop-orchestrator`; `oop-orchestrator` references all five
      workers including `pattern-scanner`). Keep the existing entity-count + structural checks (102).
- [x] Verify `tests/gates/07-side-effect-gating.sh` still matches reality (kept gated files) and that
      no gate references a retired path; adjust only if a path it lists changed.

### Phase 6 — Docs + manifest, then verify
- [x] Update `README.md`: the 3-layer model, single `/audit` front door, the selector table, both
      tracks (pattern scan + fit), layered actions + audit→action handoff, the 5 workers + renamed
      orchestrator.
- [x] Update `CHANGELOG.md` + bump `.claude-plugin/plugin.json` version to `0.3.0`; refresh
      plugin.json / marketplace.json descriptions; update `CLAUDE.md` "What ships" (add
      `pattern-scanner`; renamed orchestrator; retired commands/skill; moved PATTERNS.md). Keep the
      "45 issues / 57 design patterns / 102 entities" phrasing for gate 12.
- [x] Verify: `claude plugin validate . --strict` passes; `bash tests/gates/run-all.sh` is green
      (incl. updated 07/12).
- [x] Manual TS + Python smoke (fixtures OUTSIDE the repo): `/audit` (full, both tracks parallel),
      `/audit risks`, `/audit patterns`, `/audit pattern-scan`, `/audit pattern-fit`, `/audit oop`,
      `/audit god-class`, `/audit strategy`; confirm the report's gated-action handoff prints runnable
      `/fix-risks` + `/implement-patterns`; `/fix-risks feature-envy --plan-only`;
      `/implement-patterns plan strategy`; glossary lookup. Confirm each layer is independently
      callable and the flow is language-agnostic.

## Verification summary
Done when: `/audit` is the only analysis entry and runs both tracks in parallel into one unified
report; pattern **scan** and **fit** both exist and are individually callable; every layer
(L1 full / L2 track / L3 family·entity·aspect) is reachable from the `/audit` selector; the gated
actions are layered and reachable via the audit handoff; the retired commands/skill are gone; the
strict gate suite (incl. updated 07/12) and `plugin validate --strict` pass; and `README` / `CHANGELOG`
/ `CLAUDE.md` reflect the 3-layer, single-front-door model.
