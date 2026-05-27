# Changelog

All notable changes to this plugin are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version here MUST match
`version` in `.claude-plugin/plugin.json` (the version of record).

## [Unreleased]

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
