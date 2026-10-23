#!/bin/bash
# Copyright (C) 2026 The Raspberry-Pi-5-Android Project
# SPDX-License-Identifier: Apache-2.0
#
# Copy the CYW43455 Wi-Fi and Bluetooth firmware for Raspberry Pi 5, unmodified,
# from the Raspberry Pi firmware packaging repositories into this directory,
# extract the Cypress licence text and record sources and checksums in BUILD_INFO.
#
# Usage:
#   FWSRC=/path/to/checkouts ./update_firmware.sh
#
# FWSRC must hold clean firmware-nonfree and bluez-firmware checkouts at the
# revisions below.
set -euo pipefail

WIFI_URL=https://github.com/RPi-Distro/firmware-nonfree.git
WIFI_BRANCH=trixie
WIFI_COMMIT=3bab0f823f5b53150b76aab77093adef6655b920
BT_URL=https://github.com/RPi-Distro/bluez-firmware.git
BT_BRANCH=pios/trixie
BT_COMMIT=cdf61dc691a49ff01a124752bd04194907f0f9cd

HERE=$(cd "$(dirname "$0")" && pwd)
: "${FWSRC:?set FWSRC to the directory holding the firmware checkouts}"
WIFI=$FWSRC/firmware-nonfree
BT=$FWSRC/bluez-firmware

check() {
  local head
  head=$(git -C "$1" rev-parse HEAD)
  if [ "$head" != "$2" ]; then
    echo "error: $1 is at $head, expected $2" >&2
    exit 1
  fi
  if [ -n "$(git -C "$1" status --porcelain)" ]; then
    echo "error: $1 has local changes" >&2
    exit 1
  fi
}
check "$WIFI" "$WIFI_COMMIT"
check "$BT" "$BT_COMMIT"

# Installed name (the one brcmfmac and btbcm request) and source file. The
# Raspberry Pi packages select the "standard" Wi-Fi firmware by default
# (update-alternatives priority 50, versus 10 for "minimal").
FILES="
brcm/brcmfmac43455-sdio.bin $WIFI/debian/added-firmware/cypress/cyfmac43455-sdio-standard.bin
brcm/brcmfmac43455-sdio.clm_blob $WIFI/debian/added-firmware/cypress/cyfmac43455-sdio.clm_blob
brcm/brcmfmac43455-sdio.txt $WIFI/debian/added-firmware/brcm/brcmfmac43455-sdio.txt
brcm/BCM4345C0.hcd $BT/debian/firmware/broadcom/BCM4345C0.hcd
"

rm -rf "$HERE/brcm"
mkdir "$HERE/brcm"
echo "$FILES" | while read -r dst src; do
  [ -n "$dst" ] || continue
  cp "$src" "$HERE/$dst"
done

# The licence text is the "binary-redist-Cypress" stanza of the Debian
# copyright file shipped with the Wi-Fi firmware (the same text applies to the
# Bluetooth patch file).
awk '
  hit && /^ / { grab = 1 }
  hit && !/^ / { hit = 0 }
  grab {
    if (!/^ /) exit
    s = substr($0, 2)
    print (s == "." ? "" : s)
    next
  }
  $0 == "License: binary-redist-Cypress" { hit = 1 }
' "$WIFI/debian/copyright" > "$HERE/LICENCE.cypress"
[ -s "$HERE/LICENCE.cypress" ]

{
  echo "wifi: $WIFI_URL $WIFI_BRANCH $WIFI_COMMIT"
  echo "bluetooth: $BT_URL $BT_BRANCH $BT_COMMIT"
  echo "files:"
  echo "$FILES" | while read -r dst src; do
    [ -n "$dst" ] || continue
    echo "  $dst <- ${src#"$FWSRC"/}"
  done
  echo "  LICENCE.cypress <- firmware-nonfree/debian/copyright (License: binary-redist-Cypress)"
  echo "sha256:"
  (cd "$HERE" && sha256sum brcm/* LICENCE.cypress)
} > "$HERE/BUILD_INFO"
