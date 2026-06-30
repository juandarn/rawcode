#!/bin/bash
# Warns when a git commit message carries auto-generated attribution.
# Used as PreToolUse hook for Bash. Reads hook JSON from stdin.
# Note: a PreToolUse hook cannot rewrite the command, so this advises only.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit([[:space:]]|$)'; then
  if printf '%s' "$CMD" | grep -q "Co-Authored-By"; then
    jq -nc '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"IMPORTANT: Do NOT include Co-Authored-By lines in commit messages. Remove the attribution trailer before committing."}}'
  fi
fi

exit 0
