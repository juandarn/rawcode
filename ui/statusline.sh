#!/bin/bash
# rawcode powerline status line for Claude Code
# Uses ANSI colors and unicode chars for a clean look

read -r INPUT

if [ -z "$INPUT" ]; then
  echo -e "\033[48;5;236m\033[38;5;203m  rawcode \033[0m"
  exit 0
fi

# Parse JSON fields — use jq if available, fallback to grep/sed
if command -v jq &>/dev/null; then
  MODEL=$(echo "$INPUT" | jq -r '.model // empty')
  CONTEXT_PERCENT=$(echo "$INPUT" | jq -r '.contextPercent // empty')
  COST=$(echo "$INPUT" | jq -r '.totalCost // empty')
  AGENT=$(echo "$INPUT" | jq -r '.agentName // empty')
else
  get_field() {
    echo "$INPUT" | grep -o "\"$1\":[^,}]*" | head -1 | sed 's/.*://' | tr -d ' "}'
  }
  MODEL=$(get_field "model")
  CONTEXT_PERCENT=$(get_field "contextPercent")
  COST=$(get_field "totalCost")
  AGENT=$(get_field "agentName")
fi

# Shorten model name
case "$MODEL" in
  *opus*) M="opus" ;;
  *sonnet*) M="sonnet" ;;
  *haiku*) M="haiku" ;;
  *) M="${MODEL:-?}" ;;
esac

# Context color (green < 60%, yellow < 80%, red >= 80%)
CTX="${CONTEXT_PERCENT:-0}"
if [ "$CTX" != "null" ] && [ -n "$CTX" ]; then
  if [ "$CTX" -ge 80 ] 2>/dev/null; then
    CTX_COLOR="38;5;203"  # red
  elif [ "$CTX" -ge 60 ] 2>/dev/null; then
    CTX_COLOR="38;5;220"  # yellow
  else
    CTX_COLOR="38;5;114"  # green
  fi
else
  CTX=""
  CTX_COLOR="38;5;114"
fi

# Git branch
BRANCH=$(git branch --show-current 2>/dev/null)

# Build segments
# Colors: bg=236(dark gray), 238(medium) | fg: 203(red), 114(green), 220(yellow), 75(blue), 252(white)
SEG=""

# rawcode logo
SEG+="\033[48;5;203m\033[38;5;255m rawcode \033[48;5;238m\033[38;5;203m\033[0m"

# Agent (if active)
if [ -n "$AGENT" ] && [ "$AGENT" != "null" ]; then
  SEG+="\033[48;5;238m\033[38;5;75m @${AGENT} \033[48;5;236m\033[38;5;238m\033[0m"
else
  SEG+="\033[48;5;238m\033[38;5;238m\033[48;5;236m\033[0m"
fi

# Model
if [ -n "$M" ] && [ "$M" != "?" ]; then
  SEG+="\033[48;5;236m\033[38;5;252m  ${M} "
fi

# Context
if [ -n "$CTX" ] && [ "$CTX" != "null" ]; then
  SEG+="\033[48;5;236m\033[${CTX_COLOR}m ctx:${CTX}% "
fi

# Cost
if [ -n "$COST" ] && [ "$COST" != "null" ]; then
  SEG+="\033[48;5;236m\033[38;5;220m \$${COST} "
fi

# Git branch
if [ -n "$BRANCH" ]; then
  SEG+="\033[48;5;236m\033[38;5;114m  ${BRANCH} "
fi

# End
SEG+="\033[0m\033[38;5;236m\033[0m"

echo -e "$SEG"
