load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")
load("@rules_nixpkgs_python//:python.bzl", "nixpkgs_python_configure")

def _extension_configure_impl(module_ctx):
    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        exec_constraints = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        target_constraints = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        register = False,
    )

    nixpkgs_python_configure(
        python3_attribute_path = "python312.withPackages(ps: [ ps.flask ])",
        repository = "@nixpkgs",
        register = False,
    )

extension_configure = module_extension(
    implementation = _extension_configure_impl,
)
