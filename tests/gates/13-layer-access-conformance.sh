#!/usr/bin/env bash
# Layer-access & selector-doc conformance. Guards the human-readable selector docs and the 3-layer
# direct-access contract against drift from the glossary (the single source of truth):
#   (a) every vocabulary.tracks + vocabulary.aspects value is documented in glossary/SKILL.md,
#       audit/SKILL.md, AND README.md — so the selector tables can't silently lose a track/aspect;
#   (b) a "## Direct layer access" section exists in both audit/SKILL.md and glossary/SKILL.md;
#   (c) each of the five L3 workers documents a "## Standalone invocation" section (the L3 bypass).
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

GLOSSARY="skills/glossary/glossary.json"
GLOSSARY_SKILL="skills/glossary/SKILL.md"
AUDIT_SKILL="skills/audit/SKILL.md"
README="README.md"

# python3 reads the canonical tracks/aspects out of the glossary (same validator as gate 12).
if ! have python3; then
  echo "layer-access-conformance: SKIP (python3 not found)"
  exit 0
fi

fail=0

for f in "${GLOSSARY}" "${GLOSSARY_SKILL}" "${AUDIT_SKILL}" "${README}"; do
  if [ ! -f "${f}" ]; then
    echo "FAIL: missing ${f}"
    fail=1
  fi
done
[ "${fail}" -eq 0 ] || exit 1

# (a) Selector-doc coverage: every tracks/aspects value must appear in all three selector docs.
selectors="$(
  python3 - "${GLOSSARY}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    vocab = json.load(fh).get("vocabulary", {})
print("\n".join(list(vocab.get("tracks", [])) + list(vocab.get("aspects", []))))
PY
)"

if [ -z "${selectors}" ]; then
  echo "FAIL: glossary vocabulary has no tracks/aspects to check"
  exit 1
fi

while IFS= read -r sel; do
  [ -n "${sel}" ] || continue
  for doc in "${GLOSSARY_SKILL}" "${AUDIT_SKILL}" "${README}"; do
    grep -Fq -- "${sel}" "${doc}" \
      || { echo "FAIL: selector '${sel}' (from vocabulary) not documented in ${doc}"; fail=1; }
  done
done <<<"${selectors}"

# (b) Both front-door docs must carry the direct-access contract.
for doc in "${AUDIT_SKILL}" "${GLOSSARY_SKILL}"; do
  grep -q '^## Direct layer access' "${doc}" \
    || { echo "FAIL: ${doc} is missing a '## Direct layer access' section"; fail=1; }
done

# (c) Each L3 worker must document its standalone (orchestrator-skipping) path.
for worker in \
  entity-detector \
  pattern-scanner \
  pattern-suggester \
  entity-fixer \
  pattern-implementer; do
  wf="agents/${worker}.md"
  if [ ! -f "${wf}" ]; then
    echo "FAIL: missing worker: ${wf}"
    fail=1
    continue
  fi
  grep -q '^## Standalone invocation' "${wf}" \
    || { echo "FAIL: ${wf} is missing a '## Standalone invocation' section"; fail=1; }
done

if [ "${fail}" -eq 0 ]; then
  echo "layer-access-conformance: ok (selectors documented; direct-access + standalone sections present)"
else
  exit 1
fi
