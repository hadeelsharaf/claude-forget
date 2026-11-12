Anchor rule: every "Removed verbatim", "Original verbatim" and "Added" label
carries "(at line N)". For Removed and Original blocks, N is the 1-based line
of the block's first line in the file BEFORE any change of this entry; read
those numbers (for example `grep -n` or `nl`) before you touch the file. For
Added blocks, N is the line the first added line sits on AFTER all of this
entry's changes to that file; read it once the file is final. One block per
contiguous run of lines: lines that are not next to each other get separate
blocks, listed in ascending N. A block with both Removed and Added at the
same N is a replacement. If the manifest already exists without the
`Manifest format: 2` line, insert that line directly under `# Trash manifest`.

Recording rule: prefix every recorded line with exactly "> ". A blank line is
recorded as a bare ">". A line that itself starts with ">" is recorded as
"> >" plus the rest of the line. To restore, strip exactly one leading "> "
(or the bare ">") from every recorded line.
