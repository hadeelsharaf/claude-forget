# memory-tools /forget Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `memory-tools` marketplace plugin whose `/forget <concern>` skill reversibly trashes auto-memories about a discarded effort and re-indexes MEMORY.md.

**Architecture:** A pure prompt-skill plugin — no scripts. `skills/forget/SKILL.md` carries the whole behavior as checklist-strict numbered steps; two JSON manifests make the repo an installable marketplace; a committed fixture memory folder plus a written procedure serve as the behavioral round-trip test.

**Tech Stack:** Claude Code plugin spec (`.claude-plugin/marketplace.json` + `plugin.json`), Skill spec (SKILL.md with YAML frontmatter), git.

## Global Constraints

- Spec is the contract: `docs/specs/2026-08-10-forget-design.md`. On conflict, the spec wins.
- Plugin name `memory-tools`, marketplace name `claude-memory-tools`, skill name `forget`, version `0.1.0` — exactly these strings.
- The skill NEVER deletes files; trash + rename is the only removal. Never touches files outside the memory directory. Never trashes MEMORY.md.
- The confirm gate is mandatory and happens exactly once per run.
- `.claudeignore` is written but must never be described (in skill text, README, or reports) as the thing that prevents loading — the `.md.trashed` rename is.
- Commit messages are plain ASCII; file content may use em dashes and other normal prose punctuation (real MEMORY.md index lines use them). Commit messages: one line, plain ASCII, no emojis, no co-author lines.
- SKILL.md body stays under 210 lines (spec: checklist-strict, small).
- JSON files must parse (verify with PowerShell `ConvertFrom-Json` or `python -m json.tool`).

---

### Task 1: Plugin and marketplace manifests

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

**Interfaces:**
- Produces: plugin identity strings consumed by Task 3 (README install commands) and Task 5 (local install): marketplace `claude-memory-tools`, plugin `memory-tools`.

- [ ] **Step 1: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "memory-tools",
  "description": "Memory hygiene skills for Claude Code auto-memory. /forget <concern> force-forgets a discarded effort: moves matching memory files to memory/.trash/ (reversible, never deletes), writes a manifest, keeps .trash/ in .claudeignore, and re-indexes MEMORY.md.",
  "version": "0.1.0",
  "author": { "name": "Hadeel Sharaf" },
  "homepage": "https://github.com/OWNER/claude-memory-tools"
}
```

(Replace OWNER with the GitHub owner at publish time; leaving it is harmless for local installs.)

- [ ] **Step 2: Write `.claude-plugin/marketplace.json`**

```json
{
  "name": "claude-memory-tools",
  "owner": { "name": "Hadeel Sharaf" },
  "plugins": [
    {
      "name": "memory-tools",
      "source": "./",
      "description": "Memory hygiene for Claude Code auto-memory: /forget moves memories about discarded efforts to a reversible trash and re-indexes MEMORY.md."
    }
  ]
}
```

- [ ] **Step 3: Verify both files parse**

Run (from repo root):
```powershell
Get-Content .claude-plugin\plugin.json -Raw | ConvertFrom-Json | Out-Null; Get-Content .claude-plugin\marketplace.json -Raw | ConvertFrom-Json | Out-Null; 'JSON OK'
```
Expected: `JSON OK` and no errors.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "add plugin and marketplace manifests"
```

---

### Task 2: The forget skill (SKILL.md)

