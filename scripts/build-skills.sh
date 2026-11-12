#!/bin/sh
# Builds skills/<name>/SKILL.md from src/skills/<name>.md.
#
# A template line that reads exactly "@include <name>" is replaced by the
# content of src/shared/<name>.md. Everything else is copied as is. Skills
# without a template in src/skills/ are hand-written and are not touched.
#
#   sh scripts/build-skills.sh           rewrite the generated SKILL.md files
#   sh scripts/build-skills.sh --check   change nothing; exit 1 when a
#                                        generated file is out of date
#
# Edit src/, never the generated files: forget, restore and checkup.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
mode="${1:-write}"
tmp="$root/tests/scratch/build-skills.tmp"
mkdir -p "$root/tests/scratch"
stale=0

render() {
  awk -v dir="$root/src/shared" '
    /^@include [a-z0-9-]+[[:space:]]*$/ {
      f = dir "/" $2 ".md"; n = 0
      while ((getline line < f) > 0) { print line; n++ }
      close(f)
      if (n == 0) { printf "build-skills: missing or empty partial %s\n", f > "/dev/stderr"; bad = 1 }
      next
    }
    { print }
    END { exit bad }' "$1"
}

for tpl in "$root"/src/skills/*.md; do
  name=$(basename "$tpl" .md)
  out="$root/skills/$name/SKILL.md"
  render "$tpl" > "$tmp"
  if [ -f "$out" ] && cmp -s "$tmp" "$out"; then
    continue
  fi
  if [ "$mode" = "--check" ]; then
    echo "STALE: skills/$name/SKILL.md differs from src/skills/$name.md + src/shared/"
    stale=1
  else
    mkdir -p "$root/skills/$name"
    cp "$tmp" "$out"
    echo "built skills/$name/SKILL.md"
  fi
done
rm -f "$tmp"

if [ "$stale" -ne 0 ]; then
  echo "Edit src/skills/ or src/shared/, then run: sh scripts/build-skills.sh"
  exit 1
fi
[ "$mode" = "--check" ] && echo "skills up to date"
exit 0
