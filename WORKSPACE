workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")

# For tests

nixpkgs_git_repository(
  name = "nixpkgs",
  revision = "17.09",
)

nixpkgs_package(name = "hello", repository = "@nixpkgs")

nixpkgs_package(
  name = "expr-test",
  expression = "let pkgs = import <nixpkgs> {}; in pkgs.hello",
  repository = "@nixpkgs"
)

nixpkgs_package(
  name = "attribute-test",
  attribute = "hello",
  repository = "@nixpkgs"
)

nixpkgs_package(
  name = "expr-attribute-test",
  expression = "import <nixpkgs> {}",
  attribute = "hello",
  repository = "@nixpkgs",
)
