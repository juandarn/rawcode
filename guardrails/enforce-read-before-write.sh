#!/bin/bash
# Reminds the agent to read files before modifying them
# Used as PreToolUse hook for Write|Edit. Reads hook JSON from stdin.

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# New or unknown files don't need to be read first
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

jq -nc '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: make sure you have read this file before modifying it. Read first to understand existing patterns and avoid duplicating code."}}'
exit 0
