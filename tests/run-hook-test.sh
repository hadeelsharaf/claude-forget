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

# Case 5: multiple overdue files -> count 2, listed alphabetically.
rm -rf "$mem"; mkdir -p "$mem/.trash"
cp "$root/tests/fixture-memory-baseline/project_build_pipeline_status.md" "$mem/"
printf '%s\n' '---' 'name: project_alpha_overdue' \
  'description: second overdue file for the hook multi-file test' 'metadata:' \
  '  type: project' 'review-after: 2020-02-02' '---' '' \
  'Synthetic second overdue fixture for the hook test only.' \
  > "$mem/project_alpha_overdue.md"
expected_multi='[memory-tools] 2 memory file(s) past their review-after date - treat their contents as unverified:
- project_alpha_overdue.md (review-after 2020-02-02)
- project_build_pipeline_status.md (review-after 2026-07-01)
Ask the user to run /checkup to refresh, mark historical, or forget them; do not edit memory files yourself.'
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "multiple overdue, count 2, alphabetical" "$expected_multi" "$out"
check "exit 0 (multi overdue)" "0" "$rc"

# Case 6: malformed stamp (07/2026) -> silent for that file.
rm -rf "$mem"; mkdir -p "$mem/.trash"
cp "$root/tests/fixture-memory-baseline/project_ci_flakiness_status.md" "$mem/"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "malformed stamp silent" "" "$out"
check "exit 0 (malformed stamp)" "0" "$rc"

# Case 7: body-text review-after outside the frontmatter -> not listed.
rm -rf "$mem"; mkdir -p "$mem/.trash"
cp "$root/tests/fixture-memory-baseline/feedback_release_notes_style.md" "$mem/"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "body-text stamp not listed" "" "$out"
check "exit 0 (body-text stamp)" "0" "$rc"

# Case 8: stamp dated exactly today -> not overdue, silent.
rm -rf "$mem"; mkdir -p "$mem/.trash"
today=$(date +%Y-%m-%d)
printf '%s\n' '---' 'name: project_today_stamp' \
  'description: exactly-today stamp for the hook boundary test' 'metadata:' \
  '  type: project' "review-after: $today" '---' '' \
  'Synthetic exactly-today fixture for the hook test only.' \
  > "$mem/project_today_stamp.md"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "exactly-today not overdue" "" "$out"
check "exit 0 (exactly today)" "0" "$rc"

# Case 9: lowercase drive letter maps to the same warning as uppercase.
rm -rf "$mem"; mkdir -p "$mem/.trash"
cp "$root/tests/fixture-memory-baseline/project_build_pipeline_status.md" "$mem/"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR='d:\fake\checkup-proj' sh "$root/hooks/check-stale"); rc=$?
check "lowercase drive same warning" "$expected" "$out"
check "exit 0 (lowercase drive)" "0" "$rc"

# Case 10: HOME unset -> silent, exit 0.
out=$(HOME= CLAUDE_PROJECT_DIR="$proj" sh "$root/hooks/check-stale"); rc=$?
check "HOME unset silent" "" "$out"
check "exit 0 (HOME unset)" "0" "$rc"

