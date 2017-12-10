# rules_nixpkgs

Rules for importing Nixpkgs packages into Bazel.

## Rules

* [nixpkgs_package](#nixpkgs_package)

## Setup

Add the following to your `WORKSPACE` file, and select a `$COMMIT` accordingly.

```bzl
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-$COMMIT",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/$COMMIT.tar.gz"],
)
```

and this to your BUILD files.

```bzl
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_binary", "nixpkgs_library")
```

## Rules

### nixpkgs_package

Creates a new external repository, with the content symlinked from the
given Nixpkgs package.

```bzl
nixpkgs_library(name, attribute, path, build_file, build_file_content)
```

#### Example

```bzl
nixpkgs_package(
    name = "hello",
	revision = "17.09" # Any tag or commit hash
)
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
      <td><code>revision</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>Git commit hash or tag identifying the version of Nixpkgs
           to use. If neither `revision` or `path` are specified,
           `<nixpkgs>` is assumed. Specifying one of `revision` or
           `path` is strongly recommended. The two are mutually
           exclusive.</p>
      </td>
    </tr>
    <tr>
      <td><code>path</code></td>
      <td>
        <p><code>String; optional</code></p>
        <p>The path to the directory containing Nixpkgs, as
           interpreted by `nix-build`.</p>
      </td>
    </tr>
  </tbody>
</table>

### nixpkgs_library

Generates a Nixpkgs library.

```bzl
nixpkgs_library(name, srcs, deps)
```

#### Example

```bzl
nixpkgs_library(
    name = 'hello_lib',
    srcs = glob(['hello_lib/**/*.hs']),
    deps = ["//hello_sublib:lib"]
)
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
        <p><code>Name, required</code></p>
        <p>A unique name for this target</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <p><code>List of labels, required</code></p>
        <p>List of Nixpkgs <code>.hs</code> source files used to build the library</p>
      </td>
    </tr>
    <tr>
      <td><code>deps</code></td>
      <td>
        <p><code>List of labels, required</code></p>
        <p>List of other Nixpkgs libraries to be linked to this target</p>
      </td>
    </tr>
  </tbody>
</table>
