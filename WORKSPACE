workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")

# For tests

nixpkgs_git_repository(
  name = "nixpkgs",
  revision = "17.09",
)

nixpkgs_package(name = "hello", repository = "@nixpkgs")
