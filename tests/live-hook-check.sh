#!/bin/sh
# Live check of the memory-tools freshness hook on THIS machine.
# Run from anywhere (Git Bash on Windows, WSL, macOS, Linux):
#   sh tests/live-hook-check.sh            # update plugin, then check
#   sh tests/live-hook-check.sh --no-update
#
# What it does:
#   1. updates the plugin from the marketplace and prints the version
#   2. makes a scratch git repo with a subfolder
#   3. asks a real Claude Code session (started in that subfolder) where its
#      auto-memory folder is; plants one overdue note there
#   4. starts another session in the subfolder and checks that the
#      [memory-tools] warning reached the model, and that the hook exited 0
#   5. removes only what it planted
# Needs: claude on PATH and a logged-in Claude Code. Costs two tiny haiku calls.
# If sessions here do not state a memory path (auto memory off), set
# MEMORY_DIR=<folder Claude uses for the scratch repo> to skip step 3.
set -u
here=$(cd "$(dirname "$0")" && pwd)
fixture="$here/fixture-memory-baseline/project_build_pipeline_status.md"
pass=0; fail=0
ok()   { echo "PASS: $1"; pass=$((pass + 1)); }
bad()  { echo "FAIL: $1"; fail=$((fail + 1)); }
note() { echo "      $1"; }

if [ "${1:-}" != "--no-update" ]; then
  echo "== 1. update plugin"
  claude plugin marketplace update claude-forget 2>&1 | tail -n 1
  claude plugin update memory-tools@claude-forget 2>&1 | tail -n 1
fi
ver=$(claude plugin list 2>/dev/null | awk '/memory-tools@claude-forget/{f=1} f && /Version:/{print $2; exit}')
[ -n "$ver" ] && ok "plugin installed, version $ver" || bad "memory-tools@claude-forget is not installed"

echo "== 2. scratch repo"
work="${TMPDIR:-/tmp}/memory-tools-livecheck-$$"
mkdir -p "$work/repo/sub" && cd "$work/repo" && git init -q && echo hi > README.md \
  && git -c user.name=t -c user.email=t@t add README.md \
  && git -c user.name=t -c user.email=t@t commit -qm init
cd "$work/repo/sub"
[ -f "$fixture" ] || { bad "fixture not found: $fixture (run from the repo checkout)"; exit 1; }

echo "== 3. where does Claude keep memory for this repo?"
if [ -n "${MEMORY_DIR:-}" ]; then
  mem="$MEMORY_DIR"; note "using MEMORY_DIR override: $mem"
else
mem=$(claude -p --model haiku "Reply with ONE line only: the absolute path of your auto-memory directory exactly as stated in your system prompt (the folder that holds MEMORY.md), or the single word NONE if none is stated." 2>/dev/null | tr -d '\r' | grep -v '^$' | tail -n 1)
note "session says: $mem"
case "$mem" in
  NONE|"")
    echo "WARN: sessions here state no memory path (auto memory off: cloud/background session, autoMemoryEnabled, or CLAUDE_CODE_DISABLE_AUTO_MEMORY)."
    # Fall back to the folder the hook itself predicts (git root slug), so the
    # hook-to-model chain is still exercised. Not confirmed by Claude Code.
    gr=$(git rev-parse --show-toplevel)
    case "$gr" in /[A-Za-z]/*) dl=$(printf '%s' "$gr" | cut -c2 | tr 'a-z' 'A-Z'); gr="$dl:${gr#/?}";; esac
    mem="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(printf '%s' "$gr" | sed 's/[^A-Za-z0-9]/-/g')/memory"
    note "using the hook's predicted folder instead: $mem" ;;
  *) mem=$(printf '%s' "$mem" | sed 's/^`//; s/`$//; s:[/\\]*$::')
     ok "session states its memory folder" ;;
esac
fi

planted=""; created_dir=""
if [ -n "$mem" ]; then
  [ -d "$mem" ] || { mkdir -p "$mem" && created_dir="$mem"; }
  if [ -e "$mem/project_build_pipeline_status.md" ]; then
    bad "a file with the fixture's name already exists in $mem; not touching it"
  else
    cp "$fixture" "$mem/" && planted="$mem/project_build_pipeline_status.md" && ok "planted overdue note in $mem"
  fi
fi

if [ -n "$planted" ]; then
  echo "== 4. live session from the subfolder"
  dbg="$work/debug.log"
  out=$(claude -p --model haiku --debug-file "$dbg" "If your context contains a line starting with [memory-tools], repeat that whole hook message verbatim. Otherwise reply NO-WARNING." 2>/dev/null | tr -d '\r')
  printf '%s\n' "$out" | grep -q '\[memory-tools\] 1 memory file(s) past their review-after date' \
    && ok "warning reached the model" || { bad "model did not see the warning"; note "model replied: $(printf '%s' "$out" | head -n 3)"; }
  printf '%s\n' "$out" | grep -q 'project_build_pipeline_status.md (review-after 2026-07-01)' \
    && ok "planted file listed" || bad "planted file not listed"
  if grep -q 'SessionStart:startup .*memory-tools.*finished with status 0' "$dbg" 2>/dev/null; then
    ok "hook finished with status 0"
  elif grep -q 'memory-tools.*finished with status' "$dbg" 2>/dev/null; then
    bad "hook finished with a non-zero status:"; grep 'memory-tools.*finished with status' "$dbg" | head -n 2
  else
    bad "no hook status line in the debug log (did the plugin load?)"
  fi
fi

echo "== 5. cleanup"
[ -n "$planted" ] && rm -f "$planted"
[ -n "$created_dir" ] && rmdir "$created_dir" 2>/dev/null
cd / && rm -rf "$work"
echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
