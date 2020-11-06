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
* [nixpkgs_package](#nixpkgs_package)
* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
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

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package", "nixpkgs_cc_toolchain")

load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_toolchain") # optional
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

### nixpkgs_git_repository

Name a specific revision of Nixpkgs on GitHub or a local checkout.

```bzl
nixpkgs_git_repository(name, revision, sha256)
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name; required</code></p>
        <p>A unique name for this repository.</p>
      </td>
    </tr>
    <tr>
      <td><code>revision</code></td>
      <td>
        <p><code>String; required</code></p>
        <p>Git commit hash or tag identifying the version of Nixpkgs
           to use.</p>
      </td>
    </tr>
    <tr>
      <td><code>remote</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>The URI of the remote Git repository. This must be a HTTP
           URL. There is currently no support for authentication.
           Defaults to <a href="https://github.com/NixOS/nixpkgs">
           upstream nixpkgs.</a></p>
      </td>
    </tr>
    <tr>
      <td><code>sha256</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>The SHA256 used to verify the integrity of the repository.</p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_local_repository

Create an external repository representing the content of Nixpkgs,
based on a Nix expression stored locally or provided inline. One of
`nix_file` or `nix_file_content` must be provided.

```bzl
nixpkgs_local_repository(name, nix_file, nix_file_deps, nix_file_content)
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name; required</code></p>
        <p>A unique name for this repository.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>A file containing an expression for a Nix derivation.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_deps</code></td>
      <td>
        <p><code>List of labels; optional</code></p>
        <p>Dependencies of `nix_file` if any.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix derivation.</p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_package

Make the content of a Nixpkgs package available in the Bazel workspace.

```bzl
nixpkgs_package(
    name, attribute_path, nix_file, nix_file_deps, nix_file_content,
    repository, repositories, build_file, build_file_content, nixopts,
    fail_not_supported,
)
```

If `repositories` is not specified, you must provide a
nixpkgs clone in `nix_file` or `nix_file_content`.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name; required</code></p>
        <p>A unique name for this target</p>
      </td>
    </tr>
    <tr>
      <td><code>attribute_path</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Select an attribute from the top-level Nix expression being
           evaluated. The attribute path is a sequence of attribute
           names separated by dots.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>A file containing an expression for a Nix derivation.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_deps</code></td>
      <td>
        <p><code>List of labels; optional</code></p>
        <p>Dependencies of `nix_file` if any.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix derivation.</p>
      </td>
    </tr>
    <tr>
      <td><code>repository</code></td>
      <td>
        <p><code>Label; optional</code></p>
        <p>A repository label identifying which Nixpkgs to use.
           Equivalent to `repositories = { "nixpkgs": ...}`</p>
      </td>
    </tr>
    <tr>
      <td><code>repositories</code></td>
      <td>
        <p><code>String-keyed label dict; optional</code></p>
        <p>A dictionary mapping `NIX_PATH` entries to repository labels.</p>
        <p>Setting it to
           <pre><code>repositories = { "myrepo" : "//:myrepo" }</code></pre>
           for example would replace all instances
           of <code>&lt;myrepo&gt;</code> in the called nix code by the
           path to the target <code>"//:myrepo"</code>. See the
           <a href="https://nixos.org/nix/manual/#env-NIX_PATH">relevant
           section in the nix manual</a> for more information.</p>
        <p>Specify one of `path` or `repositories`.</p>
      </td>
    </tr>
    <tr>
      <td><code>build_file</code></td>
      <td>
        <p><code>Label; optional</code></p>
        <p>The file to use as the BUILD file for this repository.
           Its contents are copied copied into the file
           <code>BUILD</code> in root of the nix output folder.
           The Label does not need to be named BUILD, but can be.
        </p>
        <p>For common use cases we provide filegroups that expose
           certain files as targets:
          <dl>
            <dt><code>:bin</code></dt>
            <dd>Everything in the <code>bin/</code> directory.</dd>
            <dt><code>:lib</code></dt>
            <dd>All <code>.so</code> and <code>.a</code> files
              that can be found in subdirectories of
              <code>lib/</code>.</dd>
            <dt><code>:include</code></dt>
            <dd>All <code>.h</code> files
              that can be found in subdirectories of
              <code>bin/</code>.</dd>
          </dl>
        </p>
        <p>If you need different files from the nix package,
          you can reference them like this: <pre><code>package(default_visibility = [ "//visibility:public" ])
filegroup(
  name = "our-docs",
  srcs = glob(["share/doc/ourpackage/**/*"]),
)</code></pre>
          See the bazel documentation of
          <a href="https://docs.bazel.build/versions/master/be/general.html#filegroup">filegroup</a>
          and
          <a href="https://docs.bazel.build/versions/master/be/functions.html#glob">glob</a>.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>build_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Like <code>build_file</code>, but a string of the contents
          instead of a file name.</p>
      </td>
    </tr>
    <tr>
      <td><code>nixopts</code></td>
      <td>
        <p><code>String list; optional</code></p>
        <p>
            Extra flags to pass when calling Nix. Subject to location
            expansion, any instance of <code>$(location LABEL)</code> will be
            replaced by the path to the file ferenced by <code>LABEL</code>
            relative to the workspace root.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>fail_not_supported</code></td>
      <td>
        <p><code>Boolean; optional; default = True</code></p>
        <p>
            If set to <code>True</code> (default) this rule will fail on
            platforms which do not support Nix (e.g. Windows). If set to
            <code>False</code> calling this rule will succeed but no output
            will be generated.
        </p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_cc_configure_hermetic

Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

By default, Bazel auto-configures a CC toolchain from commands (e.g.
`gcc`) available in the environment. To make builds more hermetic, use
this rule to specify explicitly which commands the toolchain should use.

Specifically, it builds a Nix derivation that provides the CC toolchain tools
in the `bin/` path and constructs a CC toolchain that uses those tools. The
following tools are expected `ar`, `cpp`, `dwp`, `cc`, `gcov`, `ld`, `nm`,
`objcopy`, `objdump`, `strip`. Tools that aren't found are replaced by
`${coreutils}/bin/false`.

This rule depends on [`rules_cc`](https://github.com/bazelbuild/rules_cc).

Note:

You need to configure `--crosstool_top=@<name>//:toolchain` to activate this
toolchain.

Example:

```bzl
nixpkgs_cc_configure_hermetic(repository = "@nixpkgs//:default.nix")
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>attribute_path</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Obtain the toolchain from the Nix expression under this attribute path. Requires `nix_file` or `nix_file_content`.</p>
      </td>
      <td><code>nix_file</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Obtain the toolchain from the Nix expression defined in this file. Specify only one of `nix_file` or `nix_file_content`.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Obtain the toolchain from the given Nix expression. Specify only one of `nix_file` or `nix_file_content`.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_deps</code></td>
      <td>
        <p><code>List of labels; optional</code></p>
        <p>Additional files that the Nix expression depends on.</p>
      </td>
    </tr>
    <tr>
      <td><code>repository</code></td>
      <td>
        <p><code>Label; optional</code></p>
        <p>Provides `<nixpkgs>`. Specify one of `repositories` or `repository`.</p>
      </td>
    </tr>
    <tr>
      <td><code>repositories</code></td>
      <td>
        <p><code>String-keyed label dict; optional</code></p>
        <p>Provides `<nixpkgs>` and other repositories. Specify one of `repositories` or `repository`.</p>
      </td>
    </tr>
    <tr>
      <td><code>quiet</code></td>
      <td>
        <p><code>Bool; optional</code></p>
        <p>Whether to hide `nix-build` output.</p>
      </td>
    </tr>
    <tr>
      <td><code>fail_not_supported</code></td>
      <td>
        <p><code>Bool; optional</code></p>
        <p>Whether to fail if `nix-build` is not available.</p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_cc_configure

Tells Bazel to use compilers and linkers from Nixpkgs for the CC
toolchain. By default, Bazel autodetects a toolchain on the current
`PATH`. Overriding this autodetection makes builds more hermetic and
is considered a best practice.

Deprecated:

Use `nixpkgs_cc_configure_hermetic` instead.

While this improves upon Bazel's autoconfigure toolchain by picking tools from
a Nix derivation rather than the environment, it is still not fully hermetic as
it is affected by the environment. In particular, system include directories
specified in the environment can leak in and affect the cache keys of targets
depending on the cc toolchain leading to cache misses.

Example:

```bzl
nixpkgs_cc_configure(repository = "@nixpkgs//:default.nix")
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>nix_file</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix environment derivation. The
           environment should expose all the commands that make up
           a CC toolchain (`cc`, `ld` etc). Exposes all commands in
           `stdenv.cc` and `binutils` by default.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_deps</code></td>
      <td>
        <p><code>List of labels; optional</code></p>
        <p>Dependencies of `nix_file` if any.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix environment derivation.</p>
      </td>
    </tr>
    <tr>
      <td><code>repository</code></td>
      <td>
        <p><code>Label; optional</code></p>
        <p>A repository label identifying which Nixpkgs to use.
           Equivalent to `repositories = { "nixpkgs": ...}`</p>
      </td>
    </tr>
    <tr>
      <td><code>repositories</code></td>
      <td>
        <p><code>String-keyed label dict; optional</code></p>
        <p>A dictionary mapping `NIX_PATH` entries to repository labels.</p>
        <p>Setting it to
           <pre><code>repositories = { "myrepo" : "//:myrepo" }</code></pre>
           for example would replace all instances
           of <code>&lt;myrepo&gt;</code> in the called nix code by the
           path to the target <code>"//:myrepo"</code>. See the
           <a href="https://nixos.org/nix/manual/#env-NIX_PATH">relevant
           section in the nix manual</a> for more information.</p>
        <p>Specify one of `path` or `repositories`.</p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_go_configure

**NOTE: this rule resides in `@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl` to avoid unnecessary dependencies on rules_go for those who don't need go toolchain**

For this rule to work `rules_go` must be available for loading before loading of `@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl`.

Tells bazel to use go sdk from nixpkgs. This rule **will fail** if nix is not present - you can always wrap it in rule if 
you need to optionally provide nix support.

By default rules_go configures go toolchain to be downloaded as binaries (which doesn't work on NixOS),
there is a way to tell rules_go to look into environment and find local go binary which is not hermetic.
This command allows to setup hermetic go sdk from Nixpkgs, which should be considerate as best practice.

Note that nix package must provide full go sdk at the root of the package instead of in $out/share/go
And also provide an empty normal file named PACKAGE_ROOT at the root of package

Example:

```bzl
nixpkgs_go_configure(repository = "@nixpkgs//:default.nix")
```

Example (optional nix support when go is transitive dependency):

```bzl
# .bazel-lib/nixos-support.bzl
def _has_nix(ctx):
    return ctx.which("nix-build") != None

def _gen_imports_impl(ctx):
    ctx.file("BUILD", "")

    imports_for_nix = """
        load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_toolchain")

        def fix_go():
            nixpkgs_go_toolchain(repository = "@nixpkgs")
    """
    imports_for_non_nix = """
        def fix_go():
            # if go isn't transitive you'll need to add call to go_register_toolchains here
            pass
    """

    if _has_nix(ctx):
        ctx.file("imports.bzl", imports_for_nix)
    else:
        ctx.file("imports.bzl", imports_for_non_nix)

_gen_imports = repository_rule(
    implementation = _gen_imports_impl,
    attrs = dict(),
)

def gen_imports():
    _gen_imports(
        name = "nixos_support",
    )



# WORKSPACE

// ...
http_archive(name = "io_tweag_rules_nixpkgs", ...)
// ...
local_repository(
    name = "bazel_lib",
    path = ".bazel-lib",
)
load("@bazel_lib//:nixos-support.bzl", "gen_imports")
gen_imports()
load("@nixos_support//:imports.bzl", "fix_go")
fix_go()
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>sdk_name</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Go sdk name to pass in rules_go</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix environment derivation. The
           environment should expose whole go SDK (bin, src, ...) at the root of package. It also
           must contain <code>PACKAGE_ROOT</code> file in the root of pacakge.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_deps</code></td>
      <td>
        <p><code>List of labels; optional</code></p>
        <p>Dependencies of `nix_file` if any.</p>
      </td>
    </tr>
    <tr>
      <td><code>nix_file_content</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>An expression for a Nix environment derivation.</p>
      </td>
    </tr>
    <tr>
      <td><code>repository</code></td>
      <td>
        <p><code>Label; optional</code></p>
        <p>A repository label identifying which Nixpkgs to use.
           Equivalent to `repositories = { "nixpkgs": ...}`</p>
      </td>
    </tr>
    <tr>
      <td><code>repositories</code></td>
      <td>
        <p><code>String-keyed label dict; optional</code></p>
        <p>A dictionary mapping `NIX_PATH` entries to repository labels.</p>
        <p>Setting it to
           <pre><code>repositories = { "myrepo" : "//:myrepo" }</code></pre>
           for example would replace all instances
           of <code>&lt;myrepo&gt;</code> in the called nix code by the
           path to the target <code>"//:myrepo"</code>. See the
           <a href="https://nixos.org/nix/manual/#env-NIX_PATH">relevant
           section in the nix manual</a> for more information.</p>
        <p>Specify one of `path` or `repositories`.</p>
      </td>
    </tr>
  </tbody>
</table>

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
