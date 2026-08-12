#!/bin/sh
# Automated test for hooks/check-stale. Run from the repo root:
#   sh tests/run-hook-test.sh
# Exits non-zero on any FAIL. Scratch lives in tests/scratch/ (gitignored).

root=$(pwd)
scratch="$root/tests/scratch/hook-home"
rm -rf "$scratch"
proj='D:\fake\checkup-proj'
slug='D--fake-checkup-proj'
mem="$scratch/.claude/projects/$slug/memory"
mkdir -p "$mem/.trash"

fail=0
check() {
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else
    echo "FAIL: $1"; echo "  expected: [$2]"; echo "  actual:   [$3]"; fail=1
  fi
}

expected='[memory-tools] 1 memory file(s) past their review-after date - treat their contents as unverified:
- project_build_pipeline_status.md (review-after 2026-07-01)
Ask the user to run /checkup to refresh, mark historical, or forget them; do not edit memory files yourself.'

# Case 1: overdue stamp reported; fresh stamp and unstamped files silent;
# an overdue file planted in .trash/ must never be scanned.
cp "$root/tests/fixture-memory-baseline/"*.md "$mem/"
cp "$root/tests/fixture-memory-baseline/project_build_pipeline_status.md" \
   "$mem/.trash/planted_overdue.md"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "overdue warning shape" "$expected" "$out"
check "exit 0 (overdue)" "0" "$rc"

# Case 2: POSIX-style project dir maps to the same slug (same warning).
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR='/d/fake/checkup-proj' sh "$root/hooks/check-stale"); rc=$?
check "posix path maps to same slug" "$expected" "$out"
check "exit 0 (posix path)" "0" "$rc"

# Case 3: nothing overdue -> completely silent.
rm "$mem/project_build_pipeline_status.md"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "silent when fresh" "" "$out"
check "exit 0 (fresh)" "0" "$rc"

# Case 4: no memory dir at all -> completely silent.
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR='D:\fake\no-such-proj' sh "$root/hooks/check-stale"); rc=$?
check "silent when no memory dir" "" "$out"
check "exit 0 (no dir)" "0" "$rc"

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES ABOVE"; fi
exit "$fail"
