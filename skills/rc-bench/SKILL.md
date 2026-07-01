---
name: rc-bench
description: "Measure a prompt/config change with a real pass@1 A/B on HumanEval instead of a vibe. Trigger: verifying whether a system-prompt or persona change helps or hurts. Composes with Gentle AI's sdd-verify."
user-invocable: true
license: MIT
metadata:
  author: rawcode
  version: "1.0"
  extends: gentle-ai
---

## Purpose

A rawcode extension that turns "is this prompt change better?" into a number.
It runs the repo's `bench/` — a paired HumanEval pass@1 A/B graded by executable
unit tests (no LLM judge) — and reports correctness and token deltas as separate
axes. Use it when a persona/prompt/config change needs evidence, not an opinion.

## When to use

- Before claiming a system-prompt or persona change "helps".
- As a quantitative step inside `sdd-verify` for a change that alters agent behavior.
- To sanity-check that a conciseness tweak did not lower correctness (it can — see
  the Anthropic conciseness postmortem).

## How to run

```bash
bench/run.sh 40        # 40 HumanEval problems, baseline vs the rawcode prompt
```

It downloads HumanEval on first run, generates one greedy completion per problem
per arm via `claude -p`, runs each problem's own tests, then prints:

- **Correctness (pass@1)** per arm, the paired difference, a 95% CI, and a
  McNemar exact p-value. `p > 0.05` = no significant change.
- **Output tokens** per arm and the paired reduction with a bootstrap 95% CI.

## Reading the result honestly

- A win = tokens **down** with pass@1 **not significantly down**. Report both.
- Never blend the two into one score — length and correctness are different axes.
- Watch for **grading artifacts**: an aggressive persona can make the model return
  a terse confirmation ("Done") or act agentically instead of printing code, which
  a naive extractor miscounts as a failure. If pass@1 drops, inspect the raw
  outputs before believing it — the drop may be format, not quality.
- Small N (40, single sample) → wide correctness CI. Raise N or samples for pass@k.

## Compose with Gentle AI

- Inside `sdd-verify`: cite the `bench/` numbers (with CI) as the quantitative
  evidence, alongside the spec-conformance check.
- Persist the run summary under the active artifact store's verify-report key —
  no new backend.
