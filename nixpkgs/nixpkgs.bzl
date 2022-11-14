"""<!-- Edit the docstring in `nixpkgs/nixpkgs.bzl` and run `bazel run //docs:update-readme` to change the project README. -->

# Nixpkgs rules for Bazel

[![Continuous integration](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml/badge.svg)](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml)

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
[youtube-bazel-nix]: https://www.youtube.com/watch?v=7-K_RmDasEg&t=2030s

See [examples](/examples/toolchains) for how to use `rules_nixpkgs` with different toolchains.

## Rules

* [nixpkgs_git_repository](#nixpkgs_git_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)
* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
* [nixpkgs_cc_configure_deprecated](#nixpkgs_cc_configure_deprecated)
* [nixpkgs_java_configure](#nixpkgs_java_configure)
* [nixpkgs_python_configure](#nixpkgs_python_configure)
* [nixpkgs_go_configure](toolchains/go/README.md#nixpkgs_go_configure)
* [nixpkgs_rust_configure](#nixpkgs_rust_configure)
* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)
* [nixpkgs_nodejs_configure](#nixpkgs_nodejs_configure)

## Setup

Add the following to your `WORKSPACE` file, and select a `$COMMIT` accordingly.

```bzl
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-$COMMIT",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/$COMMIT.tar.gz"],
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package", "nixpkgs_cc_configure")

load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_configure") # optional
```

If you use `rules_nixpkgs` to configure a toolchain, then you will also need to
configure the build platform to include the
`@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix` constraint. For
example by adding the following to `.bazelrc`:

```
build --host_platform=@io_tweag_rules_nixpkgs//nixpkgs/platforms:host
```

## Example

```bzl
nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "17.09", # Any tag or commit hash
    sha256 = "" # optional sha to verify package integrity!
)

nixpkgs_package(
    name = "hello",
    repositories = { "nixpkgs": "@nixpkgs//:default.nix" }
)
```

## Migration from older releases

### `path` Attribute (removed in 0.3)

`path` was an attribute from the early days of `rules_nixpkgs`, and
its ability to reference arbitrary paths is a danger to build hermeticity.

Replace it with either `nixpkgs_git_repository` if you need
a specific version of `nixpkgs`. If you absolutely *must* depend on a
local folder, use Bazel's
[`local_repository` workspace rule](https://docs.bazel.build/versions/master/be/workspace.html#local_repository).
Both approaches work well with the `repositories` attribute of `nixpkgs_package`.

```bzl
local_repository(
  name = "local-nixpkgs",
  path = "/path/to/nixpkgs",
)

nixpkgs_package(
  name = "somepackage",
  repositories = {
    "nixpkgs": "@local-nixpkgs//:default.nix",
  },
)
```
"""

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
    "@rules_nixpkgs_python//:python.bzl",
    _nixpkgs_python_configure = "nixpkgs_python_configure",
)
load(
    "@rules_nixpkgs_java//:java.bzl",
    _nixpkgs_java_configure = "nixpkgs_java_configure",
)
load(
    "@rules_nixpkgs_cc//:cc.bzl",
    _nixpkgs_cc_configure = "nixpkgs_cc_configure",
)
load(
    "@rules_nixpkgs_rust//:rust.bzl",
    _nixpkgs_rust_configure = "nixpkgs_rust_configure",
)
load(
    "@rules_nixpkgs_posix//:posix.bzl",
    _nixpkgs_sh_posix_configure = "nixpkgs_sh_posix_configure",
)
load(
    "@rules_nixpkgs_nodejs//:nodejs.bzl",
    _nixpkgs_nodejs_configure = "nixpkgs_nodejs_configure",
)

# aliases for backwards compatibility prior to `bzlmod`
nixpkgs_git_repository = _nixpkgs_git_repository
nixpkgs_local_repository = _nixpkgs_local_repository
nixpkgs_package = _nixpkgs_package
nixpkgs_python_configure = _nixpkgs_python_configure
nixpkgs_java_configure = _nixpkgs_java_configure
nixpkgs_cc_configure = _nixpkgs_cc_configure
nixpkgs_rust_configure = _nixpkgs_rust_configure
nixpkgs_sh_posix_configure = _nixpkgs_sh_posix_configure
nixpkgs_nodejs_configure = _nixpkgs_nodejs_configure

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
