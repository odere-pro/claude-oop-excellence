#!/usr/bin/env bash
# No machine-specific absolute paths (/Users/<name>, /home/<name>) in tracked files —
# they break after the plugin is copied into the cache. (10-validation-and-gates.)
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

# The pattern lives in a variable so this gate doesn't match itself.
pattern='/(Users|home)/[A-Za-z0-9._-]+'

hits="$(
  git ls-files \
    | grep -vE '^tests/gates/' \
    | while IFS= read -r f; do grep -HnE "${pattern}" "$f" 2>/dev/null || true; done
)"

if [ -n "${hits}" ]; then
  echo "FAIL: machine-specific paths found:"
  echo "${hits}"
  exit 1
fi
echo "no-absolute-paths: ok"
