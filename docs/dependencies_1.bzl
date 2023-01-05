# NOTE: temporary for compatibility with `WORKSPACE` setup!
# TODO: remove when migration to `bzlmod` is complete

# this has to be split into `docs_dependencies_1` and `docs_dependencies_2`
# because Bazel is imperative, and requires `load()` to be a top-level
# statement.
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def docs_dependencies_1():
    """
    Load repositories required for rendering documentation for `rules_nixpkgs_*`
    """
    maybe(
        http_archive,
        "rules_sh",
        sha256 = "d668bb32f112ead69c58bde2cae62f6b8acefe759a8c95a2d80ff6a85af5ac5e",
        strip_prefix = "rules_sh-0.3.0",
        urls = ["https://github.com/tweag/rules_sh/archive/v0.3.0.tar.gz"],
    )

    maybe(
        http_archive,
        "io_bazel_stardoc",
        sha256 = "aa814dae0ac400bbab2e8881f9915c6f47c49664bf087c409a15f90438d2c23e",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.5.1/stardoc-0.5.1.tar.gz",
            "https://github.com/bazelbuild/stardoc/releases/download/0.5.1/stardoc-0.5.1.tar.gz",
        ],
    )
