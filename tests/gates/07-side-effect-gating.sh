#!/usr/bin/env bash
# Side-effecting skills/commands — the ones that modify source — set
# `disable-model-invocation: true` so Claude never auto-fires a refactor. (04-skills.)
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

# Components that write to the user's source tree must be user-invoked only.
gated=(
  skills/improve/SKILL.md
  skills/pattern-implement/SKILL.md
  commands/fix-risks.md
  commands/implement-patterns.md
)

fail=0
for f in "${gated[@]}"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: expected side-effecting component missing: $f"; fail=1; continue
  fi
  grep -qE '^disable-model-invocation:[[:space:]]*true' "$f" \
    || { echo "FAIL: $f modifies source but is not disable-model-invocation: true"; fail=1; }
done

[ "${fail}" -eq 0 ] && echo "side-effect-gating: ok" || exit 1
