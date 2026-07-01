#!/bin/bash
# rawcode powerline status line for Claude Code.
# Reads the statusLine JSON from stdin. Field names per the Claude Code docs:
# https://code.claude.com/docs/en/statusline
# model.display_name | context_window.used_percentage | cost.total_cost_usd | output_style.name

INPUT=$(cat)

if [ -z "$INPUT" ] || ! command -v jq &>/dev/null; then
  echo -e "\033[48;5;236m\033[38;5;203m  rawcode \033[0m"
  exit 0
fi

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // empty')
CTX=$(printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)
COST=$(printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // empty')
STYLE=$(printf '%s' "$INPUT" | jq -r '.output_style.name // empty')

# Shorten model name (display_name is like "Opus", "Sonnet 4.5", "Haiku 4.5")
case "$(printf '%s' "$MODEL" | tr '[:upper:]' '[:lower:]')" in
  *opus*) M="opus" ;;
  *sonnet*) M="sonnet" ;;
  *haiku*) M="haiku" ;;
  *) M="$MODEL" ;;
esac

# Context color: green < 60, yellow 60-79, red >= 80
CTX_COLOR="38;5;114"
if [ -n "$CTX" ] && [ "$CTX" -eq "$CTX" ] 2>/dev/null; then
  if [ "$CTX" -ge 80 ]; then CTX_COLOR="38;5;203"
  elif [ "$CTX" -ge 60 ]; then CTX_COLOR="38;5;220"; fi
else
  CTX=""
fi

BRANCH=$(git branch --show-current 2>/dev/null)

SEG="\033[48;5;203m\033[38;5;255m rawcode \033[48;5;238m\033[38;5;203m\033[0m"

if [ -n "$STYLE" ]; then
  SEG+="\033[48;5;238m\033[38;5;75m ${STYLE} \033[48;5;236m\033[38;5;238m\033[0m"
else
  SEG+="\033[48;5;238m\033[38;5;238m\033[48;5;236m\033[0m"
fi

[ -n "$M" ] && SEG+="\033[48;5;236m\033[38;5;252m  ${M} "
[ -n "$CTX" ] && SEG+="\033[48;5;236m\033[${CTX_COLOR}m ctx:${CTX}% "
if [ -n "$COST" ]; then
  SEG+="\033[48;5;236m\033[38;5;220m \$$(printf '%.2f' "$COST" 2>/dev/null || echo "$COST") "
fi
[ -n "$BRANCH" ] && SEG+="\033[48;5;236m\033[38;5;114m  ${BRANCH} "

SEG+="\033[0m\033[38;5;236m\033[0m"
echo -e "$SEG"
