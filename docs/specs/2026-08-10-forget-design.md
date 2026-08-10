# /forget skill — design spec

Date: 2026-08-10
Status: approved by user (brainstorming session, DoZen.KnowledgeEngine workspace)

## Goal

A marketplace-installable Claude Code plugin (`memory-tools`) with one skill, `forget`.
On command — `/forget <concern>` — it removes auto-memories about a discarded effort
from the **current project's** memory folder, reversibly:

1. Move matching memory files to `memory/.trash/` and rename `name.md` -> `name.md.trashed`.
2. Record every move in `.trash/TRASH.md` (manifest with restore steps).
3. Keep `.trash/` listed in `memory/.claudeignore`.
4. Re-index: remove the trashed files' lines from `MEMORY.md` and sweep dangling `[[links]]`.

The skill is a behavioral sibling of Anthropic's `consolidate-memory` skill: same
three-phase shape (take stock -> act -> tidy the index), same file conventions.
`consolidate-memory` merges and sharpens what stays; `forget` removes what the user
has explicitly discarded.

## Non-goals (v0.1)

- No CLAUDE.md / CLAUDE.local.md / workspace-file editing. Auto-memory only.
- No cross-project sweep. Current project only; run it per project.
- No hard delete, ever. Trash is the terminal state; the user purges by hand if they want.
- No tombstone ("never re-record this") rules. May come later.
- No binary MCP memory stores (e.g. `.swarm/memory.db`), no transcripts, no claude.ai
  memory. The final report names these as NOT covered so forgetting is honest.
- No restore skill. `TRASH.md` documents the manual restore recipe.

## Why rename to `.md.trashed` (the load-bearing mechanism)

Only `MEMORY.md` is auto-loaded each session; topic files are read on demand or
surfaced by the recall system. How recall scans the memory folder is undocumented,
so the design defensively assumes some scanner may pick up any `*.md` under
`memory/`. Moving to `.trash/` plus removing index lines handles the documented
paths; the `.trashed` extension is the guarantee that holds even if a future
scanner descends into subfolders. The `memory/.claudeignore` entry is
belt-and-braces documentation of intent — nothing documented reads it in the
memory path today, and the skill must not claim it does.

## Plugin layout

```
claude-memory-tools/
  .claude-plugin/marketplace.json    lists plugin "memory-tools" (source ./)
  .claude-plugin/plugin.json         name memory-tools, version 0.1.0, author, description
  skills/forget/SKILL.md             the whole behavior, checklist-strict
  README.md                          install, usage, what it does NOT cover
  docs/specs/2026-08-10-forget-design.md   this spec
```

No scripts ship with the plugin. Candidate matching is model judgment; the
mechanical moves are stated as strict numbered instructions so they work the same
on Windows and POSIX.

## Skill frontmatter

- `name: forget`
- `description`: triggers on explicit invocation (`/forget`, "forget the X effort",
  "trash the memories about X"). It must state that the skill is destructive-adjacent
  (moves memories to trash) so it is never auto-triggered by casual phrasing.

## The forget flow (SKILL.md body, numbered and mandatory)

1. **Concern.** Take the concern from the invocation arguments. If empty, ask for it
   and stop until answered.
2. **Locate.** Resolve the current project's auto-memory directory (the harness
   states it in the session context). If there is no memory directory or no
   `MEMORY.md`, report "this project has no memories" and stop.
3. **Take stock.** Read `MEMORY.md` in full. Reconcile: if index lines point to
   missing files or files exist unindexed, note it and reconcile as part of the run.
4. **Find candidates (three passes, in order).**
   a. Index pass — match concern against titles and hook lines in `MEMORY.md`.
   b. Grep pass — search topic files for the concern's keywords AND obvious variants
      (synonyms, ticket numbers, branch names the user mentioned).
   c. Judgment pass — read every borderline file; decide relevance semantically.
   Tag each candidate **FULL** (entire file is about the discarded effort) or
   **PARTIAL** (file mixes the effort with unrelated facts).
