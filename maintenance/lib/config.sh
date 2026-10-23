#!/usr/bin/env bash

config_json=''

load_config() {
  local selected_config=$1
  local override_name=$2
  local override_file=''

  if [[ -v $override_name ]]; then
    override_file=${!override_name}
  fi

  if [[ -n $override_file ]]; then
    config_json=$(<"$override_file")
  else
    config_json=$(nix eval --json --file "$selected_config")
  fi

  jq -e 'type == "object"' >/dev/null <<<"$config_json"
}

config_names() {
  jq -r 'keys[]' <<<"$config_json"
}

named_config() {
  local kind=$1
  local name=$2

  jq -ce --arg kind "$kind" --arg name "$name" \
    '.[$name] // error("unknown \($kind): \($name)")' <<<"$config_json"
}
