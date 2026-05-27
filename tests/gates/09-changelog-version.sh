#!/usr/bin/env bash
# CHANGELOG.md has a section for the current plugin.json version. (CRITICAL)
# plugin.json is the version of record (02-manifest); this keeps the changelog from drifting.
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

if ! have jq; then
  echo "changelog-version: SKIP (jq not found)"
  exit 0
fi

ver="$(jq -r '.version // empty' .claude-plugin/plugin.json)"
if [ -z "${ver}" ]; then
  echo "FAIL: .claude-plugin/plugin.json has no version"
  exit 1
fi

if grep -qE "^##[[:space:]]+\[${ver}\]" CHANGELOG.md; then
  echo "changelog-version: ok (v${ver})"
else
  echo "FAIL: CHANGELOG.md has no '## [${ver}]' section"
  exit 1
fi
