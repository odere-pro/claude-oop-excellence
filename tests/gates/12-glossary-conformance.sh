#!/usr/bin/env bash
# Conformance of the shared glossary (skills/glossary/glossary.json) — the single source of truth
# for issues and design patterns. STRICT gate: validates structure, the field contract per entity
# kind, the controlled vocab, the selector registry (tracks/aspects), cross-references, verb-path
# coverage, the 3-layer single-front-door wiring, retired-file absence, and the entity counts echoed
# in README.md / CHANGELOG.md.
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

GLOSSARY="skills/glossary/glossary.json"

# python3 is the validator (it ships on the runner and is what we use for structured checks).
if ! have python3; then
  echo "glossary-conformance: SKIP (python3 not found)"
  exit 0
fi

if [ ! -f "${GLOSSARY}" ]; then
  echo "FAIL: missing ${GLOSSARY}"
  exit 1
fi

# Checks 1-6 (structure, field contract, ids, vocab, references, verb-path skill files) live in one
# python pass; it prints "GLOSSARY_OK <issues> <patterns> <total>" on success or "FAIL: …" lines.
counts="$(
  python3 - "${GLOSSARY}" <<'PY'
import json
import re
import sys

path = sys.argv[1]
fail = False


def err(msg):
    global fail
    print(f"FAIL: {msg}")
    fail = True


# 1. parses as valid JSON
try:
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
except (OSError, ValueError) as exc:
    print(f"FAIL: {path} is not valid JSON: {exc}")
    sys.exit(1)

vocab = data.get("vocabulary", {})
entities = data.get("entities", [])
if not isinstance(entities, list) or not entities:
    print("FAIL: glossary has no entities array")
    sys.exit(1)

FIXED_CATEGORIES = [
    "code-smell",
    "antipattern",
    "vulnerability",
    "supply-chain-risk",
    "design-pattern",
]
vocab_categories = vocab.get("categories", [])
if vocab_categories != FIXED_CATEGORIES:
    err(f"vocabulary.categories must equal {FIXED_CATEGORIES}, got {vocab_categories}")

# Selector registry: tracks and aspects are fixed, ordered sets.
FIXED_TRACKS = ["risk", "pattern"]
FIXED_ASPECTS = ["risk-scan", "pattern-scan", "pattern-fit"]
vocab_tracks = vocab.get("tracks", [])
if vocab_tracks != FIXED_TRACKS:
    err(f"vocabulary.tracks must equal {FIXED_TRACKS}, got {vocab_tracks}")
vocab_aspects = vocab.get("aspects", [])
if vocab_aspects != FIXED_ASPECTS:
    err(f"vocabulary.aspects must equal {FIXED_ASPECTS}, got {vocab_aspects}")

vocab_families = set(vocab.get("families", []))
vocab_principles = set(vocab.get("principles", []))
if not vocab_families:
    err("vocabulary.families is empty")
if not vocab_principles:
    err("vocabulary.principles is empty")

KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
COMMON_FIELDS = ["id", "name", "category", "family", "principles", "signs"]
ISSUE_FIELDS = ["default_severity", "applies_when", "corrective_patterns"]
PATTERN_FIELDS = ["resolves"]

ids = set()
issue_ids = set()
pattern_ids = set()
issues = 0
patterns = 0

for i, ent in enumerate(entities):
    label = ent.get("id", f"<index {i}>")

    for field in COMMON_FIELDS:
        if field not in ent:
            err(f"entity '{label}' missing required field '{field}'")

    ent_id = ent.get("id")
    if isinstance(ent_id, str):
        if not KEBAB.match(ent_id):
            err(f"entity id not kebab-case: '{ent_id}'")
        if ent_id in ids:
            err(f"duplicate entity id: '{ent_id}'")
        ids.add(ent_id)

    category = ent.get("category")
    if category not in FIXED_CATEGORIES:
        err(f"entity '{label}' uses category outside fixed set: '{category}'")

    family = ent.get("family")
    if family not in vocab_families:
        err(f"entity '{label}' family '{family}' not in vocabulary.families")

    for pid in ent.get("principles", []) or []:
        if pid not in vocab_principles:
            err(f"entity '{label}' references unknown principle '{pid}'")

    if category == "design-pattern":
        patterns += 1
        if isinstance(ent_id, str):
            pattern_ids.add(ent_id)
        for field in PATTERN_FIELDS:
            if field not in ent:
                err(f"design-pattern '{label}' missing required field '{field}'")
    else:
        issues += 1
        if isinstance(ent_id, str):
            issue_ids.add(ent_id)
        for field in ISSUE_FIELDS:
            if field not in ent:
                err(f"issue '{label}' missing required field '{field}'")

