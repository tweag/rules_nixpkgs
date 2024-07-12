#!/usr/bin/env bash
set -euo pipefail

TAG=$1
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_nixpkgs-${TAG:1}"
ARCHIVE="rules_nixpkgs-${TAG:1}.tar.gz"
git archive --format=tar.gz --prefix="${PREFIX}/" -o $ARCHIVE HEAD
SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

cat << EOF
## Using Bzlmod with Bazel 6+

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

### For the core module

\`\`\`starlark
bazel_dep(name = "rules_nixpkgs_core", version = "${TAG:1}")
\`\`\`

### For the nodejs module

\`\`\`starlark
bazel_dep(name = "rules_nixpkgs_nodejs", version = "${TAG:1}")
\`\`\`

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_tweag_rules_nixpkgs",
    sha256 = "${SHA}",
    strip_prefix = "$PREFIX",
    urls = ["https://github.com/tweag/rules_nixpkgs/releases/download/$TAG/$ARCHIVE"],
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package", "nixpkgs_cc_configure")

load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_configure") # optional
\`\`\`
EOF
