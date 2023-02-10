load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_nixpkgs_go//:go.bzl", "nixpkgs_go_configure")

def nixpkgs_repositories(*, bzlmod):
    nixpkgs_local_repository(
        name = "nixpkgs",
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "jdk11.home",
        repository = "@nixpkgs",
        toolchain = True,
        register = not bzlmod,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "11",
    )

    nixpkgs_go_configure(
        repository = "@nixpkgs",
    )
