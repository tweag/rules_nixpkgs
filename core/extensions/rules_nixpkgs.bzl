"""Defines the nix_flake module extension."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("//:nixpkgs.bzl", "nixpkgs_flake_package")

def _rules_nixpkgs_impl(module_ctx):
    root_deps = sets.make()
    root_dev_deps = sets.make()

    for mod in module_ctx.modules:
        module_pkgs = sets.make()

        for flake_package in mod.tags.flake_package:
            if sets.contains(module_pkgs, flake_package.name):
                fail("Duplicate rules_nixpkgs import. The flake_package name '{}' is already used.".format(flake_package.name))
            else:
                sets.insert(module_pkgs, flake_package.name)

            nixpkgs_flake_package(
                name = flake_package.name,
                nix_flake_file = flake_package.nix_flake_file,
                nix_flake_lock_file = flake_package.nix_flake_lock_file,
                nix_flake_file_deps = flake_package.nix_flake_file_deps,
                package = flake_package.package,
                build_file = flake_package.build_file,
                build_file_content = flake_package.build_file_content,
                nixopts = flake_package.nixopts,
                quiet = flake_package.quiet,
                fail_not_supported = flake_package.fail_not_supported,
            )

            if mod.is_root:
                if module_ctx.is_dev_dependency(flake_package):
                    sets.insert(root_dev_deps, flake_package.name)
                else:
                    sets.insert(root_deps, flake_package.name)

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(
            root_module_direct_deps = sets.to_list(root_deps),
            root_module_direct_dev_deps = sets.to_list(root_dev_deps),
            reproducible = True,
        )
    else:
        return module_ctx.extension_metadata(
            root_module_direct_deps = sets.to_list(root_deps),
            root_module_direct_dev_deps = sets.to_list(root_dev_deps),
        )

_flake_package_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "A unique name for this repository.",
            mandatory = True,
        ),
        "nix_flake_file": attr.label(
            doc = "Label to `flake.nix` that will be evaluated.",
            mandatory = True,
        ),
        "nix_flake_lock_file": attr.label(
            doc = "Label to `flake.lock` that corresponds to `nix_flake_file`.",
            mandatory = True,
        ),
        "nix_flake_file_deps": attr.label_list(
            doc = "Additional dependencies of `nix_flake_file` if any.",
        ),
        "package": attr.string(
            doc = "Nix Flake package to make available.  The default package will be used if not specified.",
        ),
        "build_file": attr.label(
            doc = "The file to use as the BUILD file for this repository. See [`nixpkgs_package`](#nixpkgs_package-build_file) for more information.",
        ),
        "build_file_content": attr.string(
            doc = "Like `build_file`, but a string of the contents instead of a file name. See [`nixpkgs_package`](#nixpkgs_package-build_file_content) for more information.",
        ),
        "nixopts": attr.string_list(
            doc = "Extra flags to pass when calling Nix. See [`nixpkgs_package`](#nixpkgs_package-nixopts) for more information.",
        ),
        "quiet": attr.bool(
            doc = "Whether to hide the output of the Nix command.",
        ),
        "fail_not_supported": attr.bool(
            doc = "If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.",
            default = True,
        ),
    },
    doc = "Import a globally unified Nix package from the default nixpkgs repository. May not be used on an isolated module extension.",
)

rules_nixpkgs = module_extension(
    _rules_nixpkgs_impl,
    tag_classes = {
        "flake_package": _flake_package_tag,
    },
)