**Files:**
- Create: `skills/forget/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the `/forget` behavior tested by Task 4 and run for real in Task 5. Trash artifacts it defines (`.trash/`, `*.md.trashed`, `TRASH.md`, `.claudeignore`) are asserted by Task 4's checks.

- [ ] **Step 1: Write `skills/forget/SKILL.md` with exactly this content**

````markdown
---
name: forget
description: Use ONLY when the user explicitly asks to forget, trash, or drop memories about a named topic or discarded effort (e.g. "/forget <concern>", "forget the X effort", "trash my memories about X"). Moves matching auto-memory files of the CURRENT project to memory/.trash/ (reversible, never deletes), records a manifest, and re-indexes MEMORY.md. Never trigger on casual mentions of forgetting; an explicit forget command is required.
---

# Forget — trash memories about a discarded effort

You are removing auto-memories the user has explicitly discarded. Everything is
reversible: files move to trash, nothing is ever deleted. Follow every numbered
step in order; the confirm gate in Step 5 may not be skipped for any reason.

Scope: the CURRENT project's auto-memory folder ONLY — not CLAUDE.md files, not
MCP memory databases, not session transcripts, not claude.ai memory. The final
report must say so.

## Step 1 — Concern

Take the concern from the invocation arguments. If empty, ask the user "What
should I forget?" and stop until answered.

## Step 2 — Locate

Resolve the current project's auto-memory directory: it is stated in your
system prompt's memory section (a path ending in `projects/<project-slug>/memory`).
If that directory or its `MEMORY.md` does not exist, report "this project has
no memories" and stop.

## Step 3 — Take stock

Read `MEMORY.md` in full. List the memory folder. If index lines point to
missing files, or files exist with no index line, note the mismatch — you will
fix it during Step 8.

## Step 4 — Find candidates (three passes, in order)

1. Index pass: match the concern against every title and hook line in MEMORY.md.
2. Grep pass: search all topic files for the concern's keywords AND obvious
   variants — synonyms, ticket or bug numbers, branch names, tool or library
   names tied to the effort.
3. Judgment pass: read each borderline file and decide semantically whether it
   is about the discarded effort. Exact-string matching alone is not enough.

Tag every candidate:
- FULL — the entire file is about the discarded effort.
- PARTIAL — the file mixes the effort with unrelated facts that must survive.

## Step 5 — Confirm gate (mandatory, exactly one)

Show the user the candidate list: `filename — FULL/PARTIAL — one-line reason`.

- Mark load-bearing candidates with a warning tag: memories of type `feedback`
  (lessons), files linked from other memories via `[[...]]`, or files cited by
  the project's CLAUDE.md. The user may still trash them — warn, do not refuse.
- For PARTIAL files the default action is "edit the matching lines out", not
  trashing the whole file. Say exactly which lines you would remove.
- Zero candidates: report "nothing matched <concern>" and stop. Touch nothing.

Proceed only after the user explicitly confirms. If they decline, stop and
report that nothing was touched.

## Step 6 — Execute (only after confirmation)

For each FULL file:
- Move it into `memory/.trash/` (create the folder if missing).
- Rename `<name>.md` to `<name>.md.trashed`.
- If that target name already exists, use `<name>.<YYYY-MM-DD>.md.trashed`.

For each PARTIAL file where the user chose edit: remove only the matching lines
or sections; leave every other byte unchanged.

Never delete a file. Never touch anything outside the memory directory. Never
trash MEMORY.md itself.

## Step 7 — Record

Append an entry to `memory/.trash/TRASH.md`; create the file with this header
if it does not exist:

    # Trash manifest

    Restore recipe: move the file back up one level into memory/, remove the
    `.trashed` suffix, and re-add its one-line pointer to MEMORY.md.

Entry format (one entry per forget run):

    ## <YYYY-MM-DD> — concern: "<concern>"
    - <original-name>.md — <one-line summary> (moved; FULL match)
    - <edited-name>.md — removed <what was removed> (edited in place; PARTIAL match)

Then ensure `memory/.claudeignore` exists and contains a line `.trash/`. This
file documents intent for humans and future tooling; do NOT claim it is what
prevents loading — the `.md.trashed` rename is.

## Step 8 — Re-index

- Remove each trashed file's line from `MEMORY.md`.
- Search the surviving memories for `[[slug]]` links whose slug matches a
  trashed memory's `name:` frontmatter value; remove the link, or the whole
  sentence when the sentence is only about the trashed memory.
- If a PARTIAL edit changed what a file is about, update its MEMORY.md hook line.
- Fix any index/file mismatches noted in Step 3.

## Step 9 — Report

Tell the user, in this order:
1. Files moved (`old name -> .trash/new name`) and files edited in place.
2. Index lines removed and `[[links]]` cleaned.
3. Where the manifest is, plus the one-line restore recipe.
4. NOT covered by this run: CLAUDE.md files, MCP memory stores (for example
   .swarm/memory.db), session transcripts, and claude.ai memory. If the user
   wants those cleaned, they must be handled separately.
````

- [ ] **Step 2: Verify frontmatter and length**

Run (from repo root):
```powershell
$s = Get-Content skills\forget\SKILL.md; if ($s[0] -ne '---') { throw 'no frontmatter' }; if (($s | Measure-Object -Line).Lines -gt 200) { throw 'too long' }; if (-not ($s -join ' ').Contains('name: forget')) { throw 'name missing' }; 'SKILL OK'
```
Expected: `SKILL OK`.

- [ ] **Step 3: Commit**

```bash
git add skills/forget/SKILL.md
git commit -m "add forget skill"
```

---

### Task 3: README

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: identity strings from Task 1 (marketplace `claude-memory-tools`, plugin `memory-tools`).

- [ ] **Step 1: Write `README.md` with exactly this content**

````markdown
# claude-memory-tools

Memory hygiene skills for Claude Code auto-memory.

## Skills

### /forget <concern>

Force-forget a discarded effort, reversibly. It:

1. Finds the current project's auto-memories about the concern (index scan +
   keyword grep + semantic judgment).
2. Shows you the list — one confirm.
3. Moves whole-match files to `memory/.trash/` and renames them
   `name.md -> name.md.trashed`; partial-match files get only the matching
   lines removed.
4. Records everything in `.trash/TRASH.md` (with a restore recipe) and keeps
   `.trash/` listed in `memory/.claudeignore`.
5. Re-indexes `MEMORY.md` and cleans dangling `[[links]]`.

Nothing is ever deleted. Restore = move the file back, drop the `.trashed`
suffix, re-add its index line.

Note on the mechanism: only `MEMORY.md` auto-loads each session, and topic
files are read on demand. The `.md.trashed` rename is what guarantees trashed
memories stay out of future sessions; the `.claudeignore` entry is
documentation of intent, not the enforcement.

## What it does NOT cover

- CLAUDE.md / CLAUDE.local.md instruction files
- MCP memory stores (for example `.swarm/memory.db`)
- Session transcripts
- claude.ai web memory

## Install

```
/plugin marketplace add OWNER/claude-memory-tools
/plugin install memory-tools@claude-memory-tools
```

For local testing before publishing:

```
/plugin marketplace add D:\path\to\claude-memory-tools
/plugin install memory-tools@claude-memory-tools
```

## Testing

See `tests/TESTING.md` for the fixture round-trip procedure.
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "add readme"
```

