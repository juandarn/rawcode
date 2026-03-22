# rawcode

A Claude Code plugin that replicates OpenCode's workflow philosophy. Install it and Claude Code immediately adopts OpenCode's approach: concise responses, root-cause fixes, minimal changes, and specialized agents.

## Installation

**One-liner (Mac/Linux):**
```bash
curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install.sh | bash
```

**One-liner (Windows PowerShell):**
```powershell
irm https://raw.githubusercontent.com/juandarn/rawcode/master/install.ps1 | iex
```

**Manual:**
```bash
git clone https://github.com/juandarn/rawcode.git ~/.claude/plugins/rawcode
```

That's it. Next time you run `claude`, the plugin loads automatically.

## What It Does

Once installed, you get:

### Agents

| Agent | Purpose |
|-------|---------|
| `coder` | Main agent with full raw philosophy. Use with `claude --agent rawcode:coder` |
| `task` | Read-only explorer. Fast codebase search and questions. Cannot modify files. |
| `reviewer` | Code review focused on root causes. Cannot modify files. |
| `summarizer` | Session summary generator. |
| `titler` | Short title generator (max 50 chars). |

All agents inherit the model from your active session. Change it anytime with `/model`.

### Skills (Slash Commands)

| Command | What It Does |
|---------|-------------|
| `/rawcode:review` | Review uncommitted changes or a specific file |
| `/rawcode:explore <question>` | Explore the codebase to answer a question |
| `/rawcode:summarize` | Summarize the current session |
| `/rawcode:compact` | Generate compact context summary |
| `/rawcode:fix <description>` | Fix a bug with root-cause approach |

### Commands

| Command | What It Does |
|---------|-------------|
| `/rawcode:status` | Project dashboard (git status + recent log) |
| `/rawcode:diff` | Formatted diff with per-file analysis |

### Automatic Protections

- Blocks editing `.env` files
- Blocks editing migration files
- Blocks editing lock files (package-lock.json, yarn.lock, pnpm-lock.yaml)

## The OpenCode Philosophy

1. **Concise.** Responses under 4 lines unless detail is requested.
2. **Root cause.** Fix the origin of the problem, not the symptom.
3. **Minimal.** Only change what's necessary. No drive-by refactoring.
4. **Verify.** Run tests after every change.
5. **Existing patterns.** Follow what the codebase already does.
6. **No fluff.** No preamble, no summaries, no praise.

## Using the Coder Agent

For the full OpenCode experience, start Claude Code with:

```bash
claude --agent rawcode:coder
```

This makes Claude behave like OpenCode's Coder Agent for the entire session.

## Delegating to Subagents

Within a session, Claude automatically delegates to the right agent based on your request. You can also be explicit:

```
Ask the task agent to find all API endpoints in this project
Use the reviewer to check the last commit for issues
```

Or start a session with a specific agent:

```bash
claude --agent rawcode:task        # read-only exploration
claude --agent rawcode:reviewer    # code review mode
claude --agent rawcode:summarizer  # session summary
```

## License

MIT
