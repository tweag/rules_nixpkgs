<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `nixpkgs/nixpkgs.bzl` and run `bazel run //docs:update-readme` to change the project README. -->

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
* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
* [nixpkgs_cc_configure_deprecated](#nixpkgs_cc_configure_deprecated)
* [nixpkgs_java_configure](#nixpkgs_java_configure)
* [nixpkgs_python_configure](#nixpkgs_python_configure)
* [nixpkgs_go_configure](toolchains/go/README.md#nixpkgs_go_configure)
* [nixpkgs_rust_configure](#nixpkgs_rust_configure)
* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)

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


# Reference documentation

<a id="#nixpkgs_git_repository"></a>

### nixpkgs_git_repository

<pre>
nixpkgs_git_repository(<a href="#nixpkgs_git_repository-name">name</a>, <a href="#nixpkgs_git_repository-remote">remote</a>, <a href="#nixpkgs_git_repository-revision">revision</a>, <a href="#nixpkgs_git_repository-sha256">sha256</a>)
</pre>

Name a specific revision of Nixpkgs on GitHub or a local checkout.


#### Attributes

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_git_repository-name">
<td><code>name</code></td>
<td>

<a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required

<p>

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-remote">
<td><code>remote</code></td>
<td>

String; optional

<p>

The URI of the remote Git repository. This must be a HTTP URL. There is currently no support for authentication. Defaults to [upstream nixpkgs](https://github.com/NixOS/nixpkgs).

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-revision">
<td><code>revision</code></td>
<td>

String; required

<p>

Git commit hash or tag identifying the version of Nixpkgs to use.

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-sha256">
<td><code>sha256</code></td>
<td>

String; optional

<p>

The SHA256 used to verify the integrity of the repository.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_local_repository"></a>

### nixpkgs_local_repository

<pre>
nixpkgs_local_repository(<a href="#nixpkgs_local_repository-name">name</a>, <a href="#nixpkgs_local_repository-nix_file">nix_file</a>, <a href="#nixpkgs_local_repository-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_local_repository-nix_file_deps">nix_file_deps</a>)
</pre>

Create an external repository representing the content of Nixpkgs, based on a Nix expression stored locally or provided inline. One of `nix_file` or `nix_file_content` must be provided.


#### Attributes

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_local_repository-name">
<td><code>name</code></td>
<td>

<a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required

<p>

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file">
<td><code>nix_file</code></td>
<td>

<a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional

<p>

A file containing an expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

String; optional

<p>

An expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

<a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a>; optional

<p>

Dependencies of `nix_file` if any.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_cc_configure"></a>

### nixpkgs_cc_configure

<pre>
nixpkgs_cc_configure(<a href="#nixpkgs_cc_configure-name">name</a>, <a href="#nixpkgs_cc_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_cc_configure-nix_file">nix_file</a>, <a href="#nixpkgs_cc_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_cc_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_cc_configure-repositories">repositories</a>,
                     <a href="#nixpkgs_cc_configure-repository">repository</a>, <a href="#nixpkgs_cc_configure-nixopts">nixopts</a>, <a href="#nixpkgs_cc_configure-quiet">quiet</a>, <a href="#nixpkgs_cc_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_cc_configure-exec_constraints">exec_constraints</a>,
                     <a href="#nixpkgs_cc_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_cc_configure-register">register</a>)
</pre>

Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

By default, Bazel auto-configures a CC toolchain from commands (e.g.
`gcc`) available in the environment. To make builds more hermetic, use
this rule to specify explicitly which commands the toolchain should use.

Specifically, it builds a Nix derivation that provides the CC toolchain
tools in the `bin/` path and constructs a CC toolchain that uses those
tools. Tools that aren't found are replaced by `${coreutils}/bin/false`.
You can inspect the resulting `@<name>_info//:CC_TOOLCHAIN_INFO` to see
which tools were discovered.

This rule depends on [`rules_cc`](https://github.com/bazelbuild/rules_cc).

**Note:**
You need to configure `--crosstool_top=@<name>//:toolchain` to activate
this toolchain.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_cc_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"local_config_cc"</code>

</td>
</tr>
<tr id="nixpkgs_cc_configure-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

optional, string, Obtain the toolchain from the Nix expression under this attribute path. Requires `nix_file` or `nix_file_content`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

optional, Label, Obtain the toolchain from the Nix expression defined in this file. Specify only one of `nix_file` or `nix_file_content`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>""</code>

<p>

optional, string, Obtain the toolchain from the given Nix expression. Specify only one of `nix_file` or `nix_file_content`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>[]</code>

<p>

optional, list of Label, Additional files that the Nix expression depends on.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

dict of Label to string, Provides `<nixpkgs>` and other repositories. Specify one of `repositories` or `repository`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

Label, Provides `<nixpkgs>`. Specify one of `repositories` or `repository`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

optional, list of string, Extra flags to pass when calling Nix. Subject to location expansion, any instance of `$(location LABEL)` will be replaced by the path to the file ferenced by `LABEL` relative to the workspace root.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

bool, Whether to hide `nix-build` output.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

bool, Whether to fail if `nix-build` is not available.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the execution platform.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the target platform.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

<p>

bool, enabled by default, Whether to register (with `register_toolchains`) the generated toolchain and install it as the default cc_toolchain.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_cc_configure_deprecated"></a>

### nixpkgs_cc_configure_deprecated

<pre>
nixpkgs_cc_configure_deprecated(<a href="#nixpkgs_cc_configure_deprecated-repository">repository</a>, <a href="#nixpkgs_cc_configure_deprecated-repositories">repositories</a>, <a href="#nixpkgs_cc_configure_deprecated-nix_file">nix_file</a>, <a href="#nixpkgs_cc_configure_deprecated-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_cc_configure_deprecated-nix_file_content">nix_file_content</a>,
                                <a href="#nixpkgs_cc_configure_deprecated-nixopts">nixopts</a>)
</pre>

Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

Tells Bazel to use compilers and linkers from Nixpkgs for the CC toolchain.
By default, Bazel auto-configures a CC toolchain from commands available in
the environment (e.g. `gcc`). Overriding this autodetection makes builds
more hermetic and is considered a best practice.

#### Example

  ```bzl
  nixpkgs_cc_configure(repository = "@nixpkgs//:default.nix")
  ```


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_cc_configure_deprecated-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

A repository label identifying which Nixpkgs to use.
  Equivalent to `repositories = { "nixpkgs": ...}`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure_deprecated-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

A dictionary mapping `NIX_PATH` entries to repository labels.

  Setting it to
  ```
  repositories = { "myrepo" : "//:myrepo" }
  ```
  for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

  Specify one of `repository` or `repositories`.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure_deprecated-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

An expression for a Nix environment derivation.
  The environment should expose all the commands that make up a CC
  toolchain (`cc`, `ld` etc). Exposes all commands in `stdenv.cc` and
  `binutils` by default.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure_deprecated-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

<p>

Dependencies of `nix_file` if any.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure_deprecated-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

<p>

An expression for a Nix environment derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure_deprecated-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Options to forward to the nix command.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_java_configure"></a>

### nixpkgs_java_configure

<pre>
nixpkgs_java_configure(<a href="#nixpkgs_java_configure-name">name</a>, <a href="#nixpkgs_java_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_java_configure-java_home_path">java_home_path</a>, <a href="#nixpkgs_java_configure-repository">repository</a>, <a href="#nixpkgs_java_configure-repositories">repositories</a>, <a href="#nixpkgs_java_configure-nix_file">nix_file</a>,
                       <a href="#nixpkgs_java_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_java_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_java_configure-nixopts">nixopts</a>, <a href="#nixpkgs_java_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_java_configure-quiet">quiet</a>, <a href="#nixpkgs_java_configure-toolchain">toolchain</a>,
                       <a href="#nixpkgs_java_configure-toolchain_name">toolchain_name</a>, <a href="#nixpkgs_java_configure-toolchain_version">toolchain_version</a>, <a href="#nixpkgs_java_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_java_configure-target_constraints">target_constraints</a>)
</pre>

Define a Java runtime provided by nixpkgs.

Creates a `nixpkgs_package` for a `java_runtime` instance. Optionally,
you can also create & register a Java toolchain. This only works with Bazel >= 5.0
Bazel can use this instance to run JVM binaries and tests, refer to the
[Bazel documentation](https://docs.bazel.build/versions/4.0.0/bazel-and-java.html#configuring-the-jdk) for details.

#### Example

##### Bazel 4

Add the following to your `WORKSPACE` file to import a JDK from nixpkgs:
```bzl
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_java_configure")
nixpkgs_java_configure(
    attribute_path = "jdk11.home",
    repository = "@nixpkgs",
)
```

Add the following configuration to `.bazelrc` to enable this Java runtime:
```
build --javabase=@nixpkgs_java_runtime//:runtime
build --host_javabase=@nixpkgs_java_runtime//:runtime
# Adjust this to match the Java version provided by this runtime.
# See `bazel query 'kind(java_toolchain, @bazel_tools//tools/jdk:all)'` for available options.
build --java_toolchain=@bazel_tools//tools/jdk:toolchain_java11
build --host_java_toolchain=@bazel_tools//tools/jdk:toolchain_java11
```

##### Bazel 5

Add the following to your `WORKSPACE` file to import a JDK from nixpkgs:
```bzl
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_java_configure")
nixpkgs_java_configure(
    attribute_path = "jdk11.home",
    repository = "@nixpkgs",
    toolchain = True,
    toolchain_name = "nixpkgs_java",
    toolchain_version = "11",
)
```

Add the following configuration to `.bazelrc` to enable this Java runtime:
```
build --host_platform=@io_tweag_rules_nixpkgs//nixpkgs/platforms:host
build --java_runtime_version=nixpkgs_java
build --tool_java_runtime_version=nixpkgs_java
```


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_java_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_java_runtime"</code>

<p>

The name-prefix for the created external repositories.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>None</code>

<p>

string, The nixpkgs attribute path for `jdk.home`.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-java_home_path">
<td><code>java_home_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

optional, string, The path to `JAVA_HOME` within the package.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repository).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repositories).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

optional, Label, Obtain the runtime from the Nix expression defined in this file. Specify only one of `nix_file` or `nix_file_content`.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>""</code>

<p>

optional, string, Obtain the runtime from the given Nix expression. Specify only one of `nix_file` or `nix_file_content`.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nix_file_deps).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nixopts).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-fail_not_supported).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-quiet).

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-toolchain">
<td><code>toolchain</code></td>
<td>

optional.
default is <code>False</code>

<p>

Create & register a Bazel toolchain based on the Java runtime.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-toolchain_name">
<td><code>toolchain_name</code></td>
<td>

optional.
default is <code>None</code>

<p>

The name of the toolchain that can be used in --java_runtime_version.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-toolchain_version">
<td><code>toolchain_version</code></td>
<td>

optional.
default is <code>None</code>

<p>

The version of the toolchain that can be used in --java_runtime_version.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the execution platform.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the target platform.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_package"></a>

### nixpkgs_package

<pre>
nixpkgs_package(<a href="#nixpkgs_package-name">name</a>, <a href="#nixpkgs_package-attribute_path">attribute_path</a>, <a href="#nixpkgs_package-nix_file">nix_file</a>, <a href="#nixpkgs_package-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_package-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_package-repository">repository</a>,
                <a href="#nixpkgs_package-repositories">repositories</a>, <a href="#nixpkgs_package-build_file">build_file</a>, <a href="#nixpkgs_package-build_file_content">build_file_content</a>, <a href="#nixpkgs_package-nixopts">nixopts</a>, <a href="#nixpkgs_package-quiet">quiet</a>, <a href="#nixpkgs_package-fail_not_supported">fail_not_supported</a>,
                <a href="#nixpkgs_package-kwargs">kwargs</a>)
</pre>

Make the content of a Nixpkgs package available in the Bazel workspace.

If `repositories` is not specified, you must provide a nixpkgs clone in `nix_file` or `nix_file_content`.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_package-name">
<td><code>name</code></td>
<td>

required.

<p>

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_package-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

Select an attribute from the top-level Nix expression being evaluated. The attribute path is a sequence of attribute names separated by dots.

</p>
</td>
</tr>
<tr id="nixpkgs_package-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

A file containing an expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_package-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Dependencies of `nix_file` if any.

</p>
</td>
</tr>
<tr id="nixpkgs_package-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>""</code>

<p>

An expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_package-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`

</p>
</td>
</tr>
<tr id="nixpkgs_package-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

A dictionary mapping `NIX_PATH` entries to repository labels.

  Setting it to
  ```
  repositories = { "myrepo" : "//:myrepo" }
  ```
  for example would replace all instances of `<myrepo>` in the called nix code by the path to the target `"//:myrepo"`. See the [relevant section in the nix manual](https://nixos.org/nix/manual/#env-NIX_PATH) for more information.

  Specify one of `repository` or `repositories`.

</p>
</td>
</tr>
<tr id="nixpkgs_package-build_file">
<td><code>build_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

The file to use as the BUILD file for this repository.

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

</p>
</td>
</tr>
<tr id="nixpkgs_package-build_file_content">
<td><code>build_file_content</code></td>
<td>

optional.
default is <code>""</code>

<p>

Like `build_file`, but a string of the contents instead of a file name.

</p>
</td>
</tr>
<tr id="nixpkgs_package-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Extra flags to pass when calling Nix.

</p>
</td>
</tr>
<tr id="nixpkgs_package-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

Whether to hide the output of the Nix command.

</p>
</td>
</tr>
<tr id="nixpkgs_package-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.

</p>
</td>
</tr>
<tr id="nixpkgs_package-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_python_configure"></a>

### nixpkgs_python_configure

<pre>
nixpkgs_python_configure(<a href="#nixpkgs_python_configure-name">name</a>, <a href="#nixpkgs_python_configure-python2_attribute_path">python2_attribute_path</a>, <a href="#nixpkgs_python_configure-python2_bin_path">python2_bin_path</a>, <a href="#nixpkgs_python_configure-python3_attribute_path">python3_attribute_path</a>,
                         <a href="#nixpkgs_python_configure-python3_bin_path">python3_bin_path</a>, <a href="#nixpkgs_python_configure-repository">repository</a>, <a href="#nixpkgs_python_configure-repositories">repositories</a>, <a href="#nixpkgs_python_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_python_configure-nixopts">nixopts</a>,
                         <a href="#nixpkgs_python_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_python_configure-quiet">quiet</a>, <a href="#nixpkgs_python_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_python_configure-target_constraints">target_constraints</a>)
</pre>

Define and register a Python toolchain provided by nixpkgs.

Creates `nixpkgs_package`s for Python 2 or 3 `py_runtime` instances and a
corresponding `py_runtime_pair` and `toolchain`. The toolchain is
automatically registered and uses the constraint:

```
"@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix"
```


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_python_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_python_toolchain"</code>

<p>

The name-prefix for the created external repositories.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-python2_attribute_path">
<td><code>python2_attribute_path</code></td>
<td>

optional.
default is <code>None</code>

<p>

The nixpkgs attribute path for python2.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-python2_bin_path">
<td><code>python2_bin_path</code></td>
<td>

optional.
default is <code>"bin/python"</code>

<p>

The path to the interpreter within the package.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-python3_attribute_path">
<td><code>python3_attribute_path</code></td>
<td>

optional.
default is <code>"python3"</code>

<p>

The nixpkgs attribute path for python3.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-python3_bin_path">
<td><code>python3_bin_path</code></td>
<td>

optional.
default is <code>"bin/python"</code>

<p>

The path to the interpreter within the package.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repository).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repositories).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nix_file_deps).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nixopts).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-fail_not_supported).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-quiet).

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the execution platform.

</p>
</td>
</tr>
<tr id="nixpkgs_python_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the target platform.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_rust_configure"></a>

### nixpkgs_rust_configure

<pre>
nixpkgs_rust_configure(<a href="#nixpkgs_rust_configure-name">name</a>, <a href="#nixpkgs_rust_configure-default_edition">default_edition</a>, <a href="#nixpkgs_rust_configure-repository">repository</a>, <a href="#nixpkgs_rust_configure-repositories">repositories</a>, <a href="#nixpkgs_rust_configure-nix_file">nix_file</a>, <a href="#nixpkgs_rust_configure-nix_file_deps">nix_file_deps</a>,
                       <a href="#nixpkgs_rust_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_rust_configure-nixopts">nixopts</a>, <a href="#nixpkgs_rust_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_rust_configure-quiet">quiet</a>, <a href="#nixpkgs_rust_configure-exec_constraints">exec_constraints</a>,
                       <a href="#nixpkgs_rust_configure-target_constraints">target_constraints</a>)
</pre>



#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_rust_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_rust"</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-default_edition">
<td><code>default_edition</code></td>
<td>

optional.
default is <code>"2018"</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_rust_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_sh_posix_configure"></a>

### nixpkgs_sh_posix_configure

<pre>
nixpkgs_sh_posix_configure(<a href="#nixpkgs_sh_posix_configure-name">name</a>, <a href="#nixpkgs_sh_posix_configure-packages">packages</a>, <a href="#nixpkgs_sh_posix_configure-kwargs">kwargs</a>)
</pre>

Create a POSIX toolchain from nixpkgs.

Loads the given Nix packages, scans them for standard Unix tools, and
generates a corresponding `sh_posix_toolchain`.

Make sure to call `nixpkgs_sh_posix_configure` before `sh_posix_configure`,
if you use both. Otherwise, the local toolchain will always be chosen in
favor of the nixpkgs one.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_sh_posix_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_sh_posix_config"</code>

<p>

Name prefix for the generated repositories.

</p>
</td>
</tr>
<tr id="nixpkgs_sh_posix_configure-packages">
<td><code>packages</code></td>
<td>

optional.
default is <code>["stdenv.initialPath"]</code>

<p>

List of Nix attribute paths to draw Unix tools from.

</p>
</td>
</tr>
<tr id="nixpkgs_sh_posix_configure-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

</td>
</tr>
</tbody>
</table>


