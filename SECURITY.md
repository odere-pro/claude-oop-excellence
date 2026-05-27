# Security policy

`claude-oop-excellence` ships no network code and no compiled binaries — its moving parts are
Markdown skill/command/agent instructions and JSON manifests. It ships no hooks and no MCP server.

## Trust model

- **The privileged actions are source edits, and they are user-gated.** The fix skills (`improve`,
  `pattern-implement`) and fix commands (`/fix-risks`, `/implement-patterns`) modify your code; all
  four set `disable-model-invocation: true`, so Claude cannot auto-fire them — a user must invoke
  them, and they confirm a plan before applying changes.
- **Reports are written under `tmp/`** at the repository root by the report commands; they are plain
  Markdown for review and touch nothing else.
- **Scanner agents run read-only, scoped shell only** (e.g. `git log`, `wc`, package-manager `test`
  commands) declared in each agent's `tools` allow-list — no arbitrary shell.
- **No network on the hot path:** no shipped instruction, agent, or script calls `curl` / `wget` or
  fetches a remote package. A gate enforces this (`tests/gates/`).
- **No secrets in shipped files; all paths are relative.** Gates enforce both.

## Supported versions

| Version | Supported |
| ------- | --------- |
| 0.1.x   | ✅        |
| < 0.1   | ❌        |

## Reporting a vulnerability

Please report privately via **GitHub Security Advisories** —
`https://github.com/REPLACE-ME-owner/claude-oop-excellence/security/advisories/new` — rather than opening a
public issue. We aim to acknowledge within a few days and to fix or mitigate confirmed issues before
any public disclosure.
