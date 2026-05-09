#!/bin/bash
# Blocks editing of sensitive files: .env, migrations, lock files
# Used as PreToolUse hook for Write|Edit

# shellcheck disable=SC2154 # Variables injected by Claude Code hooks
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH}${CLAUDE_TOOL_INPUT_file_path}"

case "$FILE" in
  *.env|*.env.*)
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Protected file: $FILE. Environment files should not be modified by the assistant.\"}}"
    ;;
  */migrations/*)
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Protected file: $FILE. Migration files should not be modified directly.\"}}"
    ;;
  *package-lock.json|*yarn.lock|*pnpm-lock.yaml|*Gemfile.lock|*composer.lock|*poetry.lock)
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Protected file: $FILE. Lock files should not be modified directly.\"}}"
    ;;
esac

exit 0