# --- Memory-folder lookup cases (v0.3.1) ------------------------------------
# Helper: slug a path the way the hook does (git-bash /x/ and lowercase drive
# letters normalized first), so these cases pass on Linux, macOS and git-bash.
slug_of() {
  p="$1"
  case "$p" in /[A-Za-z]/*) dl=$(printf '%s' "$p" | cut -c2 | tr 'a-z' 'A-Z'); p="$dl:${p#/?}";; esac
  case "$p" in [a-z]:*) dl=$(printf '%s' "$p" | cut -c1 | tr 'a-z' 'A-Z'); p="$dl${p#?}";; esac
  printf '%s' "$p" | sed 's/[^A-Za-z0-9]/-/g'
}
plant_overdue() {  # $1 = memory dir, $2 = file name
  mkdir -p "$1"
  cp "$root/tests/fixture-memory-baseline/project_build_pipeline_status.md" "$1/$2"
}
warn_for() {  # $1 = file name -> expected one-file warning
  printf '%s\n%s\n%s' \
    '[memory-tools] 1 memory file(s) past their review-after date - treat their contents as unverified:' \
    "- $1 (review-after 2026-07-01)" \
    'Ask the user to run /checkup to refresh, mark historical, or forget them; do not edit memory files yourself.'
}

# Case 11: launched from a subfolder of a git repo -> the repo root's slug is
# used (all worktrees and subfolders share one memory folder).
rm -rf "$scratch"; mkdir -p "$scratch/repo/sub"
git -C "$scratch/repo" init -q
gitroot=$(git -C "$scratch/repo" rev-parse --show-toplevel)
rootmem="$scratch/.claude/projects/$(slug_of "$gitroot")/memory"
plant_overdue "$rootmem" "root_status.md"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "git root slug used from a subfolder" "$(warn_for root_status.md)" "$out"
check "exit 0 (git root)" "0" "$rc"

# Case 12: no folder for the git root -> legacy launch-folder slug still works.
rm -rf "$rootmem"
submem="$scratch/.claude/projects/$(slug_of "$scratch/repo/sub")/memory"
plant_overdue "$submem" "sub_status.md"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "legacy launch-folder slug fallback" "$(warn_for sub_status.md)" "$out"
check "exit 0 (legacy fallback)" "0" "$rc"

# Case 13: autoMemoryDirectory in user settings wins over the project folder.
plant_overdue "$scratch/custom-mem" "custom_status.md"
mkdir -p "$scratch/.claude"
printf '{\n  "autoMemoryDirectory": "~/custom-mem"\n}\n' > "$scratch/.claude/settings.json"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "autoMemoryDirectory (user settings, ~/ form)" "$(warn_for custom_status.md)" "$out"
check "exit 0 (user setting)" "0" "$rc"

# Case 14: project .claude/settings.local.json beats user settings.
plant_overdue "$scratch/local-mem" "local_status.md"
mkdir -p "$scratch/repo/.claude"
printf '{"autoMemoryDirectory": "%s"}\n' "$scratch/local-mem" > "$scratch/repo/.claude/settings.local.json"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$scratch/repo" sh "$root/hooks/check-stale"); rc=$?
check "project settings.local.json beats user settings" "$(warn_for local_status.md)" "$out"
check "exit 0 (local setting)" "0" "$rc"

# Case 15: autoMemoryDirectory pointing at a missing folder is ignored.
printf '{"autoMemoryDirectory": "%s"}\n' "$scratch/does-not-exist" > "$scratch/repo/.claude/settings.local.json"
rm "$scratch/.claude/settings.json"
out=$(HOME="$scratch" CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "missing autoMemoryDirectory falls through" "$(warn_for sub_status.md)" "$out"
check "exit 0 (missing setting dir)" "0" "$rc"
rm "$scratch/repo/.claude/settings.local.json"

# Case 16: CLAUDE_CONFIG_DIR replaces ~/.claude.
cfgdir="$scratch/cfg"
plant_overdue "$cfgdir/projects/$(slug_of "$gitroot")/memory" "cfg_status.md"
out=$(HOME="$scratch" CLAUDE_CONFIG_DIR="$cfgdir" CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "CLAUDE_CONFIG_DIR respected" "$(warn_for cfg_status.md)" "$out"
check "exit 0 (config dir)" "0" "$rc"

# Case 17: CLAUDE_CODE_PROJECT_DIR_NAME beside CLAUDE_CONFIG_DIR names the folder.
plant_overdue "$cfgdir/projects/shared-name/memory" "named_status.md"
out=$(HOME="$scratch" CLAUDE_CONFIG_DIR="$cfgdir" CLAUDE_CODE_PROJECT_DIR_NAME=shared-name CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "CLAUDE_CODE_PROJECT_DIR_NAME respected" "$(warn_for named_status.md)" "$out"
check "exit 0 (project dir name)" "0" "$rc"

# Case 18: CLAUDE_CODE_PROJECT_DIR_NAME without CLAUDE_CONFIG_DIR is ignored
# (the docs require both), so the git-root slug under ~/.claude is used.
plant_overdue "$rootmem" "root_status.md"
out=$(HOME="$scratch" CLAUDE_CODE_PROJECT_DIR_NAME=shared-name CLAUDE_PROJECT_DIR="$scratch/repo/sub" sh "$root/hooks/check-stale"); rc=$?
check "project dir name ignored without config dir" "$(warn_for root_status.md)" "$out"
check "exit 0 (name without config dir)" "0" "$rc"

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES ABOVE"; fi
exit "$fail"
