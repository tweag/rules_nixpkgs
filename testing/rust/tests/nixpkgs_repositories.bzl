load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_nixpkgs_rust//:rust.bzl", "nixpkgs_rust_configure")

def nixpkgs_repositories(*, bzlmod):
    nixpkgs_local_repository(
        name = "nixpkgs",
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        register = not bzlmod,
    )

    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "jdk17.home",
        repository = "@nixpkgs",
        toolchain = True,
        register = not bzlmod,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "17",
    )

    nixpkgs_rust_configure(
        repository = "@nixpkgs",
        name = "nixpkgs_config_rust",
        register = not bzlmod,
    )
