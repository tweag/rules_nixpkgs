<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `nixpkgs/nixpkgs.bzl` and run `bazel run @rules_nixpkgs_docs//:update-readme` to change the project README. -->

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


# Reference documentation

<a id="#nixpkgs_cc_configure"></a>

### nixpkgs_cc_configure

<pre>
nixpkgs_cc_configure(<a href="#nixpkgs_cc_configure-name">name</a>, <a href="#nixpkgs_cc_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_cc_configure-nix_file">nix_file</a>, <a href="#nixpkgs_cc_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_cc_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_cc_configure-repositories">repositories</a>,
                     <a href="#nixpkgs_cc_configure-repository">repository</a>, <a href="#nixpkgs_cc_configure-nixopts">nixopts</a>, <a href="#nixpkgs_cc_configure-quiet">quiet</a>, <a href="#nixpkgs_cc_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_cc_configure-exec_constraints">exec_constraints</a>,
                     <a href="#nixpkgs_cc_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_cc_configure-register">register</a>, <a href="#nixpkgs_cc_configure-cc_lang">cc_lang</a>, <a href="#nixpkgs_cc_configure-cc_std">cc_std</a>, <a href="#nixpkgs_cc_configure-cross_cpu">cross_cpu</a>, <a href="#nixpkgs_cc_configure-apple_sdk_path">apple_sdk_path</a>)
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

If you specify the `nix_file` or `nix_file_content` argument, the CC
toolchain is discovered by evaluating the corresponding expression. In
addition, you may use the `attribute_path` argument to select an attribute
from the result of the expression to use as the CC toolchain (see example below).

If neither the `nix_file` nor `nix_file_content` argument is used, the
toolchain is discovered from the `stdenv.cc` and the `stdenv.cc.bintools`
attributes of the given `<nixpkgs>` repository.

```
# use GCC 11
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  nix_file_content = "(import <nixpkgs> {}).gcc11",
)
```
```
# use GCC 11 (same result as above)
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  attribute_path = "gcc11",
  nix_file_content = "import <nixpkgs> {}",
)
```
```
# alternate usage without specifying `nix_file` or `nix_file_content`
nixpkgs_cc_configure(
  repository = "@nixpkgs",
  attribute_path = "gcc11",
)
```
```
# use the `stdenv.cc` compiler (the default of the given @nixpkgs repository)
nixpkgs_cc_configure(
  repository = "@nixpkgs",
)
```

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

optional, string, Obtain the toolchain from the Nix expression under this attribute path. Uses default repository if no `nix_file` or `nix_file_content` is provided.

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

optional, list of string, Extra flags to pass when calling Nix. See `nixopts` attribute to `nixpkgs_package` for further details.

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
<tr id="nixpkgs_cc_configure-cc_lang">
<td><code>cc_lang</code></td>
<td>

optional.
default is <code>"c++"</code>

<p>

string, `"c++"` by default. Used to populate `CXX_FLAG` so the compiler is called in C++ mode. Can be set to `"none"` together with appropriate `copts` in the `cc_library` call: see above.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-cc_std">
<td><code>cc_std</code></td>
<td>

optional.
default is <code>"c++0x"</code>

<p>

string, `"c++0x"` by default. Used to populate `CXX_FLAG` so the compiler uses the given language standard. Can be set to `"none"` together with appropriate `copts` in the `cc_library` call: see above.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-cross_cpu">
<td><code>cross_cpu</code></td>
<td>

optional.
default is <code>""</code>

<p>

string, `""` by default. Used if you want to add a cross compilation C/C++ toolchain. Set this to the CPU architecture for the target CPU. For example x86_64, would be k8.

</p>
</td>
</tr>
<tr id="nixpkgs_cc_configure-apple_sdk_path">
<td><code>apple_sdk_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

string, `""` by default. Obtain the default nix `apple-sdk` for the toolchain form the Nix expression under this attribute path.  Uses default repository if no `nix_file` or `nix_file_content` is provided.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_flake_package"></a>

### nixpkgs_flake_package

