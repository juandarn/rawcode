#!/usr/bin/env bats
# Tests for guardrail scripts. Hooks read a JSON object from stdin.

# Build hook JSON and pipe it to a guardrail script.
run_file_hook() { # <script> <file_path>
  run bash -c "jq -nc --arg p \"\$1\" '{tool_input:{file_path:\$p}}' | bash $BATS_TEST_DIRNAME/../guardrails/$1" _ "$2"
}
run_cmd_hook() { # <script> <command>
  run bash -c "jq -nc --arg c \"\$1\" '{tool_input:{command:\$c}}' | bash $BATS_TEST_DIRNAME/../guardrails/$1" _ "$2"
}

# --- protect-sensitive-files.sh ---

@test "blocks .env files" {
  run_file_hook protect-sensitive-files.sh ".env"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks .env.local files" {
  run_file_hook protect-sensitive-files.sh ".env.local"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks nested migration files" {
  run_file_hook protect-sensitive-files.sh "db/migrations/001_create_users.sql"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks top-level migrations dir" {
  run_file_hook protect-sensitive-files.sh "migrations/001_create_users.sql"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks package-lock.json" {
  run_file_hook protect-sensitive-files.sh "package-lock.json"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks yarn.lock" {
  run_file_hook protect-sensitive-files.sh "yarn.lock"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks pnpm-lock.yaml" {
  run_file_hook protect-sensitive-files.sh "pnpm-lock.yaml"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "blocks Gemfile.lock" {
  run_file_hook protect-sensitive-files.sh "Gemfile.lock"
  [ "$status" -eq 0 ]; [[ "$output" == *"deny"* ]]
}

@test "allows normal source files" {
  run_file_hook protect-sensitive-files.sh "src/index.ts"
  [ "$status" -eq 0 ]; [[ "$output" != *"deny"* ]]
}

@test "allows README" {
  run_file_hook protect-sensitive-files.sh "README.md"
  [ "$status" -eq 0 ]; [[ "$output" != *"deny"* ]]
}

@test "emits valid JSON even for a path containing a quote" {
  run_file_hook protect-sensitive-files.sh 'weird".env'
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"'
}

# --- enforce-read-before-write.sh ---

@test "warns when editing existing file" {
  run_file_hook enforce-read-before-write.sh "README.md"
  [ "$status" -eq 0 ]; [[ "$output" == *"read this file"* ]]
}

@test "no warning for new files" {
  run_file_hook enforce-read-before-write.sh "nonexistent_file_xyz.ts"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

# --- sanitize-commit.sh ---

@test "warns on commit with Co-Authored-By" {
  run_cmd_hook sanitize-commit.sh 'git commit -m "fix: stuff

Co-Authored-By: Someone"'
  [ "$status" -eq 0 ]; [[ "$output" == *"Co-Authored-By"* ]]
}

@test "no warning on normal commit" {
  run_cmd_hook sanitize-commit.sh 'git commit -m "fix: login bug"'
  [ "$status" -eq 0 ]; [[ "$output" != *"Co-Authored-By"* ]]
}

@test "no warning on non-git commands" {
  run_cmd_hook sanitize-commit.sh 'npm run test'
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "does not fire on git commit-tree" {
  run_cmd_hook sanitize-commit.sh 'git commit-tree abc123 Co-Authored-By'
  [ "$status" -eq 0 ]; [ -z "$output" ]
}
