"""Rules for importing Nixpkgs packages."""

load("@bazel_tools//tools/cpp:cc_configure.bzl", "cc_autoconf_impl")
load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

def python(repository_ctx):
    if "BAZEL_PYTHON" in repository_ctx.os.environ:
        return repository_ctx.os.environ.get("BAZEL_PYTHON")

    python_path = repository_ctx.which("python2")
    if not python_path:
        python_path = repository_ctx.which("python")
    if not python_path:
        python_path = repository_ctx.which("python.exe")
    if python_path:
        return python_path

def _explode_package_definitions(packages):
    """ Explode the given dict of dicts defining a set of packages into
    three flat dicts because we can't pass nested dicts to bazel rules
    """
    # Bazel doesn't allow us to pass anything more complex than a
    # ``Dict[string, string]`` for the arguments of a rule, but our package set
    # is a ``Dict[string, Dict[…]]``, so we first transform it into several
    # ``Dict[string, string]`` (according to how the package is defined) to
    # pass them to the ``nixpkgs_packages_instantiate`` rule
    packagesFromAttr = {}
    packagesFromFile = {}
    packagesFromExpr = {}
    for (packageName, value) in packages.items():
        is_defined = False
        if hasAttr(value, "nix_file"):
          packagesFromFile[packageName] = value["nix_file"]
          is_defined = True
        if hasAttr(value, "nix_file_content"):
          packagesFromExpr[packageName] = value["nix_file_content"]
          is_defined = True
        if hasAttr(value, "attribute_path"):
          packagesFromAttr[packageName] = value["attribute_path"]
          is_defined = True
        # If neither a nix file nor an attribute path is specified,
        # assume that the attribute path is equal to the name
        if not is_defined:
          packagesFromAttr[packageName] = packageName
    return {
      "fromAttr": packagesFromAttr,
      "fromFile": packagesFromFile,
      "fromExpr": packagesFromExpr
    }

def _implode_packages_defs(fromFile, fromExpr, fromAttr):
    """Inverse of _explode_package_definitions"""
    combined_packageset = {}
    for package in fromFile.keys() + fromExpr.keys() + fromAttr.keys():
        combined_packageset[package] = {}
        if package in fromFile:
            combined_packageset[package]["nix_file"] = fromFile[package]
        if package in fromAttr:
            combined_packageset[package]["attribute_path"] = fromAttr[package]
        if package in fromExpr:
            combined_packageset[package]["nix_file_content"] = fromExpr[package]
    return combined_packageset


def buildNixExpr(ctx, name, nix_file = None, nix_file_content = None, attribute_path = None):
    """Build a nix expression defining the given package
    """
    if nix_file != None:
        defining_expr = "(import \"{}\")".format(ctx.path(nix_file))
    elif nix_file_content != None:
        generated_nix_file = "__internal_" + name + "_definition.nix"
        ctx.file(
            generated_nix_file,
            content = nix_file_content
            )
        defining_expr = "(import ./{})".format(generated_nix_file)
    else:
        defining_expr = "nixpkgs"

    if attribute_path == None:
        raw_access_path = ""
    else:
        raw_access_path = ".{}".format(attribute_path)
    return (defining_expr + raw_access_path)

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
        target = repository_ctx.path(repository_ctx.attr.nix_file)
        repository_ctx.symlink(target, target.basename)

    # Make "@nixpkgs" (syntactic sugar for "@nixpkgs//:nixpkgs") a valid
    # label for the target Nix file.
    repository_ctx.symlink(target.basename, repository_ctx.name)

    _symlink_nix_file_deps(repository_ctx, repository_ctx.attr.nix_file_deps)

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

def nixpkgs_package(
    name,
    repositories = None,
    repository = None,
    nixopts = [],
    **kwargs
    ):
  nixpkgs_packages(
      name = name + "__drvfile",
      repository = repository,
      repositories = repositories,
      nixopts = nixopts,
      packages = {
          name: dict(
              nixops = nixopts,
              **kwargs
            ),
          }
  )

def invert_dict(dict):
    """Swap the keys and values of a dict − assuming that all values are
    distinct
    """
    return {value: key for (key, value) in dict.items()}

def invert_repositories(f, *args, **kwargs):
    # Because of https://github.com/bazelbuild/bazel/issues/5356 we can't
    # directly pass a dict from strings to labels to the rule (which we'd like
    # for the `repositories` arguments), but we can pass a dict from labels to
    # strings. So we swap the keys and the values (assuming they all are
    # distinct).
    hasRepository = "repository" in kwargs and kwargs["repository"] != None
    hasRepositories = "repositories" in kwargs and kwargs["repositories"] != None
    if hasRepository and hasRepositories:
        fail("Specify one of 'repository' or 'repositories' (but not both).")
    if hasRepositories:
        inversed_repositories = invert_dict(kwargs["repositories"])
        kwargs["repositories"] = inversed_repositories
    if hasRepository:
        repository = kwargs.pop("repository")
        kwargs["repositories"] = { repository: "nixpkgs" }
    f(*args, **kwargs)

