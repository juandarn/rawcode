#!/bin/bash
# opencode-style installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/juandarn/opencode-style/master/install.sh | bash

set -e

REPO="juandarn/opencode-style"
INSTALL_DIR="$HOME/.claude/plugins/opencode-style"

echo "Installing opencode-style plugin..."

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
echo "opencode-style installed successfully!"
echo ""
echo "Usage:"
echo "  claude                                  # plugin loads automatically"
echo "  claude --agent opencode-style:coder     # full OpenCode mode"
echo ""
echo "Available commands:"
echo "  /opencode-style:review     Review code changes"
echo "  /opencode-style:explore    Explore the codebase"
echo "  /opencode-style:fix        Fix a bug (root-cause)"
echo "  /opencode-style:summarize  Summarize session"
echo "  /opencode-style:compact    Compact context"
echo "  /opencode-style:status     Project dashboard"
echo "  /opencode-style:diff       Formatted diff"
