#!/usr/bin/env bash
#
# PreToolUse hook for Write.
# Blocks writes whose content exceeds 800 lines.
#
# Reads the tool-input JSON from stdin (Claude Code's hook protocol). Each
# newline inside the `content` string arrives as the 2-character JSON escape
# `\n`, so we count those occurrences instead of parsing JSON. One literal
# trailing line is added for the chunk after the final `\n`.
#
# Side-effect free: exits 2 to block, 0 otherwise. Idempotent.

set -uo pipefail

LIMIT=800

escapes=$(grep -oF '\n' | wc -l | tr -d '[:space:]')
lines=$((escapes + 1))

if [ "$lines" -gt "$LIMIT" ]; then
    echo "[Hook] BLOCKED: file exceeds ${LIMIT} lines (${lines} lines) — split into smaller modules" >&2
    exit 2
fi

exit 0
