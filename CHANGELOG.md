# Changelog

## 2.0.0

### Breaking Changes
- Replaced 7 separate agents with a single system prompt (`agents/rawcode.md`)
- Moved `hooks/` to `guardrails/` — extracted inline bash to testable scripts
- Moved `statusline.sh` to `ui/statusline.sh`
- Moved `install.sh` and `install.ps1` to `setup/`
- Install URLs changed to `setup/install.sh` and `setup/install.ps1`

### Added
- **Read first** — system prompt now instructs Claude to always read code before writing
- **Check existing solutions** — Claude greps for existing utils before creating new ones
- **Security checklist** — concrete OWASP rules (parameterized queries, XSS escaping, no eval, path traversal) replace generic "be cautious"
- **No placeholders** — explicitly bans "rest of the code remains the same"
- **enforce-read-before-write.sh** — guardrail that warns when editing unread files
- **statusline.ps1** — Windows PowerShell statusline
- **uninstall.sh** — clean uninstaller
- **jq support** — statusline uses jq when available, falls back to grep/sed
- **Backup on update** — installer backs up existing installation instead of rm -rf
- **Prerequisite checks** — installer verifies git and warns about missing claude CLI
- **BATS test suite** — tests for guardrails, statusline, and plugin structure
- **GitHub Actions CI** — validates JSON, runs ShellCheck, runs BATS tests

### Removed
- `agents/coder.md` — merged into `rawcode.md`
- `agents/code.md` — merged into `rawcode.md`
- `agents/reviewer.md` — Claude Code handles review natively
- `agents/summarizer.md` — Claude Code handles summarization natively
- `agents/task.md` — Claude Code handles exploration natively
- `agents/think.md` — Claude Code handles reasoning natively
- `agents/titler.md` — Claude Code handles titles natively
- `hooks/hooks.json` — replaced by `guardrails/guardrails.json` with external scripts
- `opencode.md` creation — was duplicating native `CLAUDE.md` functionality

## 1.0.0

- Initial release with 7 agents, hooks, and statusline
