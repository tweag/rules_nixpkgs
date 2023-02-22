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

def _nixpkgs_repositories_impl(module_ctx):
    pass

nixpkgs_repositories = module_extension(
    _nixpkgs_repositories_impl,
    tag_classes = {
        "file": _repository_file_tag,
    },
)
