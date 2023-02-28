load("//private/extensions:registry.bzl", "registry")
load("//repositories:repository.bzl", "nixpkgs_repository")

def _nix_repo_impl(module_ctx):
    reg = registry.make("rules_nixpkgs_core.nix_repo")

    for module in module_ctx.modules:
        registry.add_module(reg, module)

        tag_type = "file"
        for tag in getattr(module.tags, tag_type):
            repo_name = registry.new_repository(reg, module, tag.name)
            nixpkgs_repository(name = repo_name, file = tag.file)

        tag_type = "version"
        for tag in getattr(module.tags, tag_type):
            repo_name = registry.new_repository(reg, module, tag.name)
            nixpkgs_repository(name = repo_name, version = tag.version)

    registry.all_repositories(
        reg,
        name = "nixpkgs_repositories",
        getter_name = "get_repo",
    )

_file_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "file": attr.label(mandatory = True, allow_single_file = True),
    },
)

_version_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
)

nix_repo = module_extension(
    _nix_repo_impl,
    tag_classes = {
        "file": _file_tag,
        "version": _version_tag,
    },
)
