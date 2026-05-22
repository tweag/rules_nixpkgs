load("@rules_rust//rust:defs.bzl", "rust_binary")

exports_files([
    "nixpkgs.nix",
    "nixpkgs.json",
    "openssl-static.nix",
])

rust_binary(
    name = "hello",
    srcs = ["hello.rs"],
    deps = [
        "@crates//:openssl",
    ],
)
