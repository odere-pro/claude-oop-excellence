#!/usr/bin/env bash
# No concrete secret-shaped tokens in tracked files. (CRITICAL)
# Targets real credential formats (OpenAI, GitHub PAT classic + fine-grained, AWS, Slack, PEM keys),
# not the pattern *descriptions* a doc or antipattern reference might carry.
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

# The pattern lives in a variable so this gate (under tests/gates/) never matches itself.
secret_re='(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{50,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{12,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'

fail=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if grep -nE "${secret_re}" "$f" >/dev/null 2>&1; then
    echo "FAIL: possible secret in $f:"
    grep -nE "${secret_re}" "$f" | sed 's/^/  /'
    fail=1
  fi
done < <(git ls-files | grep -vE '^tests/gates/')

[ "${fail}" -eq 0 ] && echo "secret-scan: ok" || exit 1
