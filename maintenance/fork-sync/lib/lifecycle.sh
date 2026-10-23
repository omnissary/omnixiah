#!/usr/bin/env bash

state_root=${state_root:?}
script_dir=${script_dir:?}

state_file() {
  local name=$1
  printf '%s/%s.json\n' "$state_root" "$name"
}

require_state() {
  local name=$1
  local file

  file=$(state_file "$name")
  if [[ ! -f $file ]]; then
    printf 'fork-sync: no active synchronization for %s\n' "$name" >&2
    return 1
  fi
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

create_state() {
  local name=$1
  local path=$2
  local branch=$3
  local upstream_remote=$4
  local upstream_branch=$5
  local destination_remote=$6
  local destination_branch=$7
  local remote_oid=$8
  local old_head=$9
  local tag=${10}
  local tag_created=${11}
  local update_requested=${12}
  local file temporary

  mkdir -p "$state_root"
  file=$(state_file "$name")
  temporary=$(mktemp "$state_root/.state.XXXXXX")
  jq -n \
    --arg name "$name" \
    --arg path "$path" \
    --arg branch "$branch" \
    --arg upstreamRemote "$upstream_remote" \
    --arg upstreamBranch "$upstream_branch" \
    --arg destinationRemote "$destination_remote" \
    --arg destinationBranch "$destination_branch" \
    --arg remoteOid "$remote_oid" \
    --arg oldHead "$old_head" \
    --arg tag "$tag" \
    --argjson tagCreated "$tag_created" \
    --argjson updateRequested "$update_requested" \
    '{
      name: $name,
      path: $path,
      branch: $branch,
      upstreamRemote: $upstreamRemote,
      upstreamBranch: $upstreamBranch,
      destinationRemote: $destinationRemote,
      destinationBranch: $destinationBranch,
      remoteOid: $remoteOid,
      oldHead: $oldHead,
      tag: $tag,
      tagCreated: $tagCreated,
      updateRequested: $updateRequested,
      stage: "preparing"
    }' >"$temporary"
  mv "$temporary" "$file"
}

finalize_fork() {
  local name=$1
  local file state repo_config path update_requested update_ran=false status ready_head

  file=$(state_file "$name")
  state=$(<"$file")
  repo_config=$(fork_config "$name")
  path=$(jq -r '.path' <<<"$state")
  update_requested=$(jq -r '.updateRequested' <<<"$state")

  if should_update "$repo_config" "$update_requested"; then
    update_ran=true
    if ! run_update "$path" "$repo_config"; then
      set_state_stage "$name" validation-failed
      return 1
    fi
  else
    status=$?
    if [[ $status -eq 2 ]]; then
      set_state_stage "$name" validation-failed
      return 1
    fi
  fi

  if ! run_command_group "$path" "$repo_config" format; then
    set_state_stage "$name" validation-failed
    return 1
  fi

  git_in "$path" add -A
  if ! run_command_group "$path" "$repo_config" checks; then
    set_state_stage "$name" validation-failed
    printf 'fork-sync: validation failed for %s; fix it and run continue\n' "$name" >&2
    return 1
  fi

  commit_generated_changes "$path" "$repo_config" "$update_ran"
  require_clean_repository "$path"
  ready_head=$(git_in "$path" rev-parse HEAD)
  set_state_stage "$name" ready "$ready_head"
  printf 'fork-sync: %s is ready at %s\n' "$name" "$(git_in "$path" rev-parse --short=12 HEAD)"
  printf 'fork-sync: review it, then run sync-push %s\n' "$name"
}

prepare_fork() {
  local name=$1
  local update_requested=$2
  local file stage repo_config path branch upstream_remote upstream_branch destination_remote destination_branch
  local upstream_url destination_url upstream_ref old_head remote_oid tag tag_created update_ran=false status

  printf 'fork-sync: preparing %s\n' "$name"

  file=$(state_file "$name")
  if [[ -e $file ]]; then
    stage=$(jq -r '.stage' "$file")
    if [[ $stage == ready ]]; then
      printf 'fork-sync: %s is already ready; skipping\n' "$name"
      return 0
    fi
    printf 'fork-sync: synchronization already active for %s\n' "$name" >&2
    return 1
  fi

  repo_config=$(fork_config "$name")
  path=$(fork_path "$repo_config")
  branch=$(jq -r '.branch' <<<"$repo_config")
  upstream_remote=$(jq -r '.upstream.remote' <<<"$repo_config")
  upstream_branch=$(jq -r '.upstream.branch' <<<"$repo_config")
  upstream_url=$(jq -r '.upstream.url // empty' <<<"$repo_config")
  destination_remote=$(jq -r '.destination.remote' <<<"$repo_config")
  destination_branch=$(jq -r '.destination.branch' <<<"$repo_config")
  destination_url=$(jq -r '.destination.url // empty' <<<"$repo_config")

  require_repository "$path"
  require_clean_repository "$path"
  require_branch "$path" "$branch"
  ensure_remote "$path" "$upstream_remote" "$upstream_url"
  ensure_remote "$path" "$destination_remote" "$destination_url"
  fetch_remotes "$path" "$upstream_remote" "$destination_remote"
  require_remote_branch "$path" "$upstream_remote" "$upstream_branch"
  require_remote_branch "$path" "$destination_remote" "$destination_branch"

  upstream_ref=$(remote_ref "$upstream_remote" "$upstream_branch")
  old_head=$(git_in "$path" rev-parse HEAD)
  remote_oid=$(remote_branch_oid "$path" "$destination_remote" "$destination_branch")
  if [[ $old_head != "$remote_oid" ]]; then
    printf 'fork-sync: local %s and %s/%s differ\n' "$branch" "$destination_remote" "$destination_branch" >&2
    return 1
  fi

  if should_update "$repo_config" "$update_requested"; then
    update_ran=true
  else
    status=$?
    if [[ $status -eq 2 ]]; then
      return 1
    fi
  fi

  IFS=$'\t' read -r tag tag_created < <(create_recovery_tag "$path" "$branch" "$old_head")
  create_state \
    "$name" "$path" "$branch" \
    "$upstream_remote" "$upstream_branch" \
    "$destination_remote" "$destination_branch" \
    "$remote_oid" "$old_head" "$tag" "$tag_created" "$update_requested"

  set_state_stage "$name" rebasing
  if ! rebase_fork "$path" "$upstream_ref" "$update_ran" "$script_dir/lib/drop-managed-updates"; then
    set_state_stage "$name" rebase-conflict
    printf 'fork-sync: resolve the rebase for %s, then run sync-continue %s\n' "$name" "$name" >&2
    return 1
  fi

  finalize_fork "$name"
}

