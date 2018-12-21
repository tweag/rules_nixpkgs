#!/usr/bin/env bash

set -eu

NIX_USER_CHROOT_SRC=$1
NIX_INSTALLER=$2
NIX_STORE_PATH=${3/#\~/$HOME}

mkdir -p "$NIX_STORE_PATH"

# Build nix-user-chroot
gcc "$NIX_USER_CHROOT_SRC" -o nix-user-chroot

HOME=$PWD _NIX_INSTALLER_TEST=1 ./nix-user-chroot "$NIX_STORE_PATH" "$NIX_INSTALLER"

NIX_BUILD=$(./nix-user-chroot "$NIX_STORE_PATH" bash -c ". $PWD/.nix-profile/etc/profile.d/nix.sh &&  readlink -f \$(command -v nix-build)")

for NIX_EXE in $(./nix-user-chroot "$NIX_STORE_PATH" find "$(dirname "$NIX_BUILD")" -type f); do
  ./nix-user-chroot "$NIX_STORE_PATH" cp "$NIX_EXE" ./."$(basename "$NIX_EXE")"-wrapped
done

echo "$NIX_STORE_PATH" > nix-store-path
