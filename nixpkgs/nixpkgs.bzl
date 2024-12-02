"""<!-- Edit the docstring in `nixpkgs/nixpkgs.bzl` and run `bazel run @rules_nixpkgs_docs//:update-readme` to change the project README. -->

# Nixpkgs rules for Bazel

[![Continuous integration](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml/badge.svg?event=schedule)](https://github.com/tweag/rules_nixpkgs/actions/workflows/workflow.yaml)

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
* [nixpkgs_http_repository](#nixpkgs_http_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)
* [nixpkgs_flake_package](#nixpkgs_flake_package)
* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
* [nixpkgs_java_configure](#nixpkgs_java_configure)
* [nixpkgs_python_configure](#nixpkgs_python_configure)
* [nixpkgs_python_repository](#nixpkgs_python_repository)
* [nixpkgs_go_configure](toolchains/go/README.md#nixpkgs_go_configure)
* [nixpkgs_rust_configure](#nixpkgs_rust_configure)
* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)
* [nixpkgs_nodejs_configure](#nixpkgs_nodejs_configure)

## Setup

Add the following to your `WORKSPACE` file, and select a `$COMMIT` accordingly.

```bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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
`@rules_nixpkgs_core//constraints:support_nix` constraint. For
example by adding the following to `.bazelrc`:

```
build --host_platform=@rules_nixpkgs_core//platforms:host
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
    "@rules_nixpkgs_core//:private/cc_toolchain/lib_cc_configure.bzl",
    "get_cpu_value",
)
load(
    "@rules_nixpkgs_cc//:cc.bzl",
    _nixpkgs_cc_configure = "nixpkgs_cc_configure",
)
load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    _nixpkgs_flake_package = "nixpkgs_flake_package",
    _nixpkgs_git_repository = "nixpkgs_git_repository",
    _nixpkgs_http_repository = "nixpkgs_http_repository",
    _nixpkgs_local_repository = "nixpkgs_local_repository",
    _nixpkgs_package = "nixpkgs_package",
)
load(
    "@rules_nixpkgs_core//:util.bzl",
    "execute_or_fail",
    "find_children",
    "is_supported_platform",
)
load(
    "@rules_nixpkgs_java//:java.bzl",
    _nixpkgs_java_configure = "nixpkgs_java_configure",
)
load(
    "@rules_nixpkgs_nodejs//:nodejs.bzl",
    _nixpkgs_nodejs_configure = "nixpkgs_nodejs_configure",
    _nixpkgs_nodejs_configure_platforms = "nixpkgs_nodejs_configure_platforms",
)
load(
    "@rules_nixpkgs_posix//:posix.bzl",
    _nixpkgs_sh_posix_configure = "nixpkgs_sh_posix_configure",
)
load(
    "@rules_nixpkgs_python//:python.bzl",
    _nixpkgs_python_configure = "nixpkgs_python_configure",
    _nixpkgs_python_repository = "nixpkgs_python_repository",
)
load(
    "@rules_nixpkgs_rust//:rust.bzl",
    _nixpkgs_rust_configure = "nixpkgs_rust_configure",
)

# aliases for backwards compatibility prior to `bzlmod`
nixpkgs_git_repository = _nixpkgs_git_repository
nixpkgs_http_repository = _nixpkgs_http_repository
nixpkgs_local_repository = _nixpkgs_local_repository
nixpkgs_package = _nixpkgs_package
nixpkgs_flake_package = _nixpkgs_flake_package
nixpkgs_python_configure = _nixpkgs_python_configure
nixpkgs_python_repository = _nixpkgs_python_repository
nixpkgs_java_configure = _nixpkgs_java_configure
nixpkgs_cc_configure = _nixpkgs_cc_configure
nixpkgs_rust_configure = _nixpkgs_rust_configure
nixpkgs_sh_posix_configure = _nixpkgs_sh_posix_configure
nixpkgs_nodejs_configure = _nixpkgs_nodejs_configure
nixpkgs_nodejs_configure_platforms = _nixpkgs_nodejs_configure_platforms
