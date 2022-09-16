load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

_TOOLCHAINS = sorted([ 'cc', 'java', 'python', 'go', 'rust', 'posix', 'nodejs' ])

def rules_nixpkgs_dependencies(rules_nixpkgs_name = "io_tweag_rules_nixpkgs", toolchains = None):
    """Load repositories required by rules_nixpkgs.

    Args:
        rules_nixpkgs_name: name under which this repository is known in your workspace
        toolchains:         list of toolchains to load, e.g. `['cc', 'java']`, load all toolchains by default
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
        sha256 = "ddc9e11f4836265fea905d2845ac1d04ebad12a255f791ef7fd648d1d2215a5b",
        strip_prefix = "rules_java-5.0.0",
        url = "https://github.com/bazelbuild/rules_java/archive/refs/tags/5.0.0.tar.gz",
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

    if toolchains != None:
        inexistent_toolchains = [ name for name in toolchains if not name in _TOOLCHAINS ]
        if inexistent_toolchains:
            errormsg = [
                "The following toolchains given in the `toolchains` argument are unknown: {}".format(
                    ", ".join(inexistent_toolchains)
                ),
                "Available toolchains are: {}".format(
                    ", ".join(_TOOLCHAINS)
                )
            ]
            fail("\n".join(errormsg))

    for name, prefix in [("rules_nixpkgs_core", "core")] + [
        ("rules_nixpkgs_" + toolchain, "toolchains/" + toolchain)
        for toolchain in _TOOLCHAINS
        if toolchains == None or toolchain in toolchains
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
