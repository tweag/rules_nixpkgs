"""
# Docker containerization Bazel Nixpkgs rules

To run bazel artifacts across systems and platforms, nixpkgs_rules exposed a
docker hook. e.g.

```starlark
nixpkgs_docker_image(
    name = "nix_deps_image",
    srcs = [
        "@cc_toolchain_nixpkgs_info////bazel-support",
        "@nixpkgs_python_toolchain_python3//bazel-support",
        "@nixpkgs_sh_posix_config//bazel-support",
        "@rules_haskell_ghc_nixpkgs//bazel-support",
        "@nixpkgs_valgrind//bazel-support",
    ],
    bazel = "@nixpkgs_bazel//bazel-support",
    repositories = {"nixpkgs": "@nixpkgs"},
)
```

here, nixpkgs rules dependencies are bundled into a docker container for use and
deployment.

"""

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
        package = "bazel-support/%s" % src.workspace_name
        repository_ctx.symlink(path_to_default_nix.dirname, package)
        contents.append("(import ./%s {})" % package)

    repository_ctx.template(
        "default.nix",
        Label("@io_tweag_rules_nixpkgs//containers:docker/default.nix.tpl"),
        substitutions = {
            "%{name}": repr(repository_ctx.name),
            "%{contents}": "\n    ".join(contents),
        },
        executable = False,
    )

    args = list(repository_ctx.attr.nixopts)
    for repo_label, repo_name in repositories.items():
        absolute_repo = repository_ctx.path(repo_label).dirname

        # Excessive quoting due to nix limitations for ~ in file path
        # (see NixOS/nix#7742).
        args.extend([
            '"-I"',
            "\"%s=\\\"%s\\\"\"" % (repo_name, absolute_repo),
        ])

    repository_ctx.template(
        "BUILD",
        Label("@io_tweag_rules_nixpkgs//containers:docker/BUILD.bazel.tpl"),
        substitutions = {
            "%{args_comma_sep}": ",\n        ".join(args),
            "%{args_space_sep}": " ".join(args),
        },
        executable = False,
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
            """,
        ),
    },
)

def nixpkgs_docker_image(name, **kwargs):
    repositories = kwargs.get("repositories")
    if repositories:
        inversed_repositories = {value: key for key, value in repositories.items()}
        kwargs["repositories"] = inversed_repositories
    _nixpkgs_docker_image(name = name, **kwargs)
