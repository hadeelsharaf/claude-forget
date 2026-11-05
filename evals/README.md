# Local eval suite

Run with `claude plugin eval`; results land in `evals/results/` (gitignored).
Evals stay local by design (no CI job).

Read-only gate cases (no tool grants needed):

    claude plugin eval . --scaffold --trust-plugin --tag gate --ablation none

Apply cases need write tools and a sandbox backend (Linux: bubblewrap + socat;
Windows: run under WSL2). Two things matter, both learned the hard way:

- Grant plain `Bash`. Narrow grants such as `Bash(mv *)` match only commands
  that start with `mv`; the skills open with compound commands (`cd … &&
  ls && grep`), which get denied, so the model concludes Bash is unavailable
  and correctly refuses to move files by copying. The eval sandbox still
  confines writes to the run's workspace.
- Point `TMPDIR` outside `/tmp`. The run's workspace is created under
  `TMPDIR`, and the generated sandbox config denies writes to `/tmp` as a
  whole, which wins over the workspace's allow entry: `mv`, `mkdir` and
  `touch` fail with "Read-only file system" while Edit and Write still
  work. WSL and most Linux boxes default `TMPDIR` to `/tmp`.

    mkdir -p "$HOME/evaltmp"
    TMPDIR="$HOME/evaltmp" claude plugin eval . --scaffold --trust-plugin --tag apply \
      --ablation none --allow-tools Write Edit Bash

`--scaffold` runs each case's `fixture.sh` (copies `tests/fixture-memory-baseline`
or generates the index fixture); only pass it for suites you trust, this one is
in-repo. Use `--runs 1` while iterating; the default is 3 runs per case.

Status 2026-11-05: all five cases pass. Gate cases: forget-gate 2/2 runs,
checkup-gate and checkup-index-gate 1/1. Apply cases: forget-apply and
restore-apply 1/1 with every grader green, and the restored folder matched
the baseline fixture byte for byte. The apply prompts pre-approve the confirm
gate in the same message; in every run the model showed the gate and went on
in the same turn, so no recorded gate turn is needed.

Observed behaviour when writes are blocked (useful when reading a partial
score): /forget applies nothing rather than leave MEMORY.md pointing at files
it could not move; /restore pastes what it can, does not re-add index lines
for files it could not move back, and does not mark the entry RESTORED. Both
report exactly what was skipped. A low score with "Read-only file system" in
the trace means the `TMPDIR` problem above, not a skill regression.
