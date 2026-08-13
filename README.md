# claude-forget

Memory lifecycle for Claude Code auto-memory: /forget buries what you discard, /checkup finds what went stale, /fresh works memory-free, and /recall loads the minimum back.

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

No memory file is ever deleted. Any text cut from a file that stays behind is
copied verbatim into `.trash/TRASH.md` before the cut. Restore = move the file
back, drop the `.trashed` suffix, and paste the manifest's verbatim block back.

Note on the mechanism: only `MEMORY.md` auto-loads each session, and topic
files are read on demand. The `.md.trashed` rename is what guarantees trashed
memories stay out of future sessions; the `.claudeignore` entry is
documentation of intent, not the enforcement.

### /checkup [topic]

Find status memories that went stale, and fix them with one confirm. It:

1. Sweeps the current project's auto-memories two ways: files whose
   `review-after: YYYY-MM-DD` stamp is past, and unstamped notes that read
   like a current status (open bugs, checkpoints, in-progress work).
2. Shows one table; you pick per file: REFRESH (you state what is true now),
   HISTORICAL (one banner line marks it as a record of the past), STAMP (add
   a review date), FORGET (handed off to /forget), or SKIP.
3. Copies every line it replaces verbatim into `.trash/TRASH.md` before the
   edit, and records every line it adds — the same manifest /forget uses.
   Nothing is ever lost, and every checkup can be undone.

The stamp convention: a perishable memory carries a top-level frontmatter
line `review-after: YYYY-MM-DD`. Facts, lessons, and references never need
one.

### The freshness hook

The plugin ships a SessionStart hook. At the start of each session it checks
the current project's memory folder for `review-after` stamps that are past
due and, only then, prints a short warning. That warning also lands in the
agent's context, so the agent itself stops trusting the stale note. No stale
stamps means no output at all. The hook never edits or blocks anything, and
it stays silent in projects that have no memory folder. If Claude Code ever
changes its internal project-folder naming, the hook finds nothing and stays
silent; /checkup itself still works.

### /fresh — work memory-free

`/fresh [task]` puts the current session under memory quarantine: the agent
commits to acting as if the project had no auto-memory — no citing it, no
reading or writing memory files, and every subagent dispatched carries the
same instruction.

Honesty note: this is instruction-level isolation. Memory text already loaded
into the session's context is not removed; the agent commits to not using it.
For hard isolation Claude Code offers official off-switches (the
`autoMemoryEnabled` setting, the `CLAUDE_CODE_DISABLE_AUTO_MEMORY` environment
variable, and the in-session `/memory` toggle) — manual alternatives, not
part of this skill.

Two doors back: `/recall <item>` (below) loads one named topic read-only, or
say "end fresh mode" to lift the quarantine entirely.

### /recall — load the minimum back

`/recall <item>` is the read-only pull: it lists matching memory index
entries first (with word counts, and a STALE tag when a file is past its
`review-after` date), then opens exactly ONE topic file you name. It never
writes, moves, or deletes anything.

Together the four skills cover the memory lifecycle: `/fresh` starts at zero,
`/recall` pulls the minimum back, `/checkup` reviews what has gone stale, and
`/forget` retires what is finished.

## What it does NOT cover

- CLAUDE.md / CLAUDE.local.md instruction files
- MCP memory stores (for example `.swarm/memory.db`)
- Session transcripts
- claude.ai web memory

## Install

```
/plugin marketplace add hadeelsharaf/claude-forget
/plugin install memory-tools@claude-forget
```

The same commands work from a terminal: `claude plugin marketplace add ...`
and `claude plugin install ...`.

Already installed? A second install fails with "is already installed
globally". That is expected — the plugin is on your machine. To get the
latest version instead:

```
claude plugin marketplace update claude-forget
claude plugin update memory-tools@claude-forget
```

(restart Claude Code to apply). To remove it:
`claude plugin uninstall memory-tools@claude-forget`.

For local testing from a clone:

```
/plugin marketplace add D:\path\to\claude-forget
/plugin install memory-tools@claude-forget
```

## Testing

See `tests/TESTING.md` for the fixture round-trip procedures (forget,
checkup, fresh, recall, and the scripted hook test `tests/run-hook-test.sh`).
