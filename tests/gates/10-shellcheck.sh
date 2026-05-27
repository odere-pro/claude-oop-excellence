#!/usr/bin/env bash
# The gate scripts themselves stay clean under shellcheck at error level.
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

if ! have shellcheck; then
  echo "shellcheck: SKIP (shellcheck not found)"
  exit 0
fi

scripts=()
while IFS= read -r s; do scripts+=("$s"); done \
  < <(find tests/gates -name '*.sh' | sort)

if shellcheck -S error "${scripts[@]}"; then
  echo "shellcheck: ok"
else
  echo "FAIL: shellcheck reported errors"
  exit 1
fi
