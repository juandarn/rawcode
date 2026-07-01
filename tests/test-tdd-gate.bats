#!/usr/bin/env bats
# Tests for the TDD gate Stop hook. Strict TDD by default with escapes.

setup() { TDIR="$(mktemp -d)"; export TMPDIR="$TDIR"; }  # isolate once-per-turn markers
teardown() { rm -rf "$TDIR"; }

# Build a transcript and run the gate against it. Echoes the decision or "allow".
gate() { # <transcript_file>  — empty hook output means allow
  local out
  out=$(printf '{"session_id":"%s","transcript_path":"%s","stop_hook_active":false}' "$BATS_TEST_NAME" "$1" \
    | python3 guardrails/tdd-gate.py)
  if [ -z "$out" ]; then echo "allow"; else echo "$out" | jq -r '.decision // "allow"'; fi
}

@test "blocks when code changed and no test ran" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"add a validator"}
{"message":{"role":"user","content":"add a validator"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/src/validate.py"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "block" ]
}

@test "allows when a test ran after the code change" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"add a validator"}
{"message":{"role":"user","content":"add a validator"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/src/validate.py"}}]}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","input":{"command":"pytest -q"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "allow" ]
}

@test "allows on an urgent/skip escape word in the prompt" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"urgent hotfix, patch it"}
{"message":{"role":"user","content":"urgent hotfix"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/src/validate.py"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "allow" ]
}

@test "allows when only a test file was written" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"write the failing test"}
{"message":{"role":"user","content":"write the failing test"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Write","input":{"file_path":"/x/tests/test_validate.py"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "allow" ]
}

@test "allows non-code edits (docs/config)" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"update the readme"}
{"message":{"role":"user","content":"update the readme"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/README.md"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "allow" ]
}

@test "blocks at most once per turn (no loop)" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"one shot per turn"}
{"message":{"role":"user","content":"go"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/src/a.py"}}]}}
EOF
  [ "$(gate "$TDIR/t.jsonl")" = "block" ]
  [ "$(gate "$TDIR/t.jsonl")" = "allow" ]
}

@test "allows when stop_hook_active is true" {
  cat > "$TDIR/t.jsonl" <<'EOF'
{"type":"last-prompt","lastPrompt":"loop guard"}
{"message":{"role":"user","content":"go"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/src/a.py"}}]}}
EOF
  run bash -c "printf '{\"session_id\":\"z\",\"transcript_path\":\"$TDIR/t.jsonl\",\"stop_hook_active\":true}' | python3 guardrails/tdd-gate.py"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
