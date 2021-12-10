<!-- Edit docs/README.md.tpl and run `bazel run //docs:update-readme` to change the project README. -->

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

## Rules

* [nixpkgs_git_repository](#nixpkgs_git_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)
* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
* [nixpkgs_cc_configure_deprecated](#nixpkgs_cc_configure_deprecated)
* [nixpkgs_java_configure](#nixpkgs_java_configure)
* [nixpkgs_python_configure](#nixpkgs_python_configure)
* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)
* [nixpkgs_go_configure](#nixpkgs_go_configure)

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

If you use `rules_nixpkgs` to configure a toolchain then you will also need to
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

## Rules

{{nixpkgs}}

{{toolchains_go}}

## Migration

### `path` Attribute

`path` was an attribute from the early days of `rules_nixpkgs`, and
its ability to reference arbitrary paths a danger to build hermeticity.

Replace it with either `nixpkgs_git_repository` if you need
a specific version of `nixpkgs`. If you absolutely *must* depend on a
local folder, use bazel’s
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
  …
)
```
