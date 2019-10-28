"""Rules for importing Nixpkgs packages."""

load("@bazel_tools//tools/cpp:cc_configure.bzl", "cc_autoconf_impl")
load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

def _nixpkgs_git_repository_impl(repository_ctx):
    repository_ctx.file("BUILD")

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
        "revision": attr.string(mandatory = True),
        "remote": attr.string(default = "https://github.com/NixOS/nixpkgs"),
        "sha256": attr.string(),
    },
)

def _nixpkgs_local_repository_impl(repository_ctx):
    repository_ctx.file("BUILD")
    if not bool(repository_ctx.attr.nix_file) != \
       bool(repository_ctx.attr.nix_file_content):
        fail("Specify one of 'nix_file' or 'nix_file_content' (but not both).")
    if repository_ctx.attr.nix_file_content:
        repository_ctx.file(
            path = "default.nix",
            content = repository_ctx.attr.nix_file_content,
            executable = False,
        )
        target = repository_ctx.path("default.nix")
    else:
        target = _cp(repository_ctx, repository_ctx.attr.nix_file)

    for dep in repository_ctx.attr.nix_file_deps:
        _cp(repository_ctx, dep)

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for the target Nix file.
    repository_ctx.symlink(target, repository_ctx.name)

nixpkgs_local_repository = repository_rule(
    implementation = _nixpkgs_local_repository_impl,
    attrs = {
        "nix_file": attr.label(allow_single_file = [".nix"]),
        "nix_file_deps": attr.label_list(),
        "nix_file_content": attr.string(),
    },
)

def _is_supported_platform(repository_ctx):
    return repository_ctx.which("nix-build") != None

