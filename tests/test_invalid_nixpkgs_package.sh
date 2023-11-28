#!/usr/bin/env bash
set -euo pipefail

ln -s tests/invalid_nixpkgs_package/workspace.bazel WORKSPACE
ln -s tests/invalid_nixpkgs_package/nested-build.bazel BUILD

# Create copy of default.nix as we will edit it below
cp tests/invalid_nixpkgs_package/default.nix default.nix

# DEBUG BEGIN
set -x
# DEBUG END

# We need to provide a `nixpkgs` to create an output store path which is
# a folder (because nixpkgs_package requires the output store path to
# be a directory).
#
# We use the absolute path of the static `coreutils` `mkdir` tool in the
# builder script of the `hello` derivation. Since building this
# derivation doesn't rely on `nixpkgs`, we can easily relocate the
# `/nix/store` path in the Bazel sandbox.
#
# NOTE: The MacOS version of sed does not like to appear after the commands. 
# Also, it requires a value for the suffix.
sed -i.bak "s;COREUTILS-ABS-PATH;${PWD}/external/coreutils_static/bin/;g" default.nix

# Bring a specific version of Nix which can be executed in the Bazel
# linux sandbox.
export PATH=$PWD/external/nix_2_10/bin:$PATH

# This is a create all directories required to run Nix locally.
mkdir -p ${TEST_TMPDIR}/nix/{store,var/nix,etc/nix}
export NIX_REMOTE="local"
export NIX_STORE_DIR=${TEST_TMPDIR}/nix/store
export NIX_STATE_DIR=${TEST_TMPDIR}/nix/var/nix
export NIX_LOG_DIR=${TEST_TMPDIR}/nix/var/log/nix
export NIX_CONF_DIR=${TEST_TMPDIR}/nix/etc/nix

# First, we build a script outputing "hello world 1". This message
# string comes from the file `message.nix` which is a dependency of the
# `nixpkgs_package` rule.
echo '"hello world 1"' > message.nix
bazel build //:hello-output
if [[ $(cat bazel-bin/hello-output.txt) != "hello world 1" ]]; then
    exit 1
fi

# Then, we override the content of the `message.nix` file to ensure Bazel
# rebuilds the `:hello-output` target when a Nix files is modified. The
# `hello.nix` file now builds a derivation creating a file with content
# "hello world 2".
echo '"hello world 2"' > message.nix
bazel build //:hello-output
content=$(cat bazel-bin/hello-output.txt)
if [[ $content != "hello world 2" ]]; then
    echo 'error: the content of bazel-bin/hello-output.txt must be "hello world 2" instead of' "$content"
    exit 1
fi