5. **Confirm gate (mandatory, exactly one).** Present the candidate list: filename,
   FULL/PARTIAL tag, one-line reason. Add a warning tag on candidates that look
   load-bearing (type `feedback` lessons; files cited by CLAUDE.md or other
   memories). Offer per-file overrides: PARTIAL files default to "edit matching
   lines out" instead of trashing. Proceed only on explicit user confirmation.
   Zero candidates -> report "nothing matched" and stop, touching nothing.
6. **Execute.**
   - FULL files: move to `memory/.trash/`, rename `<name>.md` -> `<name>.md.trashed`.
     If that target name already exists, suffix the date: `<name>.2026-08-10.md.trashed`.
   - PARTIAL files (when user chose edit): remove only the matching lines/sections
     in place; never rewrite unrelated content.
   - Never delete anything. Never touch files outside the memory directory.
     Never trash `MEMORY.md` itself.
7. **Record.**
   - Append one entry per run to `memory/.trash/TRASH.md` (create with a restore-recipe
     header if missing): date, concern, each file moved (original name) with a
     one-line summary, each file edited with what was removed.
   - Ensure `memory/.claudeignore` exists and contains a `.trash/` line.
8. **Re-index.**
   - Remove each trashed file's line from `MEMORY.md`.
   - Grep surviving memories for `[[name]]` links pointing at trashed memories'
     `name:` slugs; remove those links (or the sentence, if the sentence is only
     about the trashed memory).
   - Update hooks of edited PARTIAL files if their one-line summary changed.
9. **Report.** State: files moved (old -> new path), files edited, index lines
   removed, links cleaned, restore recipe pointer, and the honesty list of surfaces
   NOT covered (CLAUDE.md files, MCP stores, transcripts, claude.ai memory).

## TRASH.md manifest format

```
# Trash manifest

Restore recipe: move the file back up one level into memory/, remove the
`.trashed` suffix, re-add its one-line pointer to MEMORY.md.

## 2026-08-10 — concern: "the LiteLLM multiprovider effort"
- project_llm_agnostic_multiprovider_plan.md — LLM-agnostic provider plan; LiteLLM rejected
  (moved; was FULL match)
- project_foo.md — removed 3 lines mentioning LiteLLM benchmarking
  (edited in place; PARTIAL match)
```

## Error handling

| Situation | Behavior |
|---|---|
| No memory dir / no MEMORY.md | Report and stop |
| Index/files out of sync | Reconcile during take-stock, note in report |
| Name collision in `.trash/` | Date-suffix the new arrival |
| Zero matches | Report, touch nothing |
| User declines at confirm gate | Touch nothing, report declined |

## Testing plan

1. **Fixture round-trip** (before publishing): scratch memory folder with ~5 fake
   memories + index, including one PARTIAL mix and one `[[link]]` pair. Run the
   flow; verify move+rename, manifest entry, `.claudeignore`, index rewrite, link
   sweep. Then restore per recipe and verify the folder byte-matches the start.
2. **Real run**: one genuinely discarded effort in the DoZen project's memory,
   chosen by the user, before the repo is published.

## Distribution

Own GitHub repo. Users add with `/plugin marketplace add <owner>/claude-memory-tools`
then install `memory-tools`. Invocation: `/forget <concern>` (namespaced
`/memory-tools:forget` when ambiguous). Later option: submit to
`anthropics/claude-plugins-official` by PR.

## Known risks / accepted trade-offs

- `.claudeignore` in the memory folder is not honored by any documented loader;
  accepted as documentation-only. The rename carries the guarantee.
- Recall internals are undocumented; if the harness someday indexes trashed files
  despite the extension, revisit (move trash outside `memory/` entirely).
- Semantic matching can over-match; the single confirm gate plus warning tags on
  load-bearing files is the accepted mitigation (user chose one confirm over
  per-file confirms).
