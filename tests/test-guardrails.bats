#!/usr/bin/env bats
# Tests for guardrail scripts

setup() {
  export CLAUDE_TOOL_INPUT_file_path=""
  export CLAUDE_TOOL_INPUT_FILE_PATH=""
}

# --- protect-sensitive-files.sh ---

@test "blocks .env files" {
  export CLAUDE_TOOL_INPUT_file_path=".env"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks .env.local files" {
  export CLAUDE_TOOL_INPUT_file_path=".env.local"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks migration files" {
  export CLAUDE_TOOL_INPUT_file_path="db/migrations/001_create_users.sql"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks package-lock.json" {
  export CLAUDE_TOOL_INPUT_file_path="package-lock.json"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks yarn.lock" {
  export CLAUDE_TOOL_INPUT_file_path="yarn.lock"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks pnpm-lock.yaml" {
  export CLAUDE_TOOL_INPUT_file_path="pnpm-lock.yaml"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "blocks Gemfile.lock" {
  export CLAUDE_TOOL_INPUT_file_path="Gemfile.lock"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "allows normal source files" {
  export CLAUDE_TOOL_INPUT_file_path="src/index.ts"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}

@test "allows README" {
  export CLAUDE_TOOL_INPUT_file_path="README.md"
  run bash guardrails/protect-sensitive-files.sh
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}

# --- enforce-read-before-write.sh ---

@test "warns when editing existing file" {
  export CLAUDE_TOOL_INPUT_file_path="README.md"
  run bash guardrails/enforce-read-before-write.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"read this file"* ]]
}

@test "no warning for new files" {
  export CLAUDE_TOOL_INPUT_file_path="nonexistent_file_xyz.ts"
  run bash guardrails/enforce-read-before-write.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- sanitize-commit.sh ---

@test "warns on commit with Co-Authored-By" {
  export CLAUDE_TOOL_INPUT_command='git commit -m "fix: stuff\n\nCo-Authored-By: Someone"'
  run bash guardrails/sanitize-commit.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Co-Authored-By"* ]]
}

@test "no warning on normal commit" {
  export CLAUDE_TOOL_INPUT_command='git commit -m "fix: login bug"'
  run bash guardrails/sanitize-commit.sh
  [ "$status" -eq 0 ]
  [[ "$output" != *"Co-Authored-By"* ]]
}

@test "no warning on non-git commands" {
  export CLAUDE_TOOL_INPUT_command='npm run test'
  run bash guardrails/sanitize-commit.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
