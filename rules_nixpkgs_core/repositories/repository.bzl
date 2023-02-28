def _nixpkgs_repository_impl(repository_ctx):
    is_file = repository_ctx.attr.file != None
    is_version = repository_ctx.attr.version != ""
    if is_file and is_version:
        fail("Set only one of 'file' or 'version'.")

    if is_file:
        file = repository_ctx.attr.file
        content = "file {} with content\n".format(file)
        content += repository_ctx.read(file)
        repository_ctx.file("repository", content, executable = False)

    if is_version:
        version = repository_ctx.attr.version
        content = "version {}\n".format(version)
        repository_ctx.file("repository", content, executable = False)

    repository_ctx.file("BUILD.bazel", 'exports_files(["repository"])', executable = False)

nixpkgs_repository = repository_rule(
    _nixpkgs_repository_impl,
    attrs = {
        "file": attr.label(allow_single_file = True),
        "version": attr.string(),
    },
)
