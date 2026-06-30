#!/bin/bash
# Blocks editing of sensitive files: .env, migrations, lock files
# Used as PreToolUse hook for Write|Edit. Reads hook JSON from stdin.

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

deny() {
  jq -nc --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
}

case "$FILE" in
  *.env|*.env.*)
    deny "Protected file: $FILE. Environment files should not be modified by the assistant." ;;
  migrations/*|*/migrations/*)
    deny "Protected file: $FILE. Migration files should not be modified directly." ;;
  *package-lock.json|*yarn.lock|*pnpm-lock.yaml|*Gemfile.lock|*composer.lock|*poetry.lock)
    deny "Protected file: $FILE. Lock files should not be modified directly." ;;
esac

exit 0
