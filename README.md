# claude-memory-tools

Memory hygiene skills for Claude Code auto-memory.

## Skills

### /forget <concern>

Force-forget a discarded effort, reversibly. It:

1. Finds the current project's auto-memories about the concern (index scan +
   keyword grep + semantic judgment).
2. Shows you the list — one confirm.
3. Moves whole-match files to `memory/.trash/` and renames them
   `name.md -> name.md.trashed`; partial-match files get only the matching
   lines removed.
4. Records everything in `.trash/TRASH.md` (with a restore recipe) and keeps
   `.trash/` listed in `memory/.claudeignore`.
5. Re-indexes `MEMORY.md` and cleans dangling `[[links]]`.

Nothing is ever deleted. Restore = move the file back, drop the `.trashed`
suffix, re-add its index line.

Note on the mechanism: only `MEMORY.md` auto-loads each session, and topic
files are read on demand. The `.md.trashed` rename is what guarantees trashed
memories stay out of future sessions; the `.claudeignore` entry is
documentation of intent, not the enforcement.

## What it does NOT cover

- CLAUDE.md / CLAUDE.local.md instruction files
- MCP memory stores (for example `.swarm/memory.db`)
- Session transcripts
- claude.ai web memory

## Install

```
/plugin marketplace add OWNER/claude-memory-tools
/plugin install memory-tools@claude-memory-tools
```

For local testing before publishing:

```
/plugin marketplace add D:\path\to\claude-memory-tools
/plugin install memory-tools@claude-memory-tools
```

## Testing

See `tests/TESTING.md` for the fixture round-trip procedure.
