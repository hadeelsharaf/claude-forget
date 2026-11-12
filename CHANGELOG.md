# Changelog

All notable changes to the memory-tools plugin. Users only receive an update
when the `version` in `.claude-plugin/plugin.json` changes.

## 0.4.1 - 2026-11-12

Internal structure; no change to what /forget does, small changes to
/checkup and /restore wording.

- Shared skill text has one source: `src/shared/` holds the Locate step,
  the manifest header and the manifest rules; `src/skills/` holds the
  templates for /forget, /restore and /checkup. `sh scripts/build-skills.sh`
  writes `skills/*/SKILL.md`; CI fails when they are out of date. /fresh and
  /recall stay hand-written.
- New read-only `scripts/memory-scan` (`stamps`, `index`): the freshness
  hook and /checkup now read stamps with the same code, and /checkup takes
  its index numbers (lines, bytes, dangling lines, orphans) from the script
  instead of counting by hand. Hand counting stays as the fallback.
- /restore: the Scope line now names `--agent` folders, as the steps
  already did.
- Scanner details: an empty topic file counts as existing; a link to
  `MEMORY.md` itself is ignored; links with a title or in `<angle brackets>`
  resolve; when a file carries a malformed and a well-formed `review-after`
  line, the well-formed one is used.
- `build-skills.sh --check` and the tests ignore line endings, so a Windows
  (CRLF) checkout passes.
- New `tests/run-scan-test.sh`, run in CI beside the hook test.

## 0.4.0 - 2026-11-05

Feature release: restore, index health, subagent memory. Every change keeps
the rule that nothing is ever deleted and everything can be undone.

- Skills: `when_to_use` carries the trigger text so descriptions stay short;
  `compatibility` states the tested Claude Code version. (`arguments` was
  not adopted: the `--agent` prefix would break named positional args.)
- /forget: a line that names the effort always makes its file a PARTIAL
  candidate; the user decides at the gate (one eval run had dropped such a
  line as incidental).
- Local eval suite in `evals/` for `claude plugin eval`: gate cases for
  forget, checkup and index health (read-only), apply cases for forget and
  restore (need tool grants and a sandbox backend). Evals stay local.
- Banner lists /restore.

- /restore: new skill that undoes one /forget or /checkup entry from the
  manifest: lists open entries, dry run, one confirm, marks the entry
  `RESTORED <date>`. Never deletes an entry or a file.
- Manifest format 2: `Manifest format: 2` header line and `(at line N)`
  anchors on every Removed, Original and Added block, written by /forget and
  /checkup. Format-1 manifests still restore, with manual placement.
- Subagent memory: `--agent <name>` on /forget, /checkup, /recall and
  /restore selects that agent's folder (`.claude/agent-memory/<name>/`,
  `.claude/agent-memory-local/<name>/`, or `~/.claude/agent-memory/<name>/`);
  `--agents` on /checkup and /recall covers the project folder plus every
  agent folder. The hook scans agent folders and lists overdue files as
  `<name> (agent): file`. Gates say when a folder is inside the repository.
  Fixture `tests/fixture-agent-memory/reviewer/`, hook cases 19-21, and
  Part 5 in `TESTING.md`.
- /checkup index health: the gate starts with `MEMORY.md` lines and KB
  against the 200-line / 25 KB load limit (OVER LIMIT names the lines that
  never load), orphan files, and dangling index lines. New TRIM action
  removes a dangling or historical index line, manifest-recorded with its
  anchor; /restore puts it back. Fixture generator
  `tests/make-index-fixture.sh` and Part 3b in `TESTING.md`.
- Tests: Part 4 restore round trip and anchor assertions in `TESTING.md`.
  Both forget+restore and checkup+restore round trips were run against the
  fixture: every file matched the baseline byte for byte afterwards.

## 0.3.1 - 2026-11-04

Fix release: keeps the freshness hook working with current Claude Code.

- Hook: the memory folder is now found the way Claude Code finds it. Order:
  `autoMemoryDirectory` from settings (managed, then project local, project,
  user), then `CLAUDE_CODE_PROJECT_DIR_NAME` beside `CLAUDE_CONFIG_DIR`, then
  the slug of the git repository root, then the old launch-folder slug.
  Before this, launching Claude Code in a subfolder of a repo, or moving the
  memory folder with a setting, made the hook silently find nothing.
- Hook: `CLAUDE_CONFIG_DIR` is respected instead of a hard-coded `~/.claude`.
- Hook: also runs after `compact` and on `fork`, so the stale warning
  re-enters context when memory is re-read after compaction.
- Hook: fixed "status 126" on Linux and macOS. The hook scripts were
  committed without the executable bit, so bash could not run them and the
  hook never fired on those platforms. The script is now executable in git,
  and the hook command runs it through `bash` explicitly so it no longer
  depends on the bit. The polyglot `run-hook.cmd` wrapper is gone: Claude
  Code runs hooks under Git Bash on Windows, which Claude Code requires
  anyway. Verified end to end: a session launched from a subfolder of a
  repo received the warning.
- Hook: a memory folder named by `autoMemoryDirectory` or by the project
  name override is final. If it does not exist yet, the hook stays silent
  instead of scanning the legacy folder Claude no longer loads.
- Hook: user-scope subagent memory is scanned under `~/.claude/agent-memory`
  and, when `CLAUDE_CONFIG_DIR` differs, under the config dir too.
- Tests: eight new hook cases cover every lookup path.
- Packaging: plugin icon, keywords, repository and JSON schema; marketplace
  description, category and tags. `claude plugin validate --strict` is clean.
- CI: GitHub Actions runs the hook test and the strict validator.
- Docs: README explains how the memory folder is found and the 200-line /
  25 KB `MEMORY.md` load limit; subagent memory folders listed as not covered.

## 0.3.0

- /fresh: instruction-level memory quarantine for the session.
- /recall: read-only pull of one memory topic, with STALE tags.

## 0.2.0

- /checkup: find stale status memories and fix them with one confirm.
- SessionStart freshness hook warning about overdue `review-after` stamps.

## 0.1.0

- /forget: reversible trashing of auto-memories about a discarded effort.