---

### Task 4: Fixture round-trip test

**Files:**
- Create: `tests/fixture-memory-baseline/MEMORY.md`
- Create: `tests/fixture-memory-baseline/project_widget_exporter_plan.md`
- Create: `tests/fixture-memory-baseline/project_widget_exporter_poc_results.md`
- Create: `tests/fixture-memory-baseline/feedback_csv_quoting_lesson.md`
- Create: `tests/fixture-memory-baseline/project_dashboard_redesign.md`
- Create: `tests/fixture-memory-baseline/reference_ci_dashboard_url.md`
- Create: `tests/TESTING.md`
- Create: `.gitignore` (ignores `tests/scratch/`)

**Interfaces:**
- Consumes: the Step 1-9 flow and artifact names defined in Task 2's SKILL.md (`.trash/`, `*.md.trashed`, `TRASH.md`, `.claudeignore`).
- Produces: a repeatable test asset for every future skill edit.

The fixture simulates a project that abandoned a "widget exporter" effort. It
contains two FULL matches (one with an inbound `[[link]]` from a survivor, to
prove the link sweep), one PARTIAL mix, and two pure survivors.

- [ ] **Step 1: Write the six fixture files**

`tests/fixture-memory-baseline/MEMORY.md`:
```markdown
- [Widget exporter plan](project_widget_exporter_plan.md) — CSV/XLSX export design, approved
- [Widget exporter POC results](project_widget_exporter_poc_results.md) — 2x faster than baseline
- [LESSON: CSV quoting](feedback_csv_quoting_lesson.md) — always quote fields with commas
- [Dashboard redesign](project_dashboard_redesign.md) — dark theme approved; widget export button deferred
- [CI dashboard URL](reference_ci_dashboard_url.md) — where the build dashboard lives
```

`tests/fixture-memory-baseline/project_widget_exporter_plan.md`:
```markdown
---
name: project_widget_exporter_plan
description: Design for the widget exporter (CSV/XLSX export of widget tables)
metadata:
  type: project
---

The widget exporter converts widget tables to CSV and XLSX. Approved 2026-07-01.
Uses the streaming writer. See [[project_widget_exporter_poc_results]].
```

`tests/fixture-memory-baseline/project_widget_exporter_poc_results.md`:
```markdown
---
name: project_widget_exporter_poc_results
description: POC benchmark results for the widget exporter
metadata:
  type: project
---

POC ran 2026-07-03: widget exporter streaming writer is 2x faster than the
baseline pandas dump. Quoting bug found, see [[feedback_csv_quoting_lesson]].
```

`tests/fixture-memory-baseline/feedback_csv_quoting_lesson.md`:
```markdown
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
```

`tests/fixture-memory-baseline/project_dashboard_redesign.md`:
```markdown
---
name: project_dashboard_redesign
description: Dashboard redesign decisions
metadata:
  type: project
---

Dark theme approved 2026-07-10. Sidebar collapses under 900px.
The widget export button is deferred until the widget exporter ships.
Header search stays server-side.
```

`tests/fixture-memory-baseline/reference_ci_dashboard_url.md`:
```markdown
---
name: reference_ci_dashboard_url
description: Where the CI build dashboard lives
metadata:
  type: reference
---

CI dashboard: https://ci.example.test/dashboard (VPN required).
```

- [ ] **Step 2: Write `.gitignore`**

