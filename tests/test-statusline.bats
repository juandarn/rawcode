#!/usr/bin/env bats
# Tests for statusline rendering. Input schema per Claude Code docs:
# model.display_name, context_window.used_percentage, cost.total_cost_usd, output_style.name

@test "empty input shows rawcode logo" {
  run bash -c 'echo "" | bash ui/statusline.sh'
  [ "$status" -eq 0 ]
  [[ "$output" == *"rawcode"* ]]
}

@test "full input renders all segments" {
  run bash -c "bash ui/statusline.sh < tests/fixtures/statusline-input.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rawcode"* ]]
  [[ "$output" == *"sonnet"* ]]
  [[ "$output" == *"45"* ]]
  [[ "$output" == *"0.12"* ]]
}

@test "renders the multi-line (pretty-printed) fixture, not just first line" {
  # read -r would capture only "{"; $(cat) must consume the whole object
  run bash -c "bash ui/statusline.sh < tests/fixtures/statusline-input.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"45"* ]]
}

@test "opus model shortens correctly" {
  INPUT='{"model":{"display_name":"Opus"},"context_window":{"used_percentage":10}}'
  run bash -c "printf '%s' '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"opus"* ]]
}

@test "haiku model shortens correctly" {
  INPUT='{"model":{"display_name":"Haiku 4.5"},"context_window":{"used_percentage":10}}'
  run bash -c "printf '%s' '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"haiku"* ]]
}

@test "context percentage is rendered from context_window.used_percentage" {
  INPUT='{"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":73}}'
  run bash -c "printf '%s' '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"73%"* ]]
  [[ "$output" == *"▓"* ]]
}

@test "missing context percentage is omitted, no bar shown" {
  INPUT='{"model":{"display_name":"Sonnet"}}'
  run bash -c "printf '%s' '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ctx"* ]]
  [[ "$output" != *"▓"* ]]
}

@test "malformed JSON does not crash" {
  run bash -c 'echo "not json at all" | bash ui/statusline.sh'
  [ "$status" -eq 0 ]
}
