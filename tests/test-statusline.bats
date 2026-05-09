#!/usr/bin/env bats
# Tests for statusline rendering

@test "empty input shows rawcode logo" {
  run bash -c 'echo "" | bash ui/statusline.sh'
  [ "$status" -eq 0 ]
  [[ "$output" == *"rawcode"* ]]
}

@test "full input renders all segments" {
  INPUT='{"model":"claude-sonnet-4-6","contextPercent":45,"totalCost":0.12,"agentName":"rawcode"}'
  run bash -c "echo '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rawcode"* ]]
  [[ "$output" == *"sonnet"* ]]
  [[ "$output" == *"45"* ]]
  [[ "$output" == *"0.12"* ]]
}

@test "opus model shortens correctly" {
  INPUT='{"model":"claude-opus-4-6","contextPercent":10}'
  run bash -c "echo '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"opus"* ]]
}

@test "haiku model shortens correctly" {
  INPUT='{"model":"claude-haiku-4-5","contextPercent":10}'
  run bash -c "echo '$INPUT' | bash ui/statusline.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"haiku"* ]]
}

@test "malformed JSON does not crash" {
  run bash -c 'echo "not json at all" | bash ui/statusline.sh'
  [ "$status" -eq 0 ]
}
