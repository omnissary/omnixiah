#!/usr/bin/env bash

set -euo pipefail

sync=$(realpath "$1")
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

upstream="$test_root/upstream.git"
destination="$test_root/destination.git"
work="$test_root/work"
state="$test_root/state"
config="$test_root/config.json"
update="$test_root/update"

run_sync() {
  FORK_SYNC_CONFIG_JSON="$config" \
    FORK_SYNC_WORKSPACE_ROOT="$test_root" \
    XDG_STATE_HOME="$state" \
    "$sync" "$@"
}

git init --bare --initial-branch=main "$upstream"
git init --bare --initial-branch=omnixiah "$destination"
git init --initial-branch=main "$work"
git -C "$work" config user.name fork-sync-test
git -C "$work" config user.email fork-sync@example.invalid

printf 'base\n' >"$work/base"
git -C "$work" add base
git -C "$work" commit -m base
git -C "$work" remote add upstream "$upstream"
git -C "$work" remote add tatikoma "$destination"
git -C "$work" push upstream main

git -C "$work" switch -c omnixiah
printf 'fork\n' >"$work/fork"
git -C "$work" add fork
git -C "$work" commit -m 'add fork change'
git -C "$work" push --set-upstream tatikoma omnixiah

git -C "$work" switch main
printf 'upstream one\n' >"$work/upstream-one"
git -C "$work" add upstream-one
git -C "$work" commit -m 'add upstream change'
git -C "$work" push upstream main
git -C "$work" switch omnixiah

printf '%s\n' \
  'set -euo pipefail' \
  'git rev-parse refs/remotes/upstream/main >flake.lock' >"$update"

jq -n \
  --arg update "$update" \
  '{
    demo: {
      name: "demo",
      directory: "work",
      branch: "omnixiah",
      upstream: {
        remote: "upstream",
        branch: "main"
      },
      destination: {
        remote: "tatikoma",
        branch: "omnixiah"
      },
      update: {
        type: "command",
        policy: "requested",
        inputs: "all",
        argv: ["bash", $update],
        commitMessage: "update generated files"
      },
      format: [],
      checks: [["git", "merge-base", "--is-ancestor", "refs/remotes/upstream/main", "HEAD"]]
    }
  }' >"$config"

old_remote=$(git --git-dir="$destination" rev-parse refs/heads/omnixiah)
run_sync prepare demo --update

[[ $(jq -r '.stage' "$state/omnixiah/fork-sync/demo.json") == ready ]]
[[ $(git --git-dir="$destination" rev-parse refs/heads/omnixiah) == "$old_remote" ]]
git -C "$work" merge-base --is-ancestor refs/remotes/upstream/main HEAD
git -C "$work" log -1 --format=%B | grep -q '^Omnixiah-Managed-Update: command$'

tag=$(jq -r '.tag' "$state/omnixiah/fork-sync/demo.json")
run_sync push demo
[[ $(git --git-dir="$destination" rev-parse refs/heads/omnixiah) == $(git -C "$work" rev-parse HEAD) ]]
git --git-dir="$destination" rev-parse "refs/tags/$tag^{commit}" >/dev/null

printf 'later fork change\n' >"$work/later-fork"
git -C "$work" add later-fork
git -C "$work" commit -m 'add later fork change'
git -C "$work" push tatikoma omnixiah

git -C "$work" switch main
printf 'upstream two\n' >"$work/upstream-two"
git -C "$work" add upstream-two
git -C "$work" commit -m 'add another upstream change'
git -C "$work" push upstream main
git -C "$work" switch omnixiah

run_sync prepare demo --update
[[ $(git -C "$work" log --format=%B | grep -c '^Omnixiah-Managed-Update: command$') -eq 1 ]]
[[ -f $work/later-fork ]]

git clone --branch omnixiah "$destination" "$test_root/attacker"
git -C "$test_root/attacker" config user.name fork-sync-test
git -C "$test_root/attacker" config user.email fork-sync@example.invalid
printf 'remote move\n' >"$test_root/attacker/remote-move"
git -C "$test_root/attacker" add remote-move
git -C "$test_root/attacker" commit -m 'move remote branch'
git -C "$test_root/attacker" push origin omnixiah

if run_sync push demo; then
  printf 'fork-sync test: push unexpectedly ignored a moved remote\n' >&2
  exit 1
fi
[[ -f $state/omnixiah/fork-sync/demo.json ]]

run_sync abort demo
[[ ! -e $state/omnixiah/fork-sync/demo.json ]]

printf 'dirty\n' >"$work/dirty"
if run_sync prepare demo; then
  printf 'fork-sync test: prepare unexpectedly accepted a dirty repository\n' >&2
  exit 1
fi

run_sync status | grep -q $'demo\tomnixiah\t.*\tdirty\tidle'

conflict_upstream="$test_root/conflict-upstream.git"
conflict_destination="$test_root/conflict-destination.git"
conflict_work="$test_root/conflict-work"

git init --bare --initial-branch=main "$conflict_upstream"
git init --bare --initial-branch=omnixiah "$conflict_destination"
git init --initial-branch=main "$conflict_work"
git -C "$conflict_work" config user.name fork-sync-test
git -C "$conflict_work" config user.email fork-sync@example.invalid

printf 'base\n' >"$conflict_work/shared"
git -C "$conflict_work" add shared
git -C "$conflict_work" commit -m base
git -C "$conflict_work" remote add upstream "$conflict_upstream"
git -C "$conflict_work" remote add tatikoma "$conflict_destination"
git -C "$conflict_work" push upstream main

git -C "$conflict_work" switch -c omnixiah
printf 'fork\n' >"$conflict_work/shared"
git -C "$conflict_work" commit -am 'change shared file in fork'
git -C "$conflict_work" push --set-upstream tatikoma omnixiah
conflict_old_head=$(git -C "$conflict_work" rev-parse HEAD)

git -C "$conflict_work" switch main
printf 'upstream\n' >"$conflict_work/shared"
git -C "$conflict_work" commit -am 'change shared file upstream'
git -C "$conflict_work" push upstream main
git -C "$conflict_work" switch omnixiah

jq -n \
  '{
    conflict: {
      name: "conflict",
      directory: "conflict-work",
      branch: "omnixiah",
      upstream: {
        remote: "upstream",
        branch: "main"
      },
      destination: {
        remote: "tatikoma",
        branch: "omnixiah"
      },
      update: {
        type: "flake",
        policy: "never",
        inputs: "all",
        commitMessage: "update flake inputs"
      },
      format: [],
      checks: []
    }
  }' >"$config"

if run_sync prepare conflict; then
  printf 'fork-sync test: conflicting rebase unexpectedly succeeded\n' >&2
  exit 1
fi
[[ $(jq -r '.stage' "$state/omnixiah/fork-sync/conflict.json") == rebase-conflict ]]

printf 'resolved\n' >"$conflict_work/shared"
git -C "$conflict_work" add shared
run_sync continue conflict
[[ $(jq -r '.stage' "$state/omnixiah/fork-sync/conflict.json") == ready ]]

run_sync abort conflict
[[ $(git -C "$conflict_work" rev-parse HEAD) == "$conflict_old_head" ]]
[[ $(<"$conflict_work/shared") == fork ]]
