#!/usr/bin/env python3
"""Summarise results.jsonl: per-arm pass rate, mean total input tokens and cost,
plus the paired delta of each arm vs baseline (same task, same rep)."""
import json, sys, statistics as st
from collections import defaultdict

rows = [json.loads(l) for l in open(sys.argv[1] if len(sys.argv) > 1 else "results.jsonl")]
by = defaultdict(list)
for r in rows:
    by[r["arm"]].append(r)
base = {(r["task"], r["rep"]): r for r in by.get("baseline", [])}
print(f"{'arm':20} {'n':>3} {'pass':>6} {'input':>8} {'cost':>7}  paired Δ input / cost vs baseline")
for arm, rs in by.items():
    d_in = [r["input"] - base[(r["task"], r["rep"])]["input"] for r in rs if (r["task"], r["rep"]) in base]
    d_c = [r["cost"] - base[(r["task"], r["rep"])]["cost"] for r in rs if (r["task"], r["rep"]) in base]
    bi = st.mean(base[(r["task"], r["rep"])]["input"] for r in rs if (r["task"], r["rep"]) in base)
    print(f"{arm:20} {len(rs):>3} {sum(r['pass'] for r in rs)/len(rs):>6.0%} {st.mean(r['input'] for r in rs):>8.0f} "
          f"{st.mean(r['cost'] for r in rs):>7.3f}  {st.mean(d_in)/bi:+.1%} / {st.mean(d_c):+.4f}")
print("\nper task mean input:")
tasks = sorted({r["task"] for r in rows})
print(f"{'arm':20} " + " ".join(f"{t:>9}" for t in tasks))
for arm, rs in by.items():
    print(f"{arm:20} " + " ".join(f"{st.mean([r['input'] for r in rs if r['task']==t] or [0]):>9.0f}" for t in tasks))
