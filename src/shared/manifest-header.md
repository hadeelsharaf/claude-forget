# Trash manifest
Manifest format: 2

Restore recipe: run /restore and pick an entry. By hand: for each entry below,
move the `.trashed` file back up one level into `memory/`, drop the `.trashed`
suffix, delete every line under "Added", then paste every line in that entry's
"Removed verbatim" and "Original verbatim" blocks back where it came from.
Those blocks are the only copy of that text. Anchors: "(at line N)" on a
Removed or Original block is the line the first pasted line must land on,
counted in the file as it was BEFORE the entry; on an Added block it is the
line the first added line sits on AFTER the entry. Delete Added lines first
(highest N first), then paste blocks in ascending N. Blocks without an anchor
were written by format 1 and are placed by hand. When several entries touch
the same file, restore newest-first. When done, add a line `RESTORED <date>`
directly under the entry heading.
