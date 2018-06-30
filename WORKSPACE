workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")

# For tests

nixpkgs_git_repository(
  name = "nixpkgs",
  revision = "17.09",
  sha256 = "405f1d6ba523630c83fbabef93f0da11ea388510a576adf2ded26a744fbf793e",
)

nixpkgs_package(name = "hello", repository = "@nixpkgs")

nixpkgs_package(
  name = "expr-test",
  nix_file_content = "let pkgs = import <nixpkgs> {}; in pkgs.hello",
  repository = "@nixpkgs"
)

nixpkgs_package(
  name = "attribute-test",
  attribute_path = "hello",
  repository = "@nixpkgs"
)

nixpkgs_package(
  name = "expr-attribute-test",
  nix_file_content = "import <nixpkgs> {}",
  attribute_path = "hello",
  repository = "@nixpkgs",
)

nixpkgs_package(
  name = "nix-file-test",
  nix_file = "//tests:nixpkgs.nix",
  attribute_path = "hello",
  repository = "@nixpkgs",
)

nixpkgs_package(
  name = "nix-file-deps-test",
  nix_file = "//tests:hello.nix",
  nix_file_deps = ["//tests:pkgname.nix"],
  repository = "@nixpkgs",
)

