load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

def _non_module_deps_impl(ctx):
    nixpkgs_local_repository(
        name = "nixpkgs",
        # TODO[AH] Move these files out of
        #   rules_nixpkgs_core into this testing module.
        nix_file = "@rules_nixpkgs_core//:nixpkgs.nix",
        nix_file_deps = ["@rules_nixpkgs_core//:flake.lock"],
    )

    nixpkgs_package(
        name = "hello",
        # Deliberately not repository, to test whether repositories works.
        repositories = {"nixpkgs": "@nixpkgs"},
    )

    nixpkgs_package(
        name = "expr-test",
        nix_file_content = "let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.hello",
        nix_file_deps = ["//:flake.lock"],
        # Deliberately not @nixpkgs, to test whether explict file works.
        repositories = {"nixpkgs": "//:nixpkgs.nix"},
    )

non_module_deps = module_extension(
    implementation = _non_module_deps_impl,
)
