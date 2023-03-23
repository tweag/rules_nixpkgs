<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/posix/posix.bzl` and run `cd docs; bazel run :update-README.md` to change this repository's `README.md`. -->

Rules for importing a POSIX toolchain from Nixpkgs.

# Rules

* [nixpkgs_sh_posix_configure](#nixpkgs_sh_posix_configure)


# Reference documentation

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