def _readlink(repository_ctx, path):
    return repository_ctx.path(path).realpath

def _generate_mappings(repository_ctx, packagesFromExpr, packagesFromFile, packagesFromAttr):

    all_packages = _implode_packages_defs(
        fromFile = packagesFromFile,
        fromExpr = packagesFromExpr,
        fromAttr = packagesFromAttr,
    )

    nix_package_defs = \
        [
            "\"{name}\" = {definingExpr};".format(
                name = name,
                definingExpr = buildNixExpr(repository_ctx, name, **package_def)
                )
            for (name, package_def) in all_packages.items()
        ]

    packages_record_inside = " ".join(nix_package_defs)
    packages_record = "nixpkgs: { " + packages_record_inside + " }"

    file_name = "packages_attributes_mappings.nix"
    repository_ctx.file(file_name, packages_record)
    return file_name

def _nixpkgs_packages_instantiate_swapped_impl(repository_ctx):
    # Is nix supported on this platform?
    not_supported = not _is_supported_platform(repository_ctx)
    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    repository_ctx.file("BUILD", """exports_files(glob(["*"]))""")

    if not_supported and fail_not_supported:
        fail("Platform is not supported (see 'fail_not_supported')")
    elif not_supported:
        return

    nix_instantiate_path = _executable_path(
        repository_ctx,
        "nix-instantiate",
        extra_msg = "See: https://nixos.org/nix/",
    )

    packages_attributes_mappings = _generate_mappings(
        repository_ctx,
        repository_ctx.attr.packagesFromExpr,
        invert_dict(repository_ctx.attr.packagesFromFileSwapped),
        repository_ctx.attr.packagesFromAttr
    )

    nix_set_builder = repository_ctx.template("drv_set_builder.nix", Label("@io_tweag_rules_nixpkgs//nixpkgs:drv_set_builder.nix"))
    nix_instantiate_args = [
        "--eval",
        "--strict", # Ensure that everything is instantiated
        "--read-write-mode", # Allow writing the drv files to the store
        "--json",
        "drv_set_builder.nix",
        "--arg", "packages", "import ./{}".format(packages_attributes_mappings),
        ]

    nix_instantiate = [nix_instantiate_path] + \
        nix_instantiate_args + \
        repository_ctx.attr.nixopts

    # Large enough integer that Bazel can still parse. We don't have
    # access to MAX_INT and 0 is not a valid timeout so this is as good
    # as we can do.
    timeout = 1073741824

    nix_path = ":".join(
        [
            (path_name + "=" + str(repository_ctx.path(target)))
            for (target, path_name) in repository_ctx.attr.repositories.items()
        ],
    )

    exec_result = _execute_or_fail(
        repository_ctx,
        nix_instantiate,
        timeout = timeout,
        environment = dict(NIX_PATH = nix_path),
    )
    repository_ctx.file("nix_attrs.nix", content = exec_result.stdout)

    _execute_or_fail(
        repository_ctx,
        [ python(repository_ctx)
        , repository_ctx.path(repository_ctx.attr._json_to_files)
        , "."
        , "nix_attrs.nix"
        ]
    )

