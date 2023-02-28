def _nixpkgs_package_impl(repository_ctx):
    attribute = repository_ctx.attr.attribute
    repository = repository_ctx.attr.repository
    content = "attribute {} from repository {} defined as\n".format(attribute, repository)
    content += repository_ctx.read(repository)
    repository_ctx.file("package", content, executable = False)

    repository_ctx.file("BUILD.bazel", 'exports_files(["package"])', executable = False)

nixpkgs_package = repository_rule(
    _nixpkgs_package_impl,
    attrs = {
        "attribute": attr.string(mandatory = True),
        "repository": attr.label(mandatory = True),
    },
)
