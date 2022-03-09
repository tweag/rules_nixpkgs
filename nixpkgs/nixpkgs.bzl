"""Rules for importing Nixpkgs packages."""

load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "get_cpu_value",
)
load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    _nixpkgs_git_repository = "nixpkgs_git_repository",
    _nixpkgs_local_repository = "nixpkgs_local_repository",
    _nixpkgs_package = "nixpkgs_package",
)
load("@bazel_tools//tools/cpp:cc_configure.bzl", "cc_autoconf_impl")
load(
    "@rules_nixpkgs_core//:util.bzl",
    "execute_or_fail",
    "find_children",
    "is_supported_platform",
)
load(
    "//toolchains/python:python.bzl",
    _nixpkgs_python_configure = "nixpkgs_python_configure",
)
load(
    "//toolchains/java:java.bzl",
    _nixpkgs_java_configure = "nixpkgs_java_configure",
)
load(
    "@rules_nixpkgs_cc//:cc.bzl",
    _nixpkgs_cc_configure = "nixpkgs_cc_configure",
)

# aliases for backwards compatibility prior to `bzlmod`
nixpkgs_git_repository = _nixpkgs_git_repository
nixpkgs_local_repository = _nixpkgs_local_repository
nixpkgs_package = _nixpkgs_package
nixpkgs_python_configure = _nixpkgs_python_configure
nixpkgs_java_configure = _nixpkgs_java_configure
nixpkgs_cc_configure = _nixpkgs_cc_configure

