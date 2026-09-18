"""Module extension for rules_nixpkgs_python.

Provides a default Python toolchain from Nixpkgs. Usage:

    python_configure = use_extension("@rules_nixpkgs_python//extensions:python.bzl", "python_configure")
    python_configure.nixpkgs(
        nixpkgs = "@nixpkgs",
        python3_attribute_path = "python3.withPackages(ps: with ps; [ numpy opencv4 ])",
    )
    use_repo(python_configure, "nixpkgs_python_toolchain")
    use_repo(python_configure, "nixpkgs_python_toolchain_python3")
    register_toolchains("@nixpkgs_python_toolchain//:all")
"""

load("@rules_nixpkgs_python//:python.bzl", "nixpkgs_python_configure")

def _python_configure_impl(module_ctx):
    for mod in module_ctx.modules:
        for tag in mod.tags.nixpkgs:
            # nixpkgs_package expects a dict keyed by NIX_PATH entry,
            # mapping to the repository label. It inverts the dict before
            # calling the underlying rule (see core/nixpkgs.bzl).
            nixpkgs_python_configure(
                name = "nixpkgs_python_toolchain",
                python3_attribute_path = tag.python3_attribute_path,
                repositories = {"nixpkgs": tag.nixpkgs},
                register = False,
            )
    return module_ctx.extension_metadata(
        root_module_direct_deps = ["nixpkgs_python_toolchain", "nixpkgs_python_toolchain_python3"],
        root_module_direct_dev_deps = [],
    )

_nixpkgs_tag = tag_class(
    attrs = {
        "nixpkgs": attr.label(
            doc = "The nixpkgs repository (created by nix_repo extension).",
            mandatory = True,
        ),
        "python3_attribute_path": attr.string(
            default = "python3",
            doc = "The nixpkgs attribute path for python3.",
        ),
    },
)

python_configure = module_extension(
    implementation = _python_configure_impl,
    tag_classes = {
        "nixpkgs": _nixpkgs_tag,
    },
)