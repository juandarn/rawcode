#!/bin/bash
# rawcode status line for Claude Code.
# Reads the statusLine JSON from stdin. Field names per the Claude Code docs:
# https://code.claude.com/docs/en/statusline
# model.display_name | context_window.used_percentage | cost.total_cost_usd

INPUT=$(cat)

if [ -z "$INPUT" ] || ! command -v jq &>/dev/null; then
  echo -e "\033[38;5;203m\033[1mrawcode\033[0m"
  exit 0
fi

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // empty')
CTX=$(printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)
COST=$(printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // empty')

case "$(printf '%s' "$MODEL" | tr '[:upper:]' '[:lower:]')" in
  *opus*)   M="opus" ;;
  *sonnet*) M="sonnet" ;;
  *haiku*)  M="haiku" ;;
  *)        M="$MODEL" ;;
esac

# Colors
DIM='\033[38;5;244m'; WHITE='\033[38;5;252m'; RED='\033[38;5;203m'
GREEN='\033[38;5;114m'; YELLOW='\033[38;5;220m'; SEP="${DIM}·\033[0m"; R='\033[0m'

# Context progress bar (10 cells), colored by usage
CTX_SEG=""
if [ -n "$CTX" ] && [ "$CTX" -eq "$CTX" ] 2>/dev/null; then
  if   [ "$CTX" -ge 80 ]; then C="$RED"
  elif [ "$CTX" -ge 60 ]; then C="$YELLOW"
  else C="$GREEN"; fi
  filled=$(( (CTX + 5) / 10 )); [ "$filled" -gt 10 ] && filled=10
  bar=""; i=0
  while [ $i -lt 10 ]; do
    if [ $i -lt $filled ]; then bar="${bar}▓"; else bar="${bar}░"; fi
    i=$((i + 1))
  done
  CTX_SEG="${C}${bar}${R} ${C}${CTX}%${R}"
fi

# Build line: logo · model · context bar · cost · branch
OUT="${RED}\033[1mrawcode${R}"
[ -n "$M" ] && OUT="${OUT}  ${SEP}  ${WHITE}${M}${R}"
[ -n "$CTX_SEG" ] && OUT="${OUT}  ${SEP}  ${DIM}ctx${R} ${CTX_SEG}"
if [ -n "$COST" ]; then
  OUT="${OUT}  ${SEP}  ${DIM}\$$(printf '%.2f' "$COST" 2>/dev/null || echo "$COST")${R}"
fi
BRANCH=$(git branch --show-current 2>/dev/null)
[ -n "$BRANCH" ] && OUT="${OUT}  ${SEP}  ${GREEN}⎇ ${BRANCH}${R}"

echo -e "$OUT"
