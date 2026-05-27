#!/usr/bin/env bash
# Shared helpers for the gate scripts. Source this, don't run it.
# Each gate prints "<name>: ok" on success or "FAIL: …" and exits non-zero.

# Repo root is two levels up from this file (tests/gates/lib.sh).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT

# have <cmd> — true if the command exists on PATH.
have() { command -v "$1" >/dev/null 2>&1; }
