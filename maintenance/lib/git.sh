#!/usr/bin/env bash

maintenance_name=${maintenance_name:?}

git_in() {
  local path=$1
  shift
  git -C "$path" "$@"
}

require_repository() {
  local path=$1

  [[ -d $path ]]
  git_in "$path" rev-parse --git-dir >/dev/null
}

require_clean_repository() {
  local path=$1

  if [[ -n $(git_in "$path" status --porcelain) ]]; then
    printf '%s: repository is dirty: %s\n' "$maintenance_name" "$path" >&2
    return 1
  fi
}

require_branch() {
  local path=$1
  local expected=${2:-}
  local actual

  actual=$(git_in "$path" branch --show-current)
  if [[ -z $actual ]]; then
    printf '%s: repository is in detached HEAD state: %s\n' "$maintenance_name" "$path" >&2
    return 1
  fi
  if [[ -n $expected && $actual != "$expected" ]]; then
    printf '%s: expected branch %s, found %s in %s\n' \
      "$maintenance_name" "$expected" "$actual" "$path" >&2
    return 1
  fi
}
