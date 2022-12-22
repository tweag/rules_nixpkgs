#!/usr/bin/env bash
set -euo pipefail

# copy files, passed as pairs of source and target locations, to the workspace
# directory the calling rule is run from
while (($#)); do
  # `--no-preserve` is only supported by `coreutils`, so we have to control `cp`
  "$POSIX_CP" --no-preserve=all "$1" "$BUILD_WORKSPACE_DIRECTORY/$2"
  shift; shift
done
