#!/usr/bin/env bash
# Every tracked *.json file parses as strict JSON (manifest, marketplace).
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

if ! have jq; then
  echo "json-parses: SKIP (jq not found)"
  exit 0
fi

fail=0
while IFS= read -r f; do
  jq empty "$f" 2>/dev/null || { echo "FAIL: invalid JSON: $f"; fail=1; }
done < <(git ls-files '*.json')

[ "${fail}" -eq 0 ] && echo "json-parses: ok" || exit 1
