#!/usr/bin/env bash
set -euo pipefail

while (($#)); do
  cp "$1" "$BUILD_WORKSPACE_DIRECTORY/$2"
  shift; shift
done
