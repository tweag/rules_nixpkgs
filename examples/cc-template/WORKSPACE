# download the http_archive rule itself
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
# download rules_nixpkgs
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-9f08fb2322050991dead17c8d10d453650cf92b7",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/9f08fb2322050991dead17c8d10d453650cf92b7.tar.gz"],
    sha256 = "46aa0ca80b77848492aa1564e9201de9ed79588ca1284f8a4f76deb7a0eeccb9",
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
# load everything that rules_nixpkgs rules need to work (TODO: repo rules?)
rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package", "nixpkgs_cc_configure")
nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "22.05", # Any tag or commit hash
    sha256 = ""
)

nixpkgs_cc_configure(
  repository = "@nixpkgs",
  nix_file = "//:nixpkgs.nix",
  nix_file_deps = ["//:flake.lock"],
  attribute_path = "gcc11",
  name = "nixpkgs_config_cc",
)

http_archive(
    name = "rules_cc",
    sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
    urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz"],
)

load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")

rules_cc_dependencies()

rules_cc_toolchains()
