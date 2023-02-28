load("//repositories:package.bzl", "nixpkgs_package")
load("//private/extensions:registry.bzl", "registry")
load("@nixpkgs_repositories//:defs.bzl", "get_repo")

def _nix_pkg_impl(module_ctx):
    reg = registry.make("rules_nixpkgs_core.nix_pkg")

    for module in module_ctx.modules:
        registry.add_module(reg, module)

        tag_type = "attr"
        for tag in getattr(module.tags, tag_type):
            repo_name = registry.new_repository(reg, module, tag.name)
            nixpkgs_package(
                name = repo_name,
                attribute = tag.attribute,
                repository = get_repo(module.name, module.version, tag.repository, "repository"),
            )

    registry.all_repositories(
        reg,
        name = "nixpkgs_packages",
        getter_name = "get_pkg",
    )

_attr_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "attribute": attr.string(mandatory = True),
        "repository": attr.string(mandatory = True),
    },
)

nix_pkg = module_extension(
    _nix_pkg_impl,
    tag_classes = {
        "attr": _attr_tag,
    },
)
