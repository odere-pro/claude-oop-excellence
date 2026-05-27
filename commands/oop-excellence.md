---
description: >-
  Use as the front door to the OOP-excellence pipeline. With no argument it runs a full audit and
  prints the next-step menu; `scan`, `report`, `patterns`, and `fix` jump straight to a phase. The
  default is read-only — applying fixes always hands off to the gated /fix-risks and
  /implement-patterns commands, so nothing changes your source without explicit confirmation.
argument-hint: '[scan | report | patterns | fix | help] [domains|scope]'
---

# OOP Excellence — pipeline entry point

Route the request based on the first token of `$ARGUMENTS` (default: `scan`). This command never
edits source itself; the fix phases are delegated to their gated commands.

## Routing

| First token        | Action |
| ------------------ | ------ |
| _(empty)_ / `scan` | Run `/audit $REST` (default `all`). Print the unified report, then show the **Next steps** menu below. |
| `report`           | Run `/risk-report $REST` to save a timestamped report under `tmp/`. |
| `patterns`         | Run `/pattern-suggest $REST` to save design-pattern recommendations, then point at `/implement-patterns`. |
| `fix`              | Hand off to `/fix-risks $REST`. State that this modifies source and is user-confirmed; do not apply fixes from here. |
| `help`             | Print the pipeline map and stop. |

`$REST` is the remaining arguments after the first token (domains and/or scope, e.g. `oop security changed`).

## Pipeline map

```
        DETECT                 REPORT (writes tmp/)        FIX (reads tmp/, gated)
  ┌──────────────┐         ┌────────────────────┐      ┌─────────────────────┐
  │ /audit       │ ──────▶ │ /risk-report        │ ───▶ │ /fix-risks          │
  │ /pattern-    │         │ /pattern-suggest    │      │ /implement-patterns │
  │   detect     │         └────────────────────┘      └─────────────────────┘
  └──────────────┘
```

OOP is the spine: it is always covered in a scan and fixed before other domains.

## Next steps menu (after a scan)

```
Scan complete — risk score {score} ({verdict}).

Next:
  /risk-report            save this report under tmp/ before changing anything
  /fix-risks [domains]    fix findings domain by domain (OOP first; modifies source)
  /pattern-suggest        find design-pattern opportunities
  /improve <domain>       fix a single domain interactively
```
