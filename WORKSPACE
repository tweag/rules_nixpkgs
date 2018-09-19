workspace(name = "io_tweag_rules_nixpkgs")

load("//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")
load("//nix:import_fetch_builtin.bzl", "nix_import_fetch_builtin")

# For tests

nixpkgs_git_repository(
  name = "nixpkgs",
  revision = "17.09",
  sha256 = "405f1d6ba523630c83fbabef93f0da11ea388510a576adf2ded26a744fbf793e",
)

# imports nixpkgs from a nix file (via fetchTarball)
nix_import_fetch_builtin(
  name = "nixpkgs_fetchTarball",
  nix_file = "//tests:fetchTarball.nix",
)

nixpkgs_package(
  name = "hello-fetchTarball",
  attribute_path = "hello",
  # TODO(Profpatsch): why does it work as "@nixpkgs" with nixpkgs_git_repository?
  # How/where is the default file defined?
  repository = "@nixpkgs_fetchTarball//:default.nix"
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

