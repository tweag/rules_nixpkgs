load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

def nixpkgs_repositories():
    nixpkgs_local_repository(
        name = "nixpkgs",
        # TODO[AH] Remove these files from
        # rules_nixpkgs_core.
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
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

    nixpkgs_package(
        name = "attribute-test",
        attribute_path = "hello",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "expr-attribute-test",
        attribute_path = "hello",
        nix_file_content = "import <nixpkgs> { config = {}; overlays = []; }",
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
