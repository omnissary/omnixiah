#!/usr/bin/env bash

git_in() {
  local path=$1
  shift
  git -C "$path" "$@"
}

require_clean_repository() {
  local path=$1

  if [[ -n $(git_in "$path" status --porcelain) ]]; then
    printf 'package-update: repository is dirty: %s\n' "$path" >&2
    return 1
  fi
}

require_branch() {
  local path=$1
  local branch

  branch=$(git_in "$path" branch --show-current)
  if [[ -z $branch ]]; then
    printf 'package-update: repository is in detached HEAD state: %s\n' "$path" >&2
    return 1
  fi
}

remove_worktree() {
  local root=$1
  local worktree=$2
  local branch=$3

  if [[ -d $worktree ]]; then
    git_in "$root" worktree remove --force "$worktree"
  fi
  if git_in "$root" show-ref --verify --quiet "refs/heads/$branch"; then
    git_in "$root" branch -D "$branch" >/dev/null
  fi
}