<pre>
nixpkgs_flake_package(<a href="#nixpkgs_flake_package-name">name</a>, <a href="#nixpkgs_flake_package-nix_flake_file">nix_flake_file</a>, <a href="#nixpkgs_flake_package-nix_flake_lock_file">nix_flake_lock_file</a>, <a href="#nixpkgs_flake_package-nix_flake_file_deps">nix_flake_file_deps</a>,
                      <a href="#nixpkgs_flake_package-nix_license_path">nix_license_path</a>, <a href="#nixpkgs_flake_package-package">package</a>, <a href="#nixpkgs_flake_package-build_file">build_file</a>, <a href="#nixpkgs_flake_package-build_file_content">build_file_content</a>, <a href="#nixpkgs_flake_package-nixopts">nixopts</a>, <a href="#nixpkgs_flake_package-quiet">quiet</a>,
                      <a href="#nixpkgs_flake_package-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_flake_package-legacy_path_syntax">legacy_path_syntax</a>, <a href="#nixpkgs_flake_package-kwargs">kwargs</a>)
</pre>

Make the content of a local Nix Flake package available in the Bazel workspace.

**IMPORTANT NOTE**: Calling `nix build` copies the entirety of the Nix Flake
into the Nix Store.  When using the `path:` syntax, this means the directory
containing `flake.nix` and any subdirectories.  Without specifying `path:`
Nix may infer that the flake is the Git repository and copy the entire thing.
As a consequence, you may want to isolate your flake from the rest of the
repository to minimize the amount of unnecessary data that gets copied into
the Nix Store whenever the flake is rebuilt.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_flake_package-name">
<td><code>name</code></td>
<td>

required.

<p>

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-nix_flake_file">
<td><code>nix_flake_file</code></td>
<td>

required.

<p>

Label to `flake.nix` that will be evaluated.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-nix_flake_lock_file">
<td><code>nix_flake_lock_file</code></td>
<td>

required.

<p>

Label to `flake.lock` that corresponds to `nix_flake_file`.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-nix_flake_file_deps">
<td><code>nix_flake_file_deps</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Additional dependencies of `nix_flake_file` if any.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-nix_license_path">
<td><code>nix_license_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

nix expression that evaluates to the spdx identifier of the license of this package. e.g: 'pkgs.zlib.meta.license.spdxId'

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-package">
<td><code>package</code></td>
<td>

optional.
default is <code>None</code>

<p>

Nix Flake package to make available.  The default package will be used if not specified.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-build_file">
<td><code>build_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

