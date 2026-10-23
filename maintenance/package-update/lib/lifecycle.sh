#!/usr/bin/env bash

state_root=${state_root:?}
repository_root=${repository_root:?}
script_dir=${script_dir:?}
system=${system:?}

state_file() {
  local name=$1
  printf '%s/%s.json\n' "$state_root" "$name"
}

set_stage() {
  local name=$1
  local stage=$2
  local file temporary

  file=$(state_file "$name")
  temporary=$(mktemp "$state_root/.state.XXXXXX")
  jq --arg stage "$stage" '.stage = $stage' "$file" >"$temporary"
  mv "$temporary" "$file"
}

create_state() {
  local name=$1
  local attr_path=$2
  local old_head=$3
  local old_version=$4
  local branch=$5
  local worktree=$6
  local file temporary

  mkdir -p "$state_root"
  file=$(state_file "$name")
  temporary=$(mktemp "$state_root/.state.XXXXXX")
  jq -n \
    --arg name "$name" \
    --arg attrPath "$attr_path" \
    --arg oldHead "$old_head" \
    --arg oldVersion "$old_version" \
    --arg branch "$branch" \
    --arg worktree "$worktree" \
    '{
      name: $name,
      attrPath: $attrPath,
      oldHead: $oldHead,
      oldVersion: $oldVersion,
      branch: $branch,
      worktree: $worktree,
      stage: "updating"
    }' >"$temporary"
  mv "$temporary" "$file"
}

run_commands() {
  local worktree=$1
  local config=$2
  local group=$3
  local value
  local -a argv

  while IFS= read -r value; do
    mapfile -t argv < <(jq -r '.[]' <<<"$value")
    (cd "$worktree" && "${argv[@]}")
  done < <(jq -c ".${group}[]" <<<"$config")
}

package_version() {
  local path=$1
  local attr_path=$2
  local config=$3
  local -a argv

  if jq -e 'has("versionCommand")' >/dev/null <<<"$config"; then
    mapfile -t argv < <(jq -r '.versionCommand[]' <<<"$config")
    (cd "$path" && "${argv[@]}")
  else
    (cd "$path" && nix eval --raw ".#pkgs.${system}.${attr_path}.version")
  fi
}

run_update_script() {
  local worktree=$1
  local config=$2
  local attr_path wrapper
  local -a argv

  attr_path=$(jq -r '.attrPath' <<<"$config")
  if jq -e 'has("command")' >/dev/null <<<"$config"; then
    mapfile -t argv < <(jq -r '.command[]' <<<"$config")
    (cd "$worktree" && "${argv[@]}")
  else
    wrapper=$(
      PACKAGE_UPDATE_ROOT="$worktree" \
        PACKAGE_UPDATE_SYSTEM="$system" \
        PACKAGE_UPDATE_ATTR_PATH="$attr_path" \
        nix build \
          --impure \
          --no-link \
          --print-out-paths \
          --expr "import $script_dir/command.nix"
    )
    (cd "$worktree" && "$wrapper/bin/omnixiah-package-update")
  fi
}

cleanup_update() {
  local name=$1
  local file state worktree branch

  file=$(state_file "$name")
  state=$(<"$file")
  worktree=$(jq -r '.worktree' <<<"$state")
  branch=$(jq -r '.branch' <<<"$state")
  remove_worktree "$repository_root" "$worktree" "$branch"
  rm -f "$file"
}

