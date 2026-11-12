#!/bin/sh
# Automated test for scripts/memory-scan and scripts/build-skills.sh.
# Run from the repo root:
#   sh tests/run-scan-test.sh
# Exits non-zero on any FAIL. Scratch lives in tests/scratch/ (gitignored).

root=$(pwd)
scan="$root/scripts/memory-scan"
scratch="$root/tests/scratch/scan"
rm -rf "$scratch"; mkdir -p "$scratch"
tab=$(printf '\t')

fail=0
check() {
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else
    echo "FAIL: $1"; echo "  expected: [$2]"; echo "  actual:   [$3]"; fail=1
  fi
}

# --- stamps ------------------------------------------------------------------

# Case 1: baseline fixture. One tag per topic file; MEMORY.md never listed;
# the body-text stamp in feedback_release_notes_style.md does not count; a
# file planted in .trash/ is never scanned.
mem="$scratch/baseline"; mkdir -p "$mem/.trash"
cp "$root/tests/fixture-memory-baseline/"*.md "$mem/"
cp "$root/tests/fixture-memory-baseline/project_build_pipeline_status.md" "$mem/.trash/planted.md"
expected="UNSTAMPED${tab}feedback_csv_quoting_lesson.md
UNSTAMPED${tab}feedback_release_notes_style.md
OVERDUE${tab}project_build_pipeline_status.md${tab}2026-07-01
BADSTAMP${tab}project_ci_flakiness_status.md${tab}07/2026
UNSTAMPED${tab}project_dashboard_redesign.md
UNSTAMPED${tab}project_login_outage_status.md
STAMPED${tab}project_release_checklist_status.md${tab}2099-01-01
UNSTAMPED${tab}project_widget_exporter_plan.md
UNSTAMPED${tab}project_widget_exporter_poc_results.md
UNSTAMPED${tab}reference_ci_dashboard_url.md"
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" stamps "$mem"); rc=$?
check "stamps: baseline tags" "$expected" "$out"
check "stamps: exit 0" "0" "$rc"

# Case 2: a stamp dated exactly today is STAMPED, the day after it is OVERDUE.
out=$(MEMORY_SCAN_TODAY=2026-07-01 sh "$scan" stamps "$mem" | grep build_pipeline)
check "stamps: exactly today is not overdue" "STAMPED${tab}project_build_pipeline_status.md${tab}2026-07-01" "$out"
out=$(MEMORY_SCAN_TODAY=2026-07-02 sh "$scan" stamps "$mem" | grep build_pipeline)
check "stamps: one day later is overdue" "OVERDUE${tab}project_build_pipeline_status.md${tab}2026-07-01" "$out"

# Case 3: CRLF line endings and a stamp nested under metadata: (not top-level).
mem="$scratch/odd"; mkdir -p "$mem"
printf '%s\r\n' '---' 'name: crlf_note' 'review-after: 2020-02-02' '---' '' 'body' > "$mem/crlf_note.md"
printf '%s\n' '---' 'name: nested_note' 'metadata:' '  review-after: 2020-02-02' '---' 'body' > "$mem/nested_note.md"
printf '%s\n' 'no frontmatter here' 'review-after: 2020-02-02' > "$mem/plain_note.md"
expected="OVERDUE${tab}crlf_note.md${tab}2020-02-02
UNSTAMPED${tab}nested_note.md
UNSTAMPED${tab}plain_note.md"
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" stamps "$mem")
check "stamps: CRLF read, nested and body stamps ignored" "$expected" "$out"

