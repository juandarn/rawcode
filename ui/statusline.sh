#!/bin/bash
# rawcode status line for Claude Code. Reads the statusLine JSON from stdin. Field names per
# the Claude Code docs: https://code.claude.com/docs/en/statusline
#
#   identity  ◆ rawcode   model · effort · context size   repo   ⎇ branch   [session name]
#   meters    5h / 7d plan usage (Pro/Max only) and ctx: label, bar, pct, detail
#   activity  "cache hit" (or "cache cold"), "changed" lines and "session" time
# The three groups are separated by one spacer line holding a single U+2800 (braille blank):
# Claude Code trims empty and NBSP-only lines but keeps this one, and it renders as a blank cell.
#
# Two layouts, picked from the terminal width (see term_cols) and from how wide the rows really are:
#   wide     the meters share ONE row (5h │ 7d │ ctx) and the activity row sits under it (cache
#            hit, changed, session). Each row lists only the slots it has, packed left to right;
#            slot i starts in the same column in both rows and the dim │ separators line up. A │
#            appears only between two slots, never leading or trailing. Bars are 12 cells. The rows
#            are built for each step of a ladder and the first one whose widest line fits (width - 2,
#            or 118 when the width is unknown) wins: 12-cell bars with reset clock times, 12
#            without clocks, 10 without clocks, and (only when the context is over 200k) 10 with
#            the ⚠ but no token count. The session name is right-aligned on the identity row.
#   compact  nothing above fits: one metric per row, all rows sharing the same columns, 10-cell bars
# Every line starts with a 2-column margin (spacers excepted). A row or segment is omitted when
# its data is absent; nothing is printed as a placeholder. Bars are smooth: every cell sits on a
# dark track background, filled with █ plus an eighth-block boundary cell (▏ to ▉); bars and
# percentages turn yellow at 60% and red at 80%.
# Palette (256-colour only): violet 141 accent, green 78 ok, yellow 221 warn, red 203 crit,
# label 245, value 252, bright 255, track background 237, separator 240, cyan 81 (high effort).

INPUT=$(cat)

VIOLET=$'\033[38;5;141m'; OK=$'\033[38;5;78m';  WARN=$'\033[38;5;221m'; CRIT=$'\033[38;5;203m'
LABEL=$'\033[38;5;245m';  VALUE=$'\033[38;5;252m'; BRIGHT=$'\033[38;5;255m'
TRKBG=$'\033[48;5;237m';  SEPC=$'\033[38;5;240m'; CYAN=$'\033[38;5;81m'
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

