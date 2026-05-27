# Contributing

> REPLACE the project-specific bits; keep the conventions.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `<type>: <subject>`, where `type`
is one of `feat fix docs refactor test chore perf ci build`. Keep each commit to one logical change
so the history reads as a clean, reviewable sequence.

## Before you open a PR

- `claude plugin validate . --strict` exits 0 (manifest + component frontmatter + hooks.json).
- Each component's `description` leads with a concrete trigger; side-effecting skills set
  `disable-model-invocation: true`.
- No absolute machine paths and no secrets in any shipped file; hook scripts are `chmod +x` and use
  `${CLAUDE_PLUGIN_ROOT}`.
- Bump `version` in `.claude-plugin/plugin.json` and add a matching `CHANGELOG.md` entry for any
  user-visible change (see [`docs/RELEASING.md`](docs/RELEASING.md)).

## Reporting issues

Security vulnerabilities go through [`SECURITY.md`](SECURITY.md), not public issues. By participating
you agree to the [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
