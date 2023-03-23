"""<!-- Edit the docstring in `toolchains/cc/cc.bzl` and run `cd docs; bazel run :update-README.md` to change this repository's `README.md`. -->

Rules for importing a C++ toolchain from Nixpkgs.

## Compiling non-C++ languages

One may wish to use a C++ toolchain to compile certain libraries written in
non-C++ languages. For instance, Clang/LLVM can be used to compile CUDA or HIP
code targeting GPUs. This can be achieved by:

  1. passing `cc_lang = "none"` in `nixpkgs_cc_configure` below
  2. using a rule invocation of the form `cc_library(..., copts="-x cuda")`
  when defining individual libraries or executables

It is also possible to override the language used by the toolchain itself,
using `nixpkgs_cc_configure(..., cc_lang = "cuda")` or similar.

## Rules

* [nixpkgs_cc_configure](#nixpkgs_cc_configure)
"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load(
    "@bazel_tools//tools/cpp:lib_cc_configure.bzl",
    "get_cpu_value",
    "get_starlark_list",
    "write_builtin_include_directory_paths",
)
load("@bazel_skylib//lib:sets.bzl", "sets")
load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load(
    "@rules_nixpkgs_core//:util.bzl",
    "is_bazel_version_at_least",
    "ensure_constraints",
    "execute_or_fail",
)

def _parse_cc_toolchain_info(content, filename):
    """Parses the `CC_TOOLCHAIN_INFO` file generated by Nix.

    Attrs:
      content: string, The content of the `CC_TOOLCHAIN_INFO` file.
      filename: string, The path to the `CC_TOOLCHAIN_INFO` file, used for error reporting.

    Returns:
      struct, The substitutions for `@bazel_tools//tools/cpp:BUILD.tpl`.
    """

    # Parse the content of CC_TOOLCHAIN_INFO.
    #
    # Each line has the form
    #
    #   <key>:<value1>:<value2>:...
    info = {}
    for line in content.splitlines():
        fields = line.split(":")
        if len(fields) == 0:
            fail(
                "Malformed CC_TOOLCHAIN_INFO '{}': Empty line encountered.".format(filename),
                "cc_toolchain_info",
            )
        info[fields[0]] = fields[1:]

    # Validate the keys in CC_TOOLCHAIN_INFO.
    expected_keys = sets.make([
        "TOOL_NAMES",
        "TOOL_PATHS",
        "CXX_BUILTIN_INCLUDE_DIRECTORIES",
        "COMPILE_FLAGS",
        "CXX_FLAGS",
        "LINK_FLAGS",
        "LINK_LIBS",
        "OPT_COMPILE_FLAGS",
        "OPT_LINK_FLAGS",
        "UNFILTERED_COMPILE_FLAGS",
        "DBG_COMPILE_FLAGS",
        "COVERAGE_COMPILE_FLAGS",
        "COVERAGE_LINK_FLAGS",
        "SUPPORTS_START_END_LIB",
        "IS_CLANG",
    ])
    actual_keys = sets.make(info.keys())
    missing_keys = sets.difference(expected_keys, actual_keys)
    unexpected_keys = sets.difference(actual_keys, expected_keys)
    if sets.length(missing_keys) > 0:
        fail(
            "Malformed CC_TOOLCHAIN_INFO '{}': Missing entries '{}'.".format(
                filename,
                "', '".join(sets.to_list(missing_keys)),
            ),
            "cc_toolchain_info",
        )
    if sets.length(unexpected_keys) > 0:
        fail(
            "Malformed CC_TOOLCHAIN_INFO '{}': Unexpected entries '{}'.".format(
                filename,
                "', '".join(sets.to_list(unexpected_keys)),
            ),
            "cc_toolchain_info",
        )

    return struct(
        tool_paths = {
            tool: path
            for (tool, path) in zip(info["TOOL_NAMES"], info["TOOL_PATHS"])
        },
        cxx_builtin_include_directories = info["CXX_BUILTIN_INCLUDE_DIRECTORIES"],
        compile_flags = info["COMPILE_FLAGS"],
        cxx_flags = info["CXX_FLAGS"],
        link_flags = info["LINK_FLAGS"],
        link_libs = info["LINK_LIBS"],
        opt_compile_flags = info["OPT_COMPILE_FLAGS"],
        opt_link_flags = info["OPT_LINK_FLAGS"],
        unfiltered_compile_flags = info["UNFILTERED_COMPILE_FLAGS"],
        dbg_compile_flags = info["DBG_COMPILE_FLAGS"],
        coverage_compile_flags = info["COVERAGE_COMPILE_FLAGS"],
        coverage_link_flags = info["COVERAGE_LINK_FLAGS"],
        supports_start_end_lib = info["SUPPORTS_START_END_LIB"] == ["True"],
        is_clang = info["IS_CLANG"] == ["True"],
    )

def _nixpkgs_cc_toolchain_config_impl(repository_ctx):
    cpu_value = get_cpu_value(repository_ctx)
    darwin = cpu_value == "darwin" or cpu_value == "darwin_arm64"

    cc_toolchain_info_file = repository_ctx.path(repository_ctx.attr.cc_toolchain_info)
    if not cc_toolchain_info_file.exists and not repository_ctx.attr.fail_not_supported:
        return
    info = _parse_cc_toolchain_info(
        repository_ctx.read(cc_toolchain_info_file),
        cc_toolchain_info_file,
    )

    # Generate the cc_toolchain workspace following the example from
    # `@bazel_tools//tools/cpp:unix_cc_configure.bzl`.
    # Uses the corresponding templates from `@bazel_tools` as well, see the
    # private attributes of the `_nixpkgs_cc_toolchain_config` rule.
    repository_ctx.symlink(
        repository_ctx.path(repository_ctx.attr._unix_cc_toolchain_config),
        "cc_toolchain_config.bzl",
    )
    repository_ctx.symlink(
        repository_ctx.path(repository_ctx.attr._armeabi_cc_toolchain_config),
        "armeabi_cc_toolchain_config.bzl",
    )

    # A module map is required for clang starting from Bazel version 3.3.0.
    # https://github.com/bazelbuild/bazel/commit/8b9f74649512ee17ac52815468bf3d7e5e71c9fa
    bazel_version_match, bazel_from_source  = is_bazel_version_at_least("3.3.0")
    needs_module_map = info.is_clang and (bazel_version_match or bazel_from_source)
    if needs_module_map:
        generate_system_module_map = [
            repository_ctx.path(repository_ctx.attr._generate_system_module_map),
        ]
        repository_ctx.file(
            "module.modulemap",
            execute_or_fail(
                repository_ctx,
                generate_system_module_map + info.cxx_builtin_include_directories,
                "Failed to generate system module map.",
            ).stdout.strip(),
            executable = False,
        )
    cc_wrapper_src = (
        repository_ctx.attr._osx_cc_wrapper if darwin else repository_ctx.attr._linux_cc_wrapper
    )
    repository_ctx.template(
        "cc_wrapper.sh",
        repository_ctx.path(cc_wrapper_src),
        {
            "%{cc}": info.tool_paths["gcc"],
            "%{env}": "",
        },
    )
    if darwin:
        info.tool_paths["gcc"] = "cc_wrapper.sh"
        info.tool_paths["ar"] = info.tool_paths["libtool"]
    write_builtin_include_directory_paths(
        repository_ctx,
        info.tool_paths["gcc"],
        info.cxx_builtin_include_directories,
    )
    repository_ctx.template(
        "BUILD.bazel",
        repository_ctx.path(repository_ctx.attr._build),
        {
            "%{cc_toolchain_identifier}": "local",
            "%{name}": cpu_value,
            "%{modulemap}": ("\":module.modulemap\"" if needs_module_map else "None"),
            "%{supports_param_files}": "0" if darwin else "1",
            "%{cc_compiler_deps}": get_starlark_list(
                [":builtin_include_directory_paths"] + (
                    [":cc_wrapper"] if darwin else []
                ),
            ),
            "%{compiler}": "compiler",
            "%{abi_version}": "local",
            "%{abi_libc_version}": "local",
            "%{host_system_name}": "local",
            "%{target_libc}": "macosx" if darwin else "local",
            "%{target_cpu}": cpu_value,
            "%{target_system_name}": "local",
            "%{tool_paths}": ",\n        ".join(
                ['"%s": "%s"' % (k, v) for (k, v) in info.tool_paths.items()],
            ),
            "%{cxx_builtin_include_directories}": get_starlark_list(info.cxx_builtin_include_directories),
            "%{compile_flags}": get_starlark_list(info.compile_flags),
            "%{cxx_flags}": get_starlark_list(info.cxx_flags),
            "%{link_flags}": get_starlark_list(info.link_flags),
            "%{link_libs}": get_starlark_list(info.link_libs),
            "%{opt_compile_flags}": get_starlark_list(info.opt_compile_flags),
            "%{opt_link_flags}": get_starlark_list(info.opt_link_flags),
            "%{unfiltered_compile_flags}": get_starlark_list(info.unfiltered_compile_flags),
            "%{dbg_compile_flags}": get_starlark_list(info.dbg_compile_flags),
            "%{coverage_compile_flags}": get_starlark_list(info.coverage_compile_flags),
            "%{coverage_link_flags}": get_starlark_list(info.coverage_link_flags),
            "%{supports_start_end_lib}": repr(info.supports_start_end_lib),
        },
    )

_nixpkgs_cc_toolchain_config = repository_rule(
    _nixpkgs_cc_toolchain_config_impl,
    attrs = {
        "cc_toolchain_info": attr.label(),
        "fail_not_supported": attr.bool(),
        "_unix_cc_toolchain_config": attr.label(
            default = Label("@bazel_tools//tools/cpp:unix_cc_toolchain_config.bzl"),
        ),
        "_armeabi_cc_toolchain_config": attr.label(
            default = Label("@bazel_tools//tools/cpp:armeabi_cc_toolchain_config.bzl"),
        ),
        "_generate_system_module_map": attr.label(
            default = Label("@bazel_tools//tools/cpp:generate_system_module_map.sh"),
        ),
        "_osx_cc_wrapper": attr.label(
            default = Label("@bazel_tools//tools/cpp:osx_cc_wrapper.sh.tpl"),
        ),
        "_linux_cc_wrapper": attr.label(
            default = Label("@bazel_tools//tools/cpp:linux_cc_wrapper.sh.tpl"),
        ),
        "_build": attr.label(
            default = Label("@bazel_tools//tools/cpp:BUILD.tpl"),
        ),
    },
)

def _nixpkgs_cc_toolchain_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    exec_constraints, target_constraints = ensure_constraints(repository_ctx)

    repository_ctx.file(
        "BUILD.bazel",
        executable = False,
        content = """\
