load("@rules_rust//rust:defs.bzl", "rust_binary")
load("@crate_index//:defs.bzl", "all_crate_deps")

exports_files([
    "nixpkgs.nix",
    "nixpkgs.json",
    "openssl-static.nix",
    "patches/001-rules-rust-crate-universe.patch",
])

rust_binary(
    name = "hello",
    srcs = ["hello.rs"],
    deps = all_crate_deps(normal = True),
)
