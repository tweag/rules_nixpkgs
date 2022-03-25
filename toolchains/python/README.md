<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/python/python.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a Python toolchain from Nixpkgs.

# Rules

* [nixpkgs_python_configure](#nixpkgs_python_configure)


# Reference documentation

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