# Case 3b: a well-formed stamp wins over a malformed one in the same file,
# whichever comes first; a malformed one alone is BADSTAMP.
mem="$scratch/two"; mkdir -p "$mem"
printf '%s\n' '---' 'review-after: 07/2026' 'review-after: 2020-02-02' '---' 'x' > "$mem/bad_then_good.md"
printf '%s\n' '---' 'review-after: 2020-02-02' 'review-after: soon' '---' 'x' > "$mem/good_then_bad.md"
printf '%s\n' '---' 'review-after: soon' 'review-after: later' '---' 'x' > "$mem/only_bad.md"
expected="OVERDUE${tab}bad_then_good.md${tab}2020-02-02
OVERDUE${tab}good_then_bad.md${tab}2020-02-02
BADSTAMP${tab}only_bad.md${tab}soon"
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" stamps "$mem")
check "stamps: well-formed stamp wins over a malformed one" "$expected" "$out"

# Case 4: a folder with no .md files prints nothing; a missing folder is exit 2.
mkdir -p "$scratch/empty"
out=$(sh "$scan" stamps "$scratch/empty" 2>&1); rc=$?
check "stamps: empty folder silent" "" "$out"
check "stamps: empty folder exit 0" "0" "$rc"
sh "$scan" stamps "$scratch/no-such-folder" >/dev/null 2>&1; rc=$?
check "missing folder exit 2" "2" "$rc"
sh "$scan" index "$scratch/empty" >/dev/null 2>&1; rc=$?
check "index: no MEMORY.md exit 2" "2" "$rc"

# --- index -------------------------------------------------------------------

# Case 5: baseline fixture is healthy. The size line is checked by its line
# count only: the byte count differs on a CRLF checkout.
expected='today: 2026-11-05
status: OK (5%)
orphans: 0
dangling: 0'
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" index "$scratch/baseline"); rc=$?
check "index: baseline healthy" "$expected" "$(printf '%s\n' "$out" | sed '2d')"
check "index: baseline line count" "index: 10 lines" "$(printf '%s\n' "$out" | sed -n '2p' | cut -d, -f1)"
check "index: exit 0" "0" "$rc"

# Case 6: the 210-line fixture of TESTING.md Part 3b: over the line limit,
# four dangling lines, two orphans.
sh "$root/tests/make-index-fixture.sh" "$scratch/full" >/dev/null
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" index "$scratch/full" | sed '2d')
expected='today: 2026-11-05
status: OVER LIMIT
never-load: lines 201 to 210
orphans: 2
orphan: orphan_a.md
orphan: orphan_b.md
dangling: 4
dangling-line: 207 -> topic_207.md
dangling-line: 208 -> topic_208.md
dangling-line: 209 -> topic_209.md
dangling-line: 210 -> topic_210.md'
check "index: over limit, dangling, orphans" "$expected" "$out"
out=$(sh "$scan" index "$scratch/full" | sed -n '2p' | cut -d, -f1)
check "index: line count" "index: 210 lines" "$out"

# Case 7: byte limit hit before the line limit; [[slug]] links resolve through
# the name: frontmatter; a dangling [[slug]]; web links are ignored; a file
# reached only by slug is not an orphan.
mem="$scratch/bytes"; mkdir -p "$mem"
printf '%s\n' '---' 'name: alpha_slug' '---' 'a' > "$mem/alpha_file.md"
printf '%s\n' '---' 'name: beta' '---' 'b' > "$mem/beta.md"
printf '%s\n' '---' 'name: lonely' '---' 'c' > "$mem/lonely.md"
{
  printf '%s\n' '- [[alpha_slug]] — reached by slug'
  printf '%s\n' '- [Beta](beta.md) and [docs](https://example.com/x.md)'
  printf '%s\n' '- [[gone_slug]] — target missing'
  pad=$(printf '%0300d' 0)
  i=0; while [ "$i" -lt 100 ]; do printf -- '- filler %s\n' "$pad"; i=$((i + 1)); done
} > "$mem/MEMORY.md"
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" index "$mem" | sed '2d')
expected='today: 2026-11-05
status: OVER LIMIT
never-load: lines 86 to 103
orphans: 1
orphan: lonely.md
dangling: 1
dangling-line: 3 -> [[gone_slug]]'
check "index: byte limit, slugs, web links" "$expected" "$out"

