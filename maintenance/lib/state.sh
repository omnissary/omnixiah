#!/usr/bin/env bash

state_root=${state_root:?}

state_file() {
  local name=$1
  printf '%s/%s.json\n' "$state_root" "$name"
}

set_state_stage() {
  local name=$1
  local stage=$2
  local ready_head=${3:-}
  local file temporary

  file=$(state_file "$name")
  temporary=$(mktemp "$state_root/.state.XXXXXX")
  jq --arg stage "$stage" --arg readyHead "$ready_head" \
    '.stage = $stage | if $readyHead == "" then . else .readyHead = $readyHead end' \
    "$file" >"$temporary"
  mv "$temporary" "$file"
}
