#!/usr/bin/env bash
# Run every gate (NN-*.sh) in order. Continues on failure so you see them all,
# then exits non-zero if any failed. Gates may print "… SKIP (…)" and exit 0
# when an optional tool (claude, shellcheck) is absent.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

fails=0
for gate in [0-9][0-9]-*.sh; do
  echo "── ${gate}"
  if ! bash "${gate}"; then
    fails=$((fails + 1))
  fi
done

echo
if [ "${fails}" -gt 0 ]; then
  echo "FAILED: ${fails} gate(s)"
  exit 1
fi
echo "All gates passed."
