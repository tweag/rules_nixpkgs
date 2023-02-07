#!/usr/bin/env bash
set -euo pipefail

# USAGE:
# location_expansion.sh DIFF REFERENCE FILE...
#
# Compares the given files to the reference file and fails if there is a difference.
DIFF="$1"
REFERENCE="$2"

for file in "${@:3}"; do
  "$DIFF" "$file" "$REFERENCE"
done
