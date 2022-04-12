"""<!-- Edit the docstring in `core/nixpkgs.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

# Nixpkgs rules for Bazel

[![Build status](https://badge.buildkite.com/79bd0a8aa1e47a92e0254ca3afe5f439776e6d389cfbde9d8c.svg?branch=master)](https://buildkite.com/tweag-1/rules-nixpkgs)

Use [Nix][nix] and the [Nixpkgs][nixpkgs] package set to import
external dependencies (like system packages) into [Bazel][bazel]
hermetically. If the version of any dependency changes, Bazel will
correctly rebuild targets, and only those targets that use the
external dependencies that changed.

Links:
* [Nix + Bazel = fully reproducible, incremental
  builds][blog-bazel-nix] (blog post)
* [Nix + Bazel][youtube-bazel-nix] (lightning talk)

[nix]: https://nixos.org/nix
[nixpkgs]: https://github.com/NixOS/nixpkgs
[bazel]: https://bazel.build
[blog-bazel-nix]: https://www.tweag.io/posts/2018-03-15-bazel-nix.html
[youtube-bazel-nix]: https://www.youtube.com/watch?v=hDdDUrty1Gw

See [examples](/examples) for how to use `rules_nixpkgs` with different toolchains.

## Rules

* [nixpkgs_git_repository](#nixpkgs_git_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)
"""

load(
    ":util.bzl",
    "cp",
    "executable_path",
    "execute_or_fail",
    "expand_location",
    "find_children",
    "is_supported_platform",
)

def _nixpkgs_git_repository_impl(repository_ctx):
    repository_ctx.file(
        "BUILD",
        content = 'filegroup(name = "srcs", srcs = glob(["**"]), visibility = ["//visibility:public"])',
    )

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for default.nix.
    repository_ctx.symlink("default.nix", repository_ctx.name)

    repository_ctx.download_and_extract(
        url = "%s/archive/%s.tar.gz" % (repository_ctx.attr.remote, repository_ctx.attr.revision),
        stripPrefix = "nixpkgs-" + repository_ctx.attr.revision,
        sha256 = repository_ctx.attr.sha256,
    )

nixpkgs_git_repository = repository_rule(
    implementation = _nixpkgs_git_repository_impl,
    attrs = {
        "revision": attr.string(
            mandatory = True,
            doc = "Git commit hash or tag identifying the version of Nixpkgs to use.",
        ),
        "remote": attr.string(
            default = "https://github.com/NixOS/nixpkgs",
            doc = "The URI of the remote Git repository. This must be a HTTP URL. There is currently no support for authentication. Defaults to [upstream nixpkgs](https://github.com/NixOS/nixpkgs).",
        ),
        "sha256": attr.string(doc = "The SHA256 used to verify the integrity of the repository."),
    },
    doc = """\
Name a specific revision of Nixpkgs on GitHub or a local checkout.
""",
)

def _nixpkgs_local_repository_impl(repository_ctx):
    if not bool(repository_ctx.attr.nix_file) != \
       bool(repository_ctx.attr.nix_file_content):
        fail("Specify one of 'nix_file' or 'nix_file_content' (but not both).")
    if repository_ctx.attr.nix_file_content:
        target = "default.nix"
        repository_ctx.file(
            target,
            content = repository_ctx.attr.nix_file_content,
            executable = False,
        )
    else:
        target = cp(repository_ctx, repository_ctx.attr.nix_file)

    repository_files = [target]
    for dep in repository_ctx.attr.nix_file_deps:
        dest = cp(repository_ctx, dep)
        repository_files.append(dest)

    # Export all specified Nix files to make them dependencies of a
    # nixpkgs_package rule.
    export_files = "exports_files({})".format(repository_files)
    repository_ctx.file("BUILD", content = export_files)

    # Create a file listing all Nix files of this repository. This
    # file is used by the nixpgks_package rule to register all Nix
    # files.
    repository_ctx.file("nix-file-deps", content = "\n".join(repository_files))

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for the target Nix file.
    repository_ctx.symlink(target, repository_ctx.name)

nixpkgs_local_repository = repository_rule(
    implementation = _nixpkgs_local_repository_impl,
    attrs = {
        "nix_file": attr.label(
            allow_single_file = [".nix"],
            doc = "A file containing an expression for a Nix derivation.",
        ),
        "nix_file_deps": attr.label_list(
            doc = "Dependencies of `nix_file` if any.",
        ),
        "nix_file_content": attr.string(
            doc = "An expression for a Nix derivation.",
        ),
    },
    doc = """\
Create an external repository representing the content of Nixpkgs, based on a Nix expression stored locally or provided inline. One of `nix_file` or `nix_file_content` must be provided.
""",
)

