#!/bin/bash
# Reminds the agent to read files before modifying them
# Used as PreToolUse hook for Write|Edit

FILE="${CLAUDE_TOOL_INPUT_FILE_PATH}${CLAUDE_TOOL_INPUT_file_path}"

# New files don't need to be read first
if [ ! -f "$FILE" ]; then
  exit 0
fi

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"Reminder: make sure you have read this file before modifying it. Read first to understand existing patterns and avoid duplicating code.\"}}"
exit 0
