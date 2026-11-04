---
name: flaky_test_status
description: Which test suites are flaky right now
metadata:
  type: project
review-after: 2026-07-01
---

Status as of 2026-06-10: the exports and auth suites are flaky on CI. Retry
once before reporting a failure as real.
