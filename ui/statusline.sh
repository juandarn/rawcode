#!/bin/bash
# rawcode status line for Claude Code: stacked, column-aligned rows in three groups.
# Reads the statusLine JSON from stdin. Field names per the Claude Code docs:
# https://code.claude.com/docs/en/statusline
#   group 1  identity : ◆ rawcode   model · effort   repo   ⎇ branch   [session name]
#   group 2  meters   : 5h / 7d plan usage (Pro/Max only) and ctx: label, 10-cell bar, pct, detail
#   group 3  activity : cache / lines / time rows; their detail lines up with the meters' detail
# Groups are separated by a spacer line holding one NBSP (a plain empty line would be trimmed).
# A row or segment is omitted when its data is absent; nothing is printed as a placeholder.
# Bars and percentages turn yellow at 60% and red at 80%.
# Palette (256-colour only): violet 141 accent, green 78 ok, yellow 221 warn, red 203 crit,
# label 245, value 252, bright 255, track 238, cyan 81 (high effort).

INPUT=$(cat)

VIOLET=$'\033[38;5;141m'; OK=$'\033[38;5;78m';  WARN=$'\033[38;5;221m'; CRIT=$'\033[38;5;203m'
LABEL=$'\033[38;5;245m';  VALUE=$'\033[38;5;252m'; BRIGHT=$'\033[38;5;255m'
TRACK=$'\033[38;5;238m';  CYAN=$'\033[38;5;81m'
BOLD=$'\033[1m'; R=$'\033[0m'

LOGO="${VIOLET}${BOLD}◆ rawcode${R}"

if [ -z "$INPUT" ] || ! command -v jq &>/dev/null; then
  printf '%s\n' "$LOGO"
  exit 0
fi

# One jq call, tab-separated. "-" marks an absent field so `read` never collapses empty columns.
# Counts and percentages are rounded to integers here; strings are stripped of control
# characters and truncated by codepoint so bash never cuts a multibyte character.
FIELDS=(MODEL EFFORT REPO DIR SESS CTXP CTXTOK CTXSIZE EX200 H5 H5R D7 D7R
        HAVEPC OBS CWARM EXPIRES HIT LADD LREM DUR API)
