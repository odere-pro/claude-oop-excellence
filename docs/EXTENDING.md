# Extending the plugin

Adding a new entity — a code smell, antipattern, vulnerability, supply-chain risk, or design
pattern — does **not** require writing a new agent or scanner file. The generic workers
(`entity-detector`, `pattern-scanner`, `pattern-suggester`, `entity-fixer`, `pattern-implementer`)
are glossary-driven: they read the entity's record at runtime and act on it. A new record is picked
up automatically — a full audit batches it into its **family** worker, and you can target it directly
with `/audit <your-entity-id>`. No fan-out wiring to touch.

## How to add an entity

1. Open `skills/glossary/glossary.json`.
2. Append a record to the `entities` array.
3. Run the audit again — `/audit <your-entity-id>` — and the generic workers pick it up
   immediately.

## Required fields

| Field | Notes |
| --- | --- |
| `id` | Stable kebab-case identifier (e.g. `god-class`). Used as the selector. |
| `name` | Human-readable name (e.g. `God Class`). |
| `category` | One of `vocabulary.categories` — `code-smell`, `antipattern`, `vulnerability`, `supply-chain-risk`, `design-pattern`. |
| `family` | One of `vocabulary.families` — issue families (`oop`, `code`, `architecture`, `testing`, `concurrency`, `database`, `security`, `dependency`) or pattern families (`creational`, `structural`, `behavioral`, `architectural`, `enterprise`, `functional`, `ddd`). |
| `principles` | The design principles the entity **violates** (issues) or **upholds** (patterns), drawn from `vocabulary.principles` — e.g. `srp`, `ocp`, `encapsulation`, `law-of-demeter`. |
| `signs` | **Language-neutral** descriptions of how to recognize the entity — never regex. The workers read these and apply language judgment per stack. |
| `applies_when` | Precondition for the smart-dispatch check; the orchestrator only fans out a worker for entities whose `applies_when` matches the current scope. |
| `default_severity` | _(issues only)_ One of `critical`, `high`, `medium`, `low`. Drives scoring via `vocabulary.severity_weights`. |
| `corrective_patterns` | _(issues only)_ Cross-references to pattern ids that fix this issue. Surfaces in the report's Recommended Actions. |
| `resolves` | _(patterns only)_ Cross-references to issue ids this pattern resolves. The inverse side of `corrective_patterns`. |

See [`skills/glossary/SKILL.md`](../skills/glossary/SKILL.md) for the full schema reference and the
shared vocabulary every field draws from.

## Validation

The strict **glossary gate** in `tests/gates/` runs on every CI build and rejects any record that
isn't conformant — missing fields, unknown category/family/principle ids, or broken cross-references
(an issue's `corrective_patterns` must resolve, and a pattern's `resolves` must point at real issue
ids). Run the full suite locally with:

```bash
bash tests/gates/run-all.sh
```

## What you do not need to do

- ❌ Write a new agent file in `agents/`.
- ❌ Add the entity to any per-language matrix — there isn't one. See
  [LANGUAGE-COVERAGE.md](LANGUAGE-COVERAGE.md).
- ❌ Wire it into a scanner — the generic workers self-resolve from the glossary on every run.
