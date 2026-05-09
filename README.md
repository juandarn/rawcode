# rawcode

OpenCode's philosophy for Claude Code. Install it, and Claude Code thinks different.

No commands. No agents to pick. Just a system prompt that makes Claude code better.

## Install

```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.ps1 | iex

# Manual
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

## What Changes

rawcode injects a system prompt into every Claude Code session. You don't invoke anything — just open `claude` and it works.

- **Read first.** Always reads existing code before writing. No blind code generation.
- **Concise.** Responses under 4 lines unless you ask for more.
- **Root cause.** Fixes the origin, not the symptom.
- **Minimal.** Only changes what's necessary. No drive-by refactoring.
- **Secure.** Concrete OWASP checklist on every change — not "be cautious".
- **Verify.** Runs lint and tests after every change.
- **No fluff.** No preamble, no summaries, no praise.

Everything stays native — `/plan`, `/compact`, and all Claude Code features work as usual.

## Guardrails

Automatic protections that run without you doing anything:

| Guardrail | What it does |
|-----------|-------------|
| **Protect sensitive files** | Blocks editing `.env`, migrations, lock files |
| **Read before write** | Reminds Claude to read files before modifying them |
| **Sanitize commits** | Strips auto-generated attribution from commit messages |

## Uninstall

```bash
~/.claude/plugins/rawcode/setup/uninstall.sh
```

## License

MIT
