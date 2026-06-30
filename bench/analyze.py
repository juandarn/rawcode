#!/usr/bin/env python3
"""Paired analysis of results.jsonl.

Correctness: McNemar exact test on discordant pairs (paired pass/fail).
Tokens: paired bootstrap 95% CI. Length and correctness stay on separate axes.
"""
import json, os, random
from math import comb

HERE = os.path.dirname(os.path.abspath(__file__))
rows = [json.loads(l) for l in open(os.path.join(HERE, "results.jsonl"))]
by = {}
for r in rows:
    by.setdefault(r["task"], {})[r["arm"]] = r
tasks = [t for t, d in by.items() if "baseline" in d and "rawcode" in d]
n = len(tasks)

b_pass = sum(by[t]["baseline"]["pass"] for t in tasks)
r_pass = sum(by[t]["rawcode"]["pass"] for t in tasks)
b_only = sum(1 for t in tasks if by[t]["baseline"]["pass"] and not by[t]["rawcode"]["pass"])
r_only = sum(1 for t in tasks if by[t]["rawcode"]["pass"] and not by[t]["baseline"]["pass"])
disc = b_only + r_only


def binom_p_two_sided(k, nn):
    if nn == 0:
        return 1.0
    probs = [comb(nn, i) * 0.5 ** nn for i in range(nn + 1)]
    return min(1.0, sum(p for p in probs if p <= probs[k] + 1e-12))


def boot_ci(vals, B=10000):
    random.seed(42)
    means = sorted(sum(vals[random.randrange(n)] for _ in range(n)) / n for _ in range(B))
    return means[int(0.025 * B)], means[int(0.975 * B)]


pd_lo, pd_hi = boot_ci([int(by[t]["rawcode"]["pass"]) - int(by[t]["baseline"]["pass"]) for t in tasks])
td_lo, td_hi = boot_ci([by[t]["rawcode"]["out"] - by[t]["baseline"]["out"] for t in tasks])
b_tok = sum(by[t]["baseline"]["out"] for t in tasks) / n
r_tok = sum(by[t]["rawcode"]["out"] for t in tasks) / n
mp = binom_p_two_sided(min(b_only, r_only), disc)

print(f"HumanEval paired A/B  (n={n}, claude -p, executable unit tests)\n")
print("== CORRECTNESS (pass@1) ==")
print(f"  baseline : {b_pass}/{n} = {b_pass/n:.1%}")
print(f"  rawcode  : {r_pass}/{n} = {r_pass/n:.1%}")
print(f"  paired diff {(r_pass-b_pass)/n:+.1%}  95% CI [{pd_lo:+.1%}, {pd_hi:+.1%}]  McNemar p={mp:.3f}")
print(f"  -> {'NO significant difference' if mp > 0.05 else 'significant difference'}\n")
print("== OUTPUT TOKENS (separate axis) ==")
print(f"  baseline : {b_tok:.0f} tok/problem")
print(f"  rawcode  : {r_tok:.0f} tok/problem")
print(f"  paired diff {r_tok-b_tok:+.0f} tok  95% CI [{td_lo:+.0f}, {td_hi:+.0f}]  ({(r_tok-b_tok)/b_tok:+.0%})")
print(f"  -> {'significant' if (td_lo<0)==(td_hi<0) else 'not significant'}")
