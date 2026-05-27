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

A Claude Code plugin that **enforces good object-oriented design in any programming
language** — no framework, stack, or paradigm lock-in. Its spine is OOP quality:
it hunts God Classes, Anemic Domain Models, Feature Envy, and the rest, then
refactors toward proper design using GoF patterns (Strategy, Facade, Decorator…).

Around that spine it bundles a complete **detect → report → fix** pipeline —
antipattern and code-smell scanners (code, architecture, OOP, testing, concurrency,
database, security, dependency), design-pattern detection, unified risk reports,
and guided, test-verified fixes. The OOP domain is treated as first-class
throughout: it is mandatory in audits and fixed before other domains.

## The pipeline

```
        DETECT                    REPORT (writes tmp/)            FIX (reads tmp/)
  ┌──────────────────┐        ┌──────────────────────┐      ┌────────────────────┐
  │ /audit           │        │ /risk-report          │      │ /fix-risks          │
  │ /risk-antipattern│ ─────▶ │ /smell-report         │ ───▶ │ /implement-patterns │
  │ -scan /risk-scan │        │ /pattern-suggest      │      │                     │
  │ /pattern-detect  │        └──────────────────────┘      └────────────────────┘
  │ /detect-*        │           saves a timestamped            re-reads the saved
  └──────────────────┘           report under tmp/              report, applies fixes
```

The report phase writes a timestamped markdown file under `tmp/`; the fix phase
discovers that file and works through the findings domain by domain. This hand-off
lets you review findings before anything is changed.

## Phases

### 1. Detect

| Command / skill | What it does |
| --- | --- |
| `/audit [domains]` | Full multi-domain quality scan → one unified severity-ranked report |
| `/risk-antipattern-scan` | Dispatches the 8 specialized scanner agents (parallel or sequential) |
| `/risk-scan [domain] [scope]` | Risk assessment via dynamic scanner discovery; selective by domain/scope |
| `/pattern-detect [detect\|audit] [path]` | Detects existing design patterns and recommends new ones |
| `/detect-code-antipatterns` | God Object, Spaghetti, Lava Flow, Copy-Paste, Magic Numbers, Circular Deps… |
| `/detect-architecture-antipatterns` | Big Ball of Mud, Vendor Lock-In, Reinventing the Wheel, Stovepipe… |
| `/detect-oop-antipatterns` | Anemic Domain Model, God Class, Yo-Yo, Refused Bequest, Feature Envy… |
| `/detect-testing-antipatterns` | Ice Cream Cone, Flaky Tests, Implementation-detail tests, Slow Tests |
| `/detect-concurrency-antipatterns` | Race Conditions, Deadlocks, Busy Waiting, Thread Starvation |
| `/detect-database-antipatterns` | God Table, Inner-Platform Effect, EAV Abuse, N+1 Query |

### 2. Report (writes to `tmp/`)

| Command | Output |
| --- | --- |
| `/risk-report` | `tmp/risk-report-{timestamp}.md` — full 8-domain risk assessment |
| `/smell-report` | `tmp/smell-report-{timestamp}.md` — unified code-smell audit |
| `/pattern-suggest` | `tmp/pattern-recommendations-{timestamp}.md` — design-pattern opportunities |

### 3. Fix (reads from `tmp/`)

| Command | What it does |
| --- | --- |
| `/fix-risks` | Reads the risk/smell reports, fixes domain by domain via `/improve` |
| `/implement-patterns` | Reads the pattern report, applies top-priority patterns via `/pattern-implement` |

Supporting fix skills: `/improve <domain>` (detect → plan → confirm → apply →
verify for one domain) and `/pattern-implement [plan\|apply] <pattern> [path]`.

## Scanner agents

Ten agents back the scan commands. Two orchestrators —
`risk-antipattern-scanner` (fixed 8-domain dispatch) and `risk-scanner`
(dynamic discovery + cross-domain correlation) — coordinate eight leaf scanners:
code, architecture, OOP, testing, concurrency, database, security, and dependency.

## Meta: building plugins (`/build-plugin`)

The plugin also ships a **goal skill**, `/build-plugin`, that builds *other* Claude
Code plugins step by step. Give it a goal and it decomposes the work into phases,
dispatches each unit to a **fresh-context subagent**, and persists all state to disk
between runs — so context never accumulates and independent units run as **multiple
subagents in parallel**. This is the same clean-context, disk-handoff pattern the
detect → report → fix pipeline uses, generalized. The step-by-step build reference
lives in `skills/build-plugin/PLAYBOOK.md`.

## Install

From the bundled single-plugin marketplace:

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

Once installed, every command and skill above is available by name.

## Extending

`risk-scanner` auto-discovers any agent named `risk-*-scanner`, so you can drop in
new domain scanners without touching the orchestrator. Documented extension points
not yet shipped here: `risk-complexity-scanner`, `risk-configuration-scanner`,
`risk-documentation-scanner`, `risk-error-handling-scanner`, and
`risk-type-safety-scanner`.

## Notes

- The report → fix hand-off uses `tmp/` at the repository root. Reports are plain
  markdown; review them before running a fix command.
- The fix skills detect the project's package manager and test/typecheck/lint
  scripts (npm / pnpm / yarn / bun) and verify each change before moving on.
- Type-safety checks run only when a `tsconfig.json` is present.
