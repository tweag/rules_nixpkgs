load("//:nixpkgs.bzl", "nixpkgs_package")

_attribute_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "TODO",
            mandatory = True,
        ),
        "path": attr.string(
            doc = "The attribute path into the top-level Nix expression of the repository.",
            # TODO[AH] optional and default to name?
            mandatory = True,
        ),
        "repository": attr.string(
            doc = "The nixpkgs repository to take this package from.",
            # TODO[AH] optional and default to nixpkgs?
            mandatory = True,
        ),
    },
)

def _all_packages_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_packages = repository_rule(
    _all_packages_impl,
    attrs = {
    },
)

def _packages_impl(module_ctx):
    _all_packages(
        name = "nixpkgs_packages",
    )

packages = module_extension(
    _packages_impl,
    tag_classes = {
        "attribute": _attribute_tag,
    },
)
