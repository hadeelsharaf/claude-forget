# Local eval suite

Run with `claude plugin eval`; results land in `evals/results/` (gitignored).
Evals stay local by design (no CI job).

Read-only gate cases (no tool grants needed):

    claude plugin eval . --scaffold --trust-plugin --tag gate --ablation none

Apply cases need write tools and a sandbox backend (Linux: bubblewrap + socat;
Windows: run under WSL2):

    claude plugin eval . --scaffold --trust-plugin --tag apply --ablation none \
      --allow-tools Write Edit "Bash(mv *)" "Bash(mkdir *)" "Bash(grep *)" \
      "Bash(date *)" "Bash(ls *)" "Bash(nl *)" "Bash(wc *)" "Bash(cat *)" "Bash(sed -n *)"

There is no `tool_used: Skill` grader: the cases invoke the skills by slash
command, which expands into the prompt without a Skill tool call, and every
skill sets `disable-model-invocation: true`, so the Skill tool can never fire.
The content graders (gate text and produced files) are what prove the skill
ran. For the same reason the no-plugin baseline arm is not useful here; pass
`--ablation none`.

`--scaffold` runs each case's `fixture.sh` (copies `tests/fixture-memory-baseline`
or generates the index fixture); only pass it for suites you trust, this one is
in-repo. Use `--runs 1` while iterating; the default is 3 runs per case.

Status 2026-11-05: the three gate cases pass (forget-gate 2/2 runs, checkup-gate
and checkup-index-gate 1/1). The apply cases have not been run yet: they need
a sandbox backend, which the authoring machine lacked. Their prompts
pre-approve the confirm gate in the same message; if a run stops at the gate
instead (score 0 on the file graders), record a gate turn as
`context.history_file` and make the prompt the plain "yes".
