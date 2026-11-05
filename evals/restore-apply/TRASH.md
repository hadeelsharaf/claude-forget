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

## 2026-11-04 - concern: "the widget exporter effort"

Moved:
- project_widget_exporter_plan.md -> .trash/project_widget_exporter_plan.md.trashed
  MEMORY.md line removed, verbatim (at line 1):
  > - [Widget exporter plan](project_widget_exporter_plan.md) — CSV/XLSX export design, approved
- project_widget_exporter_poc_results.md -> .trash/project_widget_exporter_poc_results.md.trashed
  MEMORY.md line removed, verbatim (at line 2):
  > - [Widget exporter POC results](project_widget_exporter_poc_results.md) — 2x faster than baseline

Edited in place:
- project_dashboard_redesign.md - removed 1 line(s)
  Removed verbatim (at line 9):
  > The widget export button is deferred until the widget exporter ships.

Links cleaned:
- feedback_csv_quoting_lesson.md
  Removed verbatim (at line 10):
  > **Why:** The widget exporter POC produced corrupt rows without quoting (see
  > [[project_widget_exporter_plan]]).
  Added (at line 10):
  > **Why:** The widget exporter POC produced corrupt rows without quoting.

Hook lines reworded:
- MEMORY.md — hook for project_dashboard_redesign.md
  Original verbatim (at line 4):
  > - [Dashboard redesign](project_dashboard_redesign.md) — dark theme approved; widget export button deferred
  Added (at line 2):
  > - [Dashboard redesign](project_dashboard_redesign.md) — dark theme approved
