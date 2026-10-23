#!/usr/bin/env bash

workspace_root=${workspace_root:?}

fork_names() {
  config_names
}

fork_config() {
  local name=$1

  named_config fork "$name"
}

fork_path() {
  local repo_config=$1
  local directory

  directory=$(jq -r '.directory' <<<"$repo_config")
  realpath "$workspace_root/$directory"
}
