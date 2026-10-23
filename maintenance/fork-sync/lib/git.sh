#!/usr/bin/env bash

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
    printf 'fork-sync: repository is dirty: %s\n' "$path" >&2
    return 1
  fi
}

require_branch() {
  local path=$1
  local expected=$2
  local actual

  actual=$(git_in "$path" branch --show-current)
  if [[ $actual != "$expected" ]]; then
    printf 'fork-sync: expected branch %s, found %s in %s\n' "$expected" "${actual:-detached HEAD}" "$path" >&2
    return 1
  fi
}

fetch_remotes() {
  local path=$1
  local upstream_remote=$2
  local destination_remote=$3

  git_in "$path" fetch --prune "$upstream_remote"
  if [[ $destination_remote != "$upstream_remote" ]]; then
    git_in "$path" fetch --prune "$destination_remote"
  fi
}

remote_ref() {
  local remote=$1
  local branch=$2

  printf 'refs/remotes/%s/%s\n' "$remote" "$branch"
}

has_managed_updates() {
  local path=$1
  local upstream_ref=$2

  git_in "$path" log --format=%B "$upstream_ref..HEAD" | grep -q '^Omnixiah-Managed-Update: '
}

rebase_fork() {
  local path=$1
  local upstream_ref=$2
  local update_ran=$3
  local sequence_editor=$4

  if [[ $update_ran == true ]] && has_managed_updates "$path" "$upstream_ref"; then
    GIT_SEQUENCE_EDITOR="$sequence_editor" git_in "$path" rebase --interactive "$upstream_ref"
  else
    git_in "$path" rebase "$upstream_ref"
  fi
}

create_recovery_tag() {
  local path=$1
  local branch=$2
  local old_head=$3
  local date_part short_head tag existing

  date_part=$(date -u +%Y-%m-%d)
  short_head=$(git_in "$path" rev-parse --short=12 "$old_head")
  tag="archive/$branch/$date_part-$short_head"

  if existing=$(git_in "$path" rev-parse -q --verify "refs/tags/$tag^{commit}"); then
    if [[ $existing != "$old_head" ]]; then
      printf 'fork-sync: recovery tag collision: %s\n' "$tag" >&2
      return 1
    fi
    tag_created=false
  else
    git_in "$path" tag -a "$tag" "$old_head" -m "archive $branch before upstream synchronization"
    tag_created=true
  fi

  printf '%s\t%s\n' "$tag" "$tag_created"
}

remote_branch_oid() {
  local path=$1
  local remote=$2
  local branch=$3

  git_in "$path" rev-parse "$(remote_ref "$remote" "$branch")^{commit}"
}

push_ready_branch() {
  local path=$1
  local remote=$2
  local destination_branch=$3
  local branch=$4
  local expected_oid=$5
  local tag=$6

  git_in "$path" push \
    --atomic \
    --force-with-lease="refs/heads/$destination_branch:$expected_oid" \
    "$remote" \
    "refs/tags/$tag:refs/tags/$tag" \
    "refs/heads/$branch:refs/heads/$destination_branch"
}