The file to use as the BUILD file for this repository. See [`nixpkgs_package`](#nixpkgs_package-build_file) for more information.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-build_file_content">
<td><code>build_file_content</code></td>
<td>

optional.
default is <code>""</code>

<p>

Like `build_file`, but a string of the contents instead of a file name. See [`nixpkgs_package`](#nixpkgs_package-build_file_content) for more information.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Extra flags to pass when calling Nix. See [`nixpkgs_package`](#nixpkgs_package-nixopts) for more information.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

Whether to hide the output of the Nix command.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

If set to `True` (default) this rule will fail on platforms which do not support Nix (e.g. Windows). If set to `False` calling this rule will succeed but no output will be generated.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-legacy_path_syntax">
<td><code>legacy_path_syntax</code></td>
<td>

optional.
default is <code>False</code>

<p>

If set to True (not default), the Nix Flake invocation will directly call `nix build <path>` instead of `nix build path:<path>` which may involve copying the entirety of the Git repo into the Nix Store instead of just the path and its children.

</p>
</td>
</tr>
<tr id="nixpkgs_flake_package-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

<p>

Common rule arguments.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_git_repository"></a>

### nixpkgs_git_repository

<pre>
nixpkgs_git_repository(<a href="#nixpkgs_git_repository-name">name</a>, <a href="#nixpkgs_git_repository-revision">revision</a>, <a href="#nixpkgs_git_repository-remote">remote</a>, <a href="#nixpkgs_git_repository-sha256">sha256</a>, <a href="#nixpkgs_git_repository-kwargs">kwargs</a>)
</pre>

Name a specific revision of Nixpkgs on GitHub or a local checkout.

#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_git_repository-name">
<td><code>name</code></td>
<td>

required.

<p>

String

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-revision">
<td><code>revision</code></td>
<td>

required.

<p>

String

Git commit hash or tag identifying the version of Nixpkgs to use.

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-remote">
<td><code>remote</code></td>
<td>

optional.
default is <code>"https://github.com/NixOS/nixpkgs"</code>

<p>

String

The URI of the remote Git repository. This must be a HTTP URL. There is
currently no support for authentication. Defaults to [upstream
nixpkgs](https://github.com/NixOS/nixpkgs).

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-sha256">
<td><code>sha256</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

The SHA256 used to verify the integrity of the repository.

</p>
</td>
</tr>
<tr id="nixpkgs_git_repository-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

<p>

Additional arguments to forward to the underlying repository rule.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_http_repository"></a>

### nixpkgs_http_repository

<pre>
nixpkgs_http_repository(<a href="#nixpkgs_http_repository-name">name</a>, <a href="#nixpkgs_http_repository-url">url</a>, <a href="#nixpkgs_http_repository-urls">urls</a>, <a href="#nixpkgs_http_repository-auth">auth</a>, <a href="#nixpkgs_http_repository-strip_prefix">strip_prefix</a>, <a href="#nixpkgs_http_repository-integrity">integrity</a>, <a href="#nixpkgs_http_repository-sha256">sha256</a>, <a href="#nixpkgs_http_repository-kwargs">kwargs</a>)
</pre>

Download a Nixpkgs repository over HTTP.

#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_http_repository-name">
<td><code>name</code></td>
<td>

required.

<p>

String

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-url">
<td><code>url</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

A URL to download the repository from.

This must be a file, http or https URL. Redirections are followed.

More flexibility can be achieved by the urls parameter that allows
to specify alternative URLs to fetch from.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-urls">
<td><code>urls</code></td>
<td>

optional.
default is <code>None</code>

<p>

List of String

A list of URLs to download the repository from.

Each entry must be a file, http or https URL. Redirections are followed.

URLs are tried in order until one succeeds, so you should list local mirrors first.
If all downloads fail, the rule will fail.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-auth">
<td><code>auth</code></td>
<td>

optional.
default is <code>None</code>

<p>

Dict of String

An optional dict mapping host names to custom authorization patterns.

If a URL's host name is present in this dict the value will be used as a pattern when
generating the authorization header for the http request. This enables the use of custom
authorization schemes used in a lot of common cloud storage providers.

The pattern currently supports 2 tokens: <code>&lt;login&gt;</code> and
<code>&lt;password&gt;</code>, which are replaced with their equivalent value
in the netrc file for the same host name. After formatting, the result is set
as the value for the <code>Authorization</code> field of the HTTP request.

Example attribute and netrc for a http download to an oauth2 enabled API using a bearer token:

<pre>
auth_patterns = {
    "storage.cloudprovider.com": "Bearer &lt;password&gt;"
}
</pre>

netrc:

<pre>
machine storage.cloudprovider.com
        password RANDOM-TOKEN
</pre>

The final HTTP request would have the following header:

<pre>
Authorization: Bearer RANDOM-TOKEN
</pre>

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-strip_prefix">
<td><code>strip_prefix</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

A directory prefix to strip from the extracted files.

Many archives contain a top-level directory that contains all of the useful
files in archive. This field can be used to strip it from all of the
extracted files.

For example, suppose you are using `nixpkgs-22.11.zip`, which contains
the directory `nixpkgs-22.11/` under which there is the `default.nix`
file and the `pkgs/` directory. Specify `strip_prefix =
"nixpkgs-22.11"` to use the `nixpkgs-22.11` directory as your top-level
directory.

Note that if there are files outside of this directory, they will be
discarded and inaccessible (e.g., a top-level license file). This includes
files/directories that start with the prefix but are not in the directory
(e.g., `nixpkgs-22.11.release-notes`). If the specified prefix does not
match a directory in the archive, Bazel will return an error.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-integrity">
<td><code>integrity</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

Expected checksum in Subresource Integrity format of the file downloaded.

This must match the checksum of the file downloaded. _It is a security risk
to omit the checksum as remote files can change._ At best omitting this
field will make your build non-hermetic. It is optional to make development
easier but either this attribute or `sha256` should be set before shipping.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-sha256">
<td><code>sha256</code></td>
<td>

optional.
default is <code>None</code>

<p>

String
The expected SHA-256 of the file downloaded.

This must match the SHA-256 of the file downloaded. _It is a security risk
to omit the SHA-256 as remote files can change._ At best omitting this
field will make your build non-hermetic. It is optional to make development
easier but should be set before shipping.

</p>
</td>
</tr>
<tr id="nixpkgs_http_repository-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

<p>

Additional arguments to forward to the underlying repository rule.

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
                       <a href="#nixpkgs_java_configure-register">register</a>, <a href="#nixpkgs_java_configure-toolchain_name">toolchain_name</a>, <a href="#nixpkgs_java_configure-toolchain_version">toolchain_version</a>, <a href="#nixpkgs_java_configure-exec_constraints">exec_constraints</a>,
                       <a href="#nixpkgs_java_configure-target_constraints">target_constraints</a>)
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

##### Bazel 6

#### with with [Bzlmod](https://bazel.build/versions/6.5.0/external/overview#bzlmod)

Add the following to your `MODULE.bazel` file to depend on `rules_nixpkgs`, `rules_nixpkgs_java`, and nixpgks:
```bzl
bazel_dep(name = "rules_nixpkgs_core", version = "0.13.0")
bazel_dep(name = "rules_nixpkgs_java", version = "0.13.0")
bazel_dep(name = "rules_java", version = "7.3.1")
bazel_dep(name = "platforms", version = "0.0.9")

nix_repo = use_extension("@rules_nixpkgs_core//extensions:repository.bzl", "nix_repo")
nix_repo.github(
    name = "nixpkgs",
    org = "NixOS",
    repo = "nixpkgs",
    commit = "ff0dbd94265ac470dda06a657d5fe49de93b4599",
    sha256 = "1bf0f88ee9181dd993a38d73cb120d0435e8411ea9e95b58475d4426c0948e98",
)
use_repo(nix_repo, "nixpkgs")

non_module_dependencies = use_extension("//:non_module_dependencies.bzl", "non_module_dependencies")
use_repo(non_module_dependencies, "nixpkgs_java_runtime_toolchain")

register_toolchains("@nixpkgs_java_runtime_toolchain//:all")

archive_override(
    module_name = "rules_nixpkgs_java",
    urls = "https://github.com/tweag/rules_nixpkgs/releases/download/v0.13.0/rules_nixpkgs-0.13.0.tar.gz",
    integrity = "",
    strip_prefix = "rules_nixpkgs-0.13.0/toolchains/java",
)
```

Add the following to a `.bzl` file, like `non_module_dependencies.bzl`, to import a JDK from nixpkgs:
```bzl
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")

def _non_module_dependencies_impl(_ctx):
    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "openjdk19.home",
        repository = "@nixpkgs",
        toolchain = True,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "19",
        register = False,
    )

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
```

Add the following configuration to `.bazelrc` to enable this Java runtime:
```
common --enable_bzlmod
build --host_platform=@rules_nixpkgs_core//platforms:host
build --java_runtime_version=nixpkgs_java_19
build --tool_java_runtime_version=nixpkgs_java_19
build --java_language_version=19
build --tool_java_language_version=19
```

#### with `WORKSPACE`

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
build --java_runtime_version=nixpkgs_java_11
build --tool_java_runtime_version=nixpkgs_java_11
build --java_language_version=11
build --tool_java_language_version=11
```

##### Bazel 7 with [Bzlmod](https://bazel.build/versions/7.0.0/external/overview#bzlmod)

Add the following to your `MODULE.bazel` file to depend on `rules_nixpkgs`, `rules_nixpkgs_java`, and nixpgks:
```bzl
bazel_dep(name = "rules_nixpkgs_core", version = "0.13.0")
bazel_dep(name = "rules_nixpkgs_java", version = "0.13.0")
bazel_dep(name = "rules_java", version = "7.5.0")
bazel_dep(name = "platforms", version = "0.0.9")

nix_repo = use_extension("@rules_nixpkgs_core//extensions:repository.bzl", "nix_repo")
nix_repo.github(
    name = "nixpkgs",
    org = "NixOS",
    repo = "nixpkgs",
    commit = "ff0dbd94265ac470dda06a657d5fe49de93b4599",
    sha256 = "1bf0f88ee9181dd993a38d73cb120d0435e8411ea9e95b58475d4426c0948e98",
)
use_repo(nix_repo, "nixpkgs")

non_module_dependencies = use_extension("//:non_module_dependencies.bzl", "non_module_dependencies")
use_repo(non_module_dependencies, "nixpkgs_java_runtime_toolchain")

register_toolchains("@nixpkgs_java_runtime_toolchain//:all")

archive_override(
    module_name = "rules_nixpkgs_java",
    urls = "https://github.com/tweag/rules_nixpkgs/releases/download/v0.13.0/rules_nixpkgs-0.13.0.tar.gz",
    integrity = "",
    strip_prefix = "rules_nixpkgs-0.13.0/toolchains/java",
)
```

Add the following to a `.bzl` file, like `non_module_dependencies.bzl`, to import a JDK from nixpkgs:
```bzl
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")

def _non_module_dependencies_impl(_ctx):
    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "openjdk19.home",
        repository = "@nixpkgs",
        toolchain = True,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "19",
        register = False,
    )

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
```

Add the following configuration to `.bazelrc` to enable this Java runtime:
```
build --host_platform=@rules_nixpkgs_core//platforms:host
build --java_runtime_version=nixpkgs_java_19
build --tool_java_runtime_version=nixpkgs_java_19
build --java_language_version=19
build --tool_java_language_version=19
build --extra_toolchains=@nixpkgs_java_runtime_toolchain//:all # necessary on NixOS only
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

Create a Bazel toolchain based on the Java runtime.

</p>
</td>
</tr>
<tr id="nixpkgs_java_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>None</code>

<p>

Register the created toolchain. Requires `toolchain` to be `True`. Defaults to the value of `toolchain`.

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


<a id="#nixpkgs_local_repository"></a>

### nixpkgs_local_repository

<pre>
nixpkgs_local_repository(<a href="#nixpkgs_local_repository-name">name</a>, <a href="#nixpkgs_local_repository-nix_file">nix_file</a>, <a href="#nixpkgs_local_repository-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_local_repository-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_local_repository-nix_flake_lock_file">nix_flake_lock_file</a>,
                         <a href="#nixpkgs_local_repository-kwargs">kwargs</a>)
</pre>

Create an external repository representing the content of Nixpkgs.

Based on a Nix expression stored locally or provided inline. One of
`nix_file` or `nix_file_content` must be provided.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_local_repository-name">
<td><code>name</code></td>
<td>

required.

<p>

String

A unique name for this repository.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

Label

A file containing an expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

<p>

List of labels

Dependencies of `nix_file` if any.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

An expression for a Nix derivation.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-nix_flake_lock_file">
<td><code>nix_flake_lock_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

String

A flake lock file that can be used on the provided nixpkgs repository.

</p>
</td>
</tr>
<tr id="nixpkgs_local_repository-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

<p>

Additional arguments to forward to the underlying repository rule.

</p>
</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_nodejs_configure"></a>

### nixpkgs_nodejs_configure

<pre>
nixpkgs_nodejs_configure(<a href="#nixpkgs_nodejs_configure-name">name</a>, <a href="#nixpkgs_nodejs_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_nodejs_configure-repository">repository</a>, <a href="#nixpkgs_nodejs_configure-repositories">repositories</a>, <a href="#nixpkgs_nodejs_configure-nix_platform">nix_platform</a>, <a href="#nixpkgs_nodejs_configure-nix_file">nix_file</a>,
                         <a href="#nixpkgs_nodejs_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_nodejs_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_nodejs_configure-nixopts">nixopts</a>, <a href="#nixpkgs_nodejs_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_nodejs_configure-quiet">quiet</a>,
                         <a href="#nixpkgs_nodejs_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_nodejs_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_nodejs_configure-register">register</a>)
</pre>



#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_nodejs_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>"nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_platform">
<td><code>nix_platform</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_nodejs_configure_platforms"></a>

### nixpkgs_nodejs_configure_platforms

<pre>
nixpkgs_nodejs_configure_platforms(<a href="#nixpkgs_nodejs_configure_platforms-name">name</a>, <a href="#nixpkgs_nodejs_configure_platforms-platforms_mapping">platforms_mapping</a>, <a href="#nixpkgs_nodejs_configure_platforms-attribute_path">attribute_path</a>, <a href="#nixpkgs_nodejs_configure_platforms-repository">repository</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-repositories">repositories</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_platform">nix_platform</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_file">nix_file</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_file_content">nix_file_content</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_nodejs_configure_platforms-nixopts">nixopts</a>, <a href="#nixpkgs_nodejs_configure_platforms-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_nodejs_configure_platforms-quiet">quiet</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_nodejs_configure_platforms-target_constraints">target_constraints</a>, <a href="#nixpkgs_nodejs_configure_platforms-register">register</a>, <a href="#nixpkgs_nodejs_configure_platforms-kwargs">kwargs</a>)
</pre>

Runs nixpkgs_nodejs_configure for each platform.

Since rules_nodejs adds platform suffix to repository name, this can be helpful
if one wants to use npm_install and reference js dependencies from npm repo.
See the example directory.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_nodejs_configure_platforms-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-platforms_mapping">
<td><code>platforms_mapping</code></td>
<td>

optional.
default is <code>{"aarch64-darwin": struct(exec_constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"], rules_nodejs_platform = "darwin_arm64", target_constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"]), "x86_64-linux": struct(exec_constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"], rules_nodejs_platform = "linux_amd64", target_constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"]), "x86_64-darwin": struct(exec_constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"], rules_nodejs_platform = "darwin_amd64", target_constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"]), "aarch64-linux": struct(exec_constraints = ["@platforms//os:linux", "@platforms//cpu:arm64"], rules_nodejs_platform = "linux_arm64", target_constraints = ["@platforms//os:linux", "@platforms//cpu:arm64"])}</code>