```
tests/scratch/
```

- [ ] **Step 3: Write `tests/TESTING.md` with exactly this content**

````markdown
# Fixture round-trip test for /forget

Run this after every edit to skills/forget/SKILL.md.

## Setup

1. Copy `tests/fixture-memory-baseline/` to `tests/scratch/memory/` (fresh copy,
   delete any previous scratch).

## Forget pass

2. Follow skills/forget/SKILL.md literally against `tests/scratch/memory/` as
   the memory directory, with concern: `the widget exporter effort`.
   The tester plays the user at the Step 5 confirm gate: expect the candidate
   list below, approve trashing the FULL files and line-editing the PARTIAL one.

Expected candidates at the gate:
- project_widget_exporter_plan.md — FULL
- project_widget_exporter_poc_results.md — FULL
- project_dashboard_redesign.md — PARTIAL (one deferred-button line mentions it)
- feedback_csv_quoting_lesson.md — PARTIAL or WARN (a lesson that references the
  effort in its Why; the lesson itself must SURVIVE — only the [[link]] goes)

## Assertions after the run

A. `tests/scratch/memory/.trash/project_widget_exporter_plan.md.trashed` exists;
   the un-renamed original is gone from `memory/`.
B. Same for `project_widget_exporter_poc_results.md.trashed`.
C. `project_dashboard_redesign.md` survives; its widget-export line is gone;
   its other three facts are untouched.
D. `feedback_csv_quoting_lesson.md` survives; `[[project_widget_exporter_plan]]`
   no longer appears in it.
E. `.trash/TRASH.md` exists, has the restore header, and one dated entry that
   lists both moved files and the edit.
F. `.claudeignore` exists in `memory/` and contains `.trash/`.
G. `MEMORY.md` has exactly 3 lines (widget lines removed; dashboard hook may be
   reworded); no line points to a missing file.
H. Nothing outside `tests/scratch/memory/` changed.

## Restore pass

3. Follow the TRASH.md recipe: move both files back, drop `.trashed`, re-add
   their two index lines; re-add the removed [[links]] and the dashboard line
   from the baseline copies.
4. Compare `tests/scratch/memory/` to `tests/fixture-memory-baseline/`
   (PowerShell: `Get-FileHash` both trees, ignoring `.trash/` and
   `.claudeignore`). Every hash must match: the forget is proven reversible.

## Pass criteria

All assertions A-H hold and the restore hashes match. Any deviation is a
skill-text bug: fix SKILL.md, not the test.
````

- [ ] **Step 4: Execute the round-trip test per `tests/TESTING.md`**

Run the whole procedure (copy fixture to scratch, forget pass with the tester
approving at the gate, assertions A-H, restore pass, hash compare).
Expected: all assertions hold; restore hashes match baseline.

- [ ] **Step 5: Fix and re-run until green**

If any assertion fails, the fix goes in `skills/forget/SKILL.md` wording
(tighten the step that was misread). Re-run from Setup. Do not weaken the test.

- [ ] **Step 6: Commit**

```bash
git add tests/ .gitignore
git commit -m "add fixture memory test assets and procedure"
```

---

### Task 5: Local install and one real run (user-gated)

**Files:**
- None created. This task validates the shipped plugin end to end.

**Interfaces:**
- Consumes: everything committed in Tasks 1-4.

- [ ] **Step 1: Install the plugin locally (interactive Claude Code session — the user runs these)**

```
/plugin marketplace add D:\R_and_D\claude-memory-tools
/plugin install memory-tools@claude-memory-tools
```

- [ ] **Step 2: Real run in the DoZen project**

In a DoZen.KnowledgeEngine session, the user picks one genuinely discarded
effort from their memory index and runs `/forget <that concern>`. Verify the
gate shows sensible candidates, confirm, and check the report plus
`memory/.trash/` afterward.

- [ ] **Step 3: Publish (optional, user decision)**

Create the GitHub repo, replace OWNER in plugin.json homepage and README
install line, push, and re-add the marketplace from GitHub.

---

## Self-review record

- Spec coverage: flow steps 1-9, trash format, `.claudeignore` honesty rule,
  error rows (no memory dir, zero matches, decline, collision, index mismatch),
  non-goals (nothing in SKILL.md touches CLAUDE.md/MCP/transcripts), testing
  plan (fixture round-trip + real run) — all present in Tasks 1-5.
- Placeholder scan: OWNER in two install strings is a deliberate publish-time
  substitution, called out in Task 1 and Task 5; no TBDs remain.
- Type/name consistency: `memory-tools`, `claude-memory-tools`, `forget`,
  `.md.trashed`, `TRASH.md`, `.claudeignore` spelled identically across
  Tasks 1-4 and the fixture assertions.
