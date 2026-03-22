---
name: init
description: Initialize project — create opencode.md with project info, commands, and conventions
---

Create or update an `opencode.md` file at the project root with project-specific information.

## Process

1. Scan the project to detect:
   - Language(s) and framework(s)
   - Package manager and build system
   - Test framework and test command
   - Linter/formatter configuration
   - Existing conventions (.editorconfig, .prettierrc, eslint, etc.)

2. Write `opencode.md` with:
   - Project name and one-line description
   - Key commands (build, test, lint, dev, deploy)
   - Conventions discovered from config files
   - Any project-specific notes

Keep it under 30 lines. Facts only, no fluff.

$ARGUMENTS
