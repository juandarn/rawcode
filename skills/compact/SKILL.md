---
name: compact
description: Generate a compact summary of the conversation to reduce context usage
context: fork
agent: rawcode:summarizer
---

Generate a compact summary of this entire conversation for context preservation.

Include:
1. Key decisions made
2. Files modified and why
3. Current state of the work
4. Unresolved items or next steps

Format as a dense, scannable list. This summary will be used to continue work in a new session if needed.

$ARGUMENTS
