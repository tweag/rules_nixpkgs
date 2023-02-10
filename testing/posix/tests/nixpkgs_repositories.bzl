load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_nixpkgs_posix//:posix.bzl", "nixpkgs_sh_posix_configure")

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

    nixpkgs_sh_posix_configure(
        name = "nixpkgs_sh_posix_config",
        repository = "@nixpkgs",
        register = not bzlmod,
    )
