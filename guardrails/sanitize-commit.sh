#!/bin/bash
# Strips Co-Authored-By lines from commit messages
# Used as PreToolUse hook for Bash (git commit)

# shellcheck disable=SC2154 # Variable injected by Claude Code hooks
CMD="$CLAUDE_TOOL_INPUT_command"

if echo "$CMD" | grep -q "git commit"; then
  if echo "$CMD" | grep -q "Co-Authored-By"; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"IMPORTANT: Do NOT include Co-Authored-By lines in commit messages. The plugin handles attribution automatically.\"}}"
  fi
fi

exit 0