IFS=$'\t' read -r "${FIELDS[@]}" <<<"$(printf '%s' "$INPUT" | jq -r '
  def f: (if type == "string" then gsub("[[:cntrl:]]"; "") else . end)
         | if . == null or . == "" then "-" else . end;
  def v(p): (try p catch null) | f;
  def n(p): (try (p | floor) catch null) | f;
  def r(p): (try (p | round) catch null) | f;
  def t(k): if type == "string" and length > k then .[0:k-1] + "…" else . end;
  [ v(.model.display_name | t(24)),
    v(.effort.level),
    v(.workspace.repo | if .name then ((.owner // "") | if . == "" then "" else . + "/" end) + .name else null end | t(32)),
    v(.workspace.current_dir // .cwd),
    v(.session_name | t(24)),
    r(.context_window.used_percentage),
    n(.context_window.total_input_tokens),
    n(.context_window.context_window_size),
    v(.exceeds_200k_tokens),
    r(.rate_limits.five_hour.used_percentage),
    n(.rate_limits.five_hour.resets_at),
    r(.rate_limits.seven_day.used_percentage),
    n(.rate_limits.seven_day.resets_at),
    v(.prompt_cache | if type == "object" then "1" else null end),
    v(.prompt_cache.caching_observed),
    v(.prompt_cache.warm),
    n(.prompt_cache.expires_at),
    r(.prompt_cache.hit_ratio | if . == null then null else . * 100 end),
    n(.cost.total_lines_added),
    n(.cost.total_lines_removed),
    n(.cost.total_duration_ms / 1000),
    r(if (.cost.total_duration_ms // 0) > 0 and .cost.total_api_duration_ms != null
        then .cost.total_api_duration_ms * 100 / .cost.total_duration_ms else null end)
  ] | @tsv' 2>/dev/null)"

for v in "${FIELDS[@]}"; do
  [ "${!v}" = "-" ] && printf -v "$v" '%s' ''
done

NOW=$(date +%s)

# Column layout, computed once. Every row is: label | value | detail. The activity rows'
# detail column lines up with the meters' (label, 10-cell bar, gap, right-aligned pct, gap).
LABW=7; BARGAP=3; PCTW=4; GAPW=4
DETAIL_COL=$(( LABW + 10 + BARGAP + PCTW + GAPW ))
VALW=$(( DETAIL_COL - LABW ))

# ---- helpers -------------------------------------------------------------------------
isnum() { [[ "$1" =~ ^[0-9]+$ ]]; }

# pcol <pct>  -> sets PC: green (<60), yellow (60-79), red (>=80)
pcol() {
  if   [ "$1" -ge 80 ]; then PC="$CRIT"
  elif [ "$1" -ge 60 ]; then PC="$WARN"
  else PC="$OK"; fi
}

# bar <pct>  -> 10-cell bar in BAR: coloured ━ for the load, dim ─ for the rest
bar() {
  local filled=$(( ($1 * 10 + 50) / 100 )) i=0 on="" off=""
  [ "$filled" -gt 10 ] && filled=10
  while [ "$i" -lt 10 ]; do
    if [ "$i" -lt "$filled" ]; then on="${on}━"; else off="${off}─"; fi
    i=$((i + 1))
  done
  BAR="${PC}${on}${R}${TRACK}${off}${R}"
}

# countdown <epoch>  -> "2d9h" | "2h10m" | "42m" in CD (empty when unknown or already past)
countdown() {
  local left
  CD=""
  isnum "$1" || return 0
  left=$(( $1 - NOW ))
  if   [ "$left" -le 0 ];     then :
  elif [ "$left" -ge 86400 ]; then CD="$(( left / 86400 ))d$(( left % 86400 / 3600 ))h"
  elif [ "$left" -ge 3600 ];  then CD="$(( left / 3600 ))h$(( left % 3600 / 60 ))m"
  else CD="$(( left / 60 ))m"; fi
}

# clock <epoch> <strftime-format>  -> local time in CLK (BSD `date -r`, GNU `date -d @` fallback)
clock() {
  CLK=$(date -r "$1" "+$2" 2>/dev/null) || CLK=$(date -d "@$1" "+$2" 2>/dev/null) || CLK=""
}

# elapsed <seconds> -> "1h 12m" | "12m" | "40s" in EL
elapsed() {
  EL=""
  isnum "$1" || return 0
  if   [ "$1" -ge 3600 ]; then EL="$(( $1 / 3600 ))h $(( $1 % 3600 / 60 ))m"
  elif [ "$1" -ge 60 ];   then EL="$(( $1 / 60 ))m"
  else EL="${1}s"; fi
}

# human <tokens> -> "90k" | "1M" | "1.5M" | "850" in HUM
human() {
  local t
  if   [ "$1" -ge 1000000 ]; then
    t=$(( $1 / 100000 ))
    if [ $(( t % 10 )) -eq 0 ]; then HUM="$(( t / 10 ))M"; else HUM="$(( t / 10 )).$(( t % 10 ))M"; fi
  elif [ "$1" -ge 1000 ]; then HUM="$(( $1 / 1000 ))k"
  else HUM="$1"; fi
}

# gap <n>  -> n spaces in SP
gap() { printf -v SP '%*s' "$1" ''; }

# reset_detail <epoch> <clock-format>  -> DET: dim "↻ 2d9h · Wed 04:32" (empty if unknown or past)
reset_detail() {
  countdown "$1"
  DET=""
  [ -n "$CD" ] || return 0
  DET="↻ ${CD}"
  clock "$1" "$2"
  [ -n "$CLK" ] && DET="${DET} · ${CLK}"
  DET="${LABEL}${DET}${R}"
}

# meter <label> <pct> [detail]  -> "5h     ━━━━━━────    62%    <detail>" (empty when pct is absent)
# Padding is applied to plain text; colour codes are wrapped around it afterwards.
meter() {
  local lab pct out
  isnum "$2" || return 0
  printf -v lab '%-*s' "$LABW" "$1"
  printf -v pct '%*s' "$PCTW" "$2%"
  pcol "$2"; bar "$2"
  gap "$BARGAP"; out="${LABEL}${lab}${R}${BAR}${SP}${PC}${pct}${R}"
  gap "$GAPW";   [ -n "$3" ] && out="${out}${SP}${3}"
  printf '%s' "$out"
}

# arow <label> <plain-value> <coloured-value> [detail]  -> ROW
#   "cache  95%           ↻ 4m": the value is padded (as plain text) so the detail starts at DETAIL_COL
arow() {
  local lab pad=1
  printf -v lab '%-*s' "$LABW" "$1"
  [ $(( VALW - ${#2} )) -gt 1 ] && pad=$(( VALW - ${#2} ))
  ROW="${LABEL}${lab}${R}${3}"
  if [ -n "$4" ]; then gap "$pad"; ROW="${ROW}${SP}${4}"; fi
}

# join <separator> <segment>...  -> non-empty segments joined by the separator, in JOINED
join() {
  local sep="$1" s
  shift
  JOINED=""
  for s in "$@"; do
    [ -z "$s" ] && continue
    if [ -n "$JOINED" ]; then JOINED="${JOINED}${sep}${s}"; else JOINED="$s"; fi
  done
}

# add <var> <row>  -> appends a non-empty row (newline-separated) to the group held in <var>
add() {
  [ -z "$2" ] && return 0
  if [ -n "${!1}" ]; then printf -v "$1" '%s\n%s' "${!1}" "$2"; else printf -v "$1" '%s' "$2"; fi
}

# ---- group 1: identity ---------------------------------------------------------------
case "$EFFORT" in
  low)        EC="$LABEL" ;;
  medium)     EC="$VALUE" ;;
  high)       EC="$CYAN" ;;
  xhigh|max)  EC="$VIOLET" ;;
  *)          EC="$LABEL" ;;
esac

MODEL_SEG=""
[ -n "$MODEL" ] && MODEL_SEG="${BRIGHT}${BOLD}${MODEL}${R}"
if [ -n "$EFFORT" ]; then
  [ -n "$MODEL_SEG" ] && MODEL_SEG="${MODEL_SEG} ${LABEL}·${R} "
  MODEL_SEG="${MODEL_SEG}${EC}${EFFORT}${R}"
fi

REPO_SEG=""
if [ -n "$REPO" ]; then
  REPO_SEG="${VALUE}${REPO}${R}"
else
  DIRNAME=${DIR%/}; DIRNAME=${DIRNAME##*/}
  [ -n "$DIRNAME" ] && REPO_SEG="${VALUE}${DIRNAME}${R}"
fi

BRANCH=""
[ -n "$DIR" ] && [ -d "$DIR" ] && BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
[ "${#BRANCH}" -gt 28 ] && BRANCH="${BRANCH:0:27}…"
BRANCH_SEG=""; [ -n "$BRANCH" ] && BRANCH_SEG="${OK}⎇ ${BRANCH}${R}"
SESS_SEG="";   [ -n "$SESS" ]   && SESS_SEG="${LABEL}${SESS}${R}"

join "   " "$LOGO" "$MODEL_SEG" "$REPO_SEG" "$BRANCH_SEG" "$SESS_SEG"
G1="$JOINED"

# ---- group 2: plan + context meters --------------------------------------------------
G2=""
reset_detail "$H5R" "%H:%M";    add G2 "$(meter 5h "$H5" "$DET")"
reset_detail "$D7R" "%a %H:%M"; add G2 "$(meter 7d "$D7" "$DET")"

if ! isnum "$CTXP" && isnum "$CTXTOK" && isnum "$CTXSIZE" && [ "$CTXSIZE" -gt 0 ]; then
  CTXP=$(( CTXTOK * 100 / CTXSIZE ))
fi
DET=""
if isnum "$CTXTOK" && isnum "$CTXSIZE"; then
  human "$CTXTOK"; USED="$HUM"; human "$CTXSIZE"
  DET="${LABEL}${USED}/${HUM}${R}"
fi
if [ "$EX200" = "true" ]; then
  [ -n "$DET" ] && DET="${DET}  "
  DET="${DET}${WARN}⚠ >200k${R}"
fi
add G2 "$(meter ctx "$CTXP" "$DET")"

# ---- group 3: activity ---------------------------------------------------------------
G3=""
if [ -n "$HAVEPC" ] && [ "$OBS" != "false" ]; then
  countdown "$EXPIRES"
  # Warm only while the TTL has not lapsed; a past expires_at means the cache went cold.
  if [ "$CWARM" = "true" ] && { ! isnum "$EXPIRES" || [ -n "$CD" ]; }; then
    if isnum "$HIT"; then PLAIN="${HIT}%"; else PLAIN="warm"; fi
    DET=""; [ -n "$CD" ] && DET="${LABEL}↻ ${CD}${R}"
    arow cache "$PLAIN" "${OK}${PLAIN}${R}" "$DET"
  else
    arow cache cold "${CRIT}cold${R}"
  fi
  add G3 "$ROW"
fi

if { isnum "$LADD" && [ "$LADD" -gt 0 ]; } || { isnum "$LREM" && [ "$LREM" -gt 0 ]; }; then
  arow lines "" "${OK}+${LADD:-0}${R} ${CRIT}−${LREM:-0}${R}"
  add G3 "$ROW"
fi

elapsed "$DUR"
if [ -n "$EL" ]; then
  DET=""; isnum "$API" && DET="${LABEL}api ${API}%${R}"
  arow time "$EL" "${LABEL}${EL}${R}" "$DET"
  add G3 "$ROW"
fi

# ---- output: groups separated by a single-NBSP line (Claude Code trims truly empty ones) ----
NBSP=$'\xc2\xa0'
printf '%s\n' "$G1"
[ -n "$G2" ] && printf '%s\n%s\n' "$NBSP" "$G2"
[ -n "$G3" ] && printf '%s\n%s\n' "$NBSP" "$G3"
exit 0
