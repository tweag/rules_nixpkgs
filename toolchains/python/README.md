<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/python/python.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules to import Python toolchains and packages from Nixpkgs.

# Rules

* [nixpkgs_python_configure](#nixpkgs_python_configure)
* [nixpkgs_python_repository](#nixpkgs_python_repository)


# Reference documentation

<a id="#nixpkgs_python_configure"></a>

### nixpkgs_python_configure

<pre>
nixpkgs_python_configure(<a href="#nixpkgs_python_configure-name">name</a>, <a href="#nixpkgs_python_configure-python2_attribute_path">python2_attribute_path</a>, <a href="#nixpkgs_python_configure-python2_bin_path">python2_bin_path</a>, <a href="#nixpkgs_python_configure-python3_attribute_path">python3_attribute_path</a>,
                         <a href="#nixpkgs_python_configure-python3_bin_path">python3_bin_path</a>, <a href="#nixpkgs_python_configure-repository">repository</a>, <a href="#nixpkgs_python_configure-repositories">repositories</a>, <a href="#nixpkgs_python_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_python_configure-nixopts">nixopts</a>,
                         <a href="#nixpkgs_python_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_python_configure-quiet">quiet</a>, <a href="#nixpkgs_python_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_python_configure-target_constraints">target_constraints</a>, <a href="#nixpkgs_python_configure-register">register</a>)
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


