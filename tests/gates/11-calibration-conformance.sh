#!/usr/bin/env bash
# Conformance to the calibration plugin's house rules (the cookbook's gold standard, 04/05/10):
#   - every skill and command description is trigger-first (leads with "Use ")
#   - every agent declares BOTH `model` and `tools` explicitly (least privilege + pinned model)
# The calibration plugin itself is not vendored; these mirror its documented conventions.
set -euo pipefail
# shellcheck source=tests/gates/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "${REPO_ROOT}"

fail=0

# First content word of a component's frontmatter `description` (handles folded `>-` scalars).
first_desc_word() {
  awk '
    NR==1 && $0=="---"{infm=1; next}
    infm && $0=="---"{exit}
    infm && /^description:/{
      v=$0; sub(/^description:[[:space:]]*/,"",v)
      if (v ~ /^(>-?|\|-?|>)$/ || v=="") { want=1; next }
      print v; exit
    }
    want && /[^[:space:]]/ { sub(/^[[:space:]]+/,"",$0); print; exit }
  ' "$1"
}

# 1. Trigger-first descriptions for every skill + command. (Also asserts skills are present.)
skill_count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  skill_count=$((skill_count + 1))
  case "$(first_desc_word "$f")" in
    "Use "*) : ;;
    *) echo "FAIL: description not trigger-first (should lead with \"Use \"): $f"; fail=1 ;;
  esac
done < <({ find skills -name 'SKILL.md'; find commands -name '*.md'; } 2>/dev/null | sort)

if [ "${skill_count}" -eq 0 ]; then
  echo "FAIL: no skills/commands found to check"; fail=1
fi

# 2. Every agent pins a model and declares explicit tools.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qE '^model:[[:space:]]*\S' "$f"  || { echo "FAIL: agent missing model: $f"; fail=1; }
  grep -qE '^tools:[[:space:]]*\S' "$f"   || { echo "FAIL: agent missing tools: $f"; fail=1; }
done < <(find agents -name '*.md' 2>/dev/null | sort)

[ "${fail}" -eq 0 ] && echo "calibration-conformance: ok (${skill_count} skills/commands trigger-first)" || exit 1
