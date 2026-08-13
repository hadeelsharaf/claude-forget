# Fixture round-trip tests for memory-tools

Run the relevant part after every edit to `skills/*/SKILL.md` or `hooks/`.

## Part 1 — /forget round trip

### Setup

0. I11 out-of-tree guard: snapshot every file under
   `$HOME/.claude/projects/*/memory` (all projects), for example (git-bash):
   `find "$HOME/.claude/projects" -type f -path "*/memory/*" -print0 | sort -z | xargs -0 sha256sum > snapshot-before.txt`.
   Do not use the PowerShell 5.1 `Get-ChildItem -Recurse -File` wildcard
   form — in that environment it silently returns zero rows, which makes the
   snapshot comparison pass vacuously.
   Keep this snapshot; you diff it against a matching after-snapshot once the
   run finishes, to prove the run never wrote outside `tests/scratch/`.
1. Copy `tests/fixture-memory-baseline/` to `tests/scratch/memory/` (fresh copy,
   delete any previous scratch).

Keep the scratch tree after the run. It is gitignored, and it is the only
physical evidence the run happened.

### Forget pass

2. Follow skills/forget/SKILL.md literally against `tests/scratch/memory/` as
   the memory directory, using the SKILL.md Step 2 user-supplied-path override,
   with concern: `the widget exporter effort`.
   The tester plays the user at the Step 5 confirm gate: expect the candidate
   list below, approve trashing the FULL files and line-editing the PARTIAL one.

Expected candidates at the gate:
- project_widget_exporter_plan.md — FULL
- project_widget_exporter_poc_results.md — FULL
- project_dashboard_redesign.md — PARTIAL (one deferred-button line mentions it)
- feedback_csv_quoting_lesson.md — appears under "Links to clean", WARN tag
  (link-only edit; the lesson survives)
- NOT candidates: the three *_status.md files, reference_ci_dashboard_url.md,
  project_ci_flakiness_status.md, and feedback_release_notes_style.md
  (unrelated to the widget exporter effort).

### Assertions after the run

A. `tests/scratch/memory/.trash/project_widget_exporter_plan.md.trashed` exists;
   the un-renamed original is gone from `memory/`.
B. Same for `project_widget_exporter_poc_results.md.trashed`.
C. `project_dashboard_redesign.md` survives; its widget-export line is gone;
   its other three facts are untouched.
D. `feedback_csv_quoting_lesson.md` survives; `[[project_widget_exporter_plan]]`
   no longer appears in it.
E. `.trash/TRASH.md` exists, has the restore header, and one dated entry that
   lists both moved files and the edit.
F. `.claudeignore` exists in `memory/` and contains `.trash/`.
G. `MEMORY.md` has exactly 8 lines (10 baseline - 2 widget; dashboard hook may
   be reworded); no line points to a missing file.
H. Nothing outside `tests/scratch/memory/` changed.
I. `feedback_csv_quoting_lesson.md` still contains `corrupt rows without
   quoting` — the rationale sentence survives, only the link is gone.
J. `git status --porcelain` shows nothing outside `tests/scratch/`.

### Restore pass

3. Follow the TRASH.md recipe: move both files back, drop `.trashed`, re-add
   their two index lines; re-add the removed [[links]] and the dashboard line
   using `TRASH.md` verbatim blocks only. If any text cannot be restored from
   TRASH.md alone, that is a Critical skill bug, not a test problem.
4. Compare `tests/scratch/memory/` to `tests/fixture-memory-baseline/`
   (PowerShell: `Get-FileHash` both trees, ignoring `.trash/` and
   `.claudeignore`). Every hash must match (11/11 files): the forget is
   proven reversible.
5. I11 out-of-tree guard: take the after-snapshot with the same command as
   step 0 and `diff` it against `snapshot-before.txt`. The two snapshots
   must be identical.

## Part 2 — hook test (scripted)

Run from the repo root (git-bash on Windows):

    sh tests/run-hook-test.sh