nixpkgs_packages_instantiate_swapped = repository_rule(
    implementation = _nixpkgs_packages_instantiate_swapped_impl,
    attrs = {
        "packagesFromAttr": attr.string_dict(
            mandatory = False,
            doc = "A map between the name of the packages to instantiate and their attribute path in the nix expression",
        ),
        "packagesFromFileSwapped": attr.label_keyed_string_dict(
            mandatory = False,
            doc = "A map between the name of the packages to instantiate and a nix file defining them",
        ),
        "packagesFromExpr": attr.string_dict(
            mandatory = False,
            doc = "A map between the name of the packages to instantiate and their nix expression",
        ),
        "repositories": attr.label_keyed_string_dict(),
        "nixopts": attr.string_list(doc = """
            Extra options to pass to "nix-instantiate"
            """),
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
        """),
        "_json_to_files": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "host",
            default = Label("@io_tweag_rules_nixpkgs//nixpkgs:json_to_files.py"),
        ),
    },
)

def nixpkgs_packages_instantiate(packagesFromFile = None, **kwargs):
    packagesFromFileSwapped = invert_dict(packagesFromFile) \
        if packagesFromFile != None else None
    invert_repositories(
        nixpkgs_packages_instantiate_swapped,
        packagesFromFileSwapped = packagesFromFileSwapped,
        **kwargs
    )

def _nixpkgs_package_realize_impl(repository_ctx):
    # Is nix supported on this platform?
    not_supported = not _is_supported_platform(repository_ctx)
    # Should we fail if Nix is not supported?
    fail_not_supported = repository_ctx.attr.fail_not_supported

    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")
    elif repository_ctx.attr.build_file:
        repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD")
    elif repository_ctx.attr.build_file_content:
        repository_ctx.file("BUILD", content = repository_ctx.attr.build_file_content)
    else:
        repository_ctx.template("BUILD", Label("@io_tweag_rules_nixpkgs//nixpkgs:BUILD.pkg"))

    if not_supported and fail_not_supported:
        fail("Platform is not supported (see 'fail_not_supported')")
    elif not_supported:
        return

    nix_store_path = _executable_path(
        repository_ctx,
        "nix-store",
        extra_msg = "See: https://nixos.org/nix/",
    )

    drv_path = _execute_or_fail(
        repository_ctx,
        ["cat", repository_ctx.path(repository_ctx.attr.drv_pointer)],
        quiet = True,
    ).stdout.strip("\"\n")

    nix_store_args = [
        "--realize",
        "--no-build-output",
        # Add a root to avoid this being garbage-collected.
        # This root will have the same lifetime as the bazel cache for this
        # target, so if we `bazel clean` it will be deleted
        "--add-root", "nix-root", "--indirect",
        drv_path
        ] + repository_ctx.attr.nixopts
    exec_result = _execute_or_fail(
        repository_ctx,
        [nix_store_path] + nix_store_args,
        quiet = True,
    )
    output_path = exec_result.stdout.splitlines()[0]

    # Build a forest of symlinks (like new_local_package() does) to the
    # Nix store.
    for target in _find_children(repository_ctx, output_path):
        basename = target.rpartition("/")[-1]
        repository_ctx.symlink(target, basename)


nixpkgs_package_realize = repository_rule(
    implementation = _nixpkgs_package_realize_impl,
    attrs = {
        "drv_pointer": attr.label(
            allow_single_file = True,
            doc = "A file containing the path to the drv file",
        ),
        "attribute_name": attr.string(),
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "nixopts": attr.string_list(doc = """
            Extra options to pass to "nix-store"
        """),
        "fail_not_supported": attr.bool(default = True, doc = """
            If set to True (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to False calling this rule will succeed but no output will be generated.
        """),
    },
)

def hasAttr (item, attrName):
    """
    Checks whether the given item is a record with the given field set to
    non-None
    """
    return type(item) == type({}) and \
        attrName in item and \
        item[attrName] != None

def nixpkgs_packages(
    name,
    packages,
    repositories = None,
    repository = None,
    nixopts = [],
    ):
    """
    Defines a set of targets pointing to multiple nixpkgs packages at once.

    For each `(name, package)` pair in `packages`, this macro will define a
    `@package` external repository pointing to the nix package `package`.

    This is equivalent (but faster) to calling several times nixpkgs_package.

    Keyword arguments:
    name: The base name for the generated repository containing the nix
      definitions packages: A dict associating each package name to its
      definition, which itself is a dict which can contain
      - `nix_file`: Path to a nix file defining the package
      - `nix_file_content`: Nix expression defining the package
      - `attribute_path`: Path to the package in `<nixpkgs>`.
      - `build_file`: Path to a `BUILD` file used when importing the package
        into bazel
      - `build_file_content`: Similar to `build_file`, but directly specify the
        content of the file

      As a shortcut, the definition can also be a raw string `s`, which is
      equivalent to `{"attribute_path": s}`
    """

    # We allow defining a package as a string, which is a shortcut for just
    # defining its ``attribute_path`` field.
    # To remove this particular case, we first desugar it
    desugared_packages = {}
    for (packageName, value) in packages.items():
        if type(value) == type(""):
            desugared_packages[packageName] = { "attribute_path": value }
        else:
            desugared_packages[packageName] = value

    exploded_packages = _explode_package_definitions(desugared_packages)

    # Instantiate the package set (*i.e* evaluate the nix expressions, but
    # without building anything)
    nixpkgs_packages_instantiate(
        name = name,
        repositories = repositories,
        repository = repository,
        packagesFromAttr = exploded_packages["fromAttr"],
        packagesFromFile = exploded_packages["fromFile"],
        packagesFromExpr = exploded_packages["fromExpr"],
        nixopts = nixopts,
    )

    # Define a new repository for each package containing a link to the
    # realized package
    for (package_name, package_value) in desugared_packages.items():
        nixpkgs_package_realize(
            name = package_name,
            attribute_name = package_name,
            drv_pointer = "@" + name + "//:" + package_name,
            build_file_content = package_value.get("build_file_content"),
            build_file = package_value.get("build_file"),
            nixopts = nixopts,
        )

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
        repositories = None,
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
          with import <nixpkgs> {}; buildEnv {
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

def _execute_or_fail(repository_ctx, arguments, environment = {}, failure_message = "", *args, **kwargs):
    """Call repository_ctx.execute() and fail if non-zero return code."""
    result = repository_ctx.execute(arguments, environment = environment, *args, **kwargs)
    if result.return_code:
        outputs = dict(
            failure_message = failure_message,
            environment = environment,
            arguments = arguments,
            return_code = result.return_code,
            stderr = result.stderr,
        )
        fail("""
{failure_message}
Command: {arguments}
Environment: {environment}
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

def _symlink_nix_file_deps(repository_ctx, deps):
    """Introduce an artificial dependency with a bogus name on each input."""
    for dep in deps:
        components = [c for c in [dep.workspace_root, dep.package, dep.name] if c]
        link = "/".join(components).replace("_", "_U").replace("/", "_S")
        repository_ctx.symlink(dep, link)
