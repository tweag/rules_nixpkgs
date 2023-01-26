# NOTE: temporary for compatibility with `WORKSPACE` setup!
# TODO: remove when migration to `bzlmod` is complete

# This has to be split into `test_dependencies_1` and `test_dependencies_2`
# because Bazel is imperative, and requires `load()` to be a top-level
# statement.
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def test_dependencies_1():
    """
    Load repositories required for runnings tests for `rules_nixpkgs_*`
    """
    maybe(
        http_archive,
        "rules_sh",
        sha256 = "d668bb32f112ead69c58bde2cae62f6b8acefe759a8c95a2d80ff6a85af5ac5e",
        strip_prefix = "rules_sh-0.3.0",
        urls = ["https://github.com/tweag/rules_sh/archive/v0.3.0.tar.gz"],
    )
