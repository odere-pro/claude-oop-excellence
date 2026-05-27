---
name: glossary
description: >-
  Use to look up the canonical name, category, family, principle, signs, and severity of any code
  smell, antipattern, vulnerability, supply-chain risk, or design pattern this plugin recognizes.
  Read-only reference: resolve an entity by id, list every entity in a family or category, or check
  which corrective patterns fix an issue (or which issues a pattern resolves). Language-agnostic;
  signs are language-neutral descriptions, never regex.
user-invocable: true
---

# Plugin Glossary

The canonical vocabulary for `claude-oop-excellence`. The sibling file `glossary.json` (in this same
skill directory) is the **single source of truth** for every entity the plugin recognizes — code
smells, antipatterns, vulnerabilities, supply-chain risks, and design patterns — plus the shared
vocabulary every other skill and scanner reads at runtime. When you need the authoritative record for
an entity, read `glossary.json` and return what it says verbatim. Do not invent fields or values.

## Structure

`glossary.json` has two top-level keys.

### `vocabulary`

Shared, enumerable terms used across the plugin:

- `categories` — `code-smell`, `antipattern`, `vulnerability`, `supply-chain-risk`, `design-pattern`.
- `families` — issue families (`oop`, `code`, `architecture`, `testing`, `concurrency`, `database`,
  `security`, `dependency`) and pattern families (`creational`, `structural`, `behavioral`,
  `architectural`, `enterprise`, `functional`, `ddd`).
- `severity_weights` — numeric weight per severity (`critical` 10, `high` 5, `medium` 2, `low` 1).
- `score_bands` — `clean`, `low`, `moderate`, `high`, `critical` thresholds for an aggregate score.
- `scopes` — `full`, `changed`, `component`.
- `confidence` — the `0-100` range scanners report.
- `principles` — the design principles entities reference (e.g. `srp`, `ocp`, `lsp`, `isp`, `dip`,
  `encapsulation`, `high-cohesion`, `low-coupling`, `law-of-demeter`, `dry`, `kiss`, `yagni`,
  `composition-over-inheritance`, `tell-dont-ask`).
- `tracks` — the two top-level audit tracks: `risk` (find issues) and `pattern` (work with design
  patterns).
- `aspects` — the work an audit can do within a track: `risk-scan` (detect issues), `pattern-scan`
  (detect design patterns already present), `pattern-fit` (suggest the most-suitable patterns).

### `entities`

An array of entity records. Each record has:

- `id` — stable kebab-case identifier (e.g. `god-class`). Use this to select an entity.
- `name` — human-readable name (e.g. `God Class`).
- `category` — one of the `vocabulary.categories`.
- `family` — one of the `vocabulary.families`.
- `principles` — for issues, the principles the entity **violates**; for design patterns, the
  principles it **upholds**.
- `signs` — language-neutral descriptions of what to look for. Plain English, never regex.
- `default_severity` — `critical` / `high` / `medium` / `low` (issues only).
- `applies_when` — the precondition for the entity to be in scope (e.g. "any class/struct/interface
  declarations present").
- `corrective_patterns` — (issues only) ids of design patterns that fix this issue.
- `resolves` — (design patterns only) ids of the issues this pattern fixes.

Issue entities carry `corrective_patterns`; design-pattern entities carry `resolves`.

## Looking things up

- **By id** — find the single record in `entities` whose `id` matches (e.g. `feature-envy`).
- **By family** — filter `entities` to a `family` (e.g. all `oop` issues, or all `creational`
  patterns).
- **By category** — filter `entities` to a `category` (e.g. every `vulnerability`).
- **Cross-references** — follow an issue's `corrective_patterns` to the patterns that fix it, or a
  pattern's `resolves` to the issues it addresses; both are arrays of entity ids.

Return the canonical fields as-is. This skill never modifies code or the glossary.

## Selectors

The plugin has a single front door — `/audit` — that zooms across three layers: **track** →
**aspect** → **family / category / entity**. A selector is the argument that tells `/audit` how far
to zoom. Each selector resolves to exactly one row below.

| Selector                                                            | Resolves to                  | Meaning                                                                                                            |
| ------------------------------------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `risks`                                                             | RISK track                   | Every issue family: `oop`, `code`, `architecture`, `testing`, `concurrency`, `database`, `security`, `dependency` |
| `patterns`                                                         | PATTERN track                | Both pattern aspects together: `pattern-scan` + `pattern-fit`                                                      |
| `risk-scan`                                                        | aspect (risk track)          | The issue-detection aspect of the risk track                                                                      |
| `pattern-scan`                                                     | aspect (pattern track)       | Detect design patterns **already present** in the code                                                            |
| `pattern-fit`                                                      | aspect (pattern track)       | Suggest the **most-suitable** design patterns for the code                                                        |
| `<category>` (`vulnerability`, `antipattern`, `code-smell`, `supply-chain-risk`, `design-pattern`) | entities of that category    | Filter `entities` to the matching `category`                                                                      |
| `<family>` (e.g. `oop`, `behavioral`)                              | entities of that family      | Filter `entities` to the matching `family`                                                                        |
| `<entity-id>` (e.g. `god-class`, `strategy`)                       | a single entity              | The one record in `entities` whose `id` matches                                                                   |
| `all` / none                                                       | full run                     | Both tracks (`risk` + `pattern`)                                                                                  |

`tracks` and `aspects` come from `vocabulary`; `categories`, `families`, and entity `id`s are the
same values used everywhere else in this glossary. A selector always resolves down through the
layers — choosing a track implies its aspects, an aspect implies its families, and so on.

## Direct layer access

The selector table above maps onto three layers, each independently reachable from the `/audit` front
door:

- **L1** — the full run: `/audit` with no selector covers **both** tracks.
- **L2** — a single track or aspect: the `tracks` (`risk`, `pattern`) and `aspects` (`risk-scan`,
  `pattern-scan`, `pattern-fit`) values registered in `vocabulary`.
- **L3** — a single family, category, or `<entity-id>`.

So `tracks` + `aspects` are the canonical L1/L2 selectors, while `families`, `categories`, and entity
`id`s are the L3 selectors — every value resolves through this glossary.

Beyond the `/audit` front door, the five L3 workers — `entity-detector`, `pattern-scanner`,
`pattern-suggester`, `entity-fixer`, and `pattern-implementer` — are **independently callable by
id**. Dispatched directly with just an entity id (no orchestrator, no injected record), each reads
this glossary, self-resolves the matching record, and runs identically to its orchestrator-driven
path (see each worker's `## Standalone invocation` section). The glossary is the resolution point for
every layer.
