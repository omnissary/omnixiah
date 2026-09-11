#!/usr/bin/env bash

set -euo pipefail

for patch in \
  0001-Disable-sponsored-messages.patch \
  0002-Disable-saving-restrictions.patch \
  0003-Disable-invite-peeking-restrictions.patch \
  0004-Disable-accounts-limit.patch \
  0005-Option-to-disable-stories.patch
do
  curl \
    --fail \
    --location \
    --output "$patch" \
    "https://raw.githubusercontent.com/Layerex/telegram-desktop-patches/master/$patch"
done
