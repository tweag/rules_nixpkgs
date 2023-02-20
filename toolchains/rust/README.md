<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/rust/rust.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a Rust toolchain from Nixpkgs.

# Rules

* [nixpkgs_rust_configure](#nixpkgs_rust_configure)


# Reference documentation

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