# ---- width ---------------------------------------------------------------------------
# term_cols -> W: terminal columns, 0 when unknown. Claude Code runs this script without a
# controlling tty, so `stty size </dev/tty` fails there; the fallback walks up the parent
# processes until one owns a real tty and asks that device. Order: $RAWCODE_COLS (test override),
# /dev/tty, the ancestor's tty, $COLUMNS, unknown. Failures are silent.
term_cols() {
  local sz cols="" pid=$PPID ppid tty n=0 re='^(tty|pts/)[A-Za-z0-9/]+$'
  W=0
  if isnum "$RAWCODE_COLS"; then W=$RAWCODE_COLS; return 0; fi
  sz=$(stty size 2>/dev/null </dev/tty) && cols=${sz##* }
  if isnum "$cols" && [ "$cols" -gt 0 ]; then W=$cols; return 0; fi
  while [ "$n" -lt 8 ] && isnum "$pid" && [ "$pid" -gt 1 ]; do
    read -r ppid tty <<<"$(ps -o ppid=,tty= -p "$pid" 2>/dev/null)"
    if [[ "$tty" =~ $re ]]; then
      sz=$(stty -f "/dev/$tty" size 2>/dev/null) || sz=$(stty -F "/dev/$tty" size 2>/dev/null) || sz=""
      cols=${sz##* }
      if isnum "$cols" && [ "$cols" -gt 0 ]; then W=$cols; return 0; fi
      break
    fi
    pid=$ppid; n=$(( n + 1 ))
  done
  if isnum "$COLUMNS" && [ "$COLUMNS" -gt 0 ]; then W=$COLUMNS; fi
  return 0
}
term_cols

SPACER=$'\xe2\xa0\x80'
SEP="   ${SEPC}│${R}   "                # between slots in wide mode: 3 spaces, dim │, 3 spaces
SEPW=7
PCTW=4
LIM=118; [ "$W" -gt 0 ] && LIM=$(( W - 2 ))      # widest line allowed, margin included

# pcol <pct>  -> sets PC: green (<60), yellow (60-79), red (>=80)
pcol() {
  if   [ "$1" -ge 80 ]; then PC="$CRIT"
  elif [ "$1" -ge 60 ]; then PC="$WARN"
  else PC="$OK"; fi
}

# bar <pct>  -> BARN-cell bar in BAR. Every cell has the track background; the load is full
# blocks plus one eighth-block boundary cell, rounded to eighths of a cell. Any non-zero load
# shows at least one eighth; the colours are reset right after the last cell.
EIGHTHS=(▏ ▎ ▍ ▌ ▋ ▊ ▉)
bar() {
  local eighths=$(( ($1 * BARN * 8 + 50) / 100 )) full part rest on off
  [ "$1" -gt 0 ] && [ "$eighths" -eq 0 ] && eighths=1
  [ "$eighths" -gt $(( BARN * 8 )) ] && eighths=$(( BARN * 8 ))
  full=$(( eighths / 8 )); part=$(( eighths % 8 ))
  rest=$(( BARN - full )); [ "$part" -gt 0 ] && rest=$(( rest - 1 ))
  printf -v on '%*s' "$full" '';  on=${on// /█}
  printf -v off '%*s' "$rest" ''
  BAR="${TRKBG}${PC}${on}"
  [ "$part" -gt 0 ] && BAR="${BAR}${EIGHTHS[part-1]}"
  BAR="${BAR}${off}${R}"
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
  if [ "$SHOWCLK" = 1 ]; then
    clock "$1" "$2"
    [ -n "$CLK" ] && DETP="${DETP} · ${CLK}"
  fi
  DET="${LABEL}${DETP}${R}"
}

# meter <label> <pct> <detail> <detail-plain>  -> ROW and its plain length ROWLEN
#   "5h   ██████▍     62%   ↻ 2h48m" (nothing when pct is absent)
# Padding is applied to plain text; colour codes are wrapped around it afterwards.
meter() {
  local lab pct
  ROW=""
  isnum "$2" || return 0
  printf -v lab '%-*s' "$LABW" "$1"
  printf -v pct '%*s' "$PCTW" "$2%"
  pcol "$2"; bar "$2"
  gap "$LGAP"; ROW="${LABEL}${lab}${R}${SP}"
  gap "$BARGAP"; ROW="${ROW}${BAR}${SP}${PC}${pct}${R}"
  ROWLEN=$(( ${#lab} + LGAP + BARN + BARGAP + PCTW ))
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
  gap "$LGAP"
  ROW="${LABEL}${lab}${R}${SP}${3}"
  ROWLEN=$(( ${#lab} + LGAP + VL ))
  if [ -n "$4" ]; then
    pad=$(( AVALW - VL )); [ "$pad" -lt 1 ] && pad=1
    gap "$pad"; ROW="${ROW}${SP}${4}"
    vlen "$5"; ROWLEN=$(( ROWLEN + pad + VL ))
  fi
}

# Rows are kept both as a stacked list (compact) and by slot 0-2 (wide).
LROWS=(); AROWS=(); MT=("" "" ""); ML=(0 0 0); AT=("" "" ""); AL=(0 0 0)
addl() { [ -z "$ROW" ] && return 0; LROWS[${#LROWS[@]}]="$ROW"; MT[$1]="$ROW"; ML[$1]="$ROWLEN"; }
adda() { [ -z "$ROW" ] && return 0; AROWS[${#AROWS[@]}]="$ROW"; AT[$1]="$ROW"; AL[$1]="$ROWLEN"; }

# pack m|a  -> PT[] PL[] PW[] PN: the slots present in the meters (m) or activity (a) row, packed
# left to right. PW is the width a slot takes when another slot follows it: the widest it can be
# (label 3 + 2 + bar + 2 + pct 4 + 3 + detail at its widest: DW5 for 5h, DW7 for 7d), so columns do
# not move with the data. The last slot of a row needs no width.
pack() {
  local i t l w
  PT=(); PL=(); PW=(); PN=0
  for i in 0 1 2; do
    if [ "$1" = m ]; then t=${MT[i]}; l=${ML[i]}; else t=${AT[i]}; l=${AL[i]}; fi
    [ -n "$t" ] || continue
    case "$1$i" in
      m0) w=$(( 14 + BARN + DW5 )) ;;
      m1) w=$(( 14 + BARN + DW7 )) ;;
      a0) w=29 ;;                                   # "cache hit  95%  expires 1h0m"
      a1) w=23 ;;                                   # "changed  +999 −999"
      *)  w=0 ;;
    esac
    [ "$l" -gt "$w" ] && w=$l
    PT[PN]=$t; PL[PN]=$l; PW[PN]=$w; PN=$(( PN + 1 ))
  done
}

# emit <n> <text0> <len0> <text1> <len1> <text2> <len2> -> SROW and its plain length SLEN: the n
# packed slots joined by SEP, each slot but the last padded to its column width WD[i] (shared by
# both rows, so slot i starts in the same column in each). A │ sits only between two slots.
emit() {
  local n=$1 i=0 t l pad
  shift
  SROW=""; SLEN=0
  while [ "$i" -lt "$n" ]; do
    t=$1; l=$2; shift 2
    if [ "$i" -lt $(( n - 1 )) ]; then
      pad=$(( WD[i] - l )); gap "$pad"
      SROW="${SROW}${t}${SP}${SEP}"; SLEN=$(( SLEN + WD[i] + SEPW ))
    else
      SROW="${SROW}${t}"; SLEN=$(( SLEN + l ))
    fi
    i=$(( i + 1 ))
  done
}

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

# ---- rows ----------------------------------------------------------------------------
# build fills the meter and activity rows for the current BARN / SHOWCLK / WIDE settings; it can
# run once per step of the wide ladder.
build() {
LROWS=(); AROWS=(); MT=("" "" ""); ML=(0 0 0); AT=("" "" ""); AL=(0 0 0)
reset_detail "$H5R" "%H:%M";    meter 5h "$H5" "$DET" "$DETP"; addl 0
reset_detail "$D7R" "%a %H:%M"; meter 7d "$D7" "$DET" "$DETP"; addl 1

if ! isnum "$CTXP" && isnum "$CTXTOK" && isnum "$CTXSIZE" && [ "$CTXSIZE" -gt 0 ]; then
  CTXP=$(( CTXTOK * 100 / CTXSIZE ))
fi
DET=""; DETP=""
if isnum "$CTXTOK" && isnum "$CTXSIZE"; then
  human "$CTXTOK"; USED="$HUM"; human "$CTXSIZE"
  DETP="${USED}/${HUM}"; DET="${LABEL}${DETP}${R}"
fi
if [ "$EX200" = "true" ]; then
  # Last step of the wide ladder (DROPTOK): the token count is dropped and only the warning stays.
  if [ "$WIDE" = 1 ] && [ "$DROPTOK" = 1 ]; then DET=""; DETP=""; fi
  [ -n "$DET" ] && { DET="${DET} "; DETP="${DETP} "; }
  DET="${DET}${WARN}⚠ >200k${R}"; DETP="${DETP}⚠ >200k"
fi
meter ctx "$CTXP" "$DET" "$DETP"; addl 2

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
  adda 0
fi

if { isnum "$LADD" && [ "$LADD" -gt 0 ]; } || { isnum "$LREM" && [ "$LREM" -gt 0 ]; }; then
  LA=${LADD:-0}; LR=${LREM:-0}
  arow changed "" "${OK}+${LA}${R} ${CRIT}−${LR}${R}"
  ROWLEN=$(( ROWLEN + 3 + ${#LA} + ${#LR} ))
  adda 1
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
  adda 2
fi

}

# ---- layout --------------------------------------------------------------------------
# Wide ladder: "<bar cells> <clock times> <drop ctx tokens>". Each row lists only its present
# slots, packed left to right, so a missing meter frees its column instead of leaving a blank one.
# Slot i has the same width in both rows (WD[i], from the widest slot that has one), so slot i
# starts in the same column in each row. The first step whose widest row fits LIM wins; fewer
# slots means more room. When none fits the compact stack is used.
WIDE=0
for CFG in "12 1 0" "12 0 0" "10 0 0" "10 0 1"; do
  read -r BARN SHOWCLK DROPTOK <<<"$CFG"
  [ "$DROPTOK" = 1 ] && [ "$EX200" != "true" ] && continue
  if [ "$SHOWCLK" = 1 ]; then DW5=15; DW7=19; else DW5=7; DW7=8; fi   # "↻ 4h59m · 23:59" / "↻ 6d23h · Wed 23:59"
  WIDE=1; LABW=3; LGAP=2; BARGAP=2; GAPW=3; ALABW=0; AVALW=5
  build
  pack m; MPN=$PN; MPT=("${PT[@]}"); MPL=("${PL[@]}"); MPW=("${PW[@]}")
  pack a; APN=$PN; APT=("${PT[@]}"); APL=("${PL[@]}"); APW=("${PW[@]}")
  WD=(0 0)
  for i in 0 1; do
    [ "$i" -lt $(( MPN - 1 )) ] && [ "${MPW[i]}" -gt "${WD[i]}" ] && WD[i]=${MPW[i]}
    [ "$i" -lt $(( APN - 1 )) ] && [ "${APW[i]}" -gt "${WD[i]}" ] && WD[i]=${APW[i]}
  done
  emit "$MPN" "${MPT[0]}" "${MPL[0]}" "${MPT[1]}" "${MPL[1]}" "${MPT[2]}" "${MPL[2]}"
  G2=""; [ -n "$SROW" ] && G2="${MARGIN}${SROW}"; TOTAL=$SLEN
  emit "$APN" "${APT[0]}" "${APL[0]}" "${APT[1]}" "${APL[1]}" "${APT[2]}" "${APL[2]}"
  G3=""; [ -n "$SROW" ] && G3="${MARGIN}${SROW}"; [ "$SLEN" -gt "$TOTAL" ] && TOTAL=$SLEN
  TOTAL=$(( ${#MARGIN} + TOTAL ))
  [ "$TOTAL" -le "$LIM" ] && break
  WIDE=0
done
if [ "$WIDE" = 0 ]; then
  SHOWCLK=1; BARN=10; DROPTOK=0; LABW=11; LGAP=0; BARGAP=3; GAPW=4
  ALABW=11; AVALW=$(( LABW + BARN + BARGAP + PCTW + GAPW - ALABW ))   # detail lines up with the meters'
  build
  G2=""; G3=""
  for L in "${LROWS[@]}"; do G2="${G2:+${G2}$'\n'}${MARGIN}${L}"; done
  for L in "${AROWS[@]}"; do G3="${G3:+${G3}$'\n'}${MARGIN}${L}"; done
fi

# ---- output --------------------------------------------------------------------------
# Groups (identity, meters, activity) are separated by one SPACER line; empty groups and their
# spacers are dropped, so a spacer is never first, last or doubled.
# The session name is dropped when it would push the identity row past the width.
vlen "$IDP"; ilen=$VL; vlen "$SESS"
if [ -n "$SESS" ] && [ $(( ${#MARGIN} + ilen + 3 + VL )) -le "$LIM" ]; then
  if [ "$WIDE" = 1 ]; then
    # Right-aligned so the session name ends at the right edge of the block.
    pad=$(( TOTAL - (${#MARGIN} + ilen) - VL )); [ "$pad" -lt 3 ] && pad=3
    gap "$pad"; IDC="${IDC}${SP}${LABEL}${SESS}${R}"
  else
    ident "$SESS" "${LABEL}${SESS}${R}"
  fi
fi

printf '%s%s\n' "$MARGIN" "$IDC"
[ -n "$G2" ] && printf '%s\n%s\n' "$SPACER" "$G2"
[ -n "$G3" ] && printf '%s\n%s\n' "$SPACER" "$G3"
exit 0