def _nixpkgs_package_impl(repository_ctx):
    repository = repository_ctx.attr.repository
    repositories = repository_ctx.attr.repositories

    # Is nix supported on this platform?
    not_supported = not is_supported_platform(repository_ctx)

    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    if repository and repositories or not repository and not repositories:
        fail("Specify one of 'repository' or 'repositories' (but not both).")
    elif repository:
        repositories = {repository_ctx.attr.repository: "nixpkgs"}

    # If true, a BUILD file will be created from a template if it does not
    # exist.
    # However this will happen AFTER the nix-build command.
    create_build_file_if_needed = False
    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")
    elif repository_ctx.attr.build_file:
        repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD")
    elif repository_ctx.attr.build_file_content:
        repository_ctx.file("BUILD", content = repository_ctx.attr.build_file_content)
    else:
        # No user supplied build file, we may create the default one.
        create_build_file_if_needed = True

    strFailureImplicitNixpkgs = (
        "One of 'repositories', 'nix_file' or 'nix_file_content' must be provided. " +
        "The NIX_PATH environment variable is not inherited."
    )

    expr_args = []
    if repository_ctx.attr.nix_file and repository_ctx.attr.nix_file_content:
        fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
    elif repository_ctx.attr.nix_file:
        nix_file = cp(repository_ctx, repository_ctx.attr.nix_file)
        expr_args = [repository_ctx.path(nix_file)]
    elif repository_ctx.attr.nix_file_content:
        expr_args = ["-E", repository_ctx.attr.nix_file_content]
    elif not repositories:
        fail(strFailureImplicitNixpkgs)
    else:
        expr_args = ["-E", "import <nixpkgs> { config = {}; overlays = []; }"]

    nix_file_deps = {}
    for dep in repository_ctx.attr.nix_file_deps:
        nix_file_deps[dep] = cp(repository_ctx, dep)

    expr_args.extend([
        "-A",
        repository_ctx.attr.attribute_path if repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content else repository_ctx.attr.attribute_path or repository_ctx.attr.name,
        # Creating an out link prevents nix from garbage collecting the store path.
        # nixpkgs uses `nix-support/` for such house-keeping files, so we mirror them
        # and use `bazel-support/`, under the assumption that no nix package has
        # a file named `bazel-support` in its root.
        # A `bazel clean` deletes the symlink and thus nix is free to garbage collect
        # the store path.
        "--out-link",
        "bazel-support/nix-out-link",
    ])

    expr_args.extend([
        expand_location(
            repository_ctx = repository_ctx,
            string = opt,
            labels = nix_file_deps,
            attr = "nixopts",
        )
        for opt in repository_ctx.attr.nixopts
    ])

    for repo in repositories.keys():
        path = str(repository_ctx.path(repo).dirname) + "/nix-file-deps"
        if repository_ctx.path(path).exists:
            content = repository_ctx.read(path)
            for f in content.splitlines():
                # Hack: this is to register all Nix files as dependencies
                # of this rule (see issue #113)
                repository_ctx.path(repo.relative(":{}".format(f)))

    # If repositories is not set, leave empty so nix will fail
    # unless a pinned nixpkgs is set in the `nix_file` attribute.
    nix_path = [
        "{}={}".format(prefix, repository_ctx.path(repo))
        for (repo, prefix) in repositories.items()
    ]
    if not (repositories or repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content):
        fail(strFailureImplicitNixpkgs)

    for dir in nix_path:
        expr_args.extend(["-I", dir])

    if not_supported and fail_not_supported:
        fail("Platform is not supported: nix-build not found in PATH. See attribute fail_not_supported if you don't want to use Nix.")
    elif not_supported:
        return
    else:
        nix_build_path = executable_path(
            repository_ctx,
            "nix-build",
            extra_msg = "See: https://nixos.org/nix/",
        )
        nix_build = [nix_build_path] + expr_args

        # Large enough integer that Bazel can still parse. We don't have
        # access to MAX_INT and 0 is not a valid timeout so this is as good
        # as we can do. The value shouldn't be too large to avoid errors on
        # macOS, see https://github.com/tweag/rules_nixpkgs/issues/92.
        timeout = 8640000
        repository_ctx.report_progress("Building Nix derivation")
        exec_result = execute_or_fail(
            repository_ctx,
            nix_build,
            failure_message = "Cannot build Nix attribute '{}'.".format(
                repository_ctx.attr.attribute_path,
            ),
            quiet = repository_ctx.attr.quiet,
            timeout = timeout,
        )
        output_path = exec_result.stdout.splitlines()[-1]

        # ensure that the output is a directory
        test_path = repository_ctx.which("test")
        execute_or_fail(
            repository_ctx,
            [test_path, "-d", output_path],
            failure_message = "nixpkgs_package '@{}' outputs a single file which is not supported by rules_nixpkgs. Please only use directories.".format(
                repository_ctx.name,
            ),
        )

        # Build a forest of symlinks (like new_local_package() does) to the
        # Nix store.
        for target in find_children(repository_ctx, output_path):
            basename = target.rpartition("/")[-1]
            repository_ctx.symlink(target, basename)

        # Create a default BUILD file only if it does not exists and is not
        # provided by `build_file` or `build_file_content`.
        if create_build_file_if_needed:
            p = repository_ctx.path("BUILD")
            if not p.exists:
                repository_ctx.template("BUILD", Label("@rules_nixpkgs_core//:BUILD.bazel.tpl"))

