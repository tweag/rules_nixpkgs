# rules_nixpkgs

[![CircleCI](https://circleci.com/gh/tweag/rules_nixpkgs.svg?style=svg)](https://circleci.com/gh/tweag/rules_nixpkgs)

Rules for importing Nixpkgs packages into Bazel.

## Rules

* [nixpkgs_git_repository](#nixpkgs_git_repository)
* [nixpkgs_package](#nixpkgs_package)

## Setup

Add the following to your `WORKSPACE` file, and select a `$COMMIT` accordingly.

```bzl
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-$COMMIT",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/$COMMIT.tar.gz"],
)

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")
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
        <p>Extra flags to pass when calling Nix.</p>
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

### nixpkgs_cc_configure

Tells Bazel to use compilers and linkers from Nixpkgs for the CC
toolchain. By default, Bazel autodetects a toolchain on the current
`PATH`. Overriding this autodetection makes builds more hermetic and
is considered a best practice.

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
