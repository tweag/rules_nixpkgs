<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<!-- Edit the docstring in `toolchains/java/java.bzl` and run `cd docs; bazel run :update-README.md` to change this repository's `README.md`. -->

# Rules for importing a Java toolchain from Nixpkgs

## Rules

* [nixpkgs_java_configure](#nixpkgs_java_configure)


# Reference documentation

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


