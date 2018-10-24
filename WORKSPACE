workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")

# For tests

nixpkgs_git_repository(
  name = "remote_nixpkgs",
  remote = "https://github.com/NixOS/nixpkgs",
  revision = "18.09",
  sha256 = "6451af4083485e13daa427f745cbf859bc23cb8b70454c017887c006a13bd65e",
)

nixpkgs_package(
    name = "nixpkgs-git-repository-test",
    repositories = { "nixpkgs": "@remote_nixpkgs//:default.nix" },
    attribute_path = "hello",
)

nixpkgs_package(
  name = "hello",
  # deliberately not repositories, to test whether repository still works
  repository = "//:nixpkgs.nix"
)

nixpkgs_package(
  name = "expr-test",
  nix_file_content = "let pkgs = import <nixpkgs> {}; in pkgs.hello",
  repositories = { "nixpkgs": "//:nixpkgs.nix" }
)

nixpkgs_package(
  name = "attribute-test",
  attribute_path = "hello",
  repositories = { "nixpkgs": "//:nixpkgs.nix" }
)

nixpkgs_package(
  name = "expr-attribute-test",
  nix_file_content = "import <nixpkgs> {}",
  attribute_path = "hello",
  repositories = { "nixpkgs": "//:nixpkgs.nix" },
)

nixpkgs_package(
  name = "nix-file-test",
  nix_file = "//tests:nixpkgs.nix",
  attribute_path = "hello",
  repositories = { "nixpkgs": "//:nixpkgs.nix" },
)

nixpkgs_package(
  name = "nix-file-deps-test",
  nix_file = "//tests:hello.nix",
  nix_file_deps = ["//tests:pkgname.nix"],
  repositories = { "nixpkgs": "//:nixpkgs.nix" },
)
