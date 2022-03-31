workspace(name = "io_tweag_rules_nixpkgs")

# For documentation

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load("@rules_nixpkgs_core//docs:dependencies_1.bzl", "docs_dependencies_1")

docs_dependencies_1()

load("@rules_nixpkgs_core//docs:dependencies_2.bzl", "docs_dependencies_2")

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

# This is the commit introducing a Nix version working in the Bazel
# sandbox
nixpkgs_git_repository(
    name = "remote_nixpkgs_for_nix_unstable",
    remote = "https://github.com/NixOS/nixpkgs",
    revision = "15d1011615d16a8b731adf28e2cfc33481102780",
    sha256 = "8b1161a249d50effea1f240c34a81832a88c8d5d274314ae6225fd78bd62dfb9",
)

nixpkgs_package(
    name = "nix-unstable",
    attribute_path = "nixUnstable",
    repositories = {"nixpkgs": "@remote_nixpkgs_for_nix_unstable"},
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
    sha256 = "7c10271940c6bce577d51a075ae77728964db285dac0a46614a7934dc34303e6",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.26.0/rules_go-v0.26.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.26.0/rules_go-v0.26.0.tar.gz",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies")

go_rules_dependencies()
