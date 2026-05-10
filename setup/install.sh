#!/bin/bash
# rawcode installer for Claude Code (macOS/Linux)
#
# Safe install (recommended):
#   curl -fsSL -o /tmp/rawcode-install.sh https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh
#   less /tmp/rawcode-install.sh   # inspect first
#   bash /tmp/rawcode-install.sh
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh | bash

set -e

REPO="juandarn/rawcode"
INSTALL_DIR="$HOME/.claude/plugins/rawcode"
VERSION_URL="https://raw.githubusercontent.com/$REPO/master/.claude-plugin/plugin.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Symbols
CHECK="${GREEN}\xe2\x9c\x94${RESET}"
CROSS="${RED}\xe2\x9c\x98${RESET}"
WARN="${YELLOW}\xe2\x9a\xa0${RESET}"
ARROW="${CYAN}\xe2\x96\xb6${RESET}"

step()  { printf "  ${ARROW} %b\n" "$1"; }
ok()    { printf "  ${CHECK} %b\n" "$1"; }
fail()  { printf "  ${CROSS} %b\n" "$1"; }
warn()  { printf "  ${WARN} %b\n" "$1"; }

spin() {
  local pid=$1 msg=$2
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${CYAN}%s${RESET} %s" "${frames:i%${#frames}:1}" "$msg"
    i=$((i + 1))
    sleep 0.08
  done
  printf "\r\033[2K"
}

get_local_version() {
  if [ -f "$INSTALL_DIR/.claude-plugin/plugin.json" ]; then
    grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$INSTALL_DIR/.claude-plugin/plugin.json" | grep -o '[0-9][0-9.]*' || echo "unknown"
  else
    echo "none"
  fi
}

get_remote_version() {
  if command -v curl &>/dev/null; then
    curl -fsSL "$VERSION_URL" 2>/dev/null | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '[0-9][0-9.]*' || echo "unknown"
  else
    echo "unknown"
  fi
}

# ── Banner ──────────────────────────────────────────
echo ""
printf "${BOLD}${CYAN}"
cat << 'LOGO'
                                    _
   _ __ __ ___      _____ ___   __| | ___
  | '__/ _` \ \ /\ / / __/ _ \ / _` |/ _ \
  | | | (_| |\ V  V / (_| (_) | (_| |  __/
  |_|  \__,_| \_/\_/ \___\___/ \__,_|\___|

LOGO
printf "${RESET}"
printf "  ${DIM}OpenCode philosophy for Claude Code${RESET}\n"
printf "  ${DIM}concise \xc2\xb7 root-cause \xc2\xb7 minimal \xc2\xb7 secure \xc2\xb7 verified${RESET}\n"
echo ""
printf "  ${DIM}%s${RESET}\n" "─────────────────────────────────────────"
echo ""

# ── Mode detection (install vs update) ──────────────
LOCAL_VER=$(get_local_version)
MODE="install"

if [ "$LOCAL_VER" != "none" ]; then
  REMOTE_VER=$(get_remote_version)

  if [ "$LOCAL_VER" = "$REMOTE_VER" ] && [ "$REMOTE_VER" != "unknown" ]; then
    ok "rawcode v${LOCAL_VER} is already up to date"
    echo ""
    exit 0
  fi

  MODE="update"
  if [ "$REMOTE_VER" != "unknown" ]; then
    step "Updating rawcode ${DIM}v${LOCAL_VER}${RESET} ${CYAN}\xe2\x86\x92${RESET} ${BOLD}v${REMOTE_VER}${RESET}"
  else
    step "Updating rawcode ${DIM}v${LOCAL_VER}${RESET} ${CYAN}\xe2\x86\x92${RESET} ${BOLD}latest${RESET}"
  fi
  echo ""
fi

# ── Prerequisites ───────────────────────────────────
step "Checking prerequisites..."

if ! command -v git &>/dev/null; then
  fail "git not found. Install git and try again."
  exit 1
fi
ok "git found"

if ! command -v claude &>/dev/null; then
  warn "claude CLI not found — install it: ${CYAN}https://claude.ai/code${RESET}"
else
  ok "claude CLI found"
fi

echo ""

# ── Plugin directory ────────────────────────────────
PLUGIN_DIR="$HOME/.claude/plugins"
mkdir -p "$PLUGIN_DIR" 2>/dev/null || {
  fail "Cannot create $PLUGIN_DIR. Check permissions."
  exit 2
}

# ── Backup existing installation ────────────────────
if [ -d "$INSTALL_DIR" ]; then
  BACKUP="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  warn "Backing up current installation"
  mv "$INSTALL_DIR" "$BACKUP"
fi

# ── Clone ───────────────────────────────────────────
step "Downloading rawcode..."
git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR" 2>/dev/null &
spin $! "Cloning repository..."
wait $!

if [ ! -d "$INSTALL_DIR" ]; then
  fail "Download failed. Check your internet connection."
  # Restore backup if update failed
  if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
    mv "$BACKUP" "$INSTALL_DIR"
    warn "Previous version restored"
  fi
  exit 3
fi
ok "Repository cloned"

# ── Cleanup & permissions ──────────────────────────
rm -rf "$INSTALL_DIR/.git"
chmod +x "$INSTALL_DIR/ui/statusline.sh" 2>/dev/null
chmod +x "$INSTALL_DIR/guardrails/"*.sh 2>/dev/null
chmod +x "$INSTALL_DIR/setup/"*.sh 2>/dev/null
ok "Scripts configured"

# ── Verify installation ────────────────────────────
INSTALLED_VER=$(get_local_version)
if [ -f "$INSTALL_DIR/agents/rawcode.md" ] && [ -f "$INSTALL_DIR/settings.json" ]; then
  ok "Installation verified"
else
  fail "Installation incomplete — files missing"
  exit 4
fi

# ── Clean old backups (keep last 2) ────────────────
mapfile -t BACKUPS < <(ls -dt "$PLUGIN_DIR/rawcode.backup."* 2>/dev/null || true)
if [ ${#BACKUPS[@]} -gt 2 ]; then
  for old in "${BACKUPS[@]:2}"; do
    rm -rf "$old"
  done
  ok "Old backups cleaned"
fi

# ── Done ────────────────────────────────────────────
echo ""
printf "  ${DIM}%s${RESET}\n" "─────────────────────────────────────────"
echo ""

if [ "$MODE" = "update" ]; then
  printf "  ${GREEN}${BOLD}rawcode updated to v${INSTALLED_VER}!${RESET}\n"
else
  printf "  ${GREEN}${BOLD}rawcode v${INSTALLED_VER} installed!${RESET}\n"
fi

echo ""
printf "  ${DIM}Get started:${RESET}\n"
printf "    ${BOLD}\$ claude${RESET}    ${DIM}# rawcode loads automatically${RESET}\n"
echo ""
printf "  ${DIM}Update:${RESET}\n"
printf "    ${BOLD}\$ ~/.claude/plugins/rawcode/setup/install.sh${RESET}\n"
echo ""
printf "  ${DIM}Uninstall:${RESET}\n"
printf "    ${BOLD}\$ ~/.claude/plugins/rawcode/setup/uninstall.sh${RESET}\n"
echo ""
