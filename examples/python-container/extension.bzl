# NOTE: rules_nixpkgs_python does not yet provide its own module extension.
# Users must define a wrapper extension to call nixpkgs_python_configure.
load("@rules_nixpkgs_python//:python.bzl", "nixpkgs_python_configure")

def _python_configure_impl(module_ctx):
    nixpkgs_python_configure(
        python3_attribute_path = "python312.withPackages(ps: [ ps.flask ])",
        repository = "@nixpkgs",
        register = False,
    )

python_configure = module_extension(
    implementation = _python_configure_impl,
)
