#!/usr/bin/env bash
# Every shipped agent declares `tools` explicitly (least privilege). Omitting it inherits every
# tool, including MCP tools. (05-subagents, 10-validation-and-gates house rules.)
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

fail=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qE '^tools:[[:space:]]*\S' "$f" \
    || { echo "FAIL: agent without explicit tools: $f"; fail=1; }
done < <(find agents -name '*.md' 2>/dev/null | sort)

[ "${fail}" -eq 0 ] && echo "agent-tools-explicit: ok" || exit 1
