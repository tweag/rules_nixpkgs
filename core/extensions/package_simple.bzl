"""Defines the nix_pkg module extension.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("//:nixpkgs.bzl", "nixpkgs_package")

# TODO[AH] Switch to @nixpkgs
_DEFAULT_NIXKGS = "@nixpkgs-simple"

_ISOLATED_NOT_ALLOWED_ERROR = "Illegal use of the {tag_name} tag. The {tag_name} tag may not be used on an isolated module extension."

def _default_pkg(default):
    nixpkgs_package(
        name = default.attr,
        attribute_path = default.attr,
        repository = _DEFAULT_NIXKGS,
    )

def _nix_pkg_impl(module_ctx):
    unified_pkgs = sets.make()
    root_deps = sets.make()
    root_dev_deps = sets.make()

    is_isolated = getattr(module_ctx, "is_isolated", False)

    for mod in module_ctx.modules:
        is_root = mod.is_root

        for default in mod.tags.default:
            is_dev_dep = module_ctx.is_dev_dependency(default)

            if is_isolated:
                fail(_ISOLATED_NOT_ALLOWED_ERROR.format(tag_name = "default"))

            if not sets.contains(unified_pkgs, default.attr):
                sets.insert(unified_pkgs, default.attr)
                _default_pkg(default)

            if is_root:
                if is_dev_dep:
                    sets.insert(root_dev_deps, default.attr)
                else:
                    sets.insert(root_deps, default.attr)

    return module_ctx.extension_metadata(
        root_module_direct_deps = sets.to_list(root_deps),
        root_module_direct_dev_deps = sets.to_list(root_dev_deps),
    )

_DEFAULT_ATTRS = {
    "attr": attr.string(
        doc = "The attribute path of the package to import. The attribute path is a sequence of attribute names separated by dots.",
        mandatory = True,
    ),
}

_default_tag = tag_class(
    attrs = _DEFAULT_ATTRS,
    doc = "Import a globally unified Nix package from the default nixpkgs repository. May not be used on an isolated module extension.",
)

nix_pkg = module_extension(
    _nix_pkg_impl,
    tag_classes = {
        "default": _default_tag,
    },
)
