#!/usr/bin/env bash

should_update() {
  local repo_config=$1
  local requested=$2
  local policy

  policy=$(jq -r '.update.policy' <<<"$repo_config")
  case $policy in
    always)
      return 0
      ;;
    requested)
      [[ $requested == true ]]
      ;;
    never)
      if [[ $requested == true ]]; then
        printf 'fork-sync: updates are disabled for %s\n' "$(jq -r '.name' <<<"$repo_config")" >&2
        return 2
      fi
      return 1
      ;;
  esac
}

run_update() {
  local path=$1
  local repo_config=$2
  local update_type

  update_type=$(jq -r '.update.type' <<<"$repo_config")
  case $update_type in
    flake)
      local -a inputs command
      command=(nix flake update)
      if [[ $(jq -r '.update.inputs | type' <<<"$repo_config") == array ]]; then
        mapfile -t inputs < <(jq -r '.update.inputs[]' <<<"$repo_config")
        command+=("${inputs[@]}")
      fi
      (cd "$path" && "${command[@]}")
      ;;
    command)
      local -a command_argv
      mapfile -t command_argv < <(jq -r '.update.argv[]' <<<"$repo_config")
      (cd "$path" && "${command_argv[@]}")
      ;;
  esac
}

run_command_group() {
  local path=$1
  local repo_config=$2
  local group=$3
  local command_json
  local -a command_argv

  while IFS= read -r command_json; do
    mapfile -t command_argv < <(jq -r '.[]' <<<"$command_json")
    (cd "$path" && "${command_argv[@]}")
  done < <(jq -c ".${group}[]" <<<"$repo_config")
}

commit_generated_changes() {
  local path=$1
  local repo_config=$2
  local update_ran=$3
  local message kind

  git_in "$path" add -A
  if git_in "$path" diff --cached --quiet; then
    return 0
  fi

  if [[ $update_ran == true ]]; then
    message=$(jq -r '.update.commitMessage' <<<"$repo_config")
    kind=$(jq -r '.update.type' <<<"$repo_config")
  else
    message='apply maintenance formatting'
    kind='format'
  fi

  git_in "$path" commit -m "$message" -m "Omnixiah-Managed-Update: $kind"
}
