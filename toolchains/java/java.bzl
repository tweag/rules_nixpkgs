"""<!-- Edit the docstring in `toolchains/java/java.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

# Rules for importing a Java toolchain from Nixpkgs

## Rules

* [nixpkgs_java_configure](#nixpkgs_java_configure)
"""

load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "get_cpu_value",
)
load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    "nixpkgs_package",
)
load(
    "@rules_nixpkgs_core//:util.bzl",
    "ensure_constraints",
)

_java_nix_file_content = """\
with import <nixpkgs> { config = {}; overlays = []; };

{ attrPath
, attrSet
, filePath
, javaToolchainVersion
}:

let
  javaHome =
    if attrSet == null then
      pkgs.lib.getAttrFromPath (pkgs.lib.splitString "." attrPath) pkgs
    else
      pkgs.lib.getAttrFromPath (pkgs.lib.splitString "." attrPath) attrSet
    ;
  javaHomePath =
    if filePath == "" then
      "${javaHome}"
    else
      "${javaHome}/${filePath}"
    ;
  versionArg = if javaToolchainVersion == null then
    "# version not set"
  else
    "version = ${javaToolchainVersion},";
in

pkgs.runCommand "bazel-nixpkgs-java-runtime"
  { executable = false;
    # Pointless to do this on a remote machine.
    preferLocalBuild = true;
    allowSubstitutes = false;
  }
  ''
    n=$out/BUILD.bazel
    mkdir -p "$(dirname "$n")"

    cat >>$n <<EOF
    load("@rules_java//java:defs.bzl", "java_runtime")
    java_runtime(
        name = "runtime",
        java_home = r"${javaHomePath}",
        ${versionArg}
        visibility = ["//visibility:public"],
    )
    EOF
  ''
"""

def _nixpkgs_java_toolchain_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    exec_constraints, target_constraints = ensure_constraints(repository_ctx)

    repository_ctx.file(
        "BUILD.bazel",
        executable = False,
        content = """\
load("@rules_nixpkgs_java//:local_java_repository.bzl", "local_java_runtime")
local_java_runtime(
   name = "{name}",
   version = "{version}",
   runtime_name = "@{runtime}//:runtime",
   java_home = None,
   exec_compatible_with = {exec_constraints},
   target_compatible_with = {target_constraints},
)
""".format(
            runtime = repository_ctx.attr.runtime_repo,
            version = repository_ctx.attr.runtime_version,
            name = repository_ctx.attr.runtime_name,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        ),
    )

_nixpkgs_java_toolchain = repository_rule(
    _nixpkgs_java_toolchain_impl,
    attrs = {
        "runtime_repo": attr.string(),
        "runtime_version": attr.string(),
        "runtime_name": attr.string(),
        "exec_constraints": attr.string_list(),
        "target_constraints": attr.string_list(),
    },
)

def nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = None,
        java_home_path = "",
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_content = "",
        nix_file_deps = None,
        nixopts = [],
        fail_not_supported = True,
        quiet = False,
        toolchain = False,
        register = None,
        toolchain_name = None,
        toolchain_version = None,
        exec_constraints = None,
        target_constraints = None):
    """Define a Java runtime provided by nixpkgs.

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

    ##### Bazel 6

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
    build --java_runtime_version=nixpkgs_java_11
    build --tool_java_runtime_version=nixpkgs_java_11
    build --java_language_version=11
    build --tool_java_language_version=11
    ```

    Args:
      name: The name-prefix for the created external repositories.
      attribute_path: string, The nixpkgs attribute path for `jdk.home`.
      java_home_path: optional, string, The path to `JAVA_HOME` within the package.
      repository: See [`nixpkgs_package`](#nixpkgs_package-repository).
      repositories: See [`nixpkgs_package`](#nixpkgs_package-repositories).
      nix_file: optional, Label, Obtain the runtime from the Nix expression defined in this file. Specify only one of `nix_file` or `nix_file_content`.
      nix_file_content: optional, string, Obtain the runtime from the given Nix expression. Specify only one of `nix_file` or `nix_file_content`.
      nix_file_deps: See [`nixpkgs_package`](#nixpkgs_package-nix_file_deps).
      nixopts: See [`nixpkgs_package`](#nixpkgs_package-nixopts).
      fail_not_supported: See [`nixpkgs_package`](#nixpkgs_package-fail_not_supported).
      quiet: See [`nixpkgs_package`](#nixpkgs_package-quiet).
      toolchain: Create a Bazel toolchain based on the Java runtime.
      register: Register the created toolchain. Requires `toolchain` to be `True`. Defaults to the value of `toolchain`.
      toolchain_name: The name of the toolchain that can be used in --java_runtime_version.
      toolchain_version: The version of the toolchain that can be used in --java_runtime_version.
      exec_constraints: Constraints for the execution platform.
      target_constraints: Constraints for the target platform.
    """
    if attribute_path == None:
        fail("'attribute_path' is required.", "attribute_path")

    nix_expr = None
    if nix_file and nix_file_content:
        fail("Cannot specify both 'nix_file' and 'nix_file_content'.")
    elif nix_file:
        nix_expr = "import $(location {}) {{}}".format(nix_file)
        nix_file_deps = depset(direct = [nix_file] + nix_file_deps).to_list()
    elif nix_file_content:
        nix_expr = nix_file_content
    else:
        nix_expr = "null"

    nixopts = list(nixopts)
    nixopts.extend([
        "--argstr",
        "attrPath",
        attribute_path,
        "--arg",
        "attrSet",
        nix_expr,
        "--argstr",
        "filePath",
        java_home_path,
    ])
    if toolchain_version:
        nixopts.extend([
            "--argstr",
            "javaToolchainVersion",
            toolchain_version,
        ])

    nixpkgs_package(
        name = name,
        nix_file_content = _java_nix_file_content,
        repository = repository,
        repositories = repositories,
        nix_file_deps = nix_file_deps,
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )
    if toolchain:
        _nixpkgs_java_toolchain(
            name = "{}_toolchain".format(name),
            runtime_repo = name,
            runtime_version = toolchain_version,
            runtime_name = toolchain_name,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        )
        if register or register == None:
            native.register_toolchains("@{}_toolchain//:all".format(name))
    elif register:
        fail("toolchain must be True if register is set to True.")
