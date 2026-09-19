# bench — does rawcode actually help?

A reproducible A/B test of the rawcode system prompt against the Claude Code baseline, using a **standard dataset graded by executable unit tests** — no LLM judge, so no position or verbosity bias.

```bash
./run.sh 40        # 40 HumanEval problems, baseline vs rawcode
```

## Method

- **Dataset:** [HumanEval](https://github.com/openai/human-eval) (164 Python problems, each with a hidden unit-test suite).
- **Conditions:** identical `claude -p` calls; the rawcode arm appends `agents/rawcode.md` via `--append-system-prompt`. Paired — both arms see the same problems, which cancels per-problem difficulty.
- **Metric:** pass@1 (standard) graded by running the problem's own tests. Correctness and output-token count are recorded and analysed as **separate axes** — a concise prompt must cut tokens *without* lowering pass@1 to count as a win.
- **Stats:** `analyze.py` reports McNemar's exact test on the discordant pairs (correctness) and a paired bootstrap 95% CI (tokens). A point estimate without a CI is not a claim.

## Last run (v2.1, n=40, single greedy sample, isolated)

| Axis | Baseline | rawcode | Paired Δ (95% CI) |
|------|---------:|--------:|-------------------|
| Correctness (pass@1) | 97.5% | 97.5% | +0.0% · McNemar p=1.00 → no change |
| Output tokens/problem | 130 | 118 | −9% [−38, +9] → not significant |

Runs are isolated (`--setting-sources project --strict-mcp-config`), so both arms see bare Claude Code and not the runner's personal plugins, hooks, or MCP servers. The v2.0 run (90%→95% pass@1, −35% output, 229→150 tokens) was not isolated. Its baseline was twice as verbose, which left more output to cut.

Read: v2.1 leaves correctness unchanged. On bare Claude Code, output is already short, so there is little left for the prompt to cut. For the cost that actually dominates (input), see the agentic benchmark below.

## Caveats (read before trusting the numbers)

- **Contamination.** HumanEval is partly in model training data ([Riddell et al. 2024](https://arxiv.org/abs/2403.04811)). A paired A/B cancels most of this, but one prompt could still cue memorised recall differently.
- **Weak tests.** Vanilla HumanEval under-tests; [HumanEval+](https://github.com/evalplus/evalplus) adds ~80× more cases and is the stronger follow-up.
- **Small N / single sample.** n=40 with one greedy sample: the correctness CI is wide (small effects undetectable); the token effect is robust. For pass@k, raise the sample count.
- **Codegen only.** This does not test long agentic loops, where Anthropic has reported over-aggressive conciseness can [hurt quality](https://www.anthropic.com/engineering/april-23-postmortem). rawcode's brevity rule deliberately binds to the final response, not to investigation or verification.

## Agentic token benchmark (`agentic/`)

HumanEval only prices output. In real sessions the bill is **input**: every turn re-reads the whole context and every subagent reloads the system prompt. On one heavy user's 45-day log (91.5k requests), cache reads were 63% of cost, cache writes 34%, output 3%. So a prompt must also be judged on what it costs per turn.

```bash
cd agentic && BENCH_MODEL=opus python3 agentic.py 3 HEAD && python3 analyze.py
```

- **Fixture:** `make_fixture.py` builds a ~25-module Python repo, wider than any task needs, so reading everything costs tokens and searching narrowly doesn't.
- **Tasks (5):** bugfix, feature + test, cross-file rename, multi-file trace-and-fix + regression test, read-only question. Each is graded by an executable check (unit tests, grep, `git diff --quiet`).
- **Arms:** `baseline` (no appended prompt), `rawcode@<ref>` (the prompt at a git ref), `rawcode` (working tree). Optional `HARNESS_GATE=<script>` adds an arm that forbids main-session edits.
- **Metric:** total input tokens (fresh + cache write + cache read) summed over every model in the session, subagents included, plus cost. Paired by (task, rep).

### Results (Opus, 3 reps)

Round 2 (`results.jsonl`, 45 runs, 5 tasks). Pass rate was 100% in every arm.

| Comparison (paired) | Cheaper in | Sign test | Median Δ input (95% CI) |
|---|---:|---:|---|
| v2.0 prompt vs baseline | 2/15 | p=0.007 | **+14.2%** [+12.4%, +36.9%] |
| v2.1 prompt vs v2.0 | 14/15 | p=0.001 | **−9.1%** [−27.2%, −8.1%] |
| v2.1 prompt vs baseline | 5/15 | p=0.30 | +4.0% [−16.6%, +4.9%], not significant |

Round 1 (`round1.jsonl`, 48 runs, 4 tasks) had already shown v2.0 at +15.9% mean input vs baseline. It also showed that a gate forbidding main-session edits changed nothing on these short tasks: the model edited through Bash instead of delegating.

**Reading:** v2.0 repeated much of what Claude Code's own system prompt already says, and paid for it again on every turn. v2.1 keeps only what the base prompt lacks (minimalism, root cause, honesty, context budget), which costs about the same as no prompt. The real savings are in session configuration (auto-compact window, skill listing, subagent use), not in the persona text.

### Installed plugin vs no plugin, real user config (`installed.jsonl`)

`BENCH_ISOLATE=0` runs against the installed setup: plugins, hooks, and the harness edit gate. rawcode 2.1 was installed as a plugin (agent + output style), then disabled with `claude plugin disable`. 5 tasks × 3 reps on Opus.

| Arm | Pass | Mean input | Mean cost |
|---|---:|---:|---:|
| plugin on (2.1) | 15/15 | 141.9k | $0.286 |
| plugin off | 15/15 | 161.5k | $0.312 |

Paired: on was cheaper in 11/15, with a median of −5% (95% CI −24.0%..+0.8%) and a sign test of p=0.12. The direction is favorable but not significant, and there is no quality regression. A probe confirmed the rawcode prompt appears exactly once through the plugin (agent + output style do not duplicate it) and that a bare "ok" request costs ~1.2k fewer tokens with the plugin on.

**Caveats:** these are short tasks (2-10 turns) with n=15 pairs. They measure per-turn overhead and basic behavior, not long sessions where context growth dominates.
