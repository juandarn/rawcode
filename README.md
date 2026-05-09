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

## Install

### Mac / Linux

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

## Guardrails

Automatic protections that run without you doing anything:

| Guardrail | What it does |
|-----------|-------------|
| **Protect sensitive files** | Blocks editing `.env`, migrations, lock files |
| **Read before write** | Reminds Claude to read files before modifying them |
| **Sanitize commits** | Strips auto-generated attribution from commit messages |

## How it Works

rawcode is a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code). It has three components:

```
rawcode/
├── agents/rawcode.md        # The system prompt — this is rawcode
├── guardrails/              # Automatic protections (hooks)
│   ├── protect-sensitive-files.sh
│   ├── enforce-read-before-write.sh
│   └── sanitize-commit.sh
└── ui/statusline.sh         # Shows model, context %, cost, git branch
```

The system prompt is injected into every session. The guardrails intercept tool calls to prevent common mistakes. That's it.

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
