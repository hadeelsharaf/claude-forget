---
name: project_build_pipeline_status
description: Current build pipeline status — failures and fixes in flight
metadata:
  type: project
review-after: 2026-07-01
---

Status as of 2026-06-20: two build failures open. The lint stage fails on
warnings promoted to errors; the packaging stage times out on large bundles.
Fix for the lint stage is in review. Packaging timeout not diagnosed yet.
