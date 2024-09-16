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
    name = "nix_2_18",
    attribute_path = "nixVersions.nix_2_18",
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
    sha256 = "6fb6767d1bef535310547e03247f7518b03487740c11b6c6adb7952033fe1295",
    strip_prefix = "rules_proto-6.0.2",
    url = "https://github.com/bazelbuild/rules_proto/releases/download/6.0.2/rules_proto-6.0.2.tar.gz",
)

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies")

rules_proto_dependencies()

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "f4a9314518ca6acfa16cc4ab43b0b8ce1e4ea64b81c38d8a3772883f153346b8",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.50.1/rules_go-v0.50.1.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.50.1/rules_go-v0.50.1.zip",
    ],
)

load(
    "//nixpkgs:toolchains/go.bzl",
    "nixpkgs_go_configure",
)

nixpkgs_go_configure(repository = "@nixpkgs")

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies")

go_rules_dependencies()
