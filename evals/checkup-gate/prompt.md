---
description: /checkup gate shows index health and the three stale candidates, flags nothing else (read-only run)
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---
/memory-tools:checkup

Note from the user: the memory directory for this run is the `memory` folder
in the current working directory (a user-supplied path for testing). If you
cannot run `date`, assume today is after 2026-07-01 and before 2099-01-01.
Show the confirm gate and then stop and wait for my answer. Do not change
anything.
