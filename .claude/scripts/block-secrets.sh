#!/usr/bin/env bash
#
# PreToolUse hook for Write | Edit | MultiEdit.
# Blocks tool calls that embed common hardcoded-secret patterns.
#
# Reads the tool-input JSON from stdin (Claude Code's hook protocol) and
# greps the raw stream. The pattern matches both raw text and JSON-escaped
# text — the optional `\` before the opening quote handles `\"` sequences.
#
# POSIX character classes so this works on BSD grep (macOS) as well as GNU.
# Side-effect free: exits 2 to block, 0 otherwise. Idempotent.
#
# Known limitation: also greps `old_string` payloads on Edit/MultiEdit, so
# editing a file purely to *remove* an existing secret would be blocked.
# Rare in practice; rotate-and-replace is the recommended path anyway.

set -uo pipefail

PATTERN='(password|api_key|secret|token)[[:space:]]*[:=][[:space:]]*\\?["'\''][^"'\'']{6,}'

if grep -qiE "$PATTERN"; then
    echo '[Hook] BLOCKED: hardcoded secret pattern detected (password/api_key/secret/token = "...")' >&2
    exit 2
fi

exit 0
