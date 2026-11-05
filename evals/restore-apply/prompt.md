---
description: /restore undoes a format-2 forget entry so the memory folder returns to baseline (needs --allow-tools Write Edit Bash)
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---
/memory-tools:restore

Note from the user: the memory directory for this run is the `memory` folder
in the current working directory (a user-supplied path for testing). There is
one open entry. This message is also my explicit "yes" at the confirm gate, so
you do not need to wait for another one: show the dry run, then apply all of
it and give the Step 7 report.
