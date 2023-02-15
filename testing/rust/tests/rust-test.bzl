load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

ResolvedRustToolchainInfo = provider()

def _rust_toolchain_impl(ctx):
    rust = ctx.toolchains["@rules_rust//rust:toolchain"]
    return [
        ResolvedRustToolchainInfo(rust = rust),
    ]

_rust_toolchain = rule(
    _rust_toolchain_impl,
    toolchains = ["@rules_rust//rust:toolchain"],
)

def _rust_toolchain_test_impl(ctx):
    env = unittest.begin(ctx)

    rust = ctx.attr.toolchain[ResolvedRustToolchainInfo].rust
    toolchain_label = rust.rustc.owner
    asserts.equals(env, "nixpkgs_config_rust", toolchain_label.workspace_name, "Rust toolchain must be provided by rules_nixpkgs_rust.")

    return unittest.end(env)

_rust_toolchain_test = unittest.make(
    _rust_toolchain_test_impl,
    attrs = {
        "toolchain": attr.label(),
    },
)

def rust_test_suite(name):
    _rust_toolchain(name = "rust-toolchain")
    unittest.suite(
        name,
        lambda name: _rust_toolchain_test(name = name, toolchain = ":rust-toolchain")
    )
