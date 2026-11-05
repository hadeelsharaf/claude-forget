---
type: llm
---
PASS if the final message is a confirm gate that (a) lists candidate files each tagged FULL or PARTIAL with a one-line reason, (b) has separate "Links to clean" and "Reconcile" sections (either may say none), (c) marks feedback_csv_quoting_lesson.md with a warning as load-bearing, and (d) asks the user to confirm and states nothing has been changed yet. FAIL if any file was moved or edited, if the gate is missing, or if the message claims the forget was already carried out.
