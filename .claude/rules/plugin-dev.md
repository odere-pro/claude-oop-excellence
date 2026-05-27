---
description: >-
  House rules for developing THIS plugin. Author-only — lives under .claude/ and is never shipped to
  end users. Path-scoped so it loads only when you edit plugin components.
paths:
  - ".claude-plugin/**"
  - "skills/**"
  - "commands/**"
  - "agents/**"
  - "hooks/**"
---

# Plugin-dev house rules

These extend the platform baseline (where the platform says "optional", we say "do it"):

- **Skills**: every shipped `SKILL.md` sets `disable-model-invocation: true` unless it is genuinely
  meant to auto-fire. Side-effecting skills (deploy / commit / publish / delete) MUST set it.
- **Skills**: `description` leads with the trigger; keep `description` + `when_to_use` ≤ 1,536 chars.
- **Agents**: declare `tools` explicitly (least privilege). Never ship a plugin agent that sets
  `hooks`, `mcpServers`, or `permissionMode` — the platform blocks those for security.
- **Hooks**: reference scripts with `"${CLAUDE_PLUGIN_ROOT}"`; no `curl`/`wget`/remote `npx` on the
  hot path; keep the script fast and local; `chmod +x` every hook script.
- **Paths**: every path in any config is relative and starts with `./`. No absolute machine paths
  (`/Users/…`, `/home/…`) anywhere in shipped files.
- **Manifest**: `plugin.json` is the version-of-record. Bump `version` on every release, or omit it
  to track the git SHA. `marketplace.json` does not repeat the version.
