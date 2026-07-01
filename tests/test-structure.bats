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

@test "hooks.json exists and is valid JSON" {
  run jq . hooks/hooks.json
  [ "$status" -eq 0 ]
}

@test "hooks.json has PreToolUse hooks" {
  run jq -e '.hooks.PreToolUse' hooks/hooks.json
  [ "$status" -eq 0 ]
}

@test "hook commands resolve via CLAUDE_PLUGIN_ROOT" {
  run jq -e '[.. | .command? | select(.)] | all(contains("${CLAUDE_PLUGIN_ROOT}"))' hooks/hooks.json
  [ "$status" -eq 0 ]
}

@test "Stop hook wires the TDD gate" {
  run jq -e '.hooks.Stop[0].hooks[0].command | contains("tdd-gate.py")' hooks/hooks.json
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

@test "rawcode output style exists with valid frontmatter" {
  [ -f output-styles/rawcode.md ]
  grep -q "^name: rawcode" output-styles/rawcode.md
  grep -q "^keep-coding-instructions: true" output-styles/rawcode.md
}

@test "plugin.json declares the skills directory" {
  run jq -e '.skills == "./skills/"' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "marketplace.json is valid and lists the rawcode plugin" {
  run jq -e '.plugins | map(.name) | index("rawcode")' .claude-plugin/marketplace.json
  [ "$status" -eq 0 ]
}

@test "rc-tdd skill exists with gentleman-format frontmatter" {
  [ -f skills/rc-tdd/SKILL.md ]
  grep -q "^name: rc-tdd" skills/rc-tdd/SKILL.md
  grep -q "^description:" skills/rc-tdd/SKILL.md
  grep -q "user-invocable:" skills/rc-tdd/SKILL.md
}

@test "every skill has a name and description" {
  for f in skills/*/SKILL.md; do
    grep -q "^name:" "$f" || (echo "FAIL: $f missing name" && exit 1)
    grep -q "^description:" "$f" || (echo "FAIL: $f missing description" && exit 1)
  done
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

@test "hooks directory is wired" {
  [ -f hooks/hooks.json ]
  [ ! -f guardrails/guardrails.json ]
}
