load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")

def _cc_configure_impl(module_ctx):
    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        attribute_path = "clang_16",
        register = False,
    )

cc_configure = module_extension(
    implementation = _cc_configure_impl,
)
