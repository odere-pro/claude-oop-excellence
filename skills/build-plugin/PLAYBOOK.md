# Build a Claude Code plugin — step by step

The detailed reference for [SKILL.md](SKILL.md). It documents the plugin format and
the exact build steps. The orchestrator follows it; a human can also follow it by
hand.

---

## 1. Plugin anatomy

A plugin is a directory with a manifest plus optional `agents/`, `skills/`, and
`commands/` folders:

```
<plugin-root>/
├── .claude-plugin/
│   ├── plugin.json          # required manifest
│   └── marketplace.json     # optional — only for distribution
├── README.md                # recommended
├── LICENSE                  # recommended
├── agents/                  # optional — one .md per agent
│   └── <agent-name>.md
├── skills/                  # optional — one folder per skill
│   └── <skill-name>/
│       ├── SKILL.md
│       └── <REFERENCE.md | EXAMPLES.md | …>   # optional supporting files
└── commands/                # optional — one .md per command
    └── <command-name>.md
```

Rules of the layout:

- `.claude-plugin/plugin.json` is **mandatory**; everything else is optional.
- Agents are flat `.md` files in `agents/`.
- Skills are **folders** under `skills/`, each containing a `SKILL.md` (plus any
  supporting docs the skill references).
- Commands are flat `.md` files in `commands/`.

## 2. `plugin.json` schema

```json
{
  "name": "my-plugin",                         // required, kebab-case, unique
  "description": "What the plugin does.",       // required
  "version": "0.1.0",                           // optional, semver
  "author": { "name": "...", "email": "..." },  // optional (email OR url)
  "homepage": "https://...",                    // optional
  "repository": "https://github.com/...",       // optional
  "license": "MIT",                             // optional
  "keywords": ["..."],                          // optional
  "agents":   ["./agents/a.md", "./agents/b.md"], // list paths, or omit to rely on the folder
  "skills":   ["./skills/"],                       // directory include
  "commands": ["./commands/"]                      // directory include, or list paths
}
```

- `agents`, `skills`, `commands` accept either **explicit relative paths** or a
  **directory include** (`"./skills/"`). Enumerate agents when you want control;
  use directory includes for skills/commands so new ones are picked up
  automatically.
- Keep `name` unique and kebab-case. Installed commands/skills may be namespaced as
  `<plugin>:<name>`, so internal cross-references by bare `/name` should still
  resolve but are the first thing to check after install.

## 3. Frontmatter per component

**Agent** (`agents/<name>.md`):
```yaml
---
name: my-agent
description: When to use this agent.
tools: Read, Grep, Glob, Bash      # grant the minimum needed
model: sonnet                      # optional
---
<system prompt / instructions>
```

**Skill** (`skills/<name>/SKILL.md`):
```yaml
---
name: my-skill
description: What the skill does and when to use it.
argument-hint: '[args]'            # optional
user-invocable: true               # optional
---
<skill body>
```

**Command** (`commands/<name>.md`):
```yaml
---
description: One-line command summary.
argument-hint: 'optional hint'
allowed-tools: Bash(git status:*), Read
---
<command body>
```
(A command may also be a plain `.md` with no frontmatter; the body is the prompt.)

## 4. The build steps

1. **Frame the goal.** Decide the plugin `name`, target directory, and the exact set
   of agents / skills / commands to include. Write this down (the orchestrator uses
   `.build/manifest.json`).
2. **Scaffold.** Create the tree (`.claude-plugin/`, `agents/`, `skills/`,
   `commands/`) and copy in every component that needs no changes, verbatim —
   including each skill's supporting files (`REFERENCE.md`, `EXAMPLES.md`, …).
3. **Author / transform.** For each component that must be created or adapted, write
   exactly one file at a time. When repackaging existing components, apply the
   genericization checklist (§5). One file per unit keeps the work parallelizable.
4. **Author the manifest + docs.** Write `.claude-plugin/plugin.json` (§2) and a
   `README.md` describing what the plugin does, its commands/skills, and install
   steps. Optionally add `LICENSE` and a `marketplace.json` for distribution.
5. **Verify.** Run the checks in §6. Fix issues and re-verify until clean.

## 5. Genericization checklist (when repackaging existing components)

Strip the donor project's identity so the plugin works anywhere:

- [ ] Remove the project name and product-specific nouns from titles, descriptions,
      and prose.
- [ ] Replace hard-coded source paths (e.g. `src/`) with "the source root —
      `src/` if present, else the repository root".
- [ ] Replace single-tool assumptions (`npm run test`, `bun`) with detect-the-tool
      wording (npm / pnpm / yarn / bun via lockfile + `package.json` scripts), and
      broaden agent `tools` grants accordingly.
- [ ] Gate language/tool-specific checks behind a presence test (e.g. type-safety
      only when a `tsconfig.json` exists).
- [ ] Drop components that cannot be generalized, and remove every reference to a
      dropped component from the survivors.
- [ ] Re-point examples that named project-specific files to generic placeholders.

## 6. Verification checklist

- [ ] **Counts** — `find <root> -type f` shows the expected number of agents, skill
      `SKILL.md`s (+ supporting files), and commands.
- [ ] **Manifest valid** — `python3 -m json.tool .claude-plugin/plugin.json` parses;
      every enumerated `agents`/`skills`/`commands` path exists on disk.
- [ ] **No donor coupling** — `grep -rinE '<project>|<product nouns>'` over the tree
      returns only intentional generic mentions.
- [ ] **Cross-references resolve** — every `/skill`, agent name, or command a
      component dispatches exists in the bundle (or is a documented external dep).
- [ ] **Frontmatter present** — each agent/skill/command has the required keys.

## 7. Install

- **Local:** place the plugin where your Claude Code install discovers local
  plugins, or add its directory to a marketplace you control.
- **Distribution:** add `.claude-plugin/marketplace.json` listing the plugin
  (`name`, `source: "./"`, `description`, `author`, `version`), then
  `/plugin marketplace add <repo-or-path>` and install from there.

After install, confirm each command/skill is available by name (watch for
`<plugin>:<name>` namespacing).
