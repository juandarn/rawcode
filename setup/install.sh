#!/bin/bash
# rawcode installer for Claude Code (macOS/Linux)
# Usage: curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/setup/install.sh | bash

set -e

REPO="juandarn/rawcode"
INSTALL_DIR="$HOME/.claude/plugins/rawcode"

echo "rawcode installer"
echo "================="

# Check prerequisites
if ! command -v git &>/dev/null; then
  echo "Error: git is required. Install git and try again."
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Warning: claude CLI not found. Install Claude Code first: https://claude.ai/code"
fi

# Ensure plugin directory exists
PLUGIN_DIR="$HOME/.claude/plugins"
mkdir -p "$PLUGIN_DIR" 2>/dev/null || {
  echo "Error: cannot create $PLUGIN_DIR. Check permissions."
  exit 2
}

# Backup existing installation
if [ -d "$INSTALL_DIR" ]; then
  BACKUP="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing installation to $BACKUP"
  mv "$INSTALL_DIR" "$BACKUP"
fi

# Clone
echo "Installing rawcode..."
git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR" 2>/dev/null

# Remove .git from plugin dir
rm -rf "$INSTALL_DIR/.git"

# Make scripts executable
chmod +x "$INSTALL_DIR/ui/statusline.sh" 2>/dev/null
chmod +x "$INSTALL_DIR/guardrails/"*.sh 2>/dev/null
chmod +x "$INSTALL_DIR/setup/"*.sh 2>/dev/null

echo ""
echo "rawcode installed successfully!"
echo ""
echo "Usage:"
echo "  claude    # rawcode loads automatically"
echo ""
echo "Philosophy: concise, root-cause, minimal, secure, verified."
