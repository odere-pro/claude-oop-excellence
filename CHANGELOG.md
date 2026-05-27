# Changelog

All notable changes to this plugin are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version here MUST match
`version` in `.claude-plugin/plugin.json` (the version of record).

## [Unreleased]

## [0.1.0] - 2026-05-27

### Added

- Initial release of `claude-oop-excellence`: a language- and framework-agnostic
  object-oriented design enforcement plugin.
- Detect skills: `detect-code-antipatterns`, `detect-architecture-antipatterns`,
  `detect-oop-antipatterns`, `detect-testing-antipatterns`,
  `detect-concurrency-antipatterns`, `detect-database-antipatterns`, plus `audit`,
  `risk-scan`, `risk-antipattern-scan`, and `pattern-detect`.
- Report commands writing timestamped Markdown to `tmp/`: `/risk-report`,
  `/smell-report`, `/pattern-suggest`.
- Fix skills/commands (user-invoked only): `improve`, `pattern-implement`,
  `/fix-risks`, `/implement-patterns`.
- Ten scanner subagents (two orchestrators + eight leaf scanners) with
  least-privilege tool grants.
- `build-plugin` goal skill for scaffolding new plugins via fresh-context subagents.
