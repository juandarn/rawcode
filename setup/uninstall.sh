#!/bin/bash
# rawcode uninstaller for Claude Code
# Usage: ~/.claude/plugins/rawcode/setup/uninstall.sh

INSTALL_DIR="$HOME/.claude/plugins/rawcode"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "rawcode is not installed."
  exit 0
fi

echo "Removing rawcode from $INSTALL_DIR..."

# Revert settings merged by the installer
SETTINGS="$HOME/.claude/settings.json"
if command -v jq &>/dev/null && [ -f "$SETTINGS" ]; then
  if jq \
      '(if .outputStyle == "rawcode" then del(.outputStyle) else . end)
       | (if (.statusLine.command // "") | test("plugins/rawcode/") then del(.statusLine) else . end)' \
      "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"; then
    echo "Reverted output style and statusline in settings."
  else
    rm -f "${SETTINGS}.tmp"
  fi
fi

rm -rf "$INSTALL_DIR"

# Clean up backups
for backup in "$HOME/.claude/plugins/rawcode.backup."*; do
  if [ -d "$backup" ]; then
    echo "Removing backup: $backup"
    rm -rf "$backup"
  fi
done

echo "rawcode uninstalled successfully."
