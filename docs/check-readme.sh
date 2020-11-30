#!/usr/bin/env bash
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---
set -euo pipefail

old="$(rlocation io_tweag_rules_nixpkgs/README.md)"
new="$(rlocation io_tweag_rules_nixpkgs/docs/README.md)"

if ! cmp -s "$old" "$new"; then
  cat >&2 <<EOF
The project README is not up-to-date.
Please update it using the following command.

  bazel run //docs:update-readme

EOF
  exit 1
fi
