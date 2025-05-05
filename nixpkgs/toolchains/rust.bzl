# alias to Bazel module `toolchains/go`

load("@rules_nixpkgs_rust//:rust.bzl", _nixpkgs_rust_configure = "nixpkgs_rust_configure")
load("@rules_nixpkgs_rust//:wasm.bzl", _nixpkgs_rust_wasm_configure = "nixpkgs_rust_wasm_configure")

nixpkgs_rust_configure = _nixpkgs_rust_configure
nixpkgs_rust_wasm_configure = _nixpkgs_rust_wasm_configure

