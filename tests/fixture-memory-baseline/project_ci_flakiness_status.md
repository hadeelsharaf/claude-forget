---
name: project_ci_flakiness_status
description: CI flakiness watch — current failing suites
metadata:
  type: project
review-after: 07/2026
---

Status as of 2026-06-05: two suites flaky (auth, exports). Retry rate above
5 percent. Watching for the next scheduled runner image update.

> Note from the on-call: exports suite fails only on the small runner.

Next review after the runner image lands.
