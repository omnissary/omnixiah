#!/usr/bin/env bash

set -euo pipefail

update=$(realpath "$1")
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

repository="$test_root/repository"
state="$test_root/state"
config="$test_root/config.json"
updater="$test_root/updater"
validator="$test_root/validator"
allow="$test_root/allow"

git init --initial-branch=main "$repository"
git -C "$repository" config user.name package-update-test
git -C "$repository" config user.email package-update@example.invalid
printf '1\n' >"$repository/version"
git -C "$repository" add version
git -C "$repository" commit -m initial

printf '%s\n' \
  'set -euo pipefail' \
  'printf "2\n" >version' >"$updater"
chmod +x "$updater"

printf '%s\n' \
  'set -euo pipefail' \
  'grep -q "^2$" version' >"$validator"
chmod +x "$validator"

write_config() {
  jq -n \
    --arg updater "$1" \
    --arg validator "$validator" \
    '{
      demo: {
        name: "demo",
        attrPath: "demo",
        command: ["bash", $updater],
        versionCommand: ["bash", "-c", "cat version"],
        format: [],
        build: [["bash", $validator]],
        checks: [["bash", $validator]]
      }
    }' >"$config"
}

run_update() {
  PACKAGE_UPDATE_CONFIG_JSON="$config" \
  PACKAGE_UPDATE_REPOSITORY_ROOT="$repository" \
    PACKAGE_UPDATE_SYSTEM="x86_64-linux" \
    XDG_STATE_HOME="$state" \
    bash "$update" "$@"
}

write_config "$updater"
run_update list | grep -Eq 'demo +demo +idle'

run_update run demo
[[ $(<"$repository/version") == 2 ]]
[[ $(git -C "$repository" log -1 --format=%s) == 'demo: 1 -> 2' ]]
[[ -z $(git -C "$repository" status --porcelain) ]]

printf '1\n' >"$repository/version"
git -C "$repository" commit -am reset

printf '%s\n' \
  'set -euo pipefail' \
  'printf "2\n" >version' \
  '[[ -e '"$allow"' ]]' >"$updater"
write_config "$updater"

if run_update run demo; then
  printf 'package-update test: failing updater unexpectedly succeeded\n' >&2
  exit 1
fi
[[ $(jq -r '.stage' "$state/omnixiah/package-update/demo.json") == update-failed ]]
[[ $(<"$repository/version") == 1 ]]

touch "$allow"
run_update continue demo
[[ $(<"$repository/version") == 2 ]]
[[ $(git -C "$repository" log -1 --format=%s) == 'demo: 1 -> 2' ]]

printf '1\n' >"$repository/version"
git -C "$repository" commit -am reset-again
rm "$allow"

if run_update run demo; then
  printf 'package-update test: failing updater unexpectedly succeeded\n' >&2
  exit 1
fi
run_update abort demo
[[ $(<"$repository/version") == 1 ]]
[[ ! -e $state/omnixiah/package-update/demo.json ]]
