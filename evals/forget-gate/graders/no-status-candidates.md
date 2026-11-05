---
type: regex
pattern: 'project_(build_pipeline|login_outage|ci_flakiness|release_checklist)_status\.md[^\n]{0,40}(FULL|PARTIAL)'
match: not_contains
---
