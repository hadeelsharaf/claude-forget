# Fixture round-trip test for /forget

Run this after every edit to skills/forget/SKILL.md.

## Setup

1. Copy `tests/fixture-memory-baseline/` to `tests/scratch/memory/` (fresh copy,
   delete any previous scratch).

Keep the scratch tree after the run. It is gitignored, and it is the only
physical evidence the run happened.

## Forget pass

2. Follow skills/forget/SKILL.md literally against `tests/scratch/memory/` as
   the memory directory, using the SKILL.md Step 2 user-supplied-path override,
   with concern: `the widget exporter effort`.
   The tester plays the user at the Step 5 confirm gate: expect the candidate
   list below, approve trashing the FULL files and line-editing the PARTIAL one.

Expected candidates at the gate:
- project_widget_exporter_plan.md — FULL
- project_widget_exporter_poc_results.md — FULL
- project_dashboard_redesign.md — PARTIAL (one deferred-button line mentions it)
- feedback_csv_quoting_lesson.md — WARN + link-only edit (the lesson survives;
  only the [[link]] is removed)

## Assertions after the run

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
G. `MEMORY.md` has exactly 3 lines (widget lines removed; dashboard hook may be
   reworded); no line points to a missing file.
H. Nothing outside `tests/scratch/memory/` changed.
I. `feedback_csv_quoting_lesson.md` still contains `corrupt rows without
   quoting` — the rationale sentence survives, only the link is gone.
J. `git status --porcelain` shows nothing outside `tests/scratch/`.

## Restore pass

3. Follow the TRASH.md recipe: move both files back, drop `.trashed`, re-add
   their two index lines; re-add the removed [[links]] and the dashboard line
   using `TRASH.md` verbatim blocks only. If any text cannot be restored from
   TRASH.md alone, that is a Critical skill bug, not a test problem.
4. Compare `tests/scratch/memory/` to `tests/fixture-memory-baseline/`
   (PowerShell: `Get-FileHash` both trees, ignoring `.trash/` and
   `.claudeignore`). Every hash must match: the forget is proven reversible.

## Pass criteria

All assertions A-J hold and the restore hashes match. Any deviation is a
skill-text bug: fix SKILL.md, not the test.
