---
name: fix
description: Fix a bug following OpenCode philosophy — find root cause, minimal fix, verify with tests
---

Fix the following bug using OpenCode's philosophy:

$ARGUMENTS

## Process

1. **Reproduce/understand** — Read the relevant code, understand the failure
2. **Find root cause** — Use Grep and Read to trace the issue to its origin. Do not fix symptoms.
3. **Minimal fix** — Apply the smallest possible change that resolves the root cause
4. **Verify** — Run tests or type-check to confirm the fix works
5. **Check for similar bugs** — Grep for the same pattern elsewhere in the codebase

## Rules

- Do NOT refactor surrounding code
- Do NOT add "improvements" beyond the fix
- Do NOT add comments explaining the fix (the code should be self-evident)
- If the fix requires more than ~20 lines of changes, pause and explain why before proceeding
