#!/usr/bin/env bash

set -euo pipefail

run() {
  ${NIX_BUILD} --arg stream true "$@"
}

$(run "$@")
