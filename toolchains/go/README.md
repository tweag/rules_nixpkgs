<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/go/go.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a Go toolchain from Nixpkgs.

## Rules

* [nixpkgs_go_configure](#nixpkgs_go_configure)


# Reference documentation

<a id="#nixpkgs_go_configure"></a>

### nixpkgs_go_configure

<pre>
nixpkgs_go_configure(<a href="#nixpkgs_go_configure-sdk_name">sdk_name</a>, <a href="#nixpkgs_go_configure-repository">repository</a>, <a href="#nixpkgs_go_configure-repositories">repositories</a>, <a href="#nixpkgs_go_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_go_configure-nix_file">nix_file</a>, <a href="#nixpkgs_go_configure-nix_file_deps">nix_file_deps</a>,
                     <a href="#nixpkgs_go_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_go_configure-nixopts">nixopts</a>, <a href="#nixpkgs_go_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_go_configure-quiet">quiet</a>, <a href="#nixpkgs_go_configure-register">register</a>,
                     <a href="#nixpkgs_go_configure-rules_go_repo_name">rules_go_repo_name</a>)
</pre>

Use go toolchain from Nixpkgs.

By default rules_go configures the go toolchain to be downloaded as binaries (which doesn't work on NixOS).
There is a way to tell rules_go to look into environment and find local go binary which is not hermetic.
This command allows to setup a hermetic go sdk from Nixpkgs, which should be considered as best practice.
Cross toolchains are declared and registered for each entry in the `PLATFORMS` constant in `rules_go`.

Note that the nix package must provide a full go sdk at the root of the package instead of in `$out/share/go`,
and also provide an empty normal file named `ROOT` at the root of package.

#### Example

  ```bzl
  nixpkgs_go_configure(repository = "@nixpkgs//:default.nix")
  ```

  Example (optional nix support when go is a transitive dependency):

  ```bzl
  # .bazel-lib/nixos-support.bzl
  def _has_nix(ctx):
      return ctx.which("nix-build") != None

  def _gen_imports_impl(ctx):
      ctx.file("BUILD", "")

      imports_for_nix = """
          load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/go.bzl", "nixpkgs_go_configure")

          def fix_go():
              nixpkgs_go_configure(repository = "@nixpkgs")
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


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_go_configure-sdk_name">
<td><code>sdk_name</code></td>
<td>

optional.
default is <code>"go_sdk"</code>

<p>

Go sdk name to pass to rules_go

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

<p>

A repository label identifying which Nixpkgs to use. Equivalent to `repositories = { "nixpkgs": ...}`.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-repositories">
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

Specify one of `path` or `repositories`.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>"go"</code>

<p>

The nixpkgs attribute path for the `go` to use.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

<p>

An expression for a Nix environment derivation. The environment should expose the whole go SDK (`bin`, `src`, ...) at the root of package. It also must contain a `ROOT` file in the root of package. Takes precedence over attribute_path.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>[]</code>

<p>

Dependencies of `nix_file` if any.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

<p>

An expression for a Nix environment derivation. Takes precedence over attribute_path.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_go_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

<p>

See [`nixpkgs_package`](#nixpkgs_package-fail_not_supported).

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

<p>

Whether to hide the output of the Nix command.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-register">
<td><code>register</code></td>
<td>

optional.
default is <code>True</code>

<p>

Automatically register the generated toolchain if set to True.

</p>
</td>
</tr>
<tr id="nixpkgs_go_configure-rules_go_repo_name">
<td><code>rules_go_repo_name</code></td>
<td>

optional.
default is <code>"io_bazel_rules_go"</code>

<p>

The name of the rules_go repository. Defaults to rules_go under bzlmod and io_bazel_rules_go otherwise.",

</p>
</td>
</tr>
</tbody>
</table>


