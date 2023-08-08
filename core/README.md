<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `core/nixpkgs.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

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
* [nixpkgs_http_repository](#nixpkgs_http_repository)
* [nixpkgs_local_repository](#nixpkgs_local_repository)
* [nixpkgs_package](#nixpkgs_package)


# Reference documentation

<a id="#nixpkgs_git_repository"></a>

### nixpkgs_git_repository

<pre>
nixpkgs_git_repository(<a href="#nixpkgs_git_repository-name">name</a>, <a href="#nixpkgs_git_repository-remote">remote</a>, <a href="#nixpkgs_git_repository-repo_mapping">repo_mapping</a>, <a href="#nixpkgs_git_repository-revision">revision</a>, <a href="#nixpkgs_git_repository-sha256">sha256</a>)
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
<tr id="nixpkgs_git_repository-repo_mapping">
<td><code>repo_mapping</code></td>
<td>

<a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a>; required

<p>

A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<p>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).

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
nixpkgs_local_repository(<a href="#nixpkgs_local_repository-name">name</a>, <a href="#nixpkgs_local_repository-nix_file">nix_file</a>, <a href="#nixpkgs_local_repository-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_local_repository-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_local_repository-repo_mapping">repo_mapping</a>)
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
<tr id="nixpkgs_local_repository-repo_mapping">
<td><code>repo_mapping</code></td>
<td>

<a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a>; required

<p>

A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<p>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).

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


