#!/usr/bin/env bats
# Tests that the plugin structure is valid

@test "plugin.json exists and is valid JSON" {
  run jq . .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "plugin.json has required fields" {
  run jq -e '.name' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
  run jq -e '.version' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
  run jq -e '.description' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "settings.json exists and is valid JSON" {
  run jq . settings.json
  [ "$status" -eq 0 ]
}

@test "settings.json has permissions.deny" {
  run jq -e '.permissions.deny' settings.json
  [ "$status" -eq 0 ]
}

@test "settings.json has statusLine config" {
  run jq -e '.statusLine' settings.json
  [ "$status" -eq 0 ]
}

@test "guardrails.json exists and is valid JSON" {
  run jq . guardrails/guardrails.json
  [ "$status" -eq 0 ]
}

@test "guardrails.json has PreToolUse hooks" {
  run jq -e '.hooks.PreToolUse' guardrails/guardrails.json
  [ "$status" -eq 0 ]
}

@test "rawcode.md agent exists" {
  [ -f agents/rawcode.md ]
}

@test "rawcode.md has valid frontmatter" {
  head -1 agents/rawcode.md | grep -q "^---"
  grep -q "^name: rawcode" agents/rawcode.md
  grep -q "^description:" agents/rawcode.md
}

@test "all guardrail scripts are executable" {
  for script in guardrails/*.sh; do
    [ -x "$script" ]
  done
}

@test "statusline.sh is executable" {
  [ -x ui/statusline.sh ]
}

@test "no old agent files exist" {
  [ ! -f agents/coder.md ]
  [ ! -f agents/code.md ]
  [ ! -f agents/reviewer.md ]
  [ ! -f agents/summarizer.md ]
  [ ! -f agents/task.md ]
  [ ! -f agents/think.md ]
  [ ! -f agents/titler.md ]
}

@test "no old hooks directory exists" {
  [ ! -d hooks ]
}
