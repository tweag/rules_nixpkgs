workspace(name = "io_tweag_rules_nixpkgs")

# For documentation

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//docs:dependencies_1.bzl", "docs_dependencies_1")

docs_dependencies_1()

load("@io_tweag_rules_nixpkgs//docs:dependencies_2.bzl", "docs_dependencies_2")

docs_dependencies_2()

# For tests

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_git_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

nixpkgs_local_repository(
    name = "nixpkgs",
    nix_file = "@rules_nixpkgs_core//:nixpkgs.nix",
    nix_file_deps = ["@rules_nixpkgs_core//:nixpkgs.json"],
)

nixpkgs_package(
    name = "nix_2_7",
    attribute_path = "nixVersions.nix_2_7",
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
    sha256 = "685052b498b6ddfe562ca7a97736741d87916fe536623afb7da2824c0211c369",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.33.0/rules_go-v0.33.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.33.0/rules_go-v0.33.0.zip",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies")

go_rules_dependencies()