finalize_update() {
  local name=$1
  local file state config attr_path old_head old_version worktree branch new_version message

  file=$(state_file "$name")
  state=$(<"$file")
  config=$(package_config "$name")
  attr_path=$(jq -r '.attrPath' <<<"$state")
  old_head=$(jq -r '.oldHead' <<<"$state")
  old_version=$(jq -r '.oldVersion' <<<"$state")
  worktree=$(jq -r '.worktree' <<<"$state")
  branch=$(jq -r '.branch' <<<"$state")

  set_stage "$name" formatting
  if ! run_commands "$worktree" "$config" format; then
    set_stage "$name" validation-failed
    return 1
  fi

  if git_in "$worktree" diff --quiet && [[ -z $(git_in "$worktree" status --porcelain) ]]; then
    cleanup_update "$name"
    printf 'package-update: %s is already current\n' "$name"
    return 0
  fi

  set_stage "$name" validating
  if [[ $(jq '.build | length' <<<"$config") -eq 0 ]]; then
    if ! (cd "$worktree" && nix build --no-link --show-trace ".#pkgs.${system}.${attr_path}"); then
      set_stage "$name" validation-failed
      printf 'package-update: validation failed for %s; fix it and run update-continue %s\n' "$name" "$name" >&2
      return 1
    fi
  elif ! run_commands "$worktree" "$config" build; then
    set_stage "$name" validation-failed
    printf 'package-update: validation failed for %s; fix it and run update-continue %s\n' "$name" "$name" >&2
    return 1
  fi
  if ! run_commands "$worktree" "$config" checks; then
    set_stage "$name" validation-failed
    printf 'package-update: validation failed for %s; fix it and run update-continue %s\n' "$name" "$name" >&2
    return 1
  fi

  new_version=$(package_version "$worktree" "$attr_path" "$config")
  if [[ $old_version == "$new_version" ]]; then
    message="update $name"
  else
    message="$name: $old_version -> $new_version"
  fi

  git_in "$worktree" add -A
  git_in "$worktree" commit -m "$message"

  require_clean_repository "$repository_root"
  if [[ $(git_in "$repository_root" rev-parse HEAD) != "$old_head" ]]; then
    set_stage "$name" integration-failed
    printf 'package-update: repository moved while updating %s\n' "$name" >&2
    return 1
  fi

  git_in "$repository_root" merge --ff-only "$branch"
  cleanup_update "$name"
  printf 'package-update: committed %s\n' "$message"
}

prepare_update() {
  local name=$1
  local file config attr_path old_head old_version short_head branch worktree

  printf 'package-update: updating %s\n' "$name"
  file=$(state_file "$name")
  if [[ -e $file ]]; then
    printf 'package-update: update already active for %s\n' "$name" >&2
    return 1
  fi

  config=$(package_config "$name")
  attr_path=$(jq -r '.attrPath' <<<"$config")
  require_clean_repository "$repository_root"
  require_branch "$repository_root"
  old_head=$(git_in "$repository_root" rev-parse HEAD)
  old_version=$(package_version "$repository_root" "$attr_path" "$config")
  short_head=$(git_in "$repository_root" rev-parse --short=12 HEAD)
  branch="maintenance/update-$name-$short_head"
  worktree="$state_root/worktrees/$name"

  mkdir -p "$(dirname "$worktree")"
  git_in "$repository_root" worktree add -b "$branch" "$worktree" "$old_head"
  create_state "$name" "$attr_path" "$old_head" "$old_version" "$branch" "$worktree"

  if ! run_update_script "$worktree" "$config"; then
    set_stage "$name" update-failed
    printf 'package-update: updater failed for %s; fix it and run update-continue %s\n' "$name" "$name" >&2
    return 1
  fi

  finalize_update "$name"
}

continue_update() {
  local name=$1
  local file state stage config worktree

  file=$(state_file "$name")
  if [[ ! -f $file ]]; then
    printf 'package-update: no active update for %s\n' "$name" >&2
    return 1
  fi
  state=$(<"$file")
  stage=$(jq -r '.stage' <<<"$state")
  worktree=$(jq -r '.worktree' <<<"$state")
  config=$(package_config "$name")

  case $stage in
    update-failed)
      set_stage "$name" updating
      if ! run_update_script "$worktree" "$config"; then
        set_stage "$name" update-failed
        return 1
      fi
      finalize_update "$name"
      ;;
    validation-failed)
      finalize_update "$name"
      ;;
    integration-failed)
      printf 'package-update: abort %s and retry from the new repository head\n' "$name" >&2
      return 1
      ;;
    *)
      printf 'package-update: cannot continue %s from stage %s\n' "$name" "$stage" >&2
      return 1
      ;;
  esac
}

abort_update() {
  local name=$1
  local file

  file=$(state_file "$name")
  if [[ ! -f $file ]]; then
    printf 'package-update: no active update for %s\n' "$name" >&2
    return 1
  fi
  cleanup_update "$name"
  printf 'package-update: aborted %s\n' "$name"
}

status_updates() {
  local name config file stage

  printf 'NAME\tATTRIBUTE\tSTATE\n'
  while IFS= read -r name; do
    config=$(package_config "$name")
    file=$(state_file "$name")
    if [[ -f $file ]]; then
      stage=$(jq -r '.stage' "$file")
    else
      stage=idle
    fi
    printf '%s\t%s\t%s\n' "$name" "$(jq -r '.attrPath' <<<"$config")" "$stage"
  done < <(package_names)
}
