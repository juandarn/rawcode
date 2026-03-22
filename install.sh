#!/bin/bash
# rawcode installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install.sh | bash

set -e

REPO="juandarn/rawcode"
INSTALL_DIR="$HOME/.claude/plugins/rawcode"

echo "Installing rawcode plugin..."

# Clean previous install
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  rm -rf "$INSTALL_DIR"
fi

# Clone
if command -v git &> /dev/null; then
  git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR" 2>/dev/null
else
  echo "Error: git is required. Install git and try again."
  exit 1
fi

# Remove .git from plugin dir (not needed)
rm -rf "$INSTALL_DIR/.git"

echo ""
echo "rawcode installed successfully!"
echo ""
echo "Usage:"
echo "  claude                                  # plugin loads automatically"
echo "  claude --agent rawcode:coder     # full OpenCode mode"
echo ""
echo "Available commands:"
echo "  /rawcode:review     Review code changes"
echo "  /rawcode:explore    Explore the codebase"
echo "  /rawcode:fix        Fix a bug (root-cause)"
echo "  /rawcode:summarize  Summarize session"
echo "  /rawcode:compact    Compact context"
echo "  /rawcode:status     Project dashboard"
echo "  /rawcode:diff       Formatted diff"