# Cross-references (second pass, now that we know all ids).
for ent in entities:
    label = ent.get("id", "<unknown>")
    if ent.get("category") == "design-pattern":
        for rid in ent.get("resolves", []) or []:
            if rid not in issue_ids:
                err(f"pattern '{label}' resolves unknown issue id '{rid}'")
    else:
        for cid in ent.get("corrective_patterns", []) or []:
            if cid not in pattern_ids:
                err(f"issue '{label}' corrective_patterns refers to unknown pattern id '{cid}'")

if fail:
    sys.exit(1)

print(f"GLOSSARY_OK {issues} {patterns} {issues + patterns}")
PY
)" || { echo "${counts}"; exit 1; }

# Surface any FAIL lines python may have emitted before exiting 0 (defensive; it exits 1 on fail).
case "${counts}" in
  *FAIL:*) echo "${counts}"; exit 1 ;;
esac

read -r _tag issues patterns total <<<"${counts}"
if [ "${_tag}" != "GLOSSARY_OK" ]; then
  echo "FAIL: unexpected validator output: ${counts}"
  exit 1
fi

# 6. Verb-path coverage: every category maps to existing skill files. The four ISSUE categories
#    (code-smell, antipattern, vulnerability, supply-chain-risk) each map to skills/audit (analysis)
#    and skills/improve (fix); design-pattern maps to skills/audit (pattern scan+fit) and
#    skills/pattern-implement (implement). The fixed-set check above guarantees no orphan category.
#    pattern-detect is retired — it is not part of the mapping (see check 7).
fail=0
for skill in \
  skills/audit/SKILL.md \
  skills/improve/SKILL.md \
  skills/pattern-implement/SKILL.md; do
  [ -f "${skill}" ] || { echo "FAIL: missing verb-path skill: ${skill}"; fail=1; }
done

# 7. Retired files must be gone (single-front-door architecture removed these).
for f in \
  commands/oop-excellence.md \
  commands/risk-report.md \
  commands/pattern-suggest.md \
  skills/pattern-detect/SKILL.md \
  agents/risk-scanner.md; do
  if [ -e "${f}" ]; then
    echo "FAIL: retired file must not exist: ${f}"
    fail=1
  fi
done

# Retired per-antipattern scanners must also be gone.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "FAIL: retired scanner must not exist: $f"
  fail=1
done < <(find agents -name 'risk-antipattern-*-scanner.md' 2>/dev/null)

# 7b. 3-layer wiring: the audit front door references the orchestrator, and the orchestrator
#     dispatches all five workers by name.
AUDIT_SKILL="skills/audit/SKILL.md"
if [ -f "${AUDIT_SKILL}" ]; then
  grep -q 'oop-orchestrator' "${AUDIT_SKILL}" \
    || { echo "FAIL: ${AUDIT_SKILL} does not reference oop-orchestrator"; fail=1; }
fi

ORCHESTRATOR="agents/oop-orchestrator.md"
if [ ! -f "${ORCHESTRATOR}" ]; then
  echo "FAIL: missing orchestrator: ${ORCHESTRATOR}"; fail=1
else
  for worker in \
    entity-detector \
    pattern-scanner \
    pattern-suggester \
    entity-fixer \
    pattern-implementer; do
    grep -q "${worker}" "${ORCHESTRATOR}" \
      || { echo "FAIL: ${ORCHESTRATOR} does not reference worker '${worker}'"; fail=1; }
  done
fi

# 8. README.md and CHANGELOG.md must each state the computed counts (tolerant, case-insensitive,
#    order-independent). issues→"issue", patterns→"pattern" (allows "design pattern").
states_count() {
  # states_count <doc> <n> <word>  — true if <n> sits on a line that also mentions <word>, in
  # either order, with no other digits stuck to the number (so "45" never matches "145" or "450").
  local doc="$1" n="$2" word="$3"
  # number-then-word: <n> bounded by non-digits, then <word> somewhere after on the same line.
  grep -iE "(^|[^0-9])${n}([^0-9]|$).*${word}" "${doc}" >/dev/null 2>&1 \
    && return 0
  # word-then-number: <word>, then <n> bounded by non-digits later on the same line.
  grep -iE "${word}.*(^|[^0-9])${n}([^0-9]|$)" "${doc}" >/dev/null 2>&1
}

for doc in README.md CHANGELOG.md; do
  if [ ! -f "${doc}" ]; then
    echo "FAIL: missing ${doc}"; fail=1; continue
  fi
  states_count "${doc}" "${issues}" "issue" \
    || { echo "FAIL: ${doc} does not state ${issues} issues"; fail=1; }
  states_count "${doc}" "${patterns}" "pattern" \
    || { echo "FAIL: ${doc} does not state ${patterns} design patterns"; fail=1; }
done

if [ "${fail}" -eq 0 ]; then
  echo "glossary-conformance: ok (${issues} issues + ${patterns} patterns = ${total} entities)"
else
  exit 1
fi
