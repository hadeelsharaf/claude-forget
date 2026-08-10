---
name: forget
description: Use ONLY when the user explicitly asks to forget, trash, or drop memories about a named topic or discarded effort (e.g. "/forget <concern>", "forget the X effort", "trash my memories about X"). Moves matching auto-memory files of the CURRENT project to memory/.trash/ (reversible, never deletes), records a manifest, and re-indexes MEMORY.md. Never trigger on casual mentions of forgetting; an explicit forget command is required.
---

# Forget — trash memories about a discarded effort

You are removing auto-memories the user has explicitly discarded. Everything is
reversible: files move to trash, nothing is ever deleted. Follow every numbered
step in order; the confirm gate in Step 5 may not be skipped for any reason.

Scope: the CURRENT project's auto-memory folder ONLY — not CLAUDE.md files, not
MCP memory databases, not session transcripts, not claude.ai memory. The final
report must say so.

## Step 1 — Concern

Take the concern from the invocation arguments. If empty, ask the user "What
should I forget?" and stop until answered.

## Step 2 — Locate

Resolve the current project's auto-memory directory: it is stated in your
system prompt's memory section (a path ending in `projects/<project-slug>/memory`).
If that directory or its `MEMORY.md` does not exist, report "this project has
no memories" and stop.

## Step 3 — Take stock

Read `MEMORY.md` in full. List the memory folder. If index lines point to
missing files, or files exist with no index line, note the mismatch — you will
fix it during Step 8.

## Step 4 — Find candidates (three passes, in order)

1. Index pass: match the concern against every title and hook line in MEMORY.md.
2. Grep pass: search all topic files for the concern's keywords AND obvious
   variants — synonyms, ticket or bug numbers, branch names, tool or library
   names tied to the effort.
3. Judgment pass: read each borderline file and decide semantically whether it
   is about the discarded effort. Exact-string matching alone is not enough.

Tag every candidate:
- FULL — the entire file is about the discarded effort.
- PARTIAL — the file mixes the effort with unrelated facts that must survive.

## Step 5 — Confirm gate (mandatory, exactly one)

Show the user the candidate list: `filename — FULL/PARTIAL — one-line reason`.

- Mark load-bearing candidates with a warning tag: memories of type `feedback`
  (lessons), files linked from other memories via `[[...]]`, or files cited by
  the project's CLAUDE.md. The user may still trash them — warn, do not refuse.
- For PARTIAL files the default action is "edit the matching lines out", not
  trashing the whole file. Say exactly which lines you would remove.
- Zero candidates: report "nothing matched <concern>" and stop. Touch nothing.

Proceed only after the user explicitly confirms. If they decline, stop and
report that nothing was touched.

## Step 6 — Execute (only after confirmation)

For each FULL file:
- Move it into `memory/.trash/` (create the folder if missing).
- Rename `<name>.md` to `<name>.md.trashed`.
- If that target name already exists, use `<name>.<YYYY-MM-DD>.md.trashed`.

For each PARTIAL file where the user chose edit: remove only the matching lines
or sections; leave every other byte unchanged.

Never delete a file. Never touch anything outside the memory directory. Never
trash MEMORY.md itself.

## Step 7 — Record

Append an entry to `memory/.trash/TRASH.md`; create the file with this header
if it does not exist:

    # Trash manifest

    Restore recipe: move the file back up one level into memory/, remove the
    `.trashed` suffix, and re-add its one-line pointer to MEMORY.md.

Entry format (one entry per forget run):

    ## <YYYY-MM-DD> — concern: "<concern>"
    - <original-name>.md — <one-line summary> (moved; FULL match)
    - <edited-name>.md — removed <what was removed> (edited in place; PARTIAL match)

Then ensure `memory/.claudeignore` exists and contains a line `.trash/`. This
file documents intent for humans and future tooling; do NOT claim it is what
prevents loading — the `.md.trashed` rename is.

## Step 8 — Re-index

- Remove each trashed file's line from `MEMORY.md`.
- Search the surviving memories for `[[slug]]` links whose slug matches a
  trashed memory's `name:` frontmatter value; remove the link, or the whole
  sentence when the sentence is only about the trashed memory.
- If a PARTIAL edit changed what a file is about, update its MEMORY.md hook line.
- Fix any index/file mismatches noted in Step 3.

## Step 9 — Report

Tell the user, in this order:
1. Files moved (`old name -> .trash/new name`) and files edited in place.
2. Index lines removed and `[[links]]` cleaned.
3. Where the manifest is, plus the one-line restore recipe.
4. NOT covered by this run: CLAUDE.md files, MCP memory stores (for example
   .swarm/memory.db), session transcripts, and claude.ai memory. If the user
   wants those cleaned, they must be handled separately.