Expected: every line `PASS`, final line `ALL PASS`, exit 0. Covers: exact
warning shape for an overdue stamp, POSIX-path slug mapping, silence when
nothing is stale, silence when no memory dir exists, that `.trash/` is never
scanned, multiple overdue files reported in alphabetical order, a malformed
stamp staying silent, a body-text `review-after:` outside the frontmatter
staying silent, a stamp dated exactly today staying silent, a lowercase drive
letter producing the same warning as uppercase, and `HOME` unset staying
silent with exit 0.

## Part 3 — /checkup round trip

### Setup

0. I11 out-of-tree guard: snapshot every file under
   `$HOME/.claude/projects/*/memory` (all projects) — same command as
   Part 1 step 0 — and keep it for the after-comparison.
1. Copy `tests/fixture-memory-baseline/` to `tests/scratch/memory/` (fresh
   copy, delete any previous scratch). Keep the scratch tree afterwards.

### Checkup pass

2. Follow skills/checkup/SKILL.md literally against `tests/scratch/memory/`
   as the memory directory (Step 2 user-supplied-path override), with no
   topic argument. The tester plays the user at the Step 5 gate.

Expected candidates at the gate:
- project_build_pipeline_status.md — OVERDUE (review-after 2026-07-01)
- project_login_outage_status.md — UNSTAMPED-PERISHABLE ("Current status:
  ... ongoing")
- project_ci_flakiness_status.md — BADSTAMP (review-after: 07/2026,
  malformed) — recommend STAMP with a corrected date
- NOT flagged: project_release_checklist_status.md (fresh stamp 2099-01-01),
  all Part 1 files (not perishable), and feedback_release_notes_style.md
  (lesson; its body stamp line is documentation — must NOT be flagged by
  either pass).

Approve exactly:
- REFRESH for project_build_pipeline_status.md with the new truth: "Both
  build failures fixed on 2026-08-01; pipeline green." and review-after set
  to 30 days from today.
- HISTORICAL for project_login_outage_status.md.
- STAMP for project_ci_flakiness_status.md, review-after 30 days from today
  (replaces the malformed line).

### Assertions after the run

K. Build file: the three old status lines are gone, the new truth is present,
   `review-after:` is updated; the replaced lines (including the old
   `review-after: 2026-07-01` line) appear verbatim in `.trash/TRASH.md`
   under `Refreshed` / `Removed verbatim`, and every inserted line appears
   under `Added`.
L. Login file: the banner line sits directly after the frontmatter and reads
   `> HISTORICAL as of <today> - describes past state; do not act on it.`;
   the inserted blank line follows the banner, and the pre-existing blank
   line after that is untouched baseline content, not a newly inserted
   line; its MEMORY.md hook now starts with `HISTORICAL —`; the original
   hook line is in the manifest under `Hook lines reworded` /
   `Original verbatim`; restoring this entry strips exactly one leading
   `> ` from each recorded line.
M. `project_release_checklist_status.md` and every Part 1 file are
   byte-identical to baseline.
N. No file was moved or deleted; `.trash/` contains only `TRASH.md`.
O. `git status --porcelain` shows nothing outside `tests/scratch/`.
P. The ci_flakiness file has exactly ONE `review-after:` line (the new
   date); the malformed `review-after: 07/2026` line appears verbatim in the
   manifest under `Stamped` / `Removed verbatim`.
Q. Manifest recording obeys the recording rule: the HISTORICAL banner
   appears as `> > HISTORICAL ...` and its blank line as a bare `>` under
   `Added`.

### Restore pass

3. Using TRASH.md alone: delete every `Added` line, paste every
   `Removed verbatim` / `Original verbatim` line back where it came from.
4. Hash-compare `tests/scratch/memory/` to the baseline (ignore `.trash/`).
   Every hash must match (11/11 files). If any text cannot be restored from
   TRASH.md alone, that is a Critical skill bug, not a test problem.
5. I11 out-of-tree guard: same as Part 1 step 5 — the before/after
   `$HOME\.claude\projects\*\memory` snapshots must be identical.

## Part 4 — cold-model test (mandatory before release)

I11 out-of-tree guard: snapshot every file under
`$HOME/.claude/projects/*/memory` (same command as Part 1 step 0) before
handing the fixture to the cold agent, and again after it finishes; the two
snapshots must be identical.

Hand a FRESH agent only the shipped `skills/checkup/SKILL.md` text and the
scratch fixture path; it must reach the same Part 3 gate table and, after the
same approvals, satisfy K-Q and the restore hash-compare. The builder must
not coach it. Any deviation is a skill-text bug.

## Part 5 — /fresh behavioral (assertions R-U)

Run in a real Claude Code session in this repo (auto-memory present).
Setup: BEFORE step 1, take the out-of-tree snapshot:
`find "$HOME/.claude/projects" -type f -path "*/memory/*" -print0 | sort -z | xargs -0 sha256sum`

1. Invoke `/fresh trial task`.
- **R:** The activation block appears with all three contract bullets plus the
  honesty-note bullet (memory text still in context), and `Task: trial task`.
2. Ask a question answerable only from the project's auto-memory (pick a fact
  that exists in a memory file but not in the repo).
