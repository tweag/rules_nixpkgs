#!/usr/bin/env bash
set -euo pipefail

# copy files, passed as pairs of source and target locations, to workspace directory
while (($#)); do
  cp "$1" "$BUILD_WORKSPACE_DIRECTORY/$2"
  shift; shift
done
