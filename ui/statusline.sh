#!/bin/bash
# rawcode status line for Claude Code. Reads the statusLine JSON from stdin. Field names per
# the Claude Code docs: https://code.claude.com/docs/en/statusline
#
#   identity  ◆ rawcode   model · effort · context size   repo   ⎇ branch   [session name]
#   rule      a dim horizontal rule (it separates the groups; no blank lines are printed)
#   meters    5h / 7d plan usage (Pro/Max only) and ctx: label, bar, pct, detail
#   activity  "cache hit" (or "cache cold"), "changed" lines and "session" time rows
#
# Two layouts, picked from the terminal width (stty size on /dev/tty, else $COLUMNS):
#   wide     width >= 100 or unknown: meters on the left, activity on the right, in one
#            fixed-column block of at most 104 columns; the session name is right-aligned
#   compact  0 < width < 100: one metric per row, every row sharing the same columns
# Every line starts with a 2-column margin. A row or segment is omitted when its data is
# absent; nothing is printed as a placeholder. Bars and percentages turn yellow at 60% and
# red at 80%. Bars are 16 cells wide (wide) or 10 (compact): █ for the load, ░ for the rest.
# Palette (256-colour only): violet 141 accent, green 78 ok, yellow 221 warn, red 203 crit,
# label 245, value 252, bright 255, track 238, cyan 81 (high effort).

INPUT=$(cat)

VIOLET=$'\033[38;5;141m'; OK=$'\033[38;5;78m';  WARN=$'\033[38;5;221m'; CRIT=$'\033[38;5;203m'
LABEL=$'\033[38;5;245m';  VALUE=$'\033[38;5;252m'; BRIGHT=$'\033[38;5;255m'
TRACK=$'\033[38;5;238m';  CYAN=$'\033[38;5;81m'
BOLD=$'\033[1m'; R=$'\033[0m'

MARGIN="  "
LOGO="${VIOLET}${BOLD}◆ rawcode${R}"

if [ -z "$INPUT" ] || ! command -v jq &>/dev/null; then
  printf '%s%s\n' "$MARGIN" "$LOGO"
  exit 0
fi

# One jq call, tab-separated. "-" marks an absent field so `read` never collapses empty columns.
# Counts and percentages are rounded to integers here; strings are trimmed, stripped of control
# characters and truncated by codepoint so bash never cuts a multibyte character.
FIELDS=(MODEL EFFORT REPO DIR SESS CTXP CTXTOK CTXSIZE EX200 H5 H5R D7 D7R
        HAVEPC OBS CWARM EXPIRES HIT LADD LREM DUR API)
IFS=$'\t' read -r "${FIELDS[@]}" <<<"$(printf '%s' "$INPUT" | jq -r '
  def f: (if type == "string" then gsub("[[:cntrl:]]"; "") | gsub("^\\s+|\\s+$"; "") else . end)
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

# ---- helpers -------------------------------------------------------------------------
isnum() { [[ "$1" =~ ^[0-9]+$ ]]; }

