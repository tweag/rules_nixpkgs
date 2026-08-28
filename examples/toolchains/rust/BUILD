load("@rules_rust//rust:defs.bzl", "rust_binary")
load("@rules_rust//wasm_bindgen:defs.bzl", "rust_wasm_bindgen")
load("@crate_index//:defs.bzl", "all_crate_deps")

exports_files([
    "nixpkgs.nix",
    "nixpkgs.json",
    "openssl-static.nix",
])

rust_binary(
    name = "hello",
    srcs = ["hello.rs"],
    deps = [], # all_crate_deps(normal = True),
    edition = "2021",
)

rust_wasm_bindgen(
    name = "wasm",
    target = "web",
    wasm_file = ":hello",
)
