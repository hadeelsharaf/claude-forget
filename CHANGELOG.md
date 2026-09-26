# Changelog

## 0.3.1 (2026-09-26)

- Hook: the git-bash `/x/...` to `X:/...` path rewrite now runs only on
  Windows shells (MINGW/MSYS/Cygwin). Before, a Linux or macOS project under
  a single-letter folder (for example `/w/app`) was looked up under the
  wrong memory folder, so the freshness warning never showed.
- Hook: also runs after context compaction, so the stale-memory warning is
  not lost when the session is summarized.
- New `tests/check-consistency.sh`: checks that the TRASH.md header,
  recording rule, and Locate step stay identical in /forget and /checkup,
  and that the plugin manifests agree.
- CI: GitHub Actions runs the hook test on Linux, macOS, and Windows, plus
  the consistency check and shellcheck.

## 0.3.0 (2026-08-13)

- New `/fresh` skill: work memory-free in a session (instruction-level
  quarantine).
- New `/recall` skill: read-only pull of one named memory topic.

## 0.2.0 (2026-08-13)

- New `/checkup` skill: find and fix stale status memories.
- New SessionStart freshness hook: warns about overdue `review-after` stamps.

## 0.1.0 (2026-08-11)

- First release: `/forget` skill — reversible trashing of auto-memories with
  a restore manifest.