<p>

struct describing mapping between nix platform and rules_nodejs bazel platform with
target and exec constraints

</p>
</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>"nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_platform">
<td><code>nix_platform</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_package"></a>

### nixpkgs_package

<pre>
nixpkgs_package(<a href="#nixpkgs_package-name">name</a>, <a href="#nixpkgs_package-attribute_path">attribute_path</a>, <a href="#nixpkgs_package-nix_file">nix_file</a>, <a href="#nixpkgs_package-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_package-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_package-nix_license_path">nix_license_path</a>,
                <a href="#nixpkgs_package-repository">repository</a>, <a href="#nixpkgs_package-repositories">repositories</a>, <a href="#nixpkgs_package-build_file">build_file</a>, <a href="#nixpkgs_package-build_file_content">build_file_content</a>, <a href="#nixpkgs_package-nixopts">nixopts</a>, <a href="#nixpkgs_package-quiet">quiet</a>,
                <a href="#nixpkgs_package-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_package-kwargs">kwargs</a>)
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
<tr id="nixpkgs_package-nix_license_path">
<td><code>nix_license_path</code></td>
<td>

optional.
default is <code>""</code>

<p>

nix expression that evaluates to the spdx identifier of the license of this package. e.g: 'pkgs.zlib.meta.license.spdxId'

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

