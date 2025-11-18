load("@rules_nixpkgs_cc//:cc.bzl", "nixpkgs_cc_configure")

def _cc_configure_impl(module_ctx):
    nixpkgs_cc_configure(
        name = "nixpkgs_config_cc",
        nix_file = "//toolchains:cc.nix",
        repository = "@nixpkgs",
        register = False,
    )

    nixpkgs_cc_configure(
        name = "nixpkgs_cross_cc",
        cross_cpu = "k8",
        exec_constraints = [
            "@platforms//os:osx",
            "@platforms//cpu:arm64",
        ],
        nix_file = "//toolchains:osxcross_cc.nix",
        nixopts = [
            "--arg",
            "ccPkgs",
            "import <nixpkgs> { crossSystem = \"x86_64-linux\";}",
            "--show-trace",
        ],
        repository = "@nixpkgs",
        target_constraints = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
            "@rules_nixpkgs_core//constraints:support_nix",
        ],
        register = False,
    )


cc_configure = module_extension(
    implementation = _cc_configure_impl,
)
