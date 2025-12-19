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
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.11/platforms-0.0.11.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.11/platforms-0.0.11.tar.gz",
        ],
        sha256 = "29742e87275809b5e598dc2f04d86960cc7a55b3067d97221c9abbc9926bff0f",
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
        urls = [
            "https://github.com/bazelbuild/rules_java/releases/download/7.3.1/rules_java-7.3.1.tar.gz",
        ],
        sha256 = "4018e97c93f97680f1650ffd2a7530245b864ac543fd24fae8c02ba447cb2864",
    )
    maybe(
        http_archive,
        "rules_nodejs",
        sha256 = "83d2bb029c2a9a06a474c8748d1221a92a7ca02222dcf49a0b567825c4e3f1ce",
        strip_prefix = "rules_nodejs-6.3.0",
        urls = ["https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.0/rules_nodejs-v6.3.0.tar.gz"],
    )
    maybe(
        http_archive,
        "rules_license",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_license/releases/download/1.0.0/rules_license-1.0.0.tar.gz",
            "https://github.com/bazelbuild/rules_license/releases/download/1.0.0/rules_license-1.0.0.tar.gz",
        ],
        sha256 = "26d4021f6898e23b82ef953078389dd49ac2b5618ac564ade4ef87cced147b38",
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
                type = rules_nixpkgs.get("type"),
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
