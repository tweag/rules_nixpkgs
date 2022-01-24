load("//nixpkgs:nixpkgs.bzl", "nixpkgs_package")
load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

_foreign_cc_nix_build = """
load("@rules_foreign_cc//toolchains/native_tools:native_tools_toolchain.bzl", "native_tool_toolchain")

filegroup(
    name = "data",
    srcs = glob(["bin/**"]),
)
native_tool_toolchain(
    name = "cmake_nix_impl",
    path = "bin/cmake",
    target = ":data",
)
native_tool_toolchain(
    name = "make_nix_impl",
    path = "bin/make",
    target = ":data",
)
native_tool_toolchain(
    name = "ninja_nix_impl",
    path = "bin/ninja",
    target = ":data",
)
"""

_foreign_cc_nix_toolchain = """
toolchain(
    name = "cmake_nix_toolchain",
    toolchain = "@{toolchain_repo}//:cmake_nix_impl",
    toolchain_type = "@rules_foreign_cc//toolchains:cmake_toolchain",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
toolchain(
    name = "make_nix_toolchain",
    toolchain = "@{toolchain_repo}//:make_nix_impl",
    toolchain_type = "@rules_foreign_cc//toolchains:make_toolchain",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
toolchain(
    name = "ninja_nix_toolchain",
    toolchain = "@{toolchain_repo}//:ninja_nix_impl",
    toolchain_type = "@rules_foreign_cc//toolchains:ninja_toolchain",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
"""

def _ensure_constraints(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    os = {"darwin": "osx"}.get(cpu, "linux")
    if not repository_ctx.attr.target_constraints and not repository_ctx.attr.exec_constraints:
        target_constraints = ["@platforms//cpu:x86_64"]
        target_constraints.append("@platforms//os:{}".format(os))
        exec_constraints = target_constraints
    else:
        target_constraints = list(repository_ctx.attr.target_constraints)
        exec_constraints = list(repository_ctx.attr.exec_constraints)
    exec_constraints.append("@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix")
    return exec_constraints, target_constraints

def _nixpkgs_foreign_cc_toolchain_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    exec_constraints, target_constraints = _ensure_constraints(repository_ctx)
    repository_ctx.file(
            "BUILD.bazel",
            executable = False,
            content = _foreign_cc_nix_toolchain.format(
                    toolchain_repo = repository_ctx.attr.toolchain_repo,
                    exec_constraints = exec_constraints,
                    target_constraints = target_constraints
            )
    )

_nixpkgs_foreign_cc_toolchain = repository_rule(
    _nixpkgs_foreign_cc_toolchain_impl,
    attrs = {
        "toolchain_repo": attr.string(),
        "exec_constraints": attr.string_list(),
        "target_constraints": attr.string_list(),
    },
)

def nixpkgs_foreign_cc_configure(
        name = "foreign_cc_nix",
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = [],
        fail_not_supported = True,
        quiet = False,
        exec_constraints = None,
        target_constraints = None,
):
    if not nix_file and not nix_file_content:
        nix_file_content = """
            with import <nixpkgs> { config = {}; overlays = []; }; buildEnv {
              name = "bazel-foreign-cc-toolchain";
              paths = [ cmake gnumake ninja glibc ];
            }
        """
    nixpkgs_package(
        name = name,
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        build_file_content = _foreign_cc_nix_build,
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )
    _nixpkgs_foreign_cc_toolchain(
        name = name + "_toolchain",
        toolchain_repo = name,
        exec_constraints = exec_constraints,
        target_constraints = target_constraints,
    )
    native.register_toolchains(
        str(Label("@{}_toolchain//:cmake_nix_toolchain".format(name))),
        str(Label("@{}_toolchain//:make_nix_toolchain".format(name))),
        str(Label("@{}_toolchain//:ninja_nix_toolchain".format(name))),
    )
