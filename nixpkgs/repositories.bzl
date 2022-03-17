load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def rules_nixpkgs_dependencies(rules_nixpkgs_name = "io_tweag_rules_nixpkgs"):
    """Load repositories required by rules_nixpkgs.

    Args:
        rules_nixpkgs_name: name under which this repository is known in your workspace
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

    # the following complication is due to migrating to `bzlmod`.
    # fetch extracted submodules as external repositories from an existing source tree, based on the import type.
    rules_nixpkgs = native.existing_rule(rules_nixpkgs_name)
    if not rules_nixpkgs:
        errormsg = [
            "External repository `rules_nixpkgs` not found as `{}`.".format(rules_nixpkgs_name),
            "Specify `rules_nixpkgs_dependencies(rules_nixpkgs_name=<name>)`",
            "with `<name>` as used for importing `rules_nixpkgs`.",
        ]
        fail("\n".join(errormsg))
    kind = rules_nixpkgs.get("kind")

    strip_prefix = rules_nixpkgs.get("strip_prefix", "")
    if strip_prefix:
        strip_prefix += "/"

    for name, prefix in [
        ("rules_nixpkgs_core", "core"),
        ("rules_nixpkgs_cc", "toolchains/cc"),
        ("rules_nixpkgs_java", "toolchains/java"),
        ("rules_nixpkgs_python", "toolchains/python"),
        ("rules_nixpkgs_go", "toolchains/go"),
        ("rules_nixpkgs_posix", "toolchains/posix"),
    ]:
        # case analysis in inner loop to reduce code duplication
        if kind == "local_repository":
            path = rules_nixpkgs.get("path")
            maybe(native.local_repository, name, path = "{}/{}".format(path, prefix))
        elif kind == "http_archive":
            maybe(
                http_archive,
                name,
                strip_prefix = strip_prefix + prefix,
                # there may be more attributes needed. please submit a pull request to support your use case.
                url = rules_nixpkgs.get("url"),
                urls = rules_nixpkgs.get("urls"),
                sha256 = rules_nixpkgs.get("sha256"),
            )
        elif kind == "git_repository":
            maybe(
                git_repository,
                name,
                strip_prefix = strip_prefix + prefix,
                # there may be more attributes needed. please submit a pull request to support your use case.
                remote = rules_nixpkgs.get("remote"),
                commit = rules_nixpkgs.get("commit"),
                branch = rules_nixpkgs.get("branch"),
                tag = rules_nixpkgs.get("tag"),
                shallow_since = rules_nixpkgs.get("shallow_since"),
            )
        else:
            errormsg = [
                "Could not find any import type for `rules_nixpkgs`.",
                "This should not happen. If you encounter this using the latest release",
                "of `rules_nixpkgs`, please file an issue describing your use case:",
                "https://github.com/tweag/rules_nixpkgs/issues",
                "or submit a pull request with corrections:",
                "https://github.com/tweag/rules_nixpkgs/pulls",
            ]
            fail("\n".join(errormsg))
