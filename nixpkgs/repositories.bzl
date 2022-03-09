load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_nixpkgs_dependencies(local = None):
    """Load repositories required by rules_nixpkgs.

    Args:
        local: path to local `rules_nixpkgs` repository.
               use for testing and CI.
               TODO: remove when migration to `bzlmod` is complete.
    """
    maybe(
        http_archive,
        "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.4/platforms-0.0.4.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.4/platforms-0.0.4.tar.gz",
        ],
        sha256 = "079945598e4b6cc075846f7fd6a9d0857c33a7afc0de868c2ccb96405225135d",
    )
    maybe(
        http_archive,
        "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )
    maybe(
        http_archive,
        "rules_java",
        url = "https://github.com/bazelbuild/rules_java/releases/download/4.0.0/rules_java-4.0.0.tar.gz",
        sha256 = "34b41ec683e67253043ab1a3d1e8b7c61e4e8edefbcad485381328c934d072fe",
    )

    url = "https://github.com/tweag/rules_nixpkgs/archive/refs/tags/v0.8.1.tar.gz"
    for repo, prefix in [
        ("rules_nixpkgs_core", "core"),
        ("rules_nixpkgs_cc", "toolchains/cc"),
        ("rules_nixpkgs_java", "toolchains/java"),
        ("rules_nixpkgs_python", "toolchains/python"),
    ]:
        if not local:
            # XXX: no way to use `sha256` here, but if this surrounding repo comes
            # from that URL, Bazel should hit the cache for the sub-workspaces
            maybe(http_archive, repo, url = url, strip_prefix = prefix)
        else:
            maybe(native.local_repository, repo, path = "{}/{}".format(local, prefix))
