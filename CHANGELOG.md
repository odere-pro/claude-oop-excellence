# Changelog

All notable changes to this plugin are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version here MUST match
`version` in `.claude-plugin/plugin.json` (the version of record).

## [Unreleased]

## [0.3.0] - 2026-05-27

### Added

- A single read-only front door, `/audit`, that runs **both** analysis tracks (RISK +
  PATTERN) in parallel and merges them into one unified report. Every layer — track,
  aspect, family, and individual entity — is also individually callable through the
  `/audit` selector.
- The PATTERN track now has two aspects: **scan** (find existing patterns, via the new
  `pattern-scanner` worker) and **fit** (suggest patterns that would help, via
  `pattern-suggester`).
- A `vocabulary.tracks` + `vocabulary.aspects` selector registry in the glossary so the
  `/audit` selector can resolve any track / aspect / family / entity target; gate 12
  extended to enforce it.

### Changed

- Renamed the `risk-scanner` orchestrator to `oop-orchestrator` and gave it an `analyze`
  super-mode that drives both tracks. It now closes the audit → action handoff: the
  unified report's **Recommended Actions** emit the gated `/fix-risks` and
  `/implement-patterns` commands.
- The glossary's 102 entities — 45 issues and 57 design patterns — are unchanged; this
  release reworks orchestration and the front door only.

### Removed

- Retired the `/oop-excellence`, `/risk-report`, and `/pattern-suggest` commands and the
  `pattern-detect` skill; all analysis is folded into `/audit`.
- Relocated the patterns catalog docs (`PATTERNS.md`, `PATTERN-EXAMPLES.md`,
  `PATTERN-REFERENCE.md`) under `skills/glossary/`.

## [0.2.0] - 2026-05-27

### Added

- Canonical plugin glossary (`skills/glossary/glossary.json` + a lookup `SKILL.md`) as the
  single source of truth for every entity and the shared vocabulary (categories, families,
  severity weights, score bands, scopes, principles). The glossary holds **102 entities —
  45 issues and 57 design patterns**.
- Four generic, glossary-driven workers under `agents/`: `entity-detector` (validate one
  entity, read-only), `entity-fixer` (fix one entity + run the project's own tests),
  `pattern-suggester` (evaluate one pattern, read-only), and `pattern-implementer`
  (implement one pattern via a safe sequence + tests). One subagent instance runs per
  entity, fanned out in parallel.
- Entity-selectable verb grammar across the entry skills — validate (`audit`),
  fix (`improve`), suggest (`pattern-detect`), implement (`pattern-implement`) — each
  selectable by entity id, family, or all, with a scope (full / changed / component).
- Strict glossary-conformance CI gate (gate 12) that enforces the glossary as the source
  of truth and keeps the workers and vocabulary in sync.

### Changed

- Rebuilt the architecture around the glossary. All issue and design-pattern knowledge
  (signs, severities, principles, corrective patterns) now lives in the glossary rather
  than in per-scanner catalogs.
- Reframed `risk-scanner` from a fixed eight-scanner fan-out into an orchestrator that
  selects in-scope entities from the glossary and dispatches the generic workers in
  parallel, batched by family, then dedupes, scores, and correlates into a unified report.
- Universality is now expressed as principles (SOLID, encapsulation, cohesion/coupling,
  Law of Demeter, DRY/KISS/YAGNI, composition-over-inheritance, tell-don't-ask) plus
  language-neutral signs — no per-language extension globs or type-checker matrix.
  Fix and implement run the project's own detected test / typecheck / lint command.

### Removed

- Retired the eight hardcoded `risk-antipattern-*-scanner` agents (code, architecture,
  OOP, testing, concurrency, database, security, dependency); their knowledge migrated
  into the glossary.

## [0.1.0] - 2026-05-27

### Added

- Initial release of `claude-oop-excellence`: a language- and framework-agnostic
  object-oriented design enforcement plugin.
- `/oop-excellence` — the pipeline entry point (routes to scan / report / patterns / fix).
- Skills: `audit` (single scan entry, delegates to the orchestrator), `pattern-detect`,
  and the user-invoked-only `improve` and `pattern-implement`.
- Report commands writing timestamped Markdown to `tmp/`: `/risk-report`, `/pattern-suggest`.
- Fix commands (user-invoked only): `/fix-risks`, `/implement-patterns`.
- Nine scanner subagents — the `risk-scanner` orchestrator plus eight read-only,
  least-privilege leaf scanners (code, architecture, OOP, testing, concurrency,
  database, security, dependency), each carrying its own language-agnostic antipattern
  catalog.
- Author CI gate suite under `tests/gates/` (JSON parse, strict validate, frontmatter
  descriptions, no absolute paths, secret scan, explicit agent tools, side-effect gating,
  no remote calls, changelog-version, shellcheck, calibration-conformance).
- `plan.md` tracking the cross-language universality audit.
