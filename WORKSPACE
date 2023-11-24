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
    name = "nix_2_10",
    attribute_path = "nixVersions.nix_2_10",
    repositories = {"nixpkgs": "@nixpkgs"},
)

# This is used to run Nix in a sandboxed Bazel test. See the test
# `run-test-invalid-nixpkgs-package`.
nixpkgs_package(
    name = "coreutils_static",
    attribute_path = "pkgsStatic.coreutils",
    repository = "@nixpkgs",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "6dc2da7ab4cf5d7bfc7c949776b1b7c733f05e56edc4bcd9022bb249d2e2a996",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.39.1/rules_go-v0.39.1.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.39.1/rules_go-v0.39.1.zip",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies")

go_rules_dependencies()
