# alias to Bazel module `toolchains/go`

load("//toolchains/rust:rust.bzl", _nixpkgs_rust_configure = "nixpkgs_rust_configure")

nixpkgs_rust_configure = _nixpkgs_rust_configure