def nixpkgs_cc_autoconf_impl(repository_ctx):
    cpu_value = get_cpu_value(repository_ctx)
    if not is_supported_platform(repository_ctx):
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
    workspace_root = execute_or_fail(
        repository_ctx,
        ["dirname", workspace_file_path],
    ).stdout.rstrip()

    # Make a list of all available tools in the Nix derivation. Override
    # the Bazel autoconfiguration with the tools we found.
    bin_contents = find_children(repository_ctx, workspace_root + "/bin")
    overriden_tools = {
        tool: repository_ctx.path(entry).realpath
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

def nixpkgs_cc_configure_deprecated(
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = []):
    """Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

    Tells Bazel to use compilers and linkers from Nixpkgs for the CC toolchain.
    By default, Bazel auto-configures a CC toolchain from commands available in
    the environment (e.g. `gcc`). Overriding this autodetection makes builds
    more hermetic and is considered a best practice.

    #### Example

      ```bzl
      nixpkgs_cc_configure(repository = "@nixpkgs//:default.nix")
      ```

    Args:
      repository: A repository label identifying which Nixpkgs to use.
        Equivalent to `repositories = { "nixpkgs": ...}`.
      repositories: A dictionary mapping `NIX_PATH` entries to repository labels.

        Setting it to
        ```
        repositories = { "myrepo" : "//:myrepo" }
        ```
        for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

        Specify one of `repository` or `repositories`.
      nix_file: An expression for a Nix environment derivation.
        The environment should expose all the commands that make up a CC
        toolchain (`cc`, `ld` etc). Exposes all commands in `stdenv.cc` and
        `binutils` by default.
      nix_file_deps: Dependencies of `nix_file` if any.
      nix_file_content: An expression for a Nix environment derivation.
      nixopts: Options to forward to the nix command.

    Deprecated:
      Use `nixpkgs_cc_configure` instead.

      While this improves upon Bazel's autoconfigure toolchain by picking tools
      from a Nix derivation rather than the environment, it is still not fully
      hermetic as it is affected by the environment. In particular, system
      include directories specified in the environment can leak in and affect
      the cache keys of targets depending on the cc toolchain leading to cache
      misses.
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

def nixpkgs_sh_posix_config(name, packages, **kwargs):
    nixpkgs_package(
        name = name,
        nix_file_content = """
with import <nixpkgs> {{ config = {{}}; overlays = []; }};

let
  # `packages` might include lists, e.g. `stdenv.initialPath` is a list itself,
  # so we need to flatten `packages`.
  flatten = builtins.concatMap (x: if builtins.isList x then x else [x]);
  env = buildEnv {{
    name = "posix-toolchain";
    paths = flatten [ {} ];
  }};
  cmd_glob = "${{env}}/bin/*";
  os = if stdenv.isDarwin then "osx" else "linux";
in

runCommand "bazel-nixpkgs-posix-toolchain"
  {{ executable = false;
    # Pointless to do this on a remote machine.
    preferLocalBuild = true;
    allowSubstitutes = false;
  }}
  ''
    n=$out/nixpkgs_sh_posix.bzl
    mkdir -p "$(dirname "$n")"

    cat >>$n <<EOF
    load("@rules_sh//sh:posix.bzl", "posix", "sh_posix_toolchain")
    discovered = {{
    EOF
    for cmd in ${{cmd_glob}}; do
        if [[ -x $cmd ]]; then
            echo "    '$(basename $cmd)': '$cmd'," >>$n
        fi
    done
    cat >>$n <<EOF
    }}
    def create_posix_toolchain():
        sh_posix_toolchain(
            name = "nixpkgs_sh_posix",
            cmds = {{
                cmd: discovered[cmd]
                for cmd in posix.commands
                if cmd in discovered
            }}
        )
    EOF
  ''
""".format(" ".join(packages)),
        build_file_content = """
load("//:nixpkgs_sh_posix.bzl", "create_posix_toolchain")
create_posix_toolchain()
""",
        **kwargs
    )

# Note [Target constraints for POSIX tools]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# There at least three cases for POSIX tools.
#
# Case 1) The tools are used at build time in the execution platform.
#
# Case 2) The tools are used at runtime time in the target platform
#         when the target platform is the same as the execution
#         platform.
#
# Case 3) The tools are used at runtime time in the target platform
#         when cross-compiling.
#
# At the moment, only (1) and (2) are supported by ignoring any target
# constraints when defining the toolchain. This makes available
# any tools that don't depend on the target platform like grep, find
# or sort. In case (2), the tools are still usable at runtime since
# the platforms match.
#
# POSIX tools that depend on the target platform, like cc and strip,
# are better taken from the Bazel cc toolchain instead, so they do
# match the target platform.
#
# TODO: In order to support (3), where the tools would be needed at
# runtime, nixpkgs_sh_posix_configure will need to be changed to take
# as parameter the constraints for the platform in which the tools
# should run.

def _nixpkgs_sh_posix_toolchain_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    repository_ctx.file("BUILD", executable = False, content = """
toolchain(
    name = "nixpkgs_sh_posix_toolchain",
    toolchain = "@{workspace}//:nixpkgs_sh_posix",
    toolchain_type = "@rules_sh//sh/posix:toolchain_type",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:{os}",
        "@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix",
    ],
    # Leaving the target constraints empty matter for cross-compilation.
    # See Note [Target constraints for POSIX tools]
    target_compatible_with = [],
)
    """.format(
        workspace = repository_ctx.attr.workspace,
        os = {"darwin": "osx"}.get(cpu, "linux"),
    ))

_nixpkgs_sh_posix_toolchain = repository_rule(
    _nixpkgs_sh_posix_toolchain_impl,
    attrs = {
        "workspace": attr.string(),
    },
)

def nixpkgs_sh_posix_configure(
        name = "nixpkgs_sh_posix_config",
        packages = ["stdenv.initialPath"],
        **kwargs):
    """Create a POSIX toolchain from nixpkgs.

    Loads the given Nix packages, scans them for standard Unix tools, and
    generates a corresponding `sh_posix_toolchain`.

    Make sure to call `nixpkgs_sh_posix_configure` before `sh_posix_configure`,
    if you use both. Otherwise, the local toolchain will always be chosen in
    favor of the nixpkgs one.

    Args:
      name: Name prefix for the generated repositories.
      packages: List of Nix attribute paths to draw Unix tools from.
      nix_file_deps: See nixpkgs_package.
      repositories: See nixpkgs_package.
      repository: See nixpkgs_package.
      nixopts: See nixpkgs_package.
      fail_not_supported: See nixpkgs_package.
    """
    nixpkgs_sh_posix_config(
        name = name,
        packages = packages,
        **kwargs
    )

    # The indirection is required to avoid errors when `nix-build` is not in `PATH`.
    _nixpkgs_sh_posix_toolchain(
        name = name + "_toolchain",
        workspace = name,
    )
    native.register_toolchains(
        "@{}//:nixpkgs_sh_posix_toolchain".format(name + "_toolchain"),
    )
