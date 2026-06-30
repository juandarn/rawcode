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

## Last run (n=40, single greedy sample)

| Axis | Baseline | rawcode | Paired Δ (95% CI) |
|------|---------:|--------:|-------------------|
| Correctness (pass@1) | 90.0% | 95.0% | +5.0% [0, +12.5%] · McNemar p=0.50 → no significant change |
| Output tokens/problem | 229 | 150 | −35% [−138, −34] → significant |

Read: rawcode cut output ~a third with no measurable correctness change on this set.

## Caveats (read before trusting the numbers)

- **Contamination.** HumanEval is partly in model training data ([Riddell et al. 2024](https://arxiv.org/abs/2403.04811)). A paired A/B cancels most of this, but one prompt could still cue memorised recall differently.
- **Weak tests.** Vanilla HumanEval under-tests; [HumanEval+](https://github.com/evalplus/evalplus) adds ~80× more cases and is the stronger follow-up.
- **Small N / single sample.** n=40 with one greedy sample: the correctness CI is wide (small effects undetectable); the token effect is robust. For pass@k, raise the sample count.
- **Codegen only.** This does not test long agentic loops, where Anthropic has reported over-aggressive conciseness can [hurt quality](https://www.anthropic.com/engineering/april-23-postmortem). rawcode's brevity rule deliberately binds to the final response, not to investigation or verification.
