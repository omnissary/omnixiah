#!/usr/bin/env bash

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
