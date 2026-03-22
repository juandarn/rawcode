#!/bin/bash
# rawcode status line for Claude Code
# Reads JSON session data from stdin and displays a compact status bar

read -r INPUT

if [ -z "$INPUT" ]; then
  echo "rawcode"
  exit 0
fi

# Parse JSON fields using grep/sed (no jq dependency)
get_field() {
  echo "$INPUT" | grep -o "\"$1\":[^,}]*" | head -1 | sed 's/.*://' | tr -d ' "}'
}

MODEL=$(get_field "model")
CONTEXT_PERCENT=$(get_field "contextPercent")
COST=$(get_field "totalCost")
AGENT=$(get_field "agentName")

# Format model name (shorten)
case "$MODEL" in
  *opus*) MODEL_SHORT="opus" ;;
  *sonnet*) MODEL_SHORT="sonnet" ;;
  *haiku*) MODEL_SHORT="haiku" ;;
  *) MODEL_SHORT="$MODEL" ;;
esac

# Build status line
STATUS="rawcode"

if [ -n "$AGENT" ] && [ "$AGENT" != "null" ]; then
  STATUS="$STATUS | @$AGENT"
fi

if [ -n "$MODEL_SHORT" ] && [ "$MODEL_SHORT" != "null" ]; then
  STATUS="$STATUS | $MODEL_SHORT"
fi

if [ -n "$CONTEXT_PERCENT" ] && [ "$CONTEXT_PERCENT" != "null" ]; then
  STATUS="$STATUS | ctx:${CONTEXT_PERCENT}%"
fi

if [ -n "$COST" ] && [ "$COST" != "null" ]; then
  STATUS="$STATUS | \$$COST"
fi

# Git branch
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  STATUS="$STATUS | $BRANCH"
fi

echo "$STATUS"
