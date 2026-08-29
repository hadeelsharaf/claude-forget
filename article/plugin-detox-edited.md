# I Installed Every Trending Claude Plugin. Then I Turned Them All Off.

## A lesson paid for in tokens and time

*[Header image: keep the Unsplash photo, or use `images/01-stacking-timeline.png`]*

Months of plugin stacking on a real project taught me — the expensive way — about tokens, teams, and knowing what I actually need.

I work on a backend data-processing pipeline. It is the kind of codebase where one wrong change can silently drop a piece of output, and nobody notices for a month — no matter how much you automate or how well you train the quality engineers. We are a team of four developers, all using Claude Code every day, with the quality team joining us for a share of their time based on needs and delivery dates.

Over the past months I went through the full plugin life cycle: discovery, excitement, stacking, chaos, and — at the end — a detox. This article is the honest version of that story, including the part where I made things worse.

## Phase 1: ruflo and Graphify — the good start

I started with two plugins: [ruflo](https://github.com/ruvnet/ruflo) (a multi-agent orchestration platform, the evolution of claude-flow) and [Graphify](https://github.com/Graphify-Labs/graphify) (it turns a codebase into a knowledge graph you can query). The output was impressive for a while, and I wrote about it at the time.

These two earned their place fast, for two reasons: real token savings and real architecture improvement.

With Graphify, the agent no longer needed to re-read half the repository to answer questions like "what calls this function?" or "how does this pipeline stage connect to that one?" The knowledge graph answered structure questions cheaply, and the saved tokens added up every day.

ruflo's value came mostly from its SPARC agents.

### A short brief on SPARC

SPARC stands for **Specification, Pseudocode, Architecture, Refinement, Completion**. It is a development methodology built into ruflo as a set of specialized agent modes. Instead of one general agent doing everything in one long conversation, each phase gets an agent with one job: pin down what the change must do, sketch the algorithm as plain logic, decide where the change lives and what it must not touch, iterate against the spec, and finally integrate and verify.

In practice, three of these modes did the heavy work for me:

- **The SPARC architect** forced design decisions to happen before the code existed. On a pipeline codebase with strict "do not break existing behavior" rules, this discipline alone prevented several bad fixes. Its decisions matched our goals for the file structure so well that we started inviting it into code reviews as the architectural voice: where to split a large module, and how to separate concerns more cleanly.
- **SPARC review** gave consistent, structured code review, instead of a review that depends on my mood and energy that day.
- **SPARC deep analysis** was always an eye-opener. When I pointed it at a bug I thought I understood, it often found a root cause two layers below my theory. If I could keep only one mode, it would be this one.

These are not abstract claims. I went back through my plans folder while writing this, and the evidence is there:

- The bug backlog that drove months of fixes was written by a SPARC analyzer deep-dive session, not by me.
- When we compared a big refactor branch against the legacy one, a SPARC analyzer trace produced the verdict as a capability matrix: what progressed, what improved, what drifted, and what was missing. Each gap became a staged fix plan, with regression tests landed first as expected failures. I would not have produced a comparison of that quality by hand on a deadline.
- One architecture plan in my folder describes its own method: parallel readers, root-cause synthesis, a multi-angle design panel, and adversarial reviews. More than a dozen agents in one review. It sounds crazy until you read the plan and see that every important claim was re-verified against the code.

At this point my setup was healthy: two plugins, each with a clear job, both saving more than they cost.

## Phase 2: Following the trend — where the big mistakes started

Then I did what everyone does. Our organization started talking about [superpowers](https://github.com/obra/superpowers) (a workflow-discipline plugin: brainstorming before building, systematic debugging, plan-driven execution). I installed it. A couple of days later I saw colleagues trying [mattpocock/skills](https://github.com/mattpocock/skills), so I installed that too, mostly to stay close to what the team was using. (Please don't judge.)

This is where the big mistakes started.

To be fair, mattpocock's skills were effective, and a few pieces deserve real credit. They are perfect at turning QE-reported bugs into agent-ready tasks: a vague defect report goes in, and a scoped, structured, executable task comes out. The merge-conflict skill made handling branch conflicts much easier. And the best gift was the meta one: the skill about writing great skills. I used it to improve my own project's local skills, and the SKILL.md files came out more accurate, with better descriptions and better triggers. If you work alone, those three things might justify the install.

But we are not one person. We are four developers, and we do not all use the same frameworks or the same plugin stack. The problems showed up quickly:

- **The task style did not fit the team.** Agent-ready tasks are written for an agent with a specific setup. A teammate on a different setup opens one and sees steps they cannot execute.
- **Our project managers got confused.** Technical, agent-formatted tasks started to appear in the shared backlog next to normal user stories. The PMs could not tell which item was a real deliverable and which was agent scaffolding.
- **We could not isolate them.** The obvious fix — a separate dashboard only for agent tasks — was not allowed under our organizational rules. So the noise stayed in the main backlog, bugging whoever reviewed it to filter out the AI-generated tasks.

A tool can be excellent and still be wrong for your team. That was lesson one.

## Phase 3: The token bill arrives

The second problem was quieter and more expensive: **sub-agents eat tokens like hell.**

Both superpowers and the skills-driven workflows love to spawn sub-agents. A researcher here, a reviewer there, a brainstormer to start things off. Every one of them runs on a model, and by default every one of them inherits your most expensive model. Nobody decides this. It just happens, silently, on every spawn.

My quota did not survive the first serious week.

The fix that actually helped was forcing a rule into my global instructions: **every sub-agent must get a model assigned explicitly, chosen by task complexity.**

*[Insert `images/02-model-tiers.png` here]*

- A small model for mechanical work: renames, fully specified edits, transcription.
- A mid-tier model for normal work: multi-file changes, debugging, standard reviews.
- The top model only for hard judgment: architecture, design trade-offs, and the final whole-branch review.

One thing I learned the hard way: **turn count beats token price.** A cheap model that needs three times more turns can cost more than a mid-tier model that finishes in one. So the mid-tier became my floor for anything that reasons from prose instead of executing ready code.

This tiering rescued my quota for a while. But notice what happened: I was now writing infrastructure to manage my plugins. That should have been a warning sign.

## What superpowers got right

I want to be fair here, because one superpowers feature gave me something I did not expect: **it reduced the randomness of the LLM across people.**

The brainstorming skill asks you questions before any feature work starts. What is the goal, what are the constraints, what already exists. Two of us on the team, working separately on our own requests, noticed we were getting almost the same questions and being pushed in the same directions when our tasks were similar.

That is a very good property for a team. Normally, the same request given to two developers' agents produces two different plans, shaped by two different conversations. Brainstorming worked like a shared checklist that nobody had to maintain. For team alignment, that one skill was worth its tokens.

Two honest notes on that praise, though.

First, brainstorming is not the most creative option I tried. [Wayfinder](https://github.com/mattpocock/skills) is much more creative; it explores directions that brainstorming never offers. But neither of them is perfect with the legacy code I maintain. They shine when the ground is new, and they struggle when every "fresh idea" must survive years of existing constraints and code that must not change.

Second, these workflows force test-driven development. TDD is a fine discipline, but my codebase runs on a different rule: prove the diagnosis with a standalone proof-of-concept script before touching any production code. Forcing tests-first on top of a POC-first workflow means paying twice. Tokens go to writing tests for a theory, and then more tokens go to the POC that sometimes kills that theory. That is token consumption of the unwise kind — spent on a workflow mismatch instead of the problem.

## Phase 4: When auto-mode goes rogue

The same plugin stack had a darker mode. Sometimes, no matter what the instructions said, auto-mode simply went too far. The anti-drift instructions in my CLAUDE.md file were ignored — loudly.

I would ask a simple question. No action needed. Just a question. And the agent would start reaching out to cloud resources and preparing for work nobody asked for. A question about whether something was configured became a mission to go configure it, or to use MCP servers to hunt the backlog for tasks about configuring things.

The token consumption was massive in a second way too: verbosity. All my CLAUDE.md instructions about keeping answers brief and in bullet points were effectively overwritten by the plugins' own prompts. The skill instructions arrive later and louder, and my "be brief" rules simply lost the argument.

That is what pushed me to install [caveman](https://www.claudepluginhub.com/plugins/juliusbrussee-caveman), a plugin that compresses the agent's output style. It removes filler, pleasantries, and narration, and keeps all the technical substance. I run it in lite and medium modes; the full mode is fun but too compressed when I hand findings to a teammate. My own instructions could not win the verbosity war, but a plugin fighting at the same layer could.

I also started forcing agents to begin big tasks in fresh sessions, instead of dragging one bloated context across the whole day. I wrote before about why making the agent forget on purpose is a feature, not a bug: [I Made My AI Coding Agent Forget on Purpose](https://medium.com/generative-ai/i-made-my-ai-coding-agent-forget-on-purpose-33af6b7b2421).

Read that paragraph again: **I installed a plugin to fix the problems my other plugins caused.** That was the moment this stopped being funny.

## One last investigation before the detox

Before turning everything off, I ran one deep investigation with two questions: which plugins rewrite my CLAUDE.md rules file, and why do sub-agents ignore rules that are clearly written there?

The findings surprised me.

*[Insert `images/03-investigation-stats.png` here]*

**Who can rewrite the rules file?** More plugins than I expected. One plugin had generated the file in the first place, and its force mode could overwrite the whole file with a template. Another plugin compresses the file and stores the backup far away from the project. A third appends its own section to it. Two installed agent playbooks would even push a "standardized" rules file over mine during normal repository work.

And two plugins inject their own instruction blocks at session start, *after* my rules load, so their instructions arrive later and speak louder. This finally explained why my "keep answers brief" rules kept losing the argument.

**Why did agents ignore the rules?** The honest finding was that they were not the rebellious teens I had imagined. The biggest cause was simple and a little embarrassing: my rules file was ignored by git. It existed only on my machine, untracked — my motive was to give each team member space to set the rules they understand and need. So every time a workflow created a fresh git worktree for a sub-agent, that worktree contained no rules at all. Eleven worktrees on my machine, and not one had the rulebook. On top of that, some built-in exploration agents skip the rules file by design.

One review skill searches for a standards file under a different name, finds nothing, and falls back to a generic refactoring guide that tells reviewers to do exactly what my rules forbid. And the dispatch templates send short, task-only prompts that never mention the rules.

I measured it: across sixty recorded sub-agent runs, the key phrases from my rulebook appeared in the agents' output **zero times**.

**The small fixes that helped.** I tracked the rules file in git, so every new worktree now carries it. I added one hard rule: every sub-agent prompt must carry the rules pointer inline, because a pasted instruction always beats an ambient file. And I built two small project-local agent roles that hold the rules inside their own definitions.

These fixes made a real but minor improvement. Then I looked at the effort: I had to reverse-engineer nine plugins just to make my own rules file survive the day. That effort is a big part of why the detox decision became easy.

## The two problems no plugin fixed

After all of this, two problems remained. They are the ones that finally forced a decision.

**1. I lost my one centralized place for plans and specs.** Here is the painful irony. My plans folder is one of the best things the agents and I ever built together: well over a hundred dated plan files in a few months, one naming convention, plus a "done" index that records every closed plan as Problem, Fix, and Outcome. (The very first file in it is a plan to fix a token-limit bug.) A mandatory impact analysis appears in almost every one of them. It became a ritual.

But when the plugin stack grew, the truth about each task stopped living in one place. The plan lives in the plans folder. The execution ledger, the per-task reports, and the test baselines live in the workflow plugin's own folder structure. Session knowledge lives in the memory layer. Each convention is fine alone. Together, "where is the full story of X?" now has three answers — no single source of truth — and you must know which plugin created an artifact to know where to look.

**2. I do not know how my colleagues will execute the agent-ready tasks.** I can show this one literally. My newer plan files open with this header:

```
*For agentic workers: REQUIRED SUB-SKILL:
Use superpowers:subagent-driven-development (recommended) or
superpowers:executing-plans to implement this plan task-by-task.*
```

My plan files now require a specific plugin to be executable as designed. A teammate with different plugins, or with none, opens that plan and the first line is an instruction their setup cannot follow.

We built tasks for agents without agreeing, as a team, on which agent setup would run them. That is not a tooling gap. It is a coordination gap, and no marketplace install will close it. I think I will keep it open for a while, as the team still delivers and still explores plugins and skills.

## The detox

So this is my decision: I am turning off all of these plugins. Then I will add back only what I really need, one by one. No global plugin installs — project level only.

Not because the plugins are bad. Each one was useful at some moment. SPARC analysis found real root causes. mattpocock's skills turn bug reports into tasks better than I do by hand. Brainstorming aligned two developers without a meeting.

The problem is the stack. Together, the plugins fought over my instructions, my tokens, my backlog, and my plans folder. I could no longer predict what my own setup would do. And prediction is the whole reason I added process in the first place — it is the control I need over the harness.

One thing makes this detox easy: the good habits stay even when the plugins go. The proof-of-concept gate that once caught an agent fix which passed every unit test but corrupted real data. The test baselines compared by test IDs, not by totals. The dated plans with a mandatory impact analysis. The plugins taught me these habits, but the habits do not need the plugins anymore.

*[Insert `images/04-reinstall-filter.png` here]*

A plugin comes back only if it passes four simple questions:

1. **Does it save more tokens than it spends?** Measured, not felt.
2. **Does it work for the whole team**, not only for me?
3. **Does it follow the organization's rules** as they are?
4. **Do my own instructions still win** over its instructions?

I expect very few plugins to survive this filter. Maybe a graph or memory layer, and one process skill for the team. Not much more.

If every new plugin still feels like a superhero to you, I will not tell you to stop. Some of them are. Just watch for one moment: the day you install a plugin to fix your plugins.

That is the day to start counting.

## Conclusion

If you take only two things from my story, take these:

1. **A plugin is not good or bad by itself. It is good or bad *for your team*.** The same skill that turns a bug report into a perfect agent task can also confuse your project managers and split your team's workflow. Test every plugin against your team and your organization's rules, not against a demo video.
2. **The plugins go, but the habits stay.** The real value of this journey was not any single tool. It was the working habits the tools forced on me: plan first, prove the diagnosis before changing the code, watch the token bill, and keep my own instructions in charge. Those habits cost nothing and need no install.

If you run a multi-developer team on a shared Claude plugin stack and it works, I really want to hear how — especially how you keep the backlog readable for the non-developers.

---

*Hadeel Sharaf is a backend engineer working on data-processing pipelines, writing about the practical side of AI-assisted development. More stories on [Medium](https://medium.com/@hadeelsharaf) · open-source work on [GitHub](https://github.com/hadeelsharaf), including [claude-forget](https://github.com/hadeelsharaf/claude-forget), a memory-lifecycle plugin for Claude Code.*
