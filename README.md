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

Start at the front door — **`/oop-excellence`** — or call any phase directly:

```
                          /oop-excellence  (entry point)
                                  │
        DETECT                    REPORT (writes tmp/)         FIX (reads tmp/, gated)
  ┌──────────────────┐      ┌──────────────────────┐      ┌─────────────────────┐
  │ /audit           │ ───▶ │ /risk-report          │ ───▶ │ /fix-risks          │
  │ /pattern-detect  │      │ /pattern-suggest      │      │ /implement-patterns │
  └──────────────────┘      └──────────────────────┘      └─────────────────────┘
       runs the scanners        saves a timestamped            re-reads the saved
       (OOP always covered)     report under tmp/              report, applies fixes
```

The report phase writes a timestamped markdown file under `tmp/`; the fix phase
discovers that file and works through the findings domain by domain. This hand-off
lets you review findings before anything is changed. The fix commands are
**user-invoked only** (`disable-model-invocation`) — Claude never refactors on its own.

## Phases

### 1. Detect

| Command / skill | What it does |
| --- | --- |
| `/oop-excellence [scan\|report\|patterns\|fix]` | Front door — routes to any phase; defaults to a full audit + next-step menu |
| `/audit [domains] [scope]` | Full multi-domain scan via the `risk-scanner` orchestrator → one unified severity-ranked report. Covers code, architecture, OOP, testing, concurrency, database, security, dependency |
| `/pattern-detect [detect\|audit] [path]` | Detects existing design patterns and recommends new ones |

The eight antipattern domains (God Object/Spaghetti/Lava Flow; Big Ball of Mud/Stovepipe; Anemic
Domain Model/God Class/Feature Envy; Ice Cream Cone/Flaky Tests; Race Conditions/Deadlocks; God
Table/N+1; injection/secrets; dependency hygiene) live in the scanner agents below — `/audit`
dispatches them, so there is one scan entry point rather than a skill per domain.

### 2. Report (writes to `tmp/`)

| Command | Output |
| --- | --- |
| `/risk-report` | `tmp/risk-report-{timestamp}.md` — full 8-domain risk assessment |
| `/pattern-suggest` | `tmp/pattern-recommendations-{timestamp}.md` — design-pattern opportunities |

### 3. Fix (reads from `tmp/`)

| Command | What it does |
| --- | --- |
| `/fix-risks` | Reads the saved risk report, fixes domain by domain via `/improve` (OOP first) |
| `/implement-patterns` | Reads the pattern report, applies top-priority patterns via `/pattern-implement` |

Supporting fix skills (both user-invoked only): `/improve <domain>` (detect → plan → confirm →
apply → verify for one domain) and `/pattern-implement [plan\|apply] <pattern> [path]`.

## Scanner agents

Nine agents back the scan. One orchestrator — `risk-scanner` — coordinates eight leaf scanners
(code, architecture, OOP, testing, concurrency, database, security, dependency), each a focused,
read-only, least-privilege specialist. `/audit` delegates to the orchestrator; the orchestrator
fans out to the applicable leaf scanners in parallel, deduplicates, scores, and correlates.

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

To add a domain scanner: write a new `agents/risk-antipattern-<domain>-scanner.md` (read-only,
least-privilege `tools`) and register it in the `risk-scanner` orchestrator's roster table and
`tools` allow-list. Candidate domains not yet shipped: complexity, configuration, documentation,
error-handling, type-safety.

## Language coverage

The detection knowledge is language-agnostic and the scanners detect the stack rather than assume
one. Known stack-specific edges (and the plan to close them) are tracked in [`plan.md`](plan.md) —
notably that the `types` domain currently uses `tsc` and the source globs do not yet span every
target language.

## Notes

- The report → fix hand-off uses `tmp/` at the repository root. Reports are plain
  markdown; review them before running a fix command.
- The fix skills detect the project's package manager and test/typecheck/lint
  scripts (npm / pnpm / yarn / bun) and verify each change before moving on.
- Type-safety checks run only when a `tsconfig.json` is present (see `plan.md`).
