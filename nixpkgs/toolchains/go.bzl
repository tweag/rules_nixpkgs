"""Rules for importing a Go toolchain from Nixpkgs.

**NOTE: The following rules must be loaded from
`@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl` to avoid unnecessary
dependencies on rules_go for those who don't need go toolchain.
`io_bazel_rules_go` must be available for loading before loading of
`@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl`.**
"""

load(
    "//toolchains/go:go.bzl",
    _nixpkgs_go_configure = "nixpkgs_go_configure",
)

nixpkgs_go_configure = _nixpkgs_go_configure
