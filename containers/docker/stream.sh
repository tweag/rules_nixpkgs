set -euo pipefail

run() {
  ${NIX_BUILD} --arg stream true "$@"
}

$(run "$@")
