#!/usr/bin/env bash

config_json=''
workspace_root=${workspace_root:?}

load_config() {
  local selected_config=$1

  if [[ -n "${FORK_SYNC_CONFIG_JSON:-}" ]]; then
    config_json=$(<"$FORK_SYNC_CONFIG_JSON")
  else
    config_json=$(nix eval --json --file "$selected_config")
  fi

  jq -e 'type == "object"' >/dev/null <<<"$config_json"
}

fork_names() {
  jq -r 'keys[]' <<<"$config_json"
}

fork_config() {
  local name=$1

  jq -ce --arg name "$name" '.[$name] // error("unknown fork: \($name)")' <<<"$config_json"
}

fork_path() {
  local repo_config=$1
  local directory

  directory=$(jq -r '.directory' <<<"$repo_config")
  realpath "$workspace_root/$directory"
}