_nixpkgs_package = repository_rule(
    implementation = _nixpkgs_package_impl,
    attrs = {
        "attribute_path": attr.string(),
        "nix_file": attr.label(allow_single_file = [".nix"]),
        "nix_file_deps": attr.label_list(),
        "nix_file_content": attr.string(),
        "repositories": attr.label_keyed_string_dict(),
        "repository": attr.label(),
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "nixopts": attr.string_list(),
        "quiet": attr.bool(),
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
                                        """),
    },
)

def nixpkgs_package(
        name,
        attribute_path = "",
        nix_file = None,
        nix_file_deps = [],
        nix_file_content = "",
        repository = None,
        repositories = {},
        build_file = None,
        build_file_content = "",
        nixopts = [],
        quiet = False,
        fail_not_supported = True,
        **kwargs):
    """Make the content of a Nixpkgs package available in the Bazel workspace.

    If `repositories` is not specified, you must provide a nixpkgs clone in `nix_file` or `nix_file_content`.

    Args:
      name: A unique name for this repository.
      attribute_path: Select an attribute from the top-level Nix expression being evaluated. The attribute path is a sequence of attribute names separated by dots.
      nix_file: A file containing an expression for a Nix derivation.
      nix_file_deps: Dependencies of `nix_file` if any.
      nix_file_content: An expression for a Nix derivation.
      repository: A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`
      repositories: A dictionary mapping `NIX_PATH` entries to repository labels.

        Setting it to
        ```
        repositories = { "myrepo" : "//:myrepo" }
        ```
        for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

        Specify one of `repository` or `repositories`.
      build_file: The file to use as the BUILD file for this repository.

        Its contents are copied copied into the file `BUILD` in root of the nix output folder. The Label does not need to be named `BUILD`, but can be.

        For common use cases we provide filegroups that expose certain files as targets:

        <dl>
          <dt><code>:bin</code></dt>
          <dd>Everything in the <code>bin/</code> directory.</dd>
          <dt><code>:lib</code></dt>
          <dd>All <code>.so</code> and <code>.a</code> files that can be found in subdirectories of <code>lib/</code>.</dd>
          <dt><code>:include</code></dt>
          <dd>All <code>.h</code> files that can be found in subdirectories of <code>bin/</code>.</dd>
        </dl>

        If you need different files from the nix package, you can reference them like this:
        ```
        package(default_visibility = [ "//visibility:public" ])
        filegroup(
            name = "our-docs",
            srcs = glob(["share/doc/ourpackage/**/*"]),
        )
        ```
        See the bazel documentation of [`filegroup`](https://docs.bazel.build/versions/master/be/general.html#filegroup) and [`glob`](https://docs.bazel.build/versions/master/be/functions.html#glob).
      build_file_content: Like `build_file`, but a string of the contents instead of a file name.
      nixopts: Extra flags to pass when calling Nix.
      quiet: Whether to hide the output of the Nix command.
      fail_not_supported: If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.
    """
    kwargs.update(
        name = name,
        attribute_path = attribute_path,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        repository = repository,
        repositories = repositories,
        build_file = build_file,
        build_file_content = build_file_content,
        nixopts = nixopts,
        quiet = quiet,
        fail_not_supported = fail_not_supported,
    )

    # Because of https://github.com/bazelbuild/bazel/issues/7989 we can't
    # directly pass a dict from strings to labels to the rule (which we'd like
    # for the `repositories` arguments), but we can pass a dict from labels to
    # strings. So we swap the keys and the values (assuming they all are
    # distinct).
    if "repositories" in kwargs:
        inversed_repositories = {value: key for (key, value) in kwargs["repositories"].items()}
        kwargs["repositories"] = inversed_repositories

    _nixpkgs_package(**kwargs)
