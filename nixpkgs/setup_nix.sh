#!/usr/bin/env bash

set -eu
set -x

NIX_USER_CHROOT_SRC=$1
NIX_INSTALLER=$2
NIX_ROOT=${3/#\~/$HOME}
NIX_STORE_PATH="$NIX_ROOT"/nix

mkdir -p "$NIX_STORE_PATH"

# Build nix-user-chroot
gcc "$NIX_USER_CHROOT_SRC" -o nix-user-chroot

HOME=$PWD _NIX_INSTALLER_TEST=1 ./nix-user-chroot "$NIX_STORE_PATH" "$NIX_INSTALLER"

NIX_BUILD=$(./nix-user-chroot "$NIX_STORE_PATH" bash -c ". $PWD/.nix-profile/etc/profile.d/nix.sh &&  readlink -f \$(command -v nix-build)")

wrap_exe () {
  cat <<EOF > "$2"
#!/bin/sh

myDir=\$(dirname \$0)

exec "\$myDir/nix-user-chroot" "$NIX_STORE_PATH" "\$myDir"/"$1" "\$@"
EOF

chmod +x "$2"
}

for NIX_EXE in $(./nix-user-chroot "$NIX_STORE_PATH" find "$(dirname "$NIX_BUILD")" -type f); do
  LOCAL_EXE=."$(basename "$NIX_EXE")"-wrapped
  ./nix-user-chroot "$NIX_STORE_PATH" cp "$NIX_EXE" "$LOCAL_EXE"
  wrap_exe "$LOCAL_EXE" "$(basename "$NIX_EXE")"
done

echo -n "$NIX_ROOT" > nix-store-path
