# rawcode

OpenCode philosophy for Claude Code. Install and it just works.

## Install

```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/juandarn/rawcode/master/install.ps1 | iex

# Manual
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

## How It Works

rawcode changes how Claude Code behaves. No commands needed — just talk to it.

**Concise.** Responses under 4 lines unless you ask for more.
**Root cause.** Fixes the origin, not the symptom.
**Minimal.** Only changes what's necessary.
**Verify.** Runs tests after every change.

## Agents

Claude delegates to the right agent automatically. You don't need to call them.

| Agent | Purpose |
|-------|---------|
| `coder` | Main agent. Writes code, fixes bugs, follows the raw philosophy. |
| `task` | Read-only. Searches and explores the codebase. |
| `reviewer` | Read-only. Reviews code for bugs, security, performance. |
| `summarizer` | Generates session summaries. |
| `titler` | Generates short titles (max 50 chars). |
| `think` | Deep reasoning with **Opus**. Read-only. |
| `code` | Fast coding with **Sonnet**. |

To force a specific agent:
```bash
claude --agent rawcode:coder    # full raw mode
claude --agent rawcode:think    # Opus reasoning
claude --agent rawcode:code     # Sonnet coding
```

## Commands

Only 4 — like OpenCode, most things are automatic.

| Command | What It Does |
|---------|-------------|
| `/rawcode:init` | Initialize project (creates opencode.md) |
| `/rawcode:compact` | Compact session context |
| `/rawcode:fix <bug>` | Fix a bug with root-cause approach |
| `/rawcode:t <task>` | Think (Opus) then code (Sonnet) |

## Protections

Automatically blocks editing: `.env`, migrations, lock files.

## License

MIT
