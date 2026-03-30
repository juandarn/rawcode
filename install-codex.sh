#!/bin/bash
# rawcode installer for Codex
# Usage: curl -fsSL https://raw.githubusercontent.com/juandarn/rawcode/master/install-codex.sh | bash

set -euo pipefail

REPO="juandarn/rawcode"
TARGET="$HOME/AGENTS.md"
URL="https://raw.githubusercontent.com/$REPO/master/codex/AGENTS.md"
TMP_FILE="$(mktemp)"

cleanup() {
  rm -f "$TMP_FILE"
}

trap cleanup EXIT

echo "Installing rawcode for Codex..."

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required. Install curl and try again."
  exit 1
fi

curl -fsSL "$URL" -o "$TMP_FILE"

if [ -f "$TARGET" ]; then
  if cmp -s "$TMP_FILE" "$TARGET"; then
    echo "rawcode for Codex is already up to date at $TARGET"
    exit 0
  fi

  BACKUP="$TARGET.rawcode.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET" "$BACKUP"
  echo "Backed up existing AGENTS.md to $BACKUP"
fi

mv "$TMP_FILE" "$TARGET"
trap - EXIT

echo ""
echo "rawcode for Codex installed successfully!"
echo "Location: $TARGET"
echo "Codex will use these defaults for repos under $HOME."
echo "Repo-local AGENTS.md files override the global one."
