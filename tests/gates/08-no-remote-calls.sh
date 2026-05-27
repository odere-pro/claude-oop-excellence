#!/usr/bin/env bash
# Shipped instructions and agents make no network calls (no curl/wget/remote npx). (CRITICAL)
# A plugin should not fetch a remote payload on the hot path. (06-hooks, 14-supply-chain.)
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

remote_re='(\b(curl|wget)\b|npx[^[:space:]]*https?://)'
fail=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if grep -nE "${remote_re}" "$f" >/dev/null 2>&1; then
    echo "FAIL: network call in ${f}:"
    grep -nE "${remote_re}" "$f" | sed 's/^/  /'
    fail=1
  fi
done < <(find skills commands agents -type f 2>/dev/null | sort)

[ "${fail}" -eq 0 ] && echo "no-remote-calls: ok" || exit 1
