<p align="center">
  <h1 align="center">rawcode</h1>
  <p align="center">
    <strong>OpenCode's philosophy for Claude Code.</strong><br>
    Install it, and Claude Code thinks different.
  </p>
  <p align="center">
    <a href="#install">Install</a> &middot;
    <a href="#what-changes">What Changes</a> &middot;
    <a href="#guardrails">Guardrails</a> &middot;
    <a href="CHANGELOG.md">Changelog</a>
  </p>
</p>

---

No commands. No agents to pick. Just a **system prompt** that makes Claude code better.

```bash
# Install in one line
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh | bash
```

## What Changes

rawcode injects a system prompt into every Claude Code session. You don't invoke anything — just open `claude` and it works.

| Principle | What Claude does | Without rawcode |
|-----------|-----------------|-----------------|
| **Read first** | Reads existing code before writing | Generates blind, duplicates utilities |
| **Concise** | Responds in < 4 lines | 20 lines of explanation, 5 of code |
| **Root cause** | Fixes the origin, not the symptom | Patches symptoms that come back |
| **Minimal** | Only changes what's necessary | Drive-by refactoring, extra features |
| **Secure** | OWASP checklist on every change | "Be cautious with user input" |
| **Verify** | Runs lint and tests after every change | Says "done" without checking |
| **No fluff** | No preamble, no summaries, no praise | "Great question! Let me explain..." |

Everything stays native — `/plan`, `/compact`, and all Claude Code features work as usual.

## How it compares

Measured, not claimed. Two paired A/Bs against the bare Claude Code baseline, both graded by executable checks (no LLM judge). Details and reproduction steps are in [`bench/`](bench/).

| Benchmark | What it prices | Result (v2.1) |
|---|---|---|
| **HumanEval** pass@1, n=40 | correctness + output tokens | 97.5% vs 97.5% (p=1.0); output −9% (not significant) |
| **Agentic repo tasks**, 5 tasks × 3 reps, Opus | total input incl. cache + subagents | v2.1 is 9% cheaper than v2.0 (14/15 pairs, p=0.001) and not significantly different from no prompt; v2.0 was +14% vs no prompt (p=0.007) |

**Honest reading:** in agentic work the bill is input tokens re-read every turn, not output. Every line of persona is paid again on every request. v2.1 keeps only what Claude Code's own prompt lacks (minimalism, root cause, honesty, context budget), so correctness is unchanged and cost is about the same as no prompt. The big savings come from session config (auto-compact window, fewer listed skills, fewer subagents), not from prompt text.

## Install

### Marketplace (recommended)

```bash
claude plugin marketplace add juandarn/rawcode
claude plugin install rawcode@rawcode
```

Guardrails and the TDD gate load automatically. To turn on the terse coding
persona: `/output-style rawcode`.

### Mac / Linux (script)

```bash
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh | bash
```

### Windows

```powershell
irm https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 | iex
```

### Manual

```bash
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

## Framework

rawcode is minimal by default, but it grows into a coding framework when you want
one — a strict TDD gate, a `rc-tdd` red→green→refactor skill, and a real `bench/`
pass@1 harness. It works **standalone or as an extension of [Gentle AI](https://github.com/Gentleman-Programming)**,
composing with its SDD flow instead of duplicating it. See
[docs/FRAMEWORK.md](docs/FRAMEWORK.md) for the architecture and
[docs/COMPOSE.md](docs/COMPOSE.md) for using the two together.

## Guardrails

Automatic protections that run without you doing anything:

| Guardrail | What it does |
|-----------|-------------|
| **Protect sensitive files** | Blocks editing `.env`, migrations, lock files |
| **Read before write** | Reminds Claude to read files before modifying them |
| **Sanitize commits** | Strips auto-generated attribution from commit messages |

## How it Works

rawcode is a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code). It has four parts:

```
rawcode/
├── output-styles/rawcode.md   # The system prompt, as an output style — this is rawcode
├── agents/rawcode.md          # Same prompt as an opt-in subagent (invoke via Task)
├── hooks/hooks.json           # Registers the guardrail hooks
├── guardrails/                # Automatic protections (hook scripts)
│   ├── protect-sensitive-files.sh
│   ├── enforce-read-before-write.sh
│   └── sanitize-commit.sh
└── ui/statusline.sh           # Shows model, context %, cost, git branch
```

The installer activates the **output style** (`outputStyle: "rawcode"` in your settings), which applies the prompt to every main session — no invocation needed. The **hooks** auto-load from `hooks/hooks.json` once the plugin is enabled and intercept tool calls to prevent common mistakes. Prefer to opt in manually? Run `/config → Output style → rawcode`.

## Statusline

rawcode adds a powerline-style status bar showing real-time info:

```
 rawcode  @agent   sonnet  ctx:45%  $0.12   main
```

- **Context color**: green (< 60%), yellow (60-79%), red (>= 80% — compact now)
- **Cost**: running session cost
- **Branch**: current git branch

## Uninstall

```bash
~/.claude/plugins/rawcode/setup/uninstall.sh
```

## Contributing

1. Fork the repo
2. Create your branch (`git checkout -b my-change`)
3. Run tests: `bats tests/`
4. Push and open a PR

## License

[MIT](LICENSE)
