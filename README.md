# rawcode

OpenCode's prompting philosophy for Claude Code. Install it, and Claude Code thinks like OpenCode.

No new commands. No new UI. Just better prompting.

## Install

```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/juandarn/rawcode/master/install.ps1 | iex

# Manual
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

## What Changes

rawcode injects OpenCode's philosophy into Claude Code's agent system:

- **Concise.** Responses under 4 lines unless you ask for more.
- **Root cause.** Fixes the origin, not the symptom.
- **Minimal.** Only changes what's necessary. No drive-by refactoring.
- **Verify.** Runs tests after every change.
- **No fluff.** No preamble, no summaries, no praise.

Everything else stays native — `/plan`, `/compact`, and all Claude Code features work as usual.

## Agents

Claude delegates to these automatically. You don't need to call them.

| Agent | Purpose |
|-------|---------|
| `coder` | Main agent. Writes code with raw philosophy. |
| `task` | Read-only. Searches and explores the codebase. |
| `reviewer` | Read-only. Reviews code for bugs and security. |
| `summarizer` | Generates session summaries. |
| `titler` | Short titles (max 50 chars). |
| `think` | Deep reasoning with **Opus**. Read-only. |
| `code` | Fast coding with **Sonnet**. |

To start a session with a specific agent:

```bash
claude --agent rawcode:coder    # full raw mode
claude --agent rawcode:think    # Opus deep reasoning
claude --agent rawcode:code     # Sonnet fast coding
```

## Protections

Automatically blocks editing: `.env`, migrations, lock files.

## License

MIT
