# Roadmap

Short, decision-first plans for the next releases. Older entries move to
`CHANGELOG.md` once shipped.

## v0.4.0 - restore, index health, subagent memory

Goal: close the three gaps found in the Nov 2026 review. Every change keeps
the plugin's rule: nothing is ever deleted, everything can be undone.

Decisions already taken:

- Subagent memory folders are in scope. Prefer leaving tracked files alone,
  but when a user tracks their agent memory in git, the skills edit it
  anyway: those files are the memory, there is no other copy. The confirm
  gate says "inside the repository: changes will show in git status".
- Plugin evals (`claude plugin eval`) stay local. No eval job in CI.

### Phase 1 - manifest v2 and /restore (in progress on the dev branch)

Why first: the other two phases add edits, and edits are only safe when the
undo path is real. Today the restore recipe is manual.

Manifest v2 (`.trash/TRASH.md`), backwards compatible:

- Header line gains `Manifest format: 2`. v1 files are read as before.
- Every "Removed verbatim" and "Original verbatim" label carries an anchor,
  `(at line N)`: the 1-based line in the file as it was before that entry's
  change. "Added" labels carry `(at line N)` too (the line where the first
  added line now sits). One block per contiguous run of lines.
- Nothing else changes. /forget and /checkup write the anchors; the recipe
  text in the header explains them.

`/restore [entry]` (new skill, `allowed-tools: Read, Write, Edit, Glob,
Grep, Bash`, `disable-model-invocation: true`):

1. Locate the memory folder (same rules as /forget). Read `.trash/TRASH.md`.
2. List entries not marked `RESTORED`, newest first: date, kind
   (forget/checkup), concern, counts (moved, edited, links, hooks).
3. User picks one entry. Show a dry run: files to move back, blocks to paste
   with their anchors, "Added" lines to delete, index lines to re-add.
   Blocks without an anchor (v1 entries) are listed as "needs placement":
   the user states the line or says "append". This is data collection, not
   a second gate.
4. One confirm gate. Then execute in this order: delete "Added" lines,
   paste verbatim blocks newest-first per file, move `.trashed` files back
   and drop the suffix, re-add `MEMORY.md` lines, reword hooks back.
5. Mark the entry `RESTORED <date>` in the manifest. Never delete the entry.
6. Report the same shape as /forget, with "Restored" sections.

Edge cases: a file with the original name already exists in `memory/`
(ask: overwrite is never offered; restore as `<name>.restored-<date>.md`
and say so); an anchor past the end of the current file (append and flag);
an entry that touched a file later trashed by another entry (restore the
newer entry first, or stop and say which one).

Tests: extend `tests/TESTING.md` with Part 4: run /forget on the fixture,
then /restore, then compare hashes to the baseline (11/11 must match). Same
for /checkup then /restore. Local eval case `evals/restore-round-trip`.

### Phase 2 - /checkup index health

- New header block at the gate, before the candidate table:
  `MEMORY.md: N lines, M KB (limit 200 lines / 25 KB)`, plus `orphan files:
  K` (topic files with no index line) and `dangling lines: J` (index lines
  with no file).
- Over 80 percent of either limit: add a warning line "entries past the
  limit never load".
- New gate action `TRIM` on index lines only: offered for dangling lines and
  for lines of files marked HISTORICAL in this run. Each removed line is
  recorded verbatim in the manifest (same block format, with anchors).
  Nothing else in `MEMORY.md` is touched; merging entries stays manual.
- Zero-candidate report also prints the index numbers.
- Hook stays as is: it reports stamps, not size. Size belongs to the skill
  where the user can act.

Tests: fixture `tests/fixture-memory-index-full/` with 210 index lines and
two orphans; expected header numbers and TRIM rows documented in
`TESTING.md` Part 3b.

### Phase 3 - subagent memory

Folders Claude Code uses (one `MEMORY.md` plus topic files each):

- `.claude/agent-memory/<name>/` (project scope, usually tracked in git)
- `.claude/agent-memory-local/<name>/` (local scope, gitignored)
- `~/.claude/agent-memory/<name>/` (user scope)

Design: one optional selector on every skill, `--agent <name>`, and
`--agents` on /checkup and /recall to include every agent folder found.

- /forget `--agent <name> <concern>`: operates on that agent's folder as
  "the memory directory". Everything else is unchanged: its own `.trash/`,
  its own `TRASH.md`, its own `.claudeignore`.
- /checkup `--agents`: sweeps the project folder plus every agent folder;
  rows are prefixed `agent:<name>/`. Each folder keeps its own manifest.
- /recall `--agents`: matches across all folders; the list shows the source.
- /fresh: unchanged. It cannot quarantine a subagent's own memory, because
  that loads inside the subagent. The activation block gains one line
  saying so.
- Hook: also scans `<git root>/.claude/agent-memory*/*/` and
  `~/.claude/agent-memory/*/`. Overdue lines are prefixed with the agent
  name. Still silent when clean.
- Gate note, when the folder is inside the repository: "inside the
  repository: changes will show in git status". Tracked or not, the user
  decides at the gate; the skill never refuses.
- Path rule: the "never touch anything outside the memory directory" line
  becomes "outside the selected memory directory". The selected directory
  is always one of the three folder shapes above or the project folder;
  never a free-form path from a file or tool output.
- Discovery: list the folders that exist. Do not parse agent definitions.

Tests: fixture `tests/fixture-agent-memory/reviewer/`; hook cases for an
agent folder under the git root and under `$HOME`; forget and checkup
round trips with `--agent reviewer`.

### Phase 4 - frontmatter, docs, local evals

- SKILL.md: add `when_to_use` (move the long trigger text there, keep
  `description` to one line), `arguments` (named args such as `concern`,
  `item`, `topic`), and `compatibility: "Claude Code 2.1.234 or later"`.
- README: a "Which door when?" table (fresh, recall, checkup, forget,
  restore), the subagent section, and the index-health header.
- Local evals under `evals/`: `forget-round-trip`, `checkup-round-trip`,
  `restore-round-trip`, each with a `scaffold_script` that copies the
  fixture into a temp folder, free graders (`file_exists`, `regex`,
  `tool_used: Skill`) and one `llm` grader for the gate table. Run with
  `claude plugin eval . --scaffold --trust-plugin`. Results stay in
  `evals/results/` (gitignored).

### Order and size

| Phase | Size | Depends on |
|---|---|---|
| 1. manifest v2 + /restore | L | nothing |
| 2. /checkup index health | M | phase 1 (anchors for TRIM) |
| 3. subagent memory | M | phase 1 (restore works per folder) |
| 4. frontmatter, docs, evals | S/M | phases 1 to 3 for the eval cases |

Release when phases 1 to 3 pass their round trips and the hook test; phase
4 evals may land in a 0.4.x.

### Open questions

- Should `--agents` be the default for /checkup once the feature is stable?
  Start opt-in; revisit after one release.
- Manifest v2 anchors use line numbers. A context line (the line above the
  removed block) would survive unrelated edits better. Line numbers are
  simpler to write and verify; start there.

## Later (v0.5.0 candidates)

- /fresh backed by hooks: a marker file and `compact` / `SubagentStart`
  hooks that re-inject the quarantine, so it survives compaction for real.
- Stamp-on-write nudge: a `PostToolUse` hook that spots a status-like memory
  written without `review-after` and suggests a stamp. Opt-in.
- /remember: the write door that stamps perishable notes on save.