continue_fork() {
  local name=$1
  local file state stage path old_head

  require_state "$name"
  file=$(state_file "$name")
  state=$(<"$file")
  stage=$(jq -r '.stage' <<<"$state")
  path=$(jq -r '.path' <<<"$state")
  old_head=$(jq -r '.oldHead' <<<"$state")

  case $stage in
    rebase-conflict)
      if rebase_in_progress "$path"; then
        if ! GIT_EDITOR=true git_in "$path" rebase --continue; then
          printf 'fork-sync: rebase still requires attention for %s\n' "$name" >&2
          return 1
        fi
      elif [[ $(git_in "$path" rev-parse HEAD) == "$old_head" ]]; then
        printf 'fork-sync: rebase for %s was aborted outside fork-sync; run sync-abort %s\n' \
          "$name" "$name" >&2
        return 1
      fi
      finalize_fork "$name"
      ;;
    validation-failed)
      finalize_fork "$name"
      ;;
    ready)
      printf 'fork-sync: %s is already ready\n' "$name"
      ;;
    *)
      printf 'fork-sync: cannot continue %s from stage %s\n' "$name" "$stage" >&2
      return 1
      ;;
  esac
}

abort_fork() {
  local name=$1
  local file state path old_head tag tag_created

  require_state "$name"
  file=$(state_file "$name")
  state=$(<"$file")
  path=$(jq -r '.path' <<<"$state")
  old_head=$(jq -r '.oldHead' <<<"$state")
  tag=$(jq -r '.tag' <<<"$state")
  tag_created=$(jq -r '.tagCreated' <<<"$state")

  if rebase_in_progress "$path"; then
    git_in "$path" rebase --abort
  fi
  git_in "$path" reset --hard "$old_head"
  if [[ $tag_created == true ]]; then
    git_in "$path" tag -d "$tag" >/dev/null
  fi
  rm -f "$file"
  printf 'fork-sync: restored %s to %s\n' "$name" "$(git_in "$path" rev-parse --short=12 HEAD)"
}

push_fork() {
  local name=$1
  local file state stage path branch destination_remote destination_branch expected_oid actual_oid ready_head tag

  require_state "$name"
  file=$(state_file "$name")
  state=$(<"$file")
  stage=$(jq -r '.stage' <<<"$state")
  if [[ $stage != ready ]]; then
    printf 'fork-sync: %s is not ready to push; current stage is %s\n' "$name" "$stage" >&2
    return 1
  fi

  path=$(jq -r '.path' <<<"$state")
  branch=$(jq -r '.branch' <<<"$state")
  destination_remote=$(jq -r '.destinationRemote' <<<"$state")
  destination_branch=$(jq -r '.destinationBranch' <<<"$state")
  expected_oid=$(jq -r '.remoteOid' <<<"$state")
  ready_head=$(jq -r '.readyHead' <<<"$state")
  tag=$(jq -r '.tag' <<<"$state")

  require_clean_repository "$path"
  require_branch "$path" "$branch"
  if [[ $(git_in "$path" rev-parse HEAD) != "$ready_head" ]]; then
    printf 'fork-sync: %s changed after validation\n' "$name" >&2
    return 1
  fi

  git_in "$path" fetch --prune "$destination_remote"
  actual_oid=$(remote_branch_oid "$path" "$destination_remote" "$destination_branch")
  if [[ $actual_oid != "$expected_oid" ]]; then
    printf 'fork-sync: refusing to push %s because %s/%s moved\n' "$name" "$destination_remote" "$destination_branch" >&2
    return 1
  fi

  push_ready_branch \
    "$path" "$destination_remote" "$destination_branch" "$branch" "$expected_oid" "$tag"
  rm -f "$file"
  printf 'fork-sync: pushed %s and recovery tag %s\n' "$name" "$tag"
}

status_forks() {
  local name repo_config path branch head cleanliness stage file

  printf 'NAME\tBRANCH\tHEAD\tWORKTREE\tSYNC\n'
  while IFS= read -r name; do
    repo_config=$(fork_config "$name")
    path=$(fork_path "$repo_config")
    branch=$(git_in "$path" branch --show-current 2>/dev/null || printf missing)
    head=$(git_in "$path" rev-parse --short=12 HEAD 2>/dev/null || printf missing)
    if [[ -n $(git_in "$path" status --porcelain 2>/dev/null) ]]; then
      cleanliness=dirty
    else
      cleanliness=clean
    fi
    file=$(state_file "$name")
    if [[ -f $file ]]; then
      stage=$(jq -r '.stage' "$file")
    else
      stage=idle
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$branch" "$head" "$cleanliness" "$stage"
  done < <(fork_names)
}
