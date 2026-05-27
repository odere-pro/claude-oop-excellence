# claude-oop-excellence — plugin development

> Author/dev project memory for this repository. **Not shipped context**: a plugin's root `CLAUDE.md`
> is never loaded into an end user's session. It serves the people (and agents) developing the
> plugin. To ship instructions into a user's context, put them in a **skill**.

This repo is the source for the `claude-oop-excellence` Claude Code plugin. Every recognized component
directory under here ships to users when the plugin is installed.

## What ships

- `.claude-plugin/plugin.json` — the manifest (version of record)
- `.claude-plugin/marketplace.json` — single-plugin marketplace (`source: "./"`); omits `version`
- `skills/` — `<name>/SKILL.md` skills (detect/audit/pattern + the side-effecting `improve` and
  `pattern-implement`, both `disable-model-invocation: true`)
- `commands/` — flat `.md` skills (the report + fix commands; `fix-risks` and `implement-patterns`
  are `disable-model-invocation: true`)
- `agents/` — ten scanner subagents (least-privilege `tools`)

This plugin ships no `hooks/` and no `.mcp.json` — it has no event hooks and no MCP server.

## What doesn't ship (author-only — copied to the cache but never loaded)

- `.claude/` — this repo's own project config (house rules, dev skills/agents)
- `CLAUDE.md` (this file) — dev-repo memory, not user context
- `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE` — docs
- `SECURITY.md`, `CODE_OF_CONDUCT.md`, `SUPPORT.md`, `docs/` — governance docs (fill the `REPLACE-ME`s)
- `.github/` — CI/Scorecard/CodeQL/release workflows, Dependabot, CODEOWNERS (Scorecard & CodeQL are
  dormant until the repo is public — see the cookbook's `14-supply-chain-and-governance`)
- `.editorconfig`, `.gitattributes`, `.gitignore`, `.markdownlint*.jsonc`, `.prettierrc` — repo config
- `tests/gates/` — the CI gate suite (`bash tests/gates/run-all.sh`); validates the plugin, never ships

## Source layout

| Path                   | Role                         | Ships? |
| ---------------------- | ---------------------------- | ------ |
| `.claude-plugin/`      | manifest + marketplace       | yes    |
| `skills/`, `commands/` | user/Claude-invokable skills | yes    |
| `agents/`              | worker subagents             | yes    |
| `.claude/`             | dev-repo project config      | no     |
| `tests/gates/`         | author-only CI gate suite    | no     |

## House rules

See [`.claude/rules/plugin-dev.md`](.claude/rules/plugin-dev.md) (path-scoped; loads when you edit
components).

## Verify before release

```bash
claude plugin validate . --strict      # manifest + component frontmatter
bash tests/gates/run-all.sh            # the full author gate suite
claude --plugin-dir .                   # load against this repo, then /reload-plugins
```