Its contents are copied into the file `BUILD` in root of the nix output folder. The Label does not need to be named `BUILD`, but can be.

For common use cases we provide filegroups that expose certain files as targets:

<dl>
  <dt><code>:bin</code></dt>
  <dd>Everything in the <code>bin/</code> directory.</dd>
  <dt><code>:lib</code></dt>
  <dd>All <code>.so</code>, <code>.dylib</code> and <code>.a</code> files that can be found in subdirectories of <code>lib/</code>.</dd>
  <dt><code>:include</code></dt>
  <dd>All <code>.h</code>, <code>.hh</code>, <code>.hpp</code> and <code>.hxx</code> files that can be found in subdirectories of <code>include/</code>.</dd>
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

Subject to location expansion, any instance of `$(location LABEL)` will be replaced by the path to the file referenced by `LABEL` relative to the workspace root.

Note, labels to external workspaces will resolve to paths that contain `~` characters if the Bazel flag `--enable_bzlmod` is true. Nix does not support `~` characters in path literals at the time of writing, see [#7742](https://github.com/NixOS/nix/issues/7742). Meaning, the result of location expansion may not form a valid Nix path literal. Use `./$${"$(location @for//:example)"}` to work around this limitation if you need to pass a path argument via `--arg`, or pass the resulting path as a string value using `--argstr` and combine it with an additional `--arg workspace_root ./.` argument using `workspace_root + ("/" + path_str)`.

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
nixpkgs_python_configure(<a href="#nixpkgs_python_configure-name">name</a>, <a href="#nixpkgs_python_configure-python3_attribute_path">python3_attribute_path</a>, <a href="#nixpkgs_python_configure-python3_bin_path">python3_bin_path</a>, <a href="#nixpkgs_python_configure-repository">repository</a>, <a href="#nixpkgs_python_configure-repositories">repositories</a>,
                         <a href="#nixpkgs_python_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_python_configure-nixopts">nixopts</a>, <a href="#nixpkgs_python_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_python_configure-quiet">quiet</a>, <a href="#nixpkgs_python_configure-exec_constraints">exec_constraints</a>,
                         <a href="#nixpkgs_python_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_python_configure-register">register</a>)
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
<tr id="nixpkgs_python_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_python_repository"></a>

### nixpkgs_python_repository

<pre>
nixpkgs_python_repository(<a href="#nixpkgs_python_repository-name">name</a>, <a href="#nixpkgs_python_repository-repository">repository</a>, <a href="#nixpkgs_python_repository-repositories">repositories</a>, <a href="#nixpkgs_python_repository-nix_file">nix_file</a>, <a href="#nixpkgs_python_repository-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_python_repository-quiet">quiet</a>)
</pre>

Define a collection of python packages based on a nix file.

The only entry point is a [`nix_file`](#nixpkgs_python_repository-nix_file)
which should expose a `pkgs` and a `python` attributes. `python` is the
python interpreter, and `pkgs` a set of python packages that will be made
available to bazel.

:warning: All the packages in `pkgs` are built by this rule. It is
therefore not a good idea to expose something as big as `pkgs.python3` as
provided by nixpkgs.

This rule is instead intended to expose an ad-hoc set of packages for your
project, as can be built by poetry2nix, mach-nix, dream2nix or by manually
picking the python packages you need from nixpkgs.

The format is generic to support the many ways to generate such packages
sets with nixpkgs. See our python [`tests`](/testing/toolchains/python) and
[`examples`](/examples/toolchains/python) to get started.

This rule is intended to mimic as closely as possible the [rules_python
API](https://github.com/bazelbuild/rules_python#using-the-package-installation-rules).
`nixpkgs_python_repository` should be a drop-in replacement of `pip_parse`.
As such, it also provides a `requirement` function.

:warning: Using the `requirement` fucntion inherits the same advantages and
limitations as the one in rules_python. All the function does is create a
label of the form `@{nixpkgs_python_repository_name}//:{package_name}`.
While depending on such a label directly will work, the layout may change
in the future. To be on the safe side, define and import your own
`requirement` function if you need to play with these labels.

:warning: Just as with rules_python, nothing is done to enforce consistency
between the version of python used to generate this repository and the one
configured in your toolchain, even if you use nixpkgs_python_toolchain. You
should ensure they both use the same python from the same nixpkgs version.

:warning: packages names exposed by this rule are determined by the `pname`
attribute of the corresponding nix package. These may vary slightly from
names used by rules_python. Should this be a problem, you can provide you
own `requirement` function, for example one that lowercases its argument.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_python_repository-name">
<td><code>name</code></td>
<td>

required.

<p>

The name for the created package set.

</p>
</td>
</tr>
<tr id="nixpkgs_python_repository-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repository).

</p>
</td>
</tr>
<tr id="nixpkgs_python_repository-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-repositories).

</p>
</td>
</tr>
<tr id="nixpkgs_python_repository-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nix_file).

</p>
</td>
</tr>
<tr id="nixpkgs_python_repository-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>[]</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-nix_file_deps).

</p>
</td>
</tr>
<tr id="nixpkgs_python_repository-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-quiet).

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
                       <a href="#nixpkgs_rust_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_rust_configure-register">register</a>)
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
<tr id="nixpkgs_rust_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_sh_posix_configure"></a>

### nixpkgs_sh_posix_configure

<pre>
nixpkgs_sh_posix_configure(<a href="#nixpkgs_sh_posix_configure-name">name</a>, <a href="#nixpkgs_sh_posix_configure-packages">packages</a>, <a href="#nixpkgs_sh_posix_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_sh_posix_configure-register">register</a>, <a href="#nixpkgs_sh_posix_configure-kwargs">kwargs</a>)
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
<tr id="nixpkgs_sh_posix_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

<p>

Constraints for the execution platform.

</p>
</td>
</tr>
<tr id="nixpkgs_sh_posix_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

<p>

Automatically register the generated toolchain if set to True.

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


