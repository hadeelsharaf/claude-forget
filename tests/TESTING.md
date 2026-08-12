# Fixture round-trip tests for memory-tools

Run the relevant part after every edit to `skills/*/SKILL.md` or `hooks/`.

## Part 1 — /forget round trip

### Setup

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
- NOT candidates: the three *_status.md files and reference_ci_dashboard_url.md
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
G. `MEMORY.md` has exactly 6 lines (widget lines removed; dashboard hook may be
   reworded); no line points to a missing file.
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
   `.claudeignore`). Every hash must match: the forget is proven reversible.

## Part 2 — hook test (scripted)

Run from the repo root (git-bash on Windows):

    sh tests/run-hook-test.sh

Expected: every line `PASS`, final line `ALL PASS`, exit 0. Covers: exact
warning shape for an overdue stamp, POSIX-path slug mapping, silence when
nothing is stale, silence when no memory dir exists, and that `.trash/` is
never scanned.

## Part 3 — /checkup round trip

### Setup

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
- NOT flagged: project_release_checklist_status.md (fresh stamp 2099-01-01)
  and all Part 1 files (not perishable).

Approve exactly:
- REFRESH for project_build_pipeline_status.md with the new truth: "Both
  build failures fixed on 2026-08-01; pipeline green." and review-after set
  to 30 days from today.
- HISTORICAL for project_login_outage_status.md.

### Assertions after the run

K. Build file: the three old status lines are gone, the new truth is present,
   `review-after:` is updated; the replaced lines (including the old
   `review-after: 2026-07-01` line) appear verbatim in `.trash/TRASH.md`
   under `Refreshed` / `Removed verbatim`, and every inserted line appears
   under `Added`.
L. Login file: the banner line sits directly after the frontmatter and reads
   `> HISTORICAL as of <today> - describes past state; do not act on it.`;
   its MEMORY.md hook now starts with `HISTORICAL —`; the original hook line
   is in the manifest under `Hook lines reworded` / `Original verbatim`.
M. `project_release_checklist_status.md` and every Part 1 file are
   byte-identical to baseline.
N. No file was moved or deleted; `.trash/` contains only `TRASH.md`.
O. `git status --porcelain` shows nothing outside `tests/scratch/`.

### Restore pass

3. Using TRASH.md alone: delete every `Added` line, paste every
   `Removed verbatim` / `Original verbatim` line back where it came from.
4. Hash-compare `tests/scratch/memory/` to the baseline (ignore `.trash/`).
   Every hash must match. If any text cannot be restored from TRASH.md
   alone, that is a Critical skill bug, not a test problem.

## Part 4 — cold-model test (mandatory before release)

Hand a FRESH agent only the shipped `skills/checkup/SKILL.md` text and the
scratch fixture path; it must reach the same Part 3 gate table and, after the
same approvals, satisfy K-O and the restore hash-compare. The builder must
not coach it. Any deviation is a skill-text bug.

## Pass criteria

Part 1: A-J plus matching restore hashes. Part 2: ALL PASS. Part 3: K-O plus
matching restore hashes. Part 4: same bar as Part 3, on a cold agent. Any
deviation is a skill/hook bug: fix the shipped text or script, never the test.
