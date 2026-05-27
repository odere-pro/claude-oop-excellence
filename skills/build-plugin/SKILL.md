---
name: build-plugin
description: >-
  Use to scaffold a new Claude Code plugin or repackage existing skills/agents/commands into one —
  a goal-driven orchestrator that decomposes the build into phases, dispatches each unit of work to a
  fresh-context subagent, persists all state to disk between runs (so context never accumulates), and
  fans independent work out across multiple subagents in parallel.
argument-hint: '<goal> — e.g. "package the detect-* skills into a plugin named my-quality-kit"'
user-invocable: true
---

# Build Plugin — goal skill

You are the **orchestrator**. You do not build the plugin yourself: you decompose
the goal, dispatch fresh subagents to do each unit of work, and track progress on
disk. The detailed step content lives in [PLAYBOOK.md](PLAYBOOK.md) — read it once
at the start of a run.

## Operating principles (the contract that makes this work)

1. **Disk is memory.** All durable state lives under `<target>/.build/`, never in
   your conversation. Subagents read their inputs from disk and write their outputs
   to disk. Nothing important survives only in context.
2. **One subagent = one fresh context.** Every unit of work is a *new* `Agent`
   invocation. A subagent never inherits another subagent's context, and never sees
   yours. This is what "clean context between runs" means — it is achieved by
   spawning a new subagent per unit, not by trying to wipe an existing one.
3. **Subagents return a status line, not a dump.** Brief each subagent to write its
   artifacts to disk and reply with only a short status (what it wrote + any
   blocker). You record that line in the manifest. Never let a subagent echo file
   contents back — that is what pollutes context.
4. **Fan out independent work.** Units with no dependency on each other are
   dispatched as **multiple `Agent` calls in a single message** so they run in
   parallel. Dependent units run in sequence.
5. **You stay lean.** Between phases, read only the compact manifest, decide the
   next batch, and dispatch. If your own context is growing, re-read the manifest
   and rely on it as the source of truth — discard the rest.

## State: the build manifest

Maintain `<target>/.build/manifest.json` as the single source of truth:

```json
{
  "goal": "<verbatim goal>",
  "plugin": { "name": "<kebab>", "target": "tmp/<name>", "version": "0.1.0" },
  "phase": "frame|inventory|scaffold|author|manifest|verify|done",
  "units": [
    {
      "id": "skill:detect-code-antipatterns",
      "kind": "skill|agent|command|doc",
      "action": "copy|author|genericize",
      "src": "<source path or null>",
      "dest": "skills/detect-code-antipatterns/SKILL.md",
      "rules": "<exact transform/authoring rules for this unit>",
      "status": "pending|in_progress|done|failed",
      "note": ""
    }
  ],
  "verification": { "passed": false, "issues": [] }
}
```

Any subagent handed the manifest path plus a unit `id` can reconstruct exactly what
to do, because the `rules` field carries the full self-contained brief.

## Phases

### 0. Frame the goal  *(you do this — it is cheap and defines the contract)*
Parse `$ARGUMENTS` into plugin name, target dir, and the components to include.
Create `<target>/.build/` and write the initial manifest: one `unit` per component,
all `pending`, each with concrete `action` + `rules`. Set `phase:"frame"`.

### 1. Inventory  *(only for "repackage existing" goals)*
Dispatch 1–3 **parallel** Explore subagents to locate and classify source
components (generic vs project-coupled — see PLAYBOOK.md §"Genericization"). Each
writes findings to `.build/inventory-<area>.md` and returns one line. Fold their
classifications into each unit's `action`/`rules`.

### 2. Scaffold
Dispatch **one** subagent to create the directory tree and copy every
`action:"copy"` unit verbatim. It flips those units to `done` and returns counts.

### 3. Author / transform  *(fan out — the main use of multiple subagents)*
For every `action:"author"` / `action:"genericize"` unit, dispatch a subagent —
**many in parallel** in one message, since each touches a single independent file.
Each brief is fully self-contained (the unit's `src`, `dest`, and `rules`). Each
subagent writes its one file, updates its unit, and returns a status line.

### 4. Manifest & docs
Dispatch **one** subagent to author `.claude-plugin/plugin.json` and `README.md`
from the finished manifest (schema + layout in PLAYBOOK.md).

### 5. Verify
Dispatch **one** subagent to run the checks in PLAYBOOK.md §"Verification"
(file counts, valid JSON, every enumerated agent path exists, coupling greps,
cross-reference resolution). It writes `.build/verification.md` and returns
pass/fail + issues.
- **Fail** → for each issue, dispatch a fresh targeted fix subagent (parallel where
  independent), then re-dispatch verify. Repeat until clean or escalate to the user.
- **Pass** → set `phase:"done"`, report the final summary, and offer to delete
  `.build/` for a clean shipped tree.

## Dispatching a subagent — briefing template

Every dispatch must be self-contained. Assume the subagent knows nothing about the
goal or prior steps:

```
GOAL: <one line>
READ FIRST: <manifest path>, <PLAYBOOK.md path>, <any input files for this unit>
YOUR UNIT: <unit id> — <action> → <dest>
RULES: <paste the unit's rules verbatim>
WRITE: <dest path>
THEN: set <unit id> in the manifest to done|failed with a ≤15-word note, and reply
      with ONLY: "<unit id>: <done|failed> — <note>".
DO NOT: touch files outside your unit; do NOT return file contents in your reply.
```

Pick the subagent type per unit: **Explore** for inventory/research, a
general-purpose/coding agent for scaffold/author/genericize/verify.

## Resuming a run

On re-invocation, read the manifest, find the first non-`done` phase (and any
`pending`/`in_progress`/`failed` units within it), and continue. Because all state
is on disk, a fresh orchestrator resumes with zero lost work — the same property
that lets subagents run with clean context.
