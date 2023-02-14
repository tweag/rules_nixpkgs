#!/usr/bin/env bash

resolved_path() {
  local path="$1"
  while [[ -L "$path" ]]; do
    path="$(readlink "$path")"
  done
  echo "$path"
}

resolved_root="$(resolved_path "$1")"
pattern="/nix/store/*-bazel-go-toolchain/ROOT"

if [[ "$resolved_root" != $pattern ]]; then
  echo "error: Expected Nix provided Go toolchain, '$pattern', got '$resolved_root'" >&2
  exit 1
fi
