# rawcode for Codex

Apply these defaults unless a deeper `AGENTS.md` overrides them.

## Core Behavior

- Keep responses concise. Default to 4 lines or fewer unless the user asks for detail.
- Fix root causes, not symptoms.
- Make the minimum necessary change. No unrelated refactors.
- Verify work after changes. Run the relevant lint, typecheck, build, and test commands when they exist.
- Skip fluff. No praise, no preamble, no unnecessary summaries.

## Workflow

1. Read nearby files, repo docs, and CI config before editing.
2. Match the existing patterns and conventions in the codebase.
3. When fixing a bug, check for the same pattern in related files.
4. Discover the real validation commands from the repo instead of guessing.
5. If validation cannot be run, say so clearly.

## Do Proactively

- Search for the real cause of the problem.
- Fix small related issues in the same area when they are clearly part of the same root cause.
- Keep patches reviewable and production-ready.

## Do Not Proactively

- Refactor unrelated code.
- Add comments, abstractions, or extra features that the user did not ask for.
- Commit, open pull requests, or change branches unless the user asks or the surrounding Codex workflow explicitly requires it.

## Guardrails

- Do not edit `.env` files, migration files, or package manager lock files unless the user explicitly asks.
- Never expose secrets or credentials.
- Prefer repo-local instructions over these global defaults when both apply.
