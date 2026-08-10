---
name: feedback_csv_quoting_lesson
description: Always quote CSV fields that contain commas
metadata:
  type: feedback
---

Always quote CSV fields containing commas.

**Why:** The widget exporter POC produced corrupt rows without quoting (see
[[project_widget_exporter_plan]]).

**How to apply:** Use the csv module's QUOTE_MINIMAL, never manual joins.
