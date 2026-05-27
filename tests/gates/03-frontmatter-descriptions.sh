#!/usr/bin/env bash
# Every shipped skill, command, and agent carries a non-empty `description`.
# No description, no routing — and `--strict` rejects it. (02-manifest, 04-skills.)
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

fail=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qE '^description:[[:space:]]*\S' "$f" \
    || { echo "FAIL: no description in $f"; fail=1; }
done < <(
  { find skills -name 'SKILL.md'
    find commands agents -name '*.md'
  } 2>/dev/null | sort
)

[ "${fail}" -eq 0 ] && echo "frontmatter-descriptions: ok" || exit 1