- **S:** The agent declines to use memory, says it is unavailable while
  fresh, and points to `/recall <item>` and "end fresh mode".
3. Ask the agent to dispatch any trivial subagent (e.g. "list repo top-level
  dirs via a subagent").
- **T:** The dispatched prompt contains, verbatim:
  `Disregard any auto-memory context; work only from this prompt.`
4. Say "end fresh mode".
- **U:** The agent announces "Memory quarantine OFF - auto-memory is back in
  use." AND the out-of-tree snapshot taken before step 1 matches the one
  taken now (no memory file changed):
  `find "$HOME/.claude/projects" -type f -path "*/memory/*" -print0 | sort -z | xargs -0 sha256sum`
  (PowerShell 5.1 note: run this in git-bash; the PS one-liner form silently
  returns zero rows.)

Cold variant: hand a fresh agent only the shipped `skills/fresh/SKILL.md`
text; it must satisfy R-U without coaching.

## Part 6 — /recall round trip (assertions V-AA, read-only proof)

Setup: copy `tests/fixture-memory-baseline/` to a scratch memory dir; tell
the agent that path in the conversation (user-typed provenance). Hash all 11
files before starting (same find|sha256sum form as Part 5).

1. Invoke `/recall build pipeline`.
- **V:** Stage 1 lists `project_build_pipeline_status` with a word count and
  the tag `STALE: review-after 2026-07-01 is past`; it lists NO trashed file
  and no unrelated file (e.g. `feedback_csv_quoting_lesson`).
2. Name `project_build_pipeline_status` to open.
- **W:** Output is a `recalled: project_build_pipeline_status, <N> words,
  last modified <date>` header, the file's full content, and the one-line
  STALE warning pointing to /checkup.
3. Invoke `/recall quantum teleportation`.
- **X:** Response is "nothing in memory matches quantum teleportation" (no
  file opened).
4. Invoke `/recall` with no argument.
- **Y:** The agent asks "What should I recall?" and stops (no listing).
5. Under /fresh: invoke `/fresh`, then `/recall build pipeline`, open
  `project_build_pipeline_status`, then ask about a DIFFERENT memory-only
  fact.
- **Z:** The recalled file's content is usable, but the other fact is
  declined (quarantine holds for everything not recalled).
6. Re-hash all 11 fixture files.
- **AA:** Every hash is identical to the pre-run hash (nothing written,
  moved, or stamped).

Cold variant: hand a fresh agent only the shipped `skills/recall/SKILL.md`
text and the scratch fixture path; it must satisfy V-AA without coaching.

## Pass criteria

Part 1: A-J plus matching restore hashes. Part 2: ALL PASS. Part 3: K-Q plus
matching restore hashes. Part 4: same bar as Part 3, on a cold agent. Part 5:
R-U with identical out-of-tree snapshots. Part 6: V-AA with 11/11 identical
fixture hashes. Any deviation is a skill/hook bug: fix the shipped text or
script, never the test.
