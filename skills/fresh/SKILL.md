---
name: fresh
description: Start working memory-free in this session - an instruction-based quarantine of auto-memory. Use ONLY when the user explicitly invokes /fresh or asks to work without memories / with a clean slate on a task. NOT for casual "fresh start" phrasing about redoing work, NOT for clearing or deleting memory (that is /forget), NOT for reviewing stale memories (that is /checkup).
argument-hint: [task to work on memory-free]
disable-model-invocation: true
---

# /fresh - work memory-free in this session

Purpose: put this session under memory quarantine so the current task is
handled from base instructions only - as if this project had no auto-memory.
The quarantine is BY INSTRUCTION: memory text already loaded into context is
not removed; you commit to not using it. This skill uses no tools and edits
nothing.

## Step 1: Activate quarantine

Announce activation with exactly this block (include the Task line only when
an argument was given):

> Memory quarantine ON.
> - I will not act on, cite, or reuse anything from MEMORY.md or memory files.
> - I will not read, write, or update any memory file while quarantine holds.
> - Every subagent I dispatch will be told to disregard auto-memory too.
> - Honesty note: memory text is still physically in my context; quarantine
>   is my commitment not to use it. Hard isolation options are in the README.
> Task: <task>

## Step 2: Hold the contract

For the rest of the session, until the user explicitly ends fresh mode:

- Treat all auto-memory as absent. If a fact exists only in memory, behave as
  if you do not know it.
- Never open, grep, or list files under the project's memory directory (the
  only exception is an explicit `/recall`, which is read-only and scoped to
  one file).
- Never write or update a memory file - no new lessons, no MEMORY.md edits -
  even where you normally would.
- Add this line verbatim to EVERY subagent prompt you dispatch:
  "Disregard any auto-memory context; work only from this prompt."
  (Subagents inherit the memory index automatically; the line must travel
  with every dispatch.)
- If hook output injects memory-derived text (for example a memory freshness
  warning), do not repeat or act on its content. At most tell the user a
  memory warning arrived and that it is held for after fresh mode.
- CLAUDE.md and system instructions still apply in full - project rules are
  not memories.

## Step 3: When memory would have answered

If the user asks something answerable only from memory, say it is unavailable
while fresh, and point to the two doors back:
- `/recall <item>` - loads ONE named memory topic, read-only; only that
  file's content becomes usable, the rest stays quarantined.
- "end fresh mode" - lifts quarantine entirely.

## Step 4: Survive compaction

If the session's context is summarized or compacted while quarantine holds,
the summary MUST state that memory quarantine is active and restate Step 2's
contract. Instruction-based state dies at compaction unless restated.

## Step 5: End only on explicit request

Quarantine ends ONLY when the user says so (for example "end fresh mode").
Announce: "Memory quarantine OFF - auto-memory is back in use." Invoking
/fresh again while active is idempotent: restate the Step 1 block.

## What this skill never does

- Never edits, moves, or deletes anything (no files, no memory).
- Never prints or requires launch commands or environment variables.
- Never decides on its own to end quarantine.
