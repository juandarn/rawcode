# rawcode

OpenCode's prompting philosophy for Claude Code and Codex.

No new commands. No new UI. Just better prompting.

## Install

### Claude Code

```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/juandarn/rawcode/master/install.ps1 | iex

# Manual
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

### Codex

Codex does not load Claude plugins, so rawcode for Codex ships as an `AGENTS.md` template.

```bash
# Mac/Linux: install globally for projects under your home directory
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install-codex.sh | bash

# Windows
irm https://raw.githubusercontent.com/juandarn/rawcode/master/install-codex.ps1 | iex
```

Manual options:

- Copy `codex/AGENTS.md` to `~/AGENTS.md` for global defaults in Codex CLI.
- Copy `codex/AGENTS.md` to a repo root for repo-specific Codex behavior, including Codex tasks opened from ChatGPT.
- The Codex installers back up an existing `AGENTS.md` before replacing it.

## What Changes

rawcode injects OpenCode's philosophy into Claude Code agents and Codex `AGENTS.md` instructions:

- **Concise.** Responses under 4 lines unless you ask for more.
- **Root cause.** Fixes the origin, not the symptom.
- **Minimal.** Only changes what's necessary. No drive-by refactoring.
- **Verify.** Runs relevant checks after every change.
- **No fluff.** No preamble, no summaries, no praise.

## Claude Code

Everything else stays native: `/plan`, `/compact`, and Claude Code's agent system keep working as usual.

### Agents

Claude delegates to these automatically. You do not need to call them.

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

## Codex

rawcode for Codex uses `AGENTS.md`, which is the official instruction surface Codex reads inside a repo or from your home directory.

- Global `AGENTS.md` gives you raw defaults across projects.
- Deeper repo-local `AGENTS.md` files override the global one when needed.
- The Codex version mirrors rawcode's philosophy and guardrails, including avoiding `.env`, migrations, and lock files unless explicitly requested.

## Limitations

Claude-specific features stay Claude-specific:

- Claude hooks and status line integrations do not exist in Codex.
- Codex support in this repo is prompt and workflow support through `AGENTS.md`, not a plugin runtime.

## Protections

- Claude Code blocks editing `.env`, migrations, and lock files through hooks and permissions.
- Codex gets the same guidance through `codex/AGENTS.md`.

## License

MIT