package(default_visibility = ["//visibility:public"])

toolchain(
    name = "cc-toolchain-{cpu}",
    toolchain = "@{cc_toolchain_config}//:cc-compiler-{cpu}",
    toolchain_type = "@rules_cc//cc:toolchain_type",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)

toolchain(
    name = "cc-toolchain-armeabi-v7a",
    toolchain = "@{cc_toolchain_config}//:cc-compiler-armeabi-v7a",
    toolchain_type = "@rules_cc//cc:toolchain_type",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = [
        "@platforms//cpu:arm",
        "@platforms//os:android",
    ],
)
""".format(
            cc_toolchain_config = repository_ctx.attr.cc_toolchain_config,
            cpu = cpu,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        ),
    )

_nixpkgs_cc_toolchain = repository_rule(
    _nixpkgs_cc_toolchain_impl,
    attrs = {
        "cc_toolchain_config": attr.string(),
        "exec_constraints": attr.string_list(),
        "target_constraints": attr.string_list(),
    },
)

def nixpkgs_cc_configure(
        name = "local_config_cc",
        attribute_path = "",
        nix_file = None,
        nix_file_content = "",
        nix_file_deps = [],
        repositories = {},
        repository = None,
        nixopts = [],
        quiet = False,
        fail_not_supported = True,
        exec_constraints = None,
        target_constraints = None,
        register = True,
        cc_lang = "c++"):
    """Use a CC toolchain from Nixpkgs. No-op if not a nix-based platform.

    By default, Bazel auto-configures a CC toolchain from commands (e.g.
    `gcc`) available in the environment. To make builds more hermetic, use
    this rule to specify explicitly which commands the toolchain should use.

    Specifically, it builds a Nix derivation that provides the CC toolchain
    tools in the `bin/` path and constructs a CC toolchain that uses those
    tools. Tools that aren't found are replaced by `${coreutils}/bin/false`.
    You can inspect the resulting `@<name>_info//:CC_TOOLCHAIN_INFO` to see
    which tools were discovered.

    If you specify the `nix_file` or `nix_file_content` argument, the CC
    toolchain is discovered by evaluating the corresponding expression. In
    addition, you may use the `attribute_path` argument to select an attribute
    from the result of the expression to use as the CC toolchain (see example below).

    If neither the `nix_file` nor `nix_file_content` argument is used, the
    toolchain is discovered from the `stdenv.cc` and the `stdenv.cc.bintools`
    attributes of the given `<nixpkgs>` repository.

    ```
    # use GCC 11
    nixpkgs_cc_configure(
      repository = "@nixpkgs",
      nix_file_content = "(import <nixpkgs> {}).gcc11",
    )
    ```
    ```
    # use GCC 11 (same result as above)
    nixpkgs_cc_configure(
      repository = "@nixpkgs",
      attribute_path = "gcc11",
      nix_file_content = "import <nixpkgs> {}",
    )
    ```
    ```
    # alternate usage without specifying `nix_file` or `nix_file_content`
    nixpkgs_cc_configure(
      repository = "@nixpkgs",
      attribute_path = "gcc11",
    )
    ```
    ```
    # use the `stdenv.cc` compiler (the default of the given @nixpkgs repository)
    nixpkgs_cc_configure(
      repository = "@nixpkgs",
    )
    ```

    This rule depends on [`rules_cc`](https://github.com/bazelbuild/rules_cc).

    **Note:**
    You need to configure `--crosstool_top=@<name>//:toolchain` to activate
    this toolchain.

    Args:
      attribute_path: optional, string, Obtain the toolchain from the Nix expression under this attribute path. Uses default repository if no `nix_file` or `nix_file_content` is provided.
      nix_file: optional, Label, Obtain the toolchain from the Nix expression defined in this file. Specify only one of `nix_file` or `nix_file_content`.
      nix_file_content: optional, string, Obtain the toolchain from the given Nix expression. Specify only one of `nix_file` or `nix_file_content`.
      nix_file_deps: optional, list of Label, Additional files that the Nix expression depends on.
      repositories: dict of Label to string, Provides `<nixpkgs>` and other repositories. Specify one of `repositories` or `repository`.
      repository: Label, Provides `<nixpkgs>`. Specify one of `repositories` or `repository`.
      nixopts: optional, list of string, Extra flags to pass when calling Nix. See `nixopts` attribute to `nixpkgs_package` for further details.
      quiet: bool, Whether to hide `nix-build` output.
      fail_not_supported: bool, Whether to fail if `nix-build` is not available.
      exec_constraints: Constraints for the execution platform.
      target_constraints: Constraints for the target platform.
      register: bool, enabled by default, Whether to register (with `register_toolchains`) the generated toolchain and install it as the default cc_toolchain.
      cc_lang: string, `"c++"` by default. Used to populate `CXX_FLAG` so the compiler is called in C++ mode. Can be set to `"none"` together with appropriate `copts` in the `cc_library` call: see above.
    """

    nixopts = list(nixopts)
    nix_file_deps = list(nix_file_deps)

    nix_expr = None
    if nix_file and nix_file_content:
        fail("Cannot specify both 'nix_file' and 'nix_file_content'.")
    elif nix_file:
        nix_expr = "import $(location {})".format(nix_file)
        nix_file_deps.append(nix_file)
    elif nix_file_content:
        nix_expr = nix_file_content
    elif attribute_path:
        nix_expr = "(import <nixpkgs> {{}}).{0}".format(attribute_path)
        attribute_path = None

    if attribute_path:
        nixopts.extend([
            "--argstr",
            "ccType",
            "ccTypeAttribute",
            "--argstr",
            "ccAttrPath",
            attribute_path,
            "--arg",
            "ccAttrSet",
            nix_expr,
            "--argstr",
            "ccLang",
            cc_lang,
        ])
    elif nix_expr:
        nixopts.extend([
            "--argstr",
            "ccType",
            "ccTypeExpression",
            "--arg",
            "ccExpr",
            nix_expr,
            "--argstr",
            "ccLang",
            cc_lang,
        ])
    else:
        nixopts.extend([
            "--argstr",
            "ccType",
            "ccTypeDefault",
            "--argstr",
            "ccLang",
            cc_lang,
        ])

    # Invoke `cc.nix` which generates `CC_TOOLCHAIN_INFO`.
    nixpkgs_package(
        name = "{}_info".format(name),
        nix_file = "@rules_nixpkgs_cc//:cc.nix",
        nix_file_deps = nix_file_deps,
        build_file_content = "exports_files(['CC_TOOLCHAIN_INFO'])",
        repositories = repositories,
        repository = repository,
        nixopts = nixopts,
        quiet = quiet,
        fail_not_supported = fail_not_supported,
    )

    # Generate the `cc_toolchain_config` workspace.
    _nixpkgs_cc_toolchain_config(
        name = "{}".format(name),
        cc_toolchain_info = "@{}_info//:CC_TOOLCHAIN_INFO".format(name),
        fail_not_supported = fail_not_supported,
    )

    # Generate the `cc_toolchain` workspace.
    if (exec_constraints == None) != (target_constraints == None):
        fail("Both exec_constraints and target_constraints need to be provided or none of them.")
    _nixpkgs_cc_toolchain(
        name = "{}_toolchains".format(name),
        cc_toolchain_config = name,
        exec_constraints = exec_constraints,
        target_constraints = target_constraints,
    )

    if register:
        maybe(
            native.bind,
            name = "cc_toolchain",
            actual = "@{}//:toolchain".format(name),
        )
        native.register_toolchains("@{}_toolchains//:all".format(name))
