# claude-oop-excellence — plugin development

> Author/dev project memory for this repository. **Not shipped context**: a plugin's root `CLAUDE.md`
> is never loaded into an end user's session. It serves the people (and agents) developing the
> plugin. To ship instructions into a user's context, put them in a **skill**.

This repo is the source for the `claude-oop-excellence` Claude Code plugin. Every recognized component
directory under here ships to users when the plugin is installed.

## What ships

- `.claude-plugin/plugin.json` — the manifest (version of record)

This repo no longer ships its own `marketplace.json`. Distribution is via the external
[`odere-pro`](https://github.com/odere-pro/claude-software-3-0-marketplace) aggregator marketplace,
which lists this plugin by `github` source — install with `claude-oop-excellence@odere-pro`.
- `skills/glossary/` — the canonical glossary (`glossary.json`, single source of truth for all 102
  entities + shared vocabulary including the `vocabulary.tracks` / `vocabulary.aspects` selector
  registry) and its lookup `SKILL.md`, plus the relocated patterns catalog docs (`PATTERNS.md`,
  `PATTERN-EXAMPLES.md`, `PATTERN-REFERENCE.md`)
- `skills/` — `audit` (the single read-only front door; runs both the RISK and PATTERN tracks in
  parallel into one unified report, every track / aspect / family / entity individually selectable),
  `onboarding` (read-only in-session orientation — the "how to use this plugin" guide; model-invocable
  like `audit`/`glossary`), and the side-effecting `improve` and `pattern-implement` (both
  `disable-model-invocation: true`)
- `commands/` — flat `.md` skills: the report command(s) and the fix commands (`fix-risks`,
  `implement-patterns`, both `disable-model-invocation: true`). The `/oop-excellence`, `/risk-report`,
  and `/pattern-suggest` commands are retired — analysis is folded into `/audit`.
- `agents/` — an `oop-orchestrator` (formerly `risk-scanner`) with an `analyze` super-mode that
  drives both tracks, plus five generic glossary-driven workers (`entity-detector`, `entity-fixer`,
  `pattern-scanner`, `pattern-suggester`, `pattern-implementer`), least-privilege `tools`. The
  orchestrator selects in-scope entities from the glossary and fans the **read** workers out **per
  family** in parallel (each reads the scope once and checks its whole family; a full audit ≈ 15 family
  workers, not ~159 per-entity ones — the pattern track uses one `pattern-scanner` per family with lens
  `both`, folding scan + fit into one read). The **action** workers (`entity-fixer`,
  `pattern-implementer`) stay **per-entity** for change isolation. Workers are **hybrid**: a single
  entity id/record or a whole family batch. It closes the audit → action handoff (Recommended Actions
  emit the gated `/fix-risks` / `/implement-patterns`). The `pattern-detect` skill and the eight hardcoded
  `risk-antipattern-*-scanner` leaf agents are retired — their knowledge now lives in the glossary.

This plugin ships no `hooks/` and no `.mcp.json` — it has no event hooks and no MCP server.

## What doesn't ship (author-only — copied to the cache but never loaded)

- `.claude/` — this repo's own project config (house rules, dev skills/agents)
- `CLAUDE.md` (this file) — dev-repo memory, not user context
- `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE` — docs
- `SECURITY.md`, `CODE_OF_CONDUCT.md`, `SUPPORT.md` — governance docs (fill the `REPLACE-ME`s)
- `docs/` — deep-dive user docs (`ARCHITECTURE.md`, `EXTENDING.md`, `LANGUAGE-COVERAGE.md`) plus
  governance (`RELEASING.md`, `openssf-badge.md`); linked from README, not loaded into user context
- `.github/` — CI/Scorecard/CodeQL/release workflows, Dependabot, CODEOWNERS (Scorecard & CodeQL are
  dormant until the repo is public — see the cookbook's `14-supply-chain-and-governance`)
- `.editorconfig`, `.gitattributes`, `.gitignore`, `.markdownlint*.jsonc`, `.prettierrc` — repo config
- `tests/gates/` — the CI gate suite (`bash tests/gates/run-all.sh`); validates the plugin, never ships

## Source layout

| Path                   | Role                         | Ships? |
| ---------------------- | ---------------------------- | ------ |
| `.claude-plugin/`      | plugin manifest              | yes    |
| `skills/`, `commands/` | user/Claude-invokable skills | yes    |
| `agents/`              | worker subagents             | yes    |
| `.claude/`             | dev-repo project config      | no     |
| `tests/gates/`         | author-only CI gate suite    | no     |

## Agents

| Agent | Role |
| --- | --- |
| `oop-orchestrator` | Orchestrator — resolves the selection across both tracks and fans out workers, in parallel, into one unified report |
| `entity-detector` | Detect one issue entity (read-only) |
| `pattern-scanner` | Detect one design pattern already present (read-only) |
| `pattern-suggester` | Evaluate fit for one design pattern (read-only) |
| `entity-fixer` | Fix one issue entity, verified with the project's own detected commands |
| `pattern-implementer` | Implement one pattern via a safe parallel-change sequence + tests |

## House rules

See [`.claude/rules/plugin-dev.md`](.claude/rules/plugin-dev.md) (path-scoped; loads when you edit
components).

## Verify before release

```bash
claude plugin validate . --strict      # manifest + component frontmatter
bash tests/gates/run-all.sh            # the full author gate suite
claude --plugin-dir .                   # load against this repo, then /reload-plugins
```
