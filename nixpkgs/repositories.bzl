load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_nixpkgs_dependencies():
    """Load repositories required by rules_nixpkgs."""
    maybe(
        http_archive,
        "platforms",
        sha256 = "23566db029006fe23d8140d14514ada8c742d82b51973b4d331ee423c75a0bfa",
        strip_prefix = "platforms-46993efdd33b73649796c5fc5c9efb193ae19d51",
        urls = ["https://github.com/bazelbuild/platforms/archive/46993efdd33b73649796c5fc5c9efb193ae19d51.tar.gz"],
    )
