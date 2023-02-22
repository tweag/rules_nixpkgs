_repository_file_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Reference this repository by `NAME` in other module tags or in Nix expressions using `<NAME>`.",
            mandatory = True,
        ),
        "file": attr.label(
            doc = "A Nix file that defines a nixpkgs repository.",
            allow_single_file = True,
            mandatory = True,
        ),
        "file_deps": attr.label_list(
            doc = "Other files needed to evaluate the Nix repository.",
            allow_files = True,
        ),
    },
)

def _all_repositories_impl(repository_ctx):
    defs = 'dummy = "hello"'
    repository_ctx.file("defs.bzl", defs, executable=False)
    repository_ctx.file("BUILD.bazel", "", executable=False)

_all_repositories = repository_rule(
    _all_repositories_impl,
    attrs = {
    },
)

def _repositories_impl(module_ctx):
    _all_repositories(
        name = "nixpkgs_repositories",
    )

repositories = module_extension(
    _repositories_impl,
    tag_classes = {
        "file": _repository_file_tag,
    },
)
