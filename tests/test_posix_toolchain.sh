#!/usr/bin/env bash

fail=0
for cmd in "$@"; do
  if [[ ! "$cmd" = /nix/store/* ]]; then
    echo "ERROR: '$cmd' is not in the Nix store." >&2
    fail=1
  fi
done
exit $fail
