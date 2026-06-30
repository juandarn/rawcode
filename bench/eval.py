#!/usr/bin/env python3
"""HumanEval pass@1 A/B for the rawcode system prompt.

Generates a completion per problem with `claude -p`, with and without the
rawcode prompt appended, then grades each against HumanEval's executable unit
tests. Correctness (pass/fail) and output tokens are recorded per problem so
they can be analysed as separate axes (see analyze.py).

Usage: python eval.py [N]      # N = number of problems (default 40)
"""
import json, subprocess, re, sys, os, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
PROMPT = re.sub(r"^---.*?---\n", "", open(os.path.join(HERE, "..", "agents", "rawcode.md")).read(), count=1, flags=re.S)
DATA = os.path.join(HERE, "HumanEval.jsonl")
OUT = os.path.join(HERE, "results.jsonl")
N = int(sys.argv[1]) if len(sys.argv) > 1 else 40


def gen(prompt_body, arm):
    instr = ("Implement the following Python function. Return ONLY the complete "
             "function definition (include any needed imports), no explanation.\n\n" + prompt_body)
    cmd = ["claude", "-p", instr, "--model", "sonnet", "--output-format", "json"]
    if arm == "rawcode":
        cmd += ["--append-system-prompt", PROMPT]
    for _ in range(3):
        try:
            d = json.loads(subprocess.run(cmd, capture_output=True, text=True, timeout=120).stdout)
            if d.get("usage", {}).get("output_tokens", 0) > 0:
                return d["result"], d["usage"]["output_tokens"]
        except Exception:
            pass
        time.sleep(5)
    return "", 0


def passes(code, test_src, entry):
    prog = code + "\n\n" + test_src + f"\n\ncheck({entry})\n"
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as f:
        f.write(prog); path = f.name
    try:
        return subprocess.run([sys.executable, path], capture_output=True, timeout=30).returncode == 0
    except Exception:
        return False
    finally:
        os.unlink(path)


def extract(text):
    m = re.findall(r"```(?:python)?\s*\n(.*?)```", text, re.S)
    return m[0] if m else text


problems = [json.loads(l) for l in open(DATA)][:N]
open(OUT, "w").close()
for arm in ["baseline", "rawcode"]:
    for p in problems:
        text, tok = gen(p["prompt"], arm)
        ok = passes(extract(text), p["test"], p["entry_point"]) if text else False
        with open(OUT, "a") as f:
            f.write(json.dumps({"arm": arm, "task": p["task_id"], "pass": ok, "out": tok}) + "\n")
        print(f"{arm:9} {p['task_id']:15} {'PASS' if ok else 'fail':5} {tok}t", flush=True)
        time.sleep(1)
print("DONE ->", OUT)
