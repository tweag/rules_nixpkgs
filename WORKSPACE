workspace(name = "io_tweag_rules_nixpkgs")

# For documentation

local_repository(
    name = "rules_nixpkgs_docs",
    path = "./docs",
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load("@rules_nixpkgs_docs//:dependencies_1.bzl", "docs_dependencies_1")

docs_dependencies_1()

load("@rules_nixpkgs_docs//:dependencies_2.bzl", "docs_dependencies_2")

docs_dependencies_2()

# For tests

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_git_repository",
    "nixpkgs_package",
)

nixpkgs_package(
    name = "nix_2_24",
    attribute_path = "nixVersions.nix_2_24",
    repositories = {"nixpkgs": "@nixpkgs"},
)

# This is used to run Nix in a sandboxed Bazel test. See the test
# `run-test-invalid-nixpkgs-package`.
nixpkgs_package(
    name = "coreutils_static",
    # Work around https://github.com/tweag/rules_nixpkgs/issues/424.
    # `pkgsStatic.coreutils` stopped working on MacOS 11 with x86_64 as used on GitHub actions CI.
    # Fall back to `pkgs.coreutils` on MacOS.
    nix_file_content = "let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in if pkgs.stdenv.isDarwin then pkgs.coreutils else pkgs.pkgsStatic.coreutils",
    repository = "@nixpkgs",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


http_archive(
    name = "rules_proto",
    sha256 = "0e5c64a2599a6e26c6a03d6162242d231ecc0de219534c38cb4402171def21e8",
    strip_prefix = "rules_proto-7.0.2",
    url = "https://github.com/bazelbuild/rules_proto/releases/download/7.0.2/rules_proto-7.0.2.tar.gz",
)

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies")

rules_proto_dependencies()

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "68af54cb97fbdee5e5e8fe8d210d15a518f9d62abfd71620c3eaff3b26a5ff86",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.59.0/rules_go-v0.59.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.59.0/rules_go-v0.59.0.zip",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies")

go_rules_dependencies()
