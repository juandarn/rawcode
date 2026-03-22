---
name: mode
description: Switch rawcode mode — choose between coder, think, code, task, or reviewer workflows
---

The user wants to switch their working mode. Based on their request, change behavior:

$ARGUMENTS

## Available Modes

If the user says "think" or "plan":
- Switch to deep analysis mode. From now on, analyze problems thoroughly before suggesting code. Read files, understand context, create plans. Do NOT modify files until explicitly asked.

If the user says "code" or "build":
- Switch to fast coding mode. Write code directly, minimal explanation. Execute plans. Verify with tests.

If the user says "review":
- Switch to review mode. Analyze recent changes for bugs, security, performance. Do NOT modify files. Report findings.

If the user says "explore" or "search":
- Switch to exploration mode. Search the codebase, answer questions. Do NOT modify files. Be ultra-concise.

If the user says "default" or "reset":
- Return to the standard rawcode coder behavior: concise, root-cause, minimal changes.

If no argument is provided, list the available modes and ask which one to switch to.

## Rules

- Acknowledge the mode switch in ONE line (e.g., "Switched to think mode.")
- Immediately adopt the new behavior for all subsequent responses in this session
- Do NOT ask for confirmation — just switch
