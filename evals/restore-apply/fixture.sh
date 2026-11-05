#!/bin/bash
# Scaffold: the baseline fixture AFTER a /forget of the widget exporter
# effort, with the format-2 manifest that run wrote. /restore must undo it.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cp -r "$here/../../tests/fixture-memory-baseline" memory
cd memory
mkdir -p .trash
mv project_widget_exporter_plan.md .trash/project_widget_exporter_plan.md.trashed
mv project_widget_exporter_poc_results.md .trash/project_widget_exporter_poc_results.md.trashed
# drop index lines 1-2, reword the dashboard hook (was line 4, now line 2)
sed -i.bak -e '1,2d' MEMORY.md && rm MEMORY.md.bak
sed -i.bak -e '2s/ — dark theme approved; widget export button deferred$/ — dark theme approved/' MEMORY.md && rm MEMORY.md.bak
# remove dashboard line 9; replace lesson lines 10-11 with one line
sed -i.bak -e '9d' project_dashboard_redesign.md && rm project_dashboard_redesign.md.bak
sed -i.bak -e '11d' -e '10s/ (see$/./' feedback_csv_quoting_lesson.md && rm feedback_csv_quoting_lesson.md.bak
printf '%s\n' '.trash/' > .claudeignore
cp "$here/TRASH.md" .trash/TRASH.md
