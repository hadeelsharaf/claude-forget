#!/bin/sh
# Static checks for text that must stay identical across files. Run from the
# repo root:
#   sh tests/check-consistency.sh
# Needs jq. Exits non-zero on any FAIL.
# shellcheck disable=SC2015  # pass() always succeeds, so A && pass || bad is safe

command -v jq >/dev/null 2>&1 || { echo "FAIL: jq not found (this check needs it)"; exit 1; }

fail=0
pass() { echo "PASS: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

# Print the lines of file $1 from the first line matching $2 through the
# first later line matching $3. CRs are stripped so CRLF checkouts compare
# equal; patterns go through ENVIRON so awk -v does not eat their backslashes.
block() {
  S="$2" E="$3" awk '
    { sub(/\r$/,"") }
    !on && $0 ~ ENVIRON["S"] { on=1 }
    on { print }
    on && $0 ~ ENVIRON["E"] { exit }' "$1"
}

same() {
  a=$(block "$2" "$4" "$5"); b=$(block "$3" "$4" "$5")
  if [ -z "$a" ]; then bad "$1 (missing in $2)"
  elif [ -z "$b" ]; then bad "$1 (missing in $3)"
  elif [ "$a" = "$b" ]; then pass "$1"
  else bad "$1 ($2 and $3 differ)"; fi
}

# 1. JSON manifests parse, and the two plugin descriptions match.
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  if jq empty "$f" 2>/dev/null; then pass "valid JSON: $f"; else bad "valid JSON: $f"; fi
done
p_name=$(jq -r .name .claude-plugin/plugin.json)
m_name=$(jq -r '.plugins[0].name' .claude-plugin/marketplace.json)
[ "$p_name" = "$m_name" ] && pass "plugin name matches marketplace" \
  || bad "plugin name matches marketplace ($p_name vs $m_name)"
p_desc=$(jq -r .description .claude-plugin/plugin.json)
m_desc=$(jq -r '.plugins[0].description' .claude-plugin/marketplace.json)
[ "$p_desc" = "$m_desc" ] && pass "plugin description matches marketplace" \
  || bad "plugin description matches marketplace"

# 2. The version in plugin.json has a CHANGELOG entry.
ver=$(jq -r .version .claude-plugin/plugin.json)
awk -v v="## $ver " 'index($0, v) == 1 { f=1 } END { exit !f }' CHANGELOG.md && pass "CHANGELOG has $ver" \
  || bad "CHANGELOG has an entry for $ver"

# 3. Every skill's frontmatter name matches its folder and has a description.
for f in skills/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  n=$(awk '{sub(/\r$/,"")} NR>1 && /^---/ {exit} /^name:/ {sub(/^name:[[:space:]]*/,""); print}' "$f")
  [ "$n" = "$d" ] && pass "skill name: $d" || bad "skill name: $f says '$n'"
  grep -q '^description: .' "$f" && pass "skill description: $d" \
    || bad "skill description: $d"
done

# 4. Every hook command points at a script that exists.
nhooks=0
for s in $(jq -r '.. | .command? // empty' hooks/hooks.json \
           | sed -n 's/.*run-hook\.cmd" *\([^ ]*\).*/\1/p'); do
  nhooks=$((nhooks + 1))
  [ -f "hooks/$s" ] && pass "hook script exists: $s" || bad "hook script exists: $s"
done
[ "$nhooks" -gt 0 ] || bad "no run-hook.cmd script found in hooks/hooks.json"

# 5. Text shared by /forget and /checkup must match word for word, since both
#    write the same .trash/TRASH.md manifest.
F=skills/forget/SKILL.md; C=skills/checkup/SKILL.md
same "TRASH.md header" "$F" "$C" '^# Trash manifest$' 'restore newest-first\.$'
same "recording rule" "$F" "$C" '^Recording rule:' 'from every recorded line\.$'
same "Locate step" "$F" "$C" '^## Step 2 — Locate$' 'no memories" and stop\.$'

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES ABOVE"; fi
exit "$fail"
