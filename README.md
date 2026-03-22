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

| Agent | Model | Purpose |
|-------|-------|---------|
| `coder` | session | Main agent with full raw philosophy |
| `task` | session | Read-only explorer. Cannot modify files. |
| `reviewer` | session | Code review focused on root causes. Read-only. |
| `summarizer` | session | Session summary generator. |
| `titler` | session | Short title generator (max 50 chars). |
| `think` | **Opus** | Deep reasoning and planning. Read-only. |
| `code` | **Sonnet** | Fast code writing. Executes plans. |

Agents marked "session" inherit your active model. Change it with `/model`.
`think` and `code` have fixed models for the Opus+Sonnet workflow.

### Skills (Slash Commands)

| Command | What It Does |
|---------|-------------|
| `/rawcode:review` | Review uncommitted changes or a specific file |
| `/rawcode:explore <question>` | Explore the codebase to answer a question |
| `/rawcode:summarize` | Summarize the current session |
| `/rawcode:compact` | Generate compact context summary |
| `/rawcode:fix <description>` | Fix a bug with root-cause approach |
| `/rawcode:think-then-code <task>` | Think with Opus, then code with Sonnet |

### Commands

| Command | What It Does |
|---------|-------------|
| `/rawcode:status` | Project dashboard (git status + recent log) |
| `/rawcode:diff` | Formatted diff with per-file analysis |

### Status Line

rawcode includes a custom status line showing: active agent, model, context usage, cost, and git branch. It activates automatically.

### Automatic Protections

- Blocks editing `.env` files
- Blocks editing migration files
- Blocks editing lock files (package-lock.json, yarn.lock, pnpm-lock.yaml)
- Strips Co-Authored-By lines from commit messages

## The Raw Philosophy

1. **Concise.** Responses under 4 lines unless detail is requested.
2. **Root cause.** Fix the origin of the problem, not the symptom.
3. **Minimal.** Only change what's necessary. No drive-by refactoring.
4. **Verify.** Run tests after every change.
5. **Existing patterns.** Follow what the codebase already does.
6. **No fluff.** No preamble, no summaries, no praise.

## Workflows

### Full raw mode
```bash
claude --agent rawcode:coder
```

### Think with Opus, code with Sonnet
```bash
# As a skill (one command):
/rawcode:think-then-code implement user authentication with JWT

# Or manually:
claude --agent rawcode:think    # analyze and plan
claude --agent rawcode:code     # execute the plan
```

### Delegating to subagents
Within a session, Claude automatically delegates based on your request:
```
Ask the task agent to find all API endpoints
Use the reviewer to check the last commit
```

Or start with a specific agent:
```bash
claude --agent rawcode:task        # read-only exploration
claude --agent rawcode:reviewer    # code review mode
claude --agent rawcode:think       # deep reasoning with Opus
claude --agent rawcode:code        # fast coding with Sonnet
```

## Extending rawcode

Add your own agents and skills directly to the plugin:

```bash
# Add a new agent
echo '---
name: my-agent
description: Does something cool
---
Your prompt here' > ~/.claude/plugins/rawcode/agents/my-agent.md

# Add a new skill
mkdir -p ~/.claude/plugins/rawcode/skills/my-skill
echo '---
name: my-skill
description: Does something useful
---
Skill instructions here
$ARGUMENTS' > ~/.claude/plugins/rawcode/skills/my-skill/SKILL.md
```

New agents and skills are loaded automatically on next session.

## License

MIT
