#!/usr/bin/env bats
# Tests for guardrail scripts. Hooks read a JSON object from stdin.

# Build hook JSON and pipe it to a guardrail script.
run_file_hook() { # <script> <file_path>
  run bash -c "jq -nc --arg p \"\$1\" '{tool_input:{file_path:\$p}}' | bash $BATS_TEST_DIRNAME/../guardrails/$1" _ "$2"
}
run_cmd_hook() { # <script> <command>
  run bash -c "jq -nc --arg c \"\$1\" '{tool_input:{command:\$c}}' | bash $BATS_TEST_DIRNAME/../guardrails/$1" _ "$2"
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
