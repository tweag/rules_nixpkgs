load("@rules_nixpkgs_rust//:rust.bzl", "nixpkgs_rust_configure")
load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")

def _rust_configure_impl(module_ctx):
    nixpkgs_rust_configure(
        name = "nixpkgs_rust",
        repository = "@nixpkgs",
        default_edition = "2021",
        register = False,
    )

def _cc_configure_impl(module_ctx):
    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        register = False,
    )

rust_configure = module_extension(
    implementation = _rust_configure_impl,
)

cc_configure = module_extension(
    implementation = _cc_configure_impl,
)
