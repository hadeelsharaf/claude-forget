#!/bin/sh
# SessionStart hook: warn when the current project's auto-memories are past
# their review-after date. Read-only; always exits 0; silent when clean.

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
# Normalize a git-bash /x/... path to the X:/... form Claude Code slugs.
case "$dir" in
  /[A-Za-z]/*) dl=$(printf '%s' "$dir" | cut -c2 | tr 'a-z' 'A-Z')
               dir="$dl:${dir#/?}" ;;
esac
case "$dir" in
  [a-z]:*) dl=$(printf '%s' "$dir" | cut -c1 | tr 'a-z' 'A-Z')
           dir="$dl${dir#?}" ;;
esac
slug=$(printf '%s' "$dir" | sed 's/[^A-Za-z0-9]/-/g')
mem="$HOME/.claude/projects/$slug/memory"
[ -d "$mem" ] || exit 0

today=$(date +%Y%m%d) || exit 0
found=''
count=0
for f in "$mem"/*.md; do
  [ -f "$f" ] || continue
  d=$(sed -n 's/^review-after:[[:space:]]*//p' "$f" | head -n 1 | tr -d '[:space:]')
  case "$d" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) continue ;;
  esac
  if [ "$(printf '%s' "$d" | tr -d '-')" -lt "$today" ]; then
    found="$found- $(basename "$f") (review-after $d)
"
    count=$((count + 1))
  fi
done
[ "$count" -gt 0 ] || exit 0
printf '[memory-tools] %s memory file(s) past their review-after date - treat their contents as unverified:\n' "$count"
printf '%s' "$found"
printf 'Run /checkup to refresh, archive, or forget them.\n'
exit 0
