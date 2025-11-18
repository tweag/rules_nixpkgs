load("@rules_nixpkgs_go//:go.bzl", "nixpkgs_go_configure")

def _go_configure_impl(module_ctx):
    nixpkgs_go_configure(
        repository = "@nixpkgs",
        sdk_name = "nix_config_go",
        register = False,
    )

go_configure = module_extension(
    implementation = _go_configure_impl,
)
