load("//nixpkgs:nixpkgs.bzl", "nixpkgs_package")
load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")

_rust_nix_build = """\
filegroup(
    name = "rustc",
    srcs = ["bin/rustc"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "cargo",
    srcs = ["bin/cargo"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "rustc_lib",
    srcs = glob(
        [
            "bin/*.so",
            "lib/*.so",
            "lib/rustlib/*/codegen-backends/*.so",
            "lib/rustlib/*/codegen-backends/*.dylib",
            "lib/rustlib/*/bin/rust-lld",
            "lib/rustlib/*/lib/*.so",
            "lib/rustlib/*/lib/*.dylib",
        ],
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
)

load("@rules_rust//rust:toolchain.bzl", "rust_stdlib_filegroup")
rust_stdlib_filegroup(
    name = "rust_lib",
    srcs = glob(
        [
            "lib/rustlib/*/lib/*.rlib",
            "lib/rustlib/*/lib/*.so",
            "lib/rustlib/*/lib/*.dylib",
            "lib/rustlib/*/lib/*.a",
            "lib/rustlib/*/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "rust_doc",
    srcs = ["bin/rustdoc"],
    visibility = ["//visibility:public"],
)

load('@rules_rust//rust:toolchain.bzl', 'rust_toolchain')
rust_toolchain(
    name = "rust_nix_impl",
    rustc = ":rustc",
    rustc_lib = ":rustc_lib",
    rust_lib = ":rust_lib",
    rust_doc = ":rust_doc",
    binary_ext = "",
    staticlib_ext = ".a",
    dylib_ext = ".so",
    stdlib_linkflags = ["-lpthread", "-ldl"],
    os = "linux",
    target_triple = "x86_64-unknown-linux-gnu",
)
"""

_rust_nix_toolchain = """
toolchain(
    name = "rust_nix",
    toolchain = "@{toolchain_repo}//:rust_nix_impl",
    toolchain_type = "@rules_rust//rust:toolchain",
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

def _nixpkgs_rust_toolchain_impl(repository_ctx):
    exec_constraints = [ "@io_tweag_rules_nixpkgs//nixpkgs/constraints:support_nix", "@platforms//cpu:x86_64" ]
    target_constraints = [ "@platforms//cpu:x86_64" ]
    cpu = get_cpu_value(repository_ctx)
    repository_ctx.file(
            "BUILD.bazel",
            executable = False,
            content = _rust_nix_toolchain.format(
                    toolchain_repo = repository_ctx.attr.toolchain_repo,
                    exec_constraints = exec_constraints,
                    target_constraints = target_constraints
            )
    )

_nixpkgs_rust_toolchain = repository_rule(
    _nixpkgs_rust_toolchain_impl,
    attrs = {
        "toolchain_repo": attr.string(),
    },
)

def nixpkgs_rust_configure(
        sdk_name = "rust_sdk",
        repository = None,
        repositories = {},
        nix_file = None,
        nix_file_deps = None,
        nix_file_content = None,
        nixopts = [],
        fail_not_supported = True,
        quiet = False,
        ):
    if not nix_file and not nix_file_content:
        nix_file_content = """
            with import <nixpkgs> { config = {}; overlays = []; }; buildEnv {
              name = "bazel-rust-toolchain";
              paths = [
                rustc
              ];
            }
        """
    nixpkgs_package(
        name = sdk_name,
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        build_file_content = _rust_nix_build,
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )
    _nixpkgs_rust_toolchain(name = sdk_name + "_toolchain", toolchain_repo = sdk_name)
    native.register_toolchains("@{}_toolchain//:rust_nix".format(sdk_name))