# Case 8: NEAR LIMIT at 80% of the line limit.
mem="$scratch/near"; mkdir -p "$mem"
i=0; while [ "$i" -lt 160 ]; do echo "- note $i"; i=$((i + 1)); done > "$mem/MEMORY.md"
out=$(sh "$scan" index "$mem" | sed -n '3p')
check "index: near limit at 80%" "status: NEAR LIMIT (80%)" "$out"

# Case 8b: an empty topic file exists (not dangling, not an orphan when
# linked); a link to MEMORY.md itself is ignored; a link with a title or in
# <angle brackets> still resolves.
mem="$scratch/forms"; mkdir -p "$mem"
: > "$mem/empty_note.md"
echo 'titled' > "$mem/titled.md"
echo 'angled' > "$mem/angled.md"
: > "$mem/empty_orphan.md"
printf '%s\n' '- [Empty](empty_note.md) — zero bytes' \
  '- [Self](MEMORY.md) and [T](titled.md "a title") and [A](<angled.md>)' > "$mem/MEMORY.md"
out=$(MEMORY_SCAN_TODAY=2026-11-05 sh "$scan" index "$mem" | sed -n '4,$p')
expected='orphans: 1
orphan: empty_orphan.md
dangling: 0'
check "index: empty files, self-link, titled and angled links" "$expected" "$out"

# Case 8c: exactly at the byte limit with no trailing newline is not over.
mem="$scratch/exact"; mkdir -p "$mem"
awk 'BEGIN { for (i = 1; i < 100; i++) { printf "%0255d\n", 0 } printf "%0256d", 0 }' > "$mem/MEMORY.md"
out=$(sh "$scan" index "$mem" | sed -n '2,3p')
expected='index: 100 lines, 25.0 KB (25600 bytes) of 200 lines / 25 KB
status: NEAR LIMIT (100%)'
check "index: exactly at the byte limit, no trailing newline" "$expected" "$out"

# --- generated skills --------------------------------------------------------

# Case 9: skills/*/SKILL.md match src/skills + src/shared.
out=$(sh "$root/scripts/build-skills.sh" --check 2>&1); rc=$?
check "generated skills up to date" "skills up to date" "$out"
check "build --check exit 0" "0" "$rc"

# Case 9b: a CRLF copy of src/ and skills/ (a Windows checkout) is still up
# to date, and a mistyped flag is refused instead of rewriting files.
crlf="$scratch/crlf"; mkdir -p "$crlf/scripts"
cp -r "$root/src" "$root/skills" "$crlf/"
cp "$root/scripts/build-skills.sh" "$crlf/scripts/"
for f in "$crlf"/src/*/*.md "$crlf"/skills/*/SKILL.md; do
  tr -d '\r' < "$f" | sed "s/\$/$(printf '\r')/" > "$f.tmp" && mv "$f.tmp" "$f"
done
out=$(sh "$crlf/scripts/build-skills.sh" --check 2>&1); rc=$?
check "build --check on a CRLF checkout" "skills up to date" "$out"
check "build --check on a CRLF checkout exit 0" "0" "$rc"
sh "$root/scripts/build-skills.sh" --chek >/dev/null 2>&1; rc=$?
check "build refuses an unknown flag" "2" "$rc"

# Case 10: no template leaves an @include line behind, and every shared
# block is used by at least two skills (otherwise it should not be shared).
out=$(grep -l '^@include ' "$root"/skills/*/SKILL.md 2>/dev/null)
check "no @include left in built skills" "" "$out"
for part in "$root"/src/shared/*.md; do
  name=$(basename "$part" .md)
  n=$(grep -l "^@include $name[[:space:]]*\$" "$root"/src/skills/*.md | wc -l | tr -d ' ')
  [ "$n" -ge 2 ] && n="2+"
  check "shared block $name used by two or more skills" "2+" "$n"
done

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES ABOVE"; fi
exit "$fail"
