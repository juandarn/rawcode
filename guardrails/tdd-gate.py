#!/usr/bin/env python3
"""rawcode TDD gate (Stop hook).

Strict TDD by default: if code changed this turn and no test ran, block the
turn once and ask for a test. Escapes: an urgent/skip word in the prompt, a
.rawcode-no-tdd marker file, or (implicitly) running a test. Blocks at most
once per turn so it can never loop. Degrades to allow on any uncertainty.
"""
import sys, json, re, os, hashlib, tempfile

CODE = re.compile(r"\.(py|js|ts|tsx|jsx|go|rs|java|rb|php|c|cc|cpp|h|hpp|kt|kts|swift|scala|ex|exs|dart)$", re.I)
TESTCMD = re.compile(r"\b(pytest|py\.test|unittest|jest|vitest|mocha|ava|go\s+test|cargo\s+test|"
                     r"bats|rspec|phpunit|ctest|gradle[\w\s./-]*test|mvn[\w\s./-]*test|"
                     r"npm\s+(run\s+)?test|yarn\s+test|pnpm\s+test|deno\s+test|dotnet\s+test|"
                     r"rails\s+test|tox|nose2|behave)\b", re.I)
ESCAPE = re.compile(r"urgent|urgente|hotfix|skip[\s_-]?tdd|sin[\s_-]?tdd|no[\s_-]?tdd|\bwip\b|no\s+test", re.I)
TESTPATH = re.compile(r"(^|/)(tests?|__tests__|spec)/|(_test|\.test|\.spec|_spec)\.", re.I)


def allow():
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        allow()
    if data.get("stop_hook_active"):
        allow()
    tp = data.get("transcript_path")
    if not tp or not os.path.isfile(tp):
        allow()

    events = []
    try:
        with open(tp) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        events.append(json.loads(line))
                    except Exception:
                        pass
    except Exception:
        allow()

    last_prompt, last_user_idx = "", -1
    for i, e in enumerate(events):
        if e.get("type") == "last-prompt":
            last_prompt = e.get("lastPrompt") or last_prompt
        msg = e.get("message") or {}
        if msg.get("role") == "user" and isinstance(msg.get("content"), str):
            last_user_idx = i

    if ESCAPE.search(last_prompt) or os.path.exists(".rawcode-no-tdd"):
        allow()

    edited_code = tested = False
    for e in events[last_user_idx + 1:]:
        msg = e.get("message") or {}
        if msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        if not isinstance(content, list):
            continue
        for c in content:
            if not isinstance(c, dict) or c.get("type") != "tool_use":
                continue
            name, inp = c.get("name"), (c.get("input") or {})
            if name in ("Edit", "Write", "NotebookEdit"):
                fp = inp.get("file_path", "") or inp.get("notebook_path", "")
                if CODE.search(fp) and not TESTPATH.search(fp):
                    edited_code = True
            elif name == "Bash" and TESTCMD.search(inp.get("command", "")):
                tested = True

    if not (edited_code and not tested):
        allow()

    # Block at most once per turn: keyed by session + prompt.
    sid = str(data.get("session_id", ""))
    key = hashlib.sha1((sid + "|" + last_prompt).encode()).hexdigest()[:16]
    marker = os.path.join(tempfile.gettempdir(), f"rawcode-tdd-{key}")
    if os.path.exists(marker):
        allow()
    try:
        open(marker, "w").close()
    except Exception:
        allow()

    print(json.dumps({
        "decision": "block",
        "reason": ("rawcode TDD gate: code changed this turn but no test ran. Write or run a "
                   "test that covers the change (red → green) before finishing. To skip, say "
                   "it's urgent / a hotfix, or add a .rawcode-no-tdd file.")
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
