workspace(name = "io_tweag_rules_nixpkgs")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_cc_configure",
    "nixpkgs_git_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

load(
    "//nixpkgs:toolchain.bzl",
    "nix_register_toolchains",
    "nix_download_toolchain",
)

# For tests

new_http_archive(
    name = "nix_user_chroot",
    urls = ["https://github.com/lethalman/nix-user-chroot/archive/809dda7f0a370e069b6bb9d818abebb059806675.tar.gz"],
    strip_prefix = "nix-user-chroot-809dda7f0a370e069b6bb9d818abebb059806675",
    build_file_content = """
package(default_visibility = ["//visibility:public"])

cc_binary(
    name = "nix_user_chroot",
    srcs = ["main.c"],
)
    """
)

new_http_archive(
    name = "nix_source",
    urls = ["https://nixos.org/releases/nix/nix-2.1.3/nix-2.1.3-x86_64-linux.tar.bz2"],
    strip_prefix = "nix-2.1.3-x86_64-linux",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
"""
)

nix_download_toolchain(
    name = "nix",
    nix_installer = "@nix_source//:install",
    nix_user_chroot_src = "@nix_user_chroot//:main.c",
    nix_store_path = "/tmp/nix",
)

nixpkgs_git_repository(
    name = "remote_nixpkgs",
    remote = "https://github.com/NixOS/nixpkgs",
    revision = "18.09",
    sha256 = "6451af4083485e13daa427f745cbf859bc23cb8b70454c017887c006a13bd65e",
)

nixpkgs_local_repository(
    name = "nixpkgs",
    nix_file = "//:nixpkgs.nix",
)

nixpkgs_package(
    name = "nixpkgs-git-repository-test",
    attribute_path = "hello",
    repositories = {"nixpkgs": "@remote_nixpkgs"},
)

nixpkgs_package(
    name = "hello",
    # Deliberately not repository, to test whether repositories works.
    repositories = {"nixpkgs": "@nixpkgs"},
)

nixpkgs_package(
    name = "expr-test",
    nix_file_content = "let pkgs = import <nixpkgs> {}; in pkgs.hello",
    # Deliberately not @nixpkgs, to test whether explict file works.
    repositories = {"nixpkgs": "//:nixpkgs.nix"},
)

nixpkgs_package(
    name = "attribute-test",
    attribute_path = "hello",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "expr-attribute-test",
    attribute_path = "hello",
    nix_file_content = "import <nixpkgs> {}",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "nix-file-test",
    attribute_path = "hello",
    nix_file = "//tests:nixpkgs.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "nix-file-deps-test",
    nix_file = "//tests:hello.nix",
    nix_file_deps = ["//tests:pkgname.nix"],
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "output-filegroup-test",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "extra-args-test",
    nix_file_content = """
{ packagePath }: (import <nixpkgs> {}).${packagePath}
    """,
    repository = "@nixpkgs",
    nixopts = ["--argstr", "packagePath", "hello"],
)

nixpkgs_package(
    name = "output-filegroup-manual-test",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
filegroup(
    name = "manual-filegroup",
    srcs = glob(["hi-i-exist", "hi-i-exist-too", "bin/*"]),
)
""",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

# nixpkgs_cc_configure(repository = "@remote_nixpkgs")
