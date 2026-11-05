#!/bin/sh
# Builds the "index full" fixture for the /checkup index-health test (Part 3b)
# at tests/scratch/memory-index-full/ (gitignored). Deterministic:
#   MEMORY.md: 210 index lines -> lines 201-210 never load (limit 200)
#     lines 1-206   point to real topic files topic_001.md .. topic_206.md
#     lines 207-210 point to missing files      -> 4 DANGLING lines
#   orphan_a.md, orphan_b.md exist with no index line -> 2 orphans
# All topic files are references (not perishable), so the stamp and judgment
# passes find nothing and only the index section is offered at the gate.
set -e
# Optional first argument: target directory (used by the eval scaffold).
root=$(cd "$(dirname "$0")/.." && pwd)
dir="${1:-$root/tests/scratch/memory-index-full}"
rm -rf "$dir"; mkdir -p "$dir"
i=1
while [ "$i" -le 206 ]; do
  n=$(printf '%03d' "$i")
  printf '%s\n' '---' "name: topic_$n" "description: reference note $n" \
    'metadata:' '  type: reference' '---' '' "Reference note $n. Static fact, no status." \
    > "$dir/topic_$n.md"
  printf -- '- [Topic %s](topic_%s.md) — reference note %s\n' "$n" "$n" "$n" >> "$dir/MEMORY.md"
  i=$((i + 1))
done
for n in 207 208 209 210; do
  printf -- '- [Topic %s](topic_%s.md) — reference note %s (file missing)\n' "$n" "$n" "$n" >> "$dir/MEMORY.md"
done
for o in a b; do
  printf '%s\n' '---' "name: orphan_$o" "description: orphan reference $o" \
    'metadata:' '  type: reference' '---' '' "Orphan reference $o: no index line points here." \
    > "$dir/orphan_$o.md"
done
echo "fixture at $dir: $(wc -l < "$dir/MEMORY.md") index lines, $(wc -c < "$dir/MEMORY.md") bytes, $(ls "$dir" | wc -l) files"
