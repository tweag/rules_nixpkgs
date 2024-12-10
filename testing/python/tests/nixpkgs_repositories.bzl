load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_nixpkgs_python//:python.bzl", "nixpkgs_python_configure", "nixpkgs_python_repository")
load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_package")

def nixpkgs_repositories(*, bzlmod):
    nixpkgs_local_repository(
        name = "nixpkgs",
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    nixpkgs_local_repository(
        name = "poetry2nix",
        nix_file = "//:poetry2nix.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    # Tests implicitly depend on Java
    nixpkgs_java_configure(
        name = "nixpkgs_java_runtime",
        attribute_path = "jdk17.home",
        repository = "@nixpkgs",
        toolchain = True,
        register = not bzlmod,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "17",
    )

    # Python depends on a CC toolchain being available
    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
        register = not bzlmod,
    )

    nixpkgs_python_configure(
        python3_attribute_path = "python3",
        repository = "@nixpkgs",
        register = not bzlmod,
    )

    nixpkgs_package(
        name = "nixpkgs_python_configure_test",
        nix_file = "//tests:python-test.nix",
        repository = "@nixpkgs",
    )

    nixpkgs_python_repository(
        name = "poetry_packages",
        repositories = {
            "nixpkgs": "@nixpkgs",
            "poetry2nix": "@poetry2nix",
        },
        nix_file = "//:poetry.nix",
        nix_file_deps = [
            "//:pyproject.toml",
            "//:poetry.lock",
        ],
    )

    nixpkgs_python_repository(
        name = "vanilla_packages",
        repository = "@nixpkgs",
        nix_file = "//:vanilla.nix",
    )
