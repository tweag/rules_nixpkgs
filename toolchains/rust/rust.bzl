"""<!-- Edit the docstring in `toolchains/rust/rust.bzl` and run `bazel run //docs:update-README.md` to change this repository's `README.md`. -->

Rules for importing a Rust and rustfmt toolchain from Nixpkgs.

# Rules

* [nixpkgs_rust_configure](#nixpkgs_rust_configure)
"""

load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")
load("@rules_nixpkgs_core//:util.bzl", "ensure_constraints")

# Adapted from rules_rust toolchain BUILD:
# https://github.com/bazelbuild/rules_rust/blob/fd436df9e2d4ac1b234ca5e969e34a4cb5891910/rust/private/repository_utils.bzl#L17-L46
# Nix generation is used to dynamically compute both Linux and Darwin environments
_rust_nix_contents = """\
let
    pkgs = import <nixpkgs> {{ config = {{}}; overrides = []; }};
    rust = pkgs.rust;
    os = rust.toTargetOs pkgs.stdenv.targetPlatform;
    build-triple = rust.toRustTargetSpec pkgs.stdenv.buildPlatform;
    target-triple = rust.toRustTargetSpec pkgs.stdenv.targetPlatform;
    rustc = if os == "macos" then
      # rustc on MacOS expects the `strip` binary in PATH, create a wrapper adding the bin
      # folder from `binutils` to the PATH
      pkgs.symlinkJoin
        {{
          name = "rustc";
          paths = [ pkgs.rustc ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/rustc --suffix PATH : ${{pkgs.darwin.cctools}}/bin
          '';
        }}
      else pkgs.rustc;
    binary-ext = "";
    staticlib-ext = ".a";
    dylib-ext = if os == "macos" then ".dylib" else ".so";
in
pkgs.buildEnv {{
    extraOutputsToInstall = ["out" "bin" "lib"];
    ignoreCollisions = true;
    name = "bazel-rust-toolchain";
    paths = [ rustc (pkgs.rustc.unwrapped or null) pkgs.rustfmt pkgs.cargo pkgs.clippy ];
    postBuild = ''
        cat <<EOF > $out/BUILD
        filegroup(
            name = "rustc",
            srcs = ["bin/rustc"],
            visibility = ["//visibility:public"],
        )

        filegroup(
            name = "rustfmt",
            srcs = ["bin/rustfmt"],
            visibility = ["//visibility:public"],
        )

        filegroup(
            name = "cargo",
            srcs = ["bin/cargo"],
            visibility = ["//visibility:public"],
        )

        filegroup(
            name = "clippy_driver",
            srcs = ["bin/clippy-driver"],
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
            name = "rust_std",
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

        load('@rules_rust//rust:toolchain.bzl', 'rust_toolchain', 'rustfmt_toolchain')
        rust_toolchain(
            name = "rust_nix_impl",
            rust_doc = ":rust_doc",
            rust_std = ":rust_std",
            rustc = ":rustc",
            rustfmt = ":rustfmt",
            cargo = ":cargo",
            clippy_driver = ":clippy_driver",
            rustc_lib = ":rustc_lib",
            binary_ext = "${{binary-ext}}",
            staticlib_ext = "${{staticlib-ext}}",
            dylib_ext = "${{dylib-ext}}",
            exec_triple = "${{build-triple}}",
            target_triple = "${{target-triple}}",
            default_edition = "{default_edition}",
            stdlib_linkflags = {stdlib_linkflags},
            visibility = ["//visibility:public"],
        )

        rustfmt_toolchain(
            name = "rustfmt_nix_impl",
            rustfmt = ":rustfmt",
            visibility = ["//visibility:public"],
        )
        EOF
    '';
}}
"""

_rust_nix_toolchain = """
toolchain(
    name = "rust_nix",
    toolchain = "@{toolchain_repo}//:rust_nix_impl",
    toolchain_type = "@rules_rust//rust:toolchain",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)

toolchain(
    name = "rustfmt_nix",
    toolchain = "@{toolchain_repo}//:rustfmt_nix_impl",
    toolchain_type = "@rules_rust//rust/rustfmt:toolchain_type",
    exec_compatible_with = {exec_constraints},
    target_compatible_with = {target_constraints},
)
"""

def _nixpkgs_rust_toolchain_impl(repository_ctx):
    exec_constraints, target_constraints = ensure_constraints(repository_ctx)
    repository_ctx.file(
        "BUILD.bazel",
        executable = False,
        content = _rust_nix_toolchain.format(
            toolchain_repo = repository_ctx.attr.toolchain_repo,
            exec_constraints = exec_constraints,
            target_constraints = target_constraints,
        ),
    )

_nixpkgs_rust_toolchain = repository_rule(
    _nixpkgs_rust_toolchain_impl,
    attrs = {
        "toolchain_repo": attr.string(),
        "exec_constraints": attr.string_list(),
        "target_constraints": attr.string_list(),
    },
)

def nixpkgs_rust_configure(
        name = "nixpkgs_rust",
        default_edition = "2018",
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
        register = True):
    if not nix_file and not nix_file_content:
        nix_file_content = _rust_nix_contents.format(
            default_edition = default_edition,
            stdlib_linkflags = '["-lpthread", "-ldl"]',
        )

    nixpkgs_package(
        name = name,
        repository = repository,
        repositories = repositories,
        nix_file = nix_file,
        nix_file_deps = nix_file_deps,
        nix_file_content = nix_file_content,
        nixopts = nixopts,
        fail_not_supported = fail_not_supported,
        quiet = quiet,
    )
    _nixpkgs_rust_toolchain(
        name = name + "_toolchain",
        toolchain_repo = name,
        exec_constraints = exec_constraints,
        target_constraints = target_constraints,
    )
    if register:
        native.register_toolchains("@{}_toolchain//:rust_nix".format(name))
