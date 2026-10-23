#!/usr/bin/env bash

config_json=''

load_config() {
  local selected_config=$1

  if [[ -n ${PACKAGE_UPDATE_CONFIG_JSON:-} ]]; then
    config_json=$(<"$PACKAGE_UPDATE_CONFIG_JSON")
  else
    config_json=$(nix eval --json --file "$selected_config")
  fi

  jq -e 'type == "object"' >/dev/null <<<"$config_json"
}

package_names() {
  jq -r 'keys[]' <<<"$config_json"
}

package_config() {
  local name=$1

  jq -ce --arg name "$name" '.[$name] // error("unknown package: \($name)")' <<<"$config_json"
}
