workspace(name = "io_tweag_rules_nixpkgs")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Download the rules_docker repository at release v0.7.0
# http_archive(
#     name = "io_bazel_rules_docker",
#     sha256 = "aed1c249d4ec8f703edddf35cbe9dfaca0b5f5ea6e4cd9e83e99f3b0d1136c3d",
#     strip_prefix = "rules_docker-0.7.0",
#     urls = ["https://github.com/bazelbuild/rules_docker/archive/v0.7.0.tar.gz"],
# )
rules_docker_commit = "27df735ce2215690a0ef4602b18cf36946bbd700"
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "57769dde81d786ad74b6e30a5a43c7f9b2a9f7b6ae9a424e49f6d5c227b3f056",
    strip_prefix = "rules_docker-{}".format(rules_docker_commit),
    # This is v0.7.0 + a custom patch to use the right python
    urls = ["https://github.com/regnat/rules_docker/archive/{}.tar.gz".format(rules_docker_commit)],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)
container_repositories()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_load",
)

load(
    "//nixpkgs:nixpkgs.bzl",
    "nixpkgs_cc_configure",
    "nixpkgs_git_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

# For tests

nixpkgs_git_repository(
    name = "remote_nixpkgs",
    remote = "https://github.com/NixOS/nixpkgs",
    revision = "18.09",
    sha256 = "6451af4083485e13daa427f745cbf859bc23cb8b70454c017887c006a13bd65e",
)

nixpkgs_local_repository(
    name = "nixpkgs",
    nix_file = "//:nixpkgs.nix",
)

nixpkgs_package(
    name = "nixpkgs-git-repository-test",
    attribute_path = "hello",
    repositories = {"nixpkgs": "@remote_nixpkgs"},
)

load("//:nix-repositories.bzl", "nix_packages")
nix_packages()
# container_load(
#     name = "rbe_image",
#     file = "@rbeDockerImage//:image.tar.gz",
# )

nixpkgs_package(
    name = "expr-test",
    nix_file_content = "let pkgs = import <nixpkgs> {}; in pkgs.hello",
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
    nix_file_content = "import <nixpkgs> {}",
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

nixpkgs_package(
    name = "output-filegroup-test",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "extra-args-test",
    nix_file_content = """
{ packagePath }: (import <nixpkgs> {}).${packagePath}
    """,
    repository = "@nixpkgs",
    nixopts = ["--argstr", "packagePath", "hello"],
)

nixpkgs_package(
    name = "output-filegroup-manual-test",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
filegroup(
    name = "manual-filegroup",
    srcs = glob(["hi-i-exist", "hi-i-exist-too", "bin/*"]),
)
""",
    nix_file = "//tests:output.nix",
    repository = "@nixpkgs",
)

# nixpkgs_cc_configure(repository = "@remote_nixpkgs")
