workspace(name = "io_tweag_rules_nixpkgs")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")

rules_nixpkgs_dependencies()

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_cc_configure",
    "nixpkgs_git_repository",
    "nixpkgs_java_configure",
    "nixpkgs_local_repository",
    "nixpkgs_package",
    "nixpkgs_python_configure",
    "nixpkgs_sh_posix_configure",
)

# For documentation

http_archive(
    name = "io_bazel_stardoc",
    sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c",
    strip_prefix = "stardoc-0.4.0",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz",
        "https://github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz",
    ],
)

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()

# For tests

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

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

nixpkgs_cc_configure(
    # Use a different name to be able to distinguish this toolchain from the
    # builtin one in the tests.
    name = "nixpkgs_config_cc",
    repository = "@remote_nixpkgs",
)

load("@rules_java//java:repositories.bzl", "rules_java_dependencies")

rules_java_dependencies()

nixpkgs_java_configure(
    attribute_path = "jdk8.home",
    repository = "@remote_nixpkgs",
)

nixpkgs_python_configure(
    python2_attribute_path = "python2",
    repository = "@remote_nixpkgs",
)

nixpkgs_package(
    name = "nixpkgs_python_configure_test",
    nix_file = "//tests:python-test.nix",
    repository = "@remote_nixpkgs",
)

http_archive(
    name = "rules_sh",
    sha256 = "83a065ba6469135a35786eb741e17d50f360ca92ab2897857475ab17c0d29931",
    strip_prefix = "rules_sh-0.2.0",
    urls = ["https://github.com/tweag/rules_sh/archive/v0.2.0.tar.gz"],
)

load("@rules_sh//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

nixpkgs_sh_posix_configure(repository = "@nixpkgs")

load("@rules_sh//sh:posix.bzl", "sh_posix_configure")

sh_posix_configure()

# go toolchain test

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
