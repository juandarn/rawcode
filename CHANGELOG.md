# Changelog

## Unreleased

### Added (benchmark)
- **`bench/` — a reproducible HumanEval A/B** of the prompt vs the Claude Code baseline, graded by executable unit tests (no LLM judge). Paired design, McNemar test on correctness, bootstrap CI on tokens, reported as separate axes. Last run (n=40): pass@1 90%→95% (no significant change, McNemar p=0.50) at −35% output tokens (significant). Replaces the earlier judge-based comparison table, which used a biased single-judge protocol on self-chosen prompts.

### Fixed
- **Guardrails now actually load.** Hook registration moved from the orphaned `guardrails/guardrails.json` to the discoverable `hooks/hooks.json`, using `${CLAUDE_PLUGIN_ROOT}` paths. They never loaded before.
- **Hooks read the real input contract.** Scripts now parse the hook JSON from stdin (`.tool_input.file_path` / `.command`) instead of unset `CLAUDE_TOOL_INPUT_*` env vars — they were silent no-ops.
- **JSON-injection in `protect-sensitive-files`.** Reasons are now built with `jq`, so a path containing `"` can no longer break the deny JSON and fail open.
- **`migrations/` at repo root** is now protected (the old `*/migrations/*` glob missed it).
- **`sanitize-commit`** no longer false-fires on `git commit-tree` and reads the command from stdin.
- **Installer portability/safety.** Replaced `mapfile` (absent in macOS bash 3.2), and a failed update clone now restores the backup instead of aborting under `set -e`.
- **Executable bits** committed for the guardrail and statusline scripts.

### Added
- **Output style delivery.** Ships `output-styles/rawcode.md`; the installer sets `outputStyle: "rawcode"` so the prompt applies to every session (the prompt was previously only an opt-in subagent). Uninstall reverts it.
- **Context Discipline** section — input-side token guidance (narrow reads, batch independent calls, delegate exploration, prefer diffs).
- **Reasoning carve-out** — conciseness binds to the final response only, never to investigation/verification depth.
- **Honesty section** — never claim a change works without running it, quote failures verbatim, no stub passed off as done. Plus an "if ambiguous, state the assumption" step before coding. (Kept deliberately small: measured turn/latency evals showed piling on more directives slows the agent without reducing turns; rawcode's terseness already wins on both.)

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
