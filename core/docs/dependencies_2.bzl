# NOTE: temporary for compatibility with `WORKSPACE` setup!
# TODO: remove when migration to `bzlmod` is complete

# this has to be split into `docs_dependencies_1` and `docs_dependencies_2`
# because Bazel is imperative, and requires `load()` to be a top-level
# statement.
load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_local_repository")
load("@rules_nixpkgs_java//:java.bzl", "nixpkgs_java_configure")
load("@rules_sh//sh:repositories.bzl", "rules_sh_dependencies")
load("@rules_sh//sh:posix.bzl", "sh_posix_configure")
load("@rules_nixpkgs_posix//:posix.bzl", "nixpkgs_sh_posix_configure")
load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")
load("@rules_java//java:repositories.bzl", "rules_java_dependencies", "rules_java_toolchains")
load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

def docs_dependencies_2():
    nixpkgs_local_repository(
        name = "nixpkgs",
        nix_file = "@rules_nixpkgs_core//:nixpkgs.nix",
        nix_file_deps = ["@rules_nixpkgs_core//:flake.lock"],
    )

    rules_sh_dependencies()
    nixpkgs_sh_posix_configure(repository = "@nixpkgs")
    sh_posix_configure()

    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        repository = "@nixpkgs",
    )

    rules_java_dependencies()

    nixpkgs_java_configure(
        attribute_path = "jdk11.home",
        repository = "@nixpkgs",
        toolchain = True,
        toolchain_name = "nixpkgs_java",
        toolchain_version = "11",
    )

    rules_java_toolchains()

    stardoc_repositories()
