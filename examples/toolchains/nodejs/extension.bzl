load("@rules_nixpkgs_nodejs//:nodejs.bzl", "nixpkgs_nodejs_configure")

def _nodejs_configure_impl(module_ctx):
    nixpkgs_nodejs_configure(
        name = "nixpkgs_nodejs",
        repository = "@nixpkgs",
        register = False,
    )

nodejs_configure = module_extension(
    implementation = _nodejs_configure_impl,
)