# vlen <string> -> VL: display length in characters, independent of the locale
# (in the C locale ${#s} counts bytes, so UTF-8 continuation bytes are dropped first).
vlen() {
  local LC_ALL=C s="$1"
  s=${s//[$'\x80'-$'\xbf']/}
  VL=${#s}
}

# ---- width and mode ------------------------------------------------------------------
# The terminal width is read once. Without a controlling tty (a pipe, a sandbox) the
# lookup fails silently and falls back to $COLUMNS, then to "unknown", which means wide.
W="$RAWCODE_COLS"
if ! isnum "$W"; then
  W=""
  SZ=$(stty size 2>/dev/null </dev/tty) && W=${SZ##* }
  isnum "$W" || W="$COLUMNS"
  isnum "$W" || W=0
fi
if [ "$W" -gt 0 ] && [ "$W" -lt 100 ]; then WIDE=0; else WIDE=1; fi
TOTAL=104
[ "$W" -gt 0 ] && [ $(( W - 2 )) -lt "$TOTAL" ] && TOTAL=$(( W - 2 ))

# Column layout, computed once from these constants.
BARGAP=3; PCTW=4
if [ "$WIDE" = 1 ]; then
  BARN=16; LABW=5; GAPW=3; DETW=20      # meters: label | bar | pct | detail (detail padded to DETW)
  ALABW=11; AVALW=6                     # activity: label (up to "cache hit") | value | detail
  RGAP=6                                # space between the meters block and the activity block
else
  BARN=10; LABW=11; GAPW=4
  ALABW=11; AVALW=$(( LABW + BARN + BARGAP + PCTW + GAPW - ALABW ))   # detail lines up with the meters'
fi
LEFTW=$(( LABW + BARN + BARGAP + PCTW + GAPW + ${DETW:-0} ))

# pcol <pct>  -> sets PC: green (<60), yellow (60-79), red (>=80)
pcol() {
  if   [ "$1" -ge 80 ]; then PC="$CRIT"
  elif [ "$1" -ge 60 ]; then PC="$WARN"
  else PC="$OK"; fi
}

# bar <pct>  -> BARN-cell bar in BAR: coloured █ for the load, dim ░ for the rest.
# Any non-zero load shows at least one filled cell.
bar() {
  local filled=$(( ($1 * BARN + 50) / 100 )) on off
  [ "$1" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
  [ "$filled" -gt "$BARN" ] && filled=$BARN
  printf -v on '%*s' "$filled" '';                 on=${on// /█}
  printf -v off '%*s' $(( BARN - filled )) '';     off=${off// /░}
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

# reset_detail <epoch> <clock-format>  -> DETP plain and DET dim: "↻ 2d9h · Wed 04:32"
# (both empty when the time is unknown or already past)
reset_detail() {
  countdown "$1"
  DET=""; DETP=""
  [ -n "$CD" ] || return 0
  DETP="↻ ${CD}"
  clock "$1" "$2"
  [ -n "$CLK" ] && DETP="${DETP} · ${CLK}"
  DET="${LABEL}${DETP}${R}"
}

# meter <label> <pct> <detail> <detail-plain>  -> ROW and its plain length ROWLEN
#   "5h   ████░░░░░░░░░░░░    62%   ↻ 2h48m · 21:57" (nothing when pct is absent)
# Padding is applied to plain text; colour codes are wrapped around it afterwards.
meter() {
  local lab pct
  ROW=""
  isnum "$2" || return 0
  printf -v lab '%-*s' "$LABW" "$1"
  printf -v pct '%*s' "$PCTW" "$2%"
  pcol "$2"; bar "$2"
  gap "$BARGAP"; ROW="${LABEL}${lab}${R}${BAR}${SP}${PC}${pct}${R}"
  ROWLEN=$(( LABW + BARN + BARGAP + PCTW ))
  if [ -n "$3" ]; then
    gap "$GAPW"; ROW="${ROW}${SP}${3}"
    vlen "$4"; ROWLEN=$(( ROWLEN + GAPW + VL ))
  fi
}

# arow <label> <plain-value> <coloured-value> [detail] [detail-plain]  -> ROW and ROWLEN
#   the value is padded (as plain text) to AVALW so the detail always starts in the same column
arow() {
  local lab pad
  printf -v lab '%-*s' "$ALABW" "$1"
  vlen "$2"
  ROW="${LABEL}${lab}${R}${3}"
  ROWLEN=$(( ALABW + VL ))
  if [ -n "$4" ]; then
    pad=$(( AVALW - VL )); [ "$pad" -lt 1 ] && pad=1
    gap "$pad"; ROW="${ROW}${SP}${4}"
    vlen "$5"; ROWLEN=$(( ROWLEN + pad + VL ))
  fi
}

LROWS=(); LLENS=(); AROWS=()
addl() { [ -z "$ROW" ] && return 0; LROWS[${#LROWS[@]}]="$ROW"; LLENS[${#LLENS[@]}]="$ROWLEN"; }
adda() { [ -z "$ROW" ] && return 0; AROWS[${#AROWS[@]}]="$ROW"; }

# ---- identity ------------------------------------------------------------------------
case "$EFFORT" in
  low)        EC="$LABEL" ;;
  medium)     EC="$VALUE" ;;
  high)       EC="$CYAN" ;;
  xhigh|max)  EC="$VIOLET" ;;
  *)          EC="$LABEL" ;;
esac

# The model segment is "name · effort · context size"; the parts that are known are kept.
MP=""; MC=""
mseg() {  # <plain> <coloured>
  if [ -n "$MP" ]; then MP="${MP} · $1"; MC="${MC} ${LABEL}·${R} $2"; else MP="$1"; MC="$2"; fi
}
[ -n "$MODEL" ]  && mseg "$MODEL"  "${BRIGHT}${BOLD}${MODEL}${R}"
[ -n "$EFFORT" ] && mseg "$EFFORT" "${EC}${EFFORT}${R}"
if isnum "$CTXSIZE" && [ "$CTXSIZE" -gt 0 ]; then
  human "$CTXSIZE"
  case "$MODEL" in *"$HUM"*) ;; *) mseg "$HUM" "${LABEL}${HUM}${R}" ;; esac
fi

IDP="◆ rawcode"; IDC="$LOGO"
ident() {  # <plain> <coloured>  -> appended with a 3-space separator
  [ -z "$1" ] && return 0
  IDP="${IDP}   $1"; IDC="${IDC}   $2"
}
ident "$MP" "$MC"

if [ -n "$REPO" ]; then
  ident "$REPO" "${VALUE}${REPO}${R}"
else
  DIRNAME=${DIR%/}; DIRNAME=${DIRNAME##*/}
  ident "$DIRNAME" "${VALUE}${DIRNAME}${R}"
fi

BRANCH=""
[ -n "$DIR" ] && [ -d "$DIR" ] && BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
[ "${#BRANCH}" -gt 28 ] && BRANCH="${BRANCH:0:27}…"
[ -n "$BRANCH" ] && ident "⎇ ${BRANCH}" "${OK}⎇ ${BRANCH}${R}"

if [ -n "$SESS" ]; then
  if [ "$WIDE" = 1 ]; then
    # Right-aligned so the session name ends at the right edge of the block.
    vlen "$IDP"; ilen=$VL; vlen "$SESS"
    pad=$(( TOTAL - (${#MARGIN} + ilen) - VL )); [ "$pad" -lt 3 ] && pad=3
    gap "$pad"; IDC="${IDC}${SP}${LABEL}${SESS}${R}"
  else
    ident "$SESS" "${LABEL}${SESS}${R}"
  fi
fi

# ---- meters --------------------------------------------------------------------------
reset_detail "$H5R" "%H:%M";    meter 5h "$H5" "$DET" "$DETP"; addl
reset_detail "$D7R" "%a %H:%M"; meter 7d "$D7" "$DET" "$DETP"; addl

if ! isnum "$CTXP" && isnum "$CTXTOK" && isnum "$CTXSIZE" && [ "$CTXSIZE" -gt 0 ]; then
  CTXP=$(( CTXTOK * 100 / CTXSIZE ))
fi
DET=""; DETP=""
if isnum "$CTXTOK" && isnum "$CTXSIZE"; then
  human "$CTXTOK"; USED="$HUM"; human "$CTXSIZE"
  DETP="${USED}/${HUM}"; DET="${LABEL}${DETP}${R}"
fi
if [ "$EX200" = "true" ]; then
  [ -n "$DET" ] && { DET="${DET}  "; DETP="${DETP}  "; }
  DET="${DET}${WARN}⚠ >200k${R}"; DETP="${DETP}⚠ >200k"
fi
meter ctx "$CTXP" "$DET" "$DETP"; addl

# ---- activity ------------------------------------------------------------------------
if [ -n "$HAVEPC" ] && [ "$OBS" != "false" ]; then
  countdown "$EXPIRES"
  # Warm only while the TTL has not lapsed; a past expires_at means the cache went cold.
  if [ "$CWARM" = "true" ] && { ! isnum "$EXPIRES" || [ -n "$CD" ]; }; then
    if isnum "$HIT"; then PLAIN="${HIT}%"; else PLAIN="warm"; fi
    DET=""; DETP=""; [ -n "$CD" ] && { DETP="expires ${CD}"; DET="${LABEL}${DETP}${R}"; }
    arow "cache hit" "$PLAIN" "${OK}${PLAIN}${R}" "$DET" "$DETP"
  else
    ROW="${LABEL}cache ${R}${CRIT}cold${R}"; ROWLEN=10
  fi
  adda
fi

if { isnum "$LADD" && [ "$LADD" -gt 0 ]; } || { isnum "$LREM" && [ "$LREM" -gt 0 ]; }; then
  arow changed "" "${OK}+${LADD:-0}${R} ${CRIT}−${LREM:-0}${R}"
  adda
fi

elapsed "$DUR"
if [ -n "$EL" ]; then
  if [ "$WIDE" = 1 ]; then
    # wide: one value, "1h 0m · 25% in API calls"
    PLAIN="$EL"; isnum "$API" && PLAIN="${EL} · ${API}% in API calls"
    arow session "$PLAIN" "${LABEL}${PLAIN}${R}"
  else
    DET=""; DETP=""; isnum "$API" && { DETP="${API}% in API calls"; DET="${LABEL}${DETP}${R}"; }
    arow session "$EL" "${LABEL}${EL}${R}" "$DET" "$DETP"
  fi
  adda
fi

# ---- output --------------------------------------------------------------------------
printf '%s%s\n' "$MARGIN" "$IDC"

NL=${#LROWS[@]}; NA=${#AROWS[@]}
if [ $(( NL + NA )) -gt 0 ]; then
  RULEN=$(( TOTAL - ${#MARGIN} )); [ "$RULEN" -lt 1 ] && RULEN=1
  printf -v RULE '%*s' "$RULEN" ''
  printf '%s%s%s%s\n' "$MARGIN" "$TRACK" "${RULE// /─}" "$R"
fi

if [ "$WIDE" = 1 ]; then
  N=$NL; [ "$NA" -gt "$N" ] && N=$NA
  i=0
  while [ "$i" -lt "$N" ]; do
    LINE="$MARGIN"; L="${LROWS[$i]-}"; A="${AROWS[$i]-}"
    if [ "$NL" -eq 0 ]; then                        # no meters: activity sits at the margin
      LINE="${LINE}${A}"
    elif [ -z "$A" ]; then
      LINE="${LINE}${L}"
    else
      pad=$(( LEFTW - ${LLENS[$i]:-0} + RGAP )); [ "$pad" -lt "$RGAP" ] && pad=$RGAP
      gap "$pad"; LINE="${LINE}${L}${SP}${A}"
    fi
    printf '%s\n' "$LINE"
    i=$(( i + 1 ))
  done
else
  i=0
  while [ "$i" -lt "$NL" ]; do printf '%s%s\n' "$MARGIN" "${LROWS[$i]}"; i=$(( i + 1 )); done
  i=0
  while [ "$i" -lt "$NA" ]; do printf '%s%s\n' "$MARGIN" "${AROWS[$i]}"; i=$(( i + 1 )); done
fi
exit 0
