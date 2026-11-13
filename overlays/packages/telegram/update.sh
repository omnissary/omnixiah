#!/usr/bin/env bash

set -euo pipefail

repo=${1:?Usage: update.sh TDESKTOP_REPO [BASE_TAG]}
base=${2:-v7.4.3}
patch_dir=$(dirname "${BASH_SOURCE[0]}")
patches=(
  0001-Disable-sponsored-messages.patch
  0002-Disable-saving-restrictions.patch
  0003-Disable-invite-peeking-restrictions.patch
  0004-Disable-accounts-limit.patch
  0005-Option-to-disable-stories.patch
)

mapfile -t commits < <(git -C "$repo" rev-list --reverse "$base..corpix" -- Telegram/SourceFiles)
if (( ${#commits[@]} != ${#patches[@]} )); then
  echo "Expected ${#patches[@]} patch commits, found ${#commits[@]}" >&2
  exit 1
fi

for i in "${!patches[@]}"; do
  git -c diff.noprefix=false -C "$repo" show \
    --src-prefix=a/ --dst-prefix=b/ --format= \
    "${commits[$i]}" -- Telegram/SourceFiles > "$patch_dir/${patches[$i]}"
done
