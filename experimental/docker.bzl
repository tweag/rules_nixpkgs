def _nixpkgs_docker_image_impl(repository_ctx):
    repositories = repository_ctx.attr.repositories

    nix_build_bin = repository_ctx.which("nix-build")
    repository_ctx.symlink(nix_build_bin, "nix-build")

    srcs = repository_ctx.attr.srcs
    bazel = repository_ctx.attr.bazel

    # HACK! On bazel from nixpkgs, shebangs get mangled in things like
    # @bazel_tools//tools/cpp:linux_cc_wrapper.sh.tpl, so that nix store
    # paths end up referenced there.
    # One needs to ensure those paths are available on the docker image
    # as well, we can do that by including bazel
    srcs = srcs + [bazel] if bazel else srcs

    contents = []
    for src in srcs:
        path_to_default_nix = repository_ctx.path(src.relative("default.nix"))
        package = "nixpkgs/%s" % src.workspace_name
        repository_ctx.symlink(path_to_default_nix.dirname, package)
        contents.append("(import ./%s {})" % package)

    repository_ctx.template(
        "default.nix",
        Label("@io_tweag_rules_nixpkgs//experimental:docker/default.nix.template"),
        substitutions = {
            "%{name}": repr(repository_ctx.name),
            "%{contents}": "\n    ".join(contents),
        },
        executable=False,
    )

    for repo in repositories.keys():
        path = str(repository_ctx.path(repo).dirname) + "/nix-file-deps"
        if repository_ctx.path(path).exists:
            content = repository_ctx.read(path)
            for f in content.splitlines():
                # Hack: this is to register all Nix files as dependencies
                # of this rule (see issue #113)
                repository_ctx.path(repo.relative(":{}".format(f)))

    args = list(repository_ctx.attr.nixopts)
    deps = []
    for repo_label, repo_name in repositories.items():
        args.extend([
            '"-I"',
            repr("%s=$(location %s)" % (repo_name, repo_label))
        ])
        deps.extend([
            repo_label,
            repo_label.relative(":srcs"),
        ])

    repository_ctx.template(
        "BUILD",
        Label("@io_tweag_rules_nixpkgs//experimental:docker/BUILD.template"),
        substitutions = {
            "%{args_comma_sep}": ",\n        ".join(args),
            "%{args_space_sep}": " ".join(args),
            "%{repo_labels}": ",\n        ".join([repr(str(dep)) for dep in deps])
        },
        executable=False,
    )



_nixpkgs_docker_image = repository_rule(
    implementation = _nixpkgs_docker_image_impl,
    attrs = {
        "nixopts": attr.string_list(),
        "repositories": attr.label_keyed_string_dict(),
        "srcs": attr.label_list(
            doc = 'List of nixpkgs_package to include in the image. E.g. ["@hello//nixpkg"]',
        ),
        "bazel": attr.label(
            doc = """If using bazel from nixpkgs, this a nixpackage_package
            based on exactly the same bazel derivation. This is to ensure any paths
            for mangled '/usr/env bash' introduced by nix exist in the store.
            Example: '<nixpkgs>.bazel_4'.
            """
        ),
    },
)

def nixpkgs_docker_image(name, **kwargs):
    repositories = kwargs.get("repositories")
    if repositories:
        inversed_repositories = {value: key for key, value in repositories.items()}
        kwargs["repositories"] = inversed_repositories
    _nixpkgs_docker_image(name=name, **kwargs)
