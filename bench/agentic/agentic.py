#!/usr/bin/env python3
"""Agentic token benchmark: what does a prompt cost on real multi-turn repo work?

HumanEval (../eval.py) measures single-shot codegen, where output length is the
only cost. In agentic sessions the bill is dominated by *input*: every turn
re-reads the whole context, and every subagent reloads the system prompt. This
benchmark runs multi-turn tasks against a fixture repo with `claude -p`, grades
each with an executable check, and records total tokens across all models
(main thread + subagents), cache reads included.

Arms: baseline (no appended prompt), rawcode@<ref> (the prompt at a git ref),
rawcode (the working-tree prompt). If HARNESS_GATE points to a PreToolUse
script that forbids main-session edits, a fourth arm measures forced delegation.

Usage: python agentic.py [REPS] [BASE_REF]    # defaults: 2, HEAD
"""
import json, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(HERE, "results.jsonl")
REPS = int(sys.argv[1]) if len(sys.argv) > 1 else 2
BASE_REF = sys.argv[2] if len(sys.argv) > 2 else "HEAD"
MODEL = os.environ.get("BENCH_MODEL", "sonnet")
GATE = os.environ.get("HARNESS_GATE")
# BENCH_ISOLATE=0 runs against the installed user config (plugins, hooks) instead of bare Claude Code.
ISOLATE = os.environ.get("BENCH_ISOLATE", "1") == "1"
TESTS = "python3 -m unittest discover -s tests -t . -q"

TASKS = {
    "bugfix": ("The tests in tests/test_pricing.py fail. Find and fix the bug.", TESTS),
    "feature": ("Add export_orders_csv(orders, path) to shop/reports.py. It writes a CSV "
                "with header id,customer,total and one row per order. Add a test for it.",
                TESTS + " && python3 -c 'import shop.reports as r; assert hasattr(r, \"export_orders_csv\")'"),
    "rename": ("Rename the function calc_total to compute_total everywhere in the codebase.",
               TESTS + " && ! grep -rn calc_total shop tests"),
    "tracebug": ("Customers who enter their country in lowercase (for example 'co') are charged "
                 "no tax. Fix it and add a regression test.",
                 TESTS + " && python3 -c 'from shop.cart import Cart, calc_total as t; c = Cart(\"co\"); "
                 "c.add(\"A\", 100.0); assert t(c) == 119.0'"),
    "question": ("Which file defines the tax rate for Colombia, and what is the value? "
                 "Answer in one line, do not change any file.",
                 "grep -q 'settings.py' $RESULT && grep -q '0.19' $RESULT && git diff --quiet"),
}


def strip_frontmatter(text):
    return re.sub(r"^---.*?---\n", "", text, count=1, flags=re.S)


def prompt_at(ref):
    src = subprocess.run(["git", "show", f"{ref}:agents/rawcode.md"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return strip_frontmatter(src)


CURRENT = strip_frontmatter(open(os.path.join(ROOT, "agents", "rawcode.md")).read())
ARMS = {"baseline": (None, None), f"rawcode@{BASE_REF}": (prompt_at(BASE_REF), None),
        "rawcode": (CURRENT, None)}
if GATE:
    hook = {"hooks": {"PreToolUse": [{"matcher": "Edit|Write|MultiEdit|NotebookEdit",
                                      "hooks": [{"type": "command", "command": GATE}]}]}}
    ARMS["rawcode+gate"] = (CURRENT, json.dumps(hook))


def run(arm, task, rep):
    prompt, check = TASKS[task]
    system, settings = ARMS[arm]
    work = tempfile.mkdtemp(prefix=f"rcbench-{task}-")
    try:
        subprocess.run([sys.executable, os.path.join(HERE, "make_fixture.py"), work]
                       + (["--bug"] if task == "bugfix" else []), check=True)
        for cmd in (["git", "init", "-q"], ["git", "add", "-A"],
                    ["git", "-c", "user.email=b@b", "-c", "user.name=b", "commit", "-qm", "init"]):
            subprocess.run(cmd, cwd=work, check=True)
        cmd = ["claude", "-p", prompt, "--model", MODEL, "--output-format", "json", "--strict-mcp-config",
               "--permission-mode", "bypassPermissions", "--max-turns", "40"]
        if ISOLATE:
            cmd += ["--setting-sources", "project"]
        if system:
            cmd += ["--append-system-prompt", system]
        if settings:
            cmd += ["--settings", settings]
        try:
            proc = subprocess.run(cmd, cwd=work, capture_output=True, text=True, timeout=900)
            d = json.loads(proc.stdout)
        except Exception as e:
            d = {"result": f"ERROR {e}"}
        result_file = os.path.join(work, ".result")
        with open(result_file, "w") as f:
            f.write(d.get("result") or "")
        ok = subprocess.run(["bash", "-c", check], cwd=work, capture_output=True,
                            env=dict(os.environ, RESULT=result_file)).returncode == 0
        mu = d.get("modelUsage") or {}
        tok = lambda k: sum(m.get(k, 0) for m in mu.values())
        row = {"arm": arm, "task": task, "rep": rep, "pass": ok,
               "input": tok("inputTokens") + tok("cacheCreationInputTokens") + tok("cacheReadInputTokens"),
               "cache_read": tok("cacheReadInputTokens"), "output": tok("outputTokens"),
               "cost": d.get("total_cost_usd", 0), "turns": d.get("num_turns", 0),
               "models": sorted(mu)}
        with open(OUT, "a") as f:
            f.write(json.dumps(row) + "\n")
        print(f"{arm:18} {task:9} r{rep} {'PASS' if ok else 'fail':4} "
              f"in={row['input']:>8} out={row['output']:>6} ${row['cost']:.3f} turns={row['turns']}", flush=True)
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    open(OUT, "w").close()
    jobs = [(a, t, r) for r in range(REPS) for t in TASKS for a in ARMS]
    with ThreadPoolExecutor(int(os.environ.get("BENCH_PARALLEL", "4"))) as ex:
        list(ex.map(lambda j: run(*j), jobs))
    print("DONE ->", OUT)
