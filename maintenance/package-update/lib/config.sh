#!/usr/bin/env bash

package_names() {
  config_names
}

package_config() {
  local name=$1

  named_config package "$name"
}
