# Changelog

All notable changes to this plugin are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version here MUST match
`version` in `.claude-plugin/plugin.json` (the version of record).

## [Unreleased]

## [0.1.0] - 2026-05-27

Initial release of `claude-oop-excellence`: a language- and framework-agnostic
object-oriented design enforcement plugin.

### Glossary (single source of truth)

- A canonical glossary — `skills/glossary/glossary.json` plus a lookup `SKILL.md` — is the
  single source of truth for every entity the plugin recognizes and for the shared
  vocabulary (categories, families, severity weights, score bands, scopes, principles, and
  the `vocabulary.tracks` / `vocabulary.aspects` selector registry) that every skill and
  agent reads at runtime. It defines **102 entities: 45 issues** (code smells, antipatterns,
  vulnerabilities, supply-chain risks) and **57 design patterns**. The patterns catalog docs
  (`PATTERNS.md`, `PATTERN-EXAMPLES.md`, `PATTERN-REFERENCE.md`) live alongside it.
- Universality is expressed as **principles, not a per-language matrix**: SOLID,
  encapsulation, cohesion/coupling, Law of Demeter, DRY/KISS/YAGNI,
  composition-over-inheritance, and tell-don't-ask, plus language-neutral signs per entity.
  There are no extension globs and no per-language type-checker baked into the architecture.

### Analyze — one read-only front door

- `/audit` is the single read-only entry point. With no selector it runs **both** analysis
  tracks (RISK + PATTERN) in parallel and merges them into ONE unified report. Every layer —
  **track → aspect → family / category / entity** — is individually callable through the
  same `/audit` selector, with an optional scope (`full` / `changed` / `component <path>`).
- The PATTERN track has two aspects: **scan** (patterns already present, via `pattern-scanner`)
  and **fit** (most-suitable suggestions, via `pattern-suggester`).
- **Direct layer access (the L3 bypass).** Every layer is reachable on its own. For
  single-entity work the orchestrator is skippable: each of the five workers can be
  dispatched directly with only an entity **id** and self-resolves its full record from the
  glossary (a `## Standalone invocation` section in every worker), running identically to its
  orchestrator-driven path. `skills/audit/SKILL.md` and `skills/glossary/SKILL.md` document
  the L1 → L2 → L3 entry points.

### Act — gated, user-invoked

- The unified report ends with a **Recommended Actions** handoff that prints the exact gated
  commands to run next, scoped to the real findings: `/fix-risks <selector> [scope]` and
  `/implement-patterns <selector> [scope]`. Both are `disable-model-invocation` (user-invoked
  only) and verify each change with the project's **own detected** test/typecheck/lint
  command — Claude never refactors on its own.

### Agents

- An `oop-orchestrator` resolves the caller's selection across both tracks, applies each
  entity's `applies_when` smart-dispatch check, and fans out **one generic worker instance
  per in-scope entity** in parallel, batched by family, then dedupes, scores, and correlates
  into the unified report.
- Five generic, glossary-driven workers: `entity-detector` and `pattern-scanner` /
  `pattern-suggester` (read-only), and `entity-fixer` / `pattern-implementer` (side-effecting,
  test-verified). Each worker has least-privilege `tools`.

### Tooling

- Author CI gate suite under `tests/gates/` (`bash tests/gates/run-all.sh`): JSON parse,
  strict `claude plugin validate`, frontmatter descriptions, no absolute paths, secret scan,
  explicit agent tools, side-effect gating, no remote calls, changelog-version, shellcheck,
  calibration-conformance, glossary-conformance (gate 12, with a retired-name scan), and
  layer-access-conformance (gate 13).
