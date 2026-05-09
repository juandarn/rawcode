#!/bin/bash
# rawcode uninstaller for Claude Code
# Usage: ~/.claude/plugins/rawcode/setup/uninstall.sh

INSTALL_DIR="$HOME/.claude/plugins/rawcode"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "rawcode is not installed."
  exit 0
fi

echo "Removing rawcode from $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"

# Clean up backups
for backup in "$HOME/.claude/plugins/rawcode.backup."*; do
  if [ -d "$backup" ]; then
    echo "Removing backup: $backup"
    rm -rf "$backup"
  fi
done

echo "rawcode uninstalled successfully."
