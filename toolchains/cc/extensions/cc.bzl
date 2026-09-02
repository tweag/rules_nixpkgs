"""Module extension for rules_nixpkgs_cc.

Provides a default CC toolchain from Nixpkgs. Usage:

    cc_configure = use_extension("@rules_nixpkgs_cc//extensions:cc.bzl", "cc_configure")
    cc_configure.nixpkgs(name = "nixpkgs")
    use_repo(cc_configure, "nixpkgs_config_cc")
    use_repo(cc_configure, "nixpkgs_config_cc_toolchains")
    register_toolchains("@nixpkgs_config_cc_toolchains//:all")
"""

load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")

def _cc_configure_impl(module_ctx):
    for mod in module_ctx.modules:
        for tag in mod.tags.nixpkgs:
            # Pass the nixpkgs repo as a label via the repositories dict.
            # Using repository= directly doesn't work in module extensions
            # because the label isn't visible to this extension.
            nixpkgs_cc_configure(
                name = "nixpkgs_config_cc",
                repositories = {str(tag.nixpkgs): "nixpkgs"},
                register = False,
            )
    return module_ctx.extension_metadata(
        root_module_direct_deps = ["nixpkgs_config_cc", "nixpkgs_config_cc_toolchains"],
        root_module_direct_dev_deps = [],
    )

_nixpkgs_tag = tag_class(
    attrs = {
        "nixpkgs": attr.label(
            doc = "The nixpkgs repository (created by nix_repo extension).",
            mandatory = True,
        ),
    },
)

cc_configure = module_extension(
    implementation = _cc_configure_impl,
    tag_classes = {
        "nixpkgs": _nixpkgs_tag,
    },
)