def _nixpkgs_package_impl(repository_ctx):
    repository = repository_ctx.attr.repository
    repositories = repository_ctx.attr.repositories

    # Is nix supported on this platform?
    not_supported = not _is_supported_platform(repository_ctx)
    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    if repository and repositories or not repository and not repositories:
        fail("Specify one of 'repository' or 'repositories' (but not both).")
    elif repository:
        repositories = {repository_ctx.attr.repository: "nixpkgs"}

    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")
    elif repository_ctx.attr.build_file:
        repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD")
    elif repository_ctx.attr.build_file_content:
        repository_ctx.file("BUILD", content = repository_ctx.attr.build_file_content)
    else:
        repository_ctx.template("BUILD", Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"))

    strFailureImplicitNixpkgs = (
        "One of 'repositories', 'nix_file' or 'nix_file_content' must be provided. " +
        "The NIX_PATH environment variable is not inherited."
    )

    expr_args = []
    if repository_ctx.attr.nix_file and repository_ctx.attr.nix_file_content:
        fail("Specify one of 'nix_file' or 'nix_file_content', but not both.")
    elif repository_ctx.attr.nix_file:
        nix_file = _cp(repository_ctx, repository_ctx.attr.nix_file)
        expr_args = [nix_file]
    elif repository_ctx.attr.nix_file_content:
        expr_args = ["-E", repository_ctx.attr.nix_file_content]
    elif not repositories:
        fail(strFailureImplicitNixpkgs)
    else:
        expr_args = ["-E", "import <nixpkgs> { config = {}; overlays = []; }"]

    for dep in repository_ctx.attr.nix_file_deps:
        _cp(repository_ctx, dep)

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

    expr_args.extend(repository_ctx.attr.nixopts)

    # If repositories is not set, leave empty so nix will fail
    # unless a pinned nixpkgs is set in the `nix_file` attribute.
    nix_paths = []
    if repositories:
        nix_paths = [
            (path_name + "=" + str(repository_ctx.path(target)))
            for (target, path_name) in repositories.items()
        ]
    elif not (repository_ctx.attr.nix_file or repository_ctx.attr.nix_file_content):
        fail(strFailureImplicitNixpkgs)

    for nix_path in nix_paths:
        expr_args.extend(["-I", nix_path])

    if not_supported and fail_not_supported:
        fail("Platform is not supported (see 'fail_not_supported')")
    elif not_supported:
        return
    else:
        nix_build_path = _executable_path(
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
        exec_result = _execute_or_fail(
            repository_ctx,
            nix_build,
            failure_message = "Cannot build Nix attribute '{}'.".format(
                repository_ctx.attr.attribute_path,
            ),
            timeout = timeout,
        )
        output_path = exec_result.stdout.splitlines()[-1]

        # Build a forest of symlinks (like new_local_package() does) to the
        # Nix store.
        for target in _find_children(repository_ctx, output_path):
            basename = target.rpartition("/")[-1]
            repository_ctx.symlink(target, basename)

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
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
                                        """),
    },
)

def nixpkgs_package(*args, **kwargs):
    # Because of https://github.com/bazelbuild/bazel/issues/7989 we can't
    # directly pass a dict from strings to labels to the rule (which we'd like
    # for the `repositories` arguments), but we can pass a dict from labels to
    # strings. So we swap the keys and the values (assuming they all are
    # distinct).
    if "repositories" in kwargs:
        inversed_repositories = {value: key for (key, value) in kwargs["repositories"].items()}
        kwargs.pop("repositories")
        _nixpkgs_package(
            repositories = inversed_repositories,
            *args,
            **kwargs
        )
    else:
        _nixpkgs_package(*args, **kwargs)

def _readlink(repository_ctx, path):
    return repository_ctx.path(path).realpath

def nixpkgs_cc_autoconf_impl(repository_ctx):
    cpu_value = get_cpu_value(repository_ctx)
    if not _is_supported_platform(repository_ctx):
        cc_autoconf_impl(repository_ctx)
        return

    # Calling repository_ctx.path() on anything but a regular file
    # fails. So the roundabout way to do the same thing is to find
    # a regular file we know is in the workspace (i.e. the WORKSPACE
    # file itself) and then use dirname to get the path of the workspace
    # root.
    workspace_file_path = repository_ctx.path(
        Label("@nixpkgs_cc_toolchain//:WORKSPACE"),
    )
    workspace_root = _execute_or_fail(
        repository_ctx,
        ["dirname", workspace_file_path],
    ).stdout.rstrip()

    # Make a list of all available tools in the Nix derivation. Override
    # the Bazel autoconfiguration with the tools we found.
    bin_contents = _find_children(repository_ctx, workspace_root + "/bin")
    overriden_tools = {
        tool: _readlink(repository_ctx, entry)
        for entry in bin_contents
        for tool in [entry.rpartition("/")[-1]]  # Compute basename
    }
    cc_autoconf_impl(repository_ctx, overriden_tools = overriden_tools)

nixpkgs_cc_autoconf = repository_rule(
    implementation = nixpkgs_cc_autoconf_impl,
    # Copied from
    # https://github.com/bazelbuild/bazel/blob/master/tools/cpp/cc_configure.bzl.
    # Keep in sync.
    environ = [
        "ABI_LIBC_VERSION",
        "ABI_VERSION",
        "BAZEL_COMPILER",
        "BAZEL_HOST_SYSTEM",
        "BAZEL_LINKOPTS",
        "BAZEL_PYTHON",
        "BAZEL_SH",
        "BAZEL_TARGET_CPU",
        "BAZEL_TARGET_LIBC",
        "BAZEL_TARGET_SYSTEM",
        "BAZEL_USE_CPP_ONLY_TOOLCHAIN",
        "BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN",
        "BAZEL_USE_LLVM_NATIVE_COVERAGE",
        "BAZEL_VC",
        "BAZEL_VS",
        "BAZEL_LLVM",
        "USE_CLANG_CL",
        "CC",
        "CC_CONFIGURE_DEBUG",
        "CC_TOOLCHAIN_NAME",
        "CPLUS_INCLUDE_PATH",
        "GCOV",
        "HOMEBREW_RUBY_PATH",
        "SYSTEMROOT",
        "VS90COMNTOOLS",
        "VS100COMNTOOLS",
        "VS110COMNTOOLS",
        "VS120COMNTOOLS",
        "VS140COMNTOOLS",
    ],
)

def nixpkgs_cc_configure(
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = []):
    """Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

    By default, Bazel auto-configures a CC toolchain from commands (e.g.
    `gcc`) available in the environment. To make builds more hermetic, use
    this rule to specific explicitly which commands the toolchain should
    use.
    """
    if not nix_file and not nix_file_content:
        nix_file_content = """
          with import <nixpkgs> { config = {}; overlays = []; }; buildEnv {
            name = "bazel-cc-toolchain";
            paths = [ stdenv.cc binutils ];
          }
        """
    nixpkgs_package(
        name = "nixpkgs_cc_toolchain",
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        build_file_content = """exports_files(glob(["bin/*"]))""",
        nixopts = nixopts,
    )

    # Following lines should match
    # https://github.com/bazelbuild/bazel/blob/master/tools/cpp/cc_configure.bzl#L93.
    nixpkgs_cc_autoconf(name = "local_config_cc")
    native.bind(name = "cc_toolchain", actual = "@local_config_cc//:toolchain")
    native.register_toolchains("@local_config_cc//:all")

def _execute_or_fail(repository_ctx, arguments, failure_message = "", *args, **kwargs):
    """Call repository_ctx.execute() and fail if non-zero return code."""
    result = repository_ctx.execute(arguments, *args, **kwargs)
    if result.return_code:
        outputs = dict(
            failure_message = failure_message,
            arguments = arguments,
            return_code = result.return_code,
            stderr = result.stderr,
        )
        fail("""
{failure_message}
Command: {arguments}
Return code: {return_code}
Error output:
{stderr}
""".format(**outputs))
    return result

def _find_children(repository_ctx, target_dir):
    find_args = [
        _executable_path(repository_ctx, "find"),
        "-L",
        target_dir,
        "-maxdepth",
        "1",
        # otherwise the directory is printed as well
        "-mindepth",
        "1",
        # filenames can contain \n
        "-print0",
    ]
    exec_result = _execute_or_fail(repository_ctx, find_args)
    return exec_result.stdout.rstrip("\0").split("\0")

def _executable_path(repository_ctx, exe_name, extra_msg = ""):
    """Try to find the executable, fail with an error."""
    path = repository_ctx.which(exe_name)
    if path == None:
        fail("Could not find the `{}` executable in PATH.{}\n"
            .format(exe_name, " " + extra_msg if extra_msg else ""))
    return path

def _cp(repository_ctx, src, dest = None):
    """Copy the given file into the external repository root.

    Args:
      repository_ctx: The repository context of the current repository rule.
      src: The source file. Must be a Label if dest is None.
      dest: Optional, The target path within the current repository root.
        By default the relative path to the repository root is preserved.

    Returns:
      The absolute target path.
    """
    if dest == None:
        if type(src) != "Label":
            fail("src must be a Label if dest is not specified explicitly.")
        dest = "/".join([
            component
            for component in [src.workspace_root, src.package, src.name]
            if component
        ])
    repository_ctx.template(dest, src, executable = False)
    return repository_ctx.path(dest)
