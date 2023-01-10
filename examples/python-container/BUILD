py_binary(
    name = "hello",
    srcs = ["hello.py"],
    main = "hello.py",
)

load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")

package(default_visibility = ["//visibility:public"])

platform(
    name = "nix_container_platform",
    constraint_values = [
        "@io_bazel_rules_docker//platforms:run_in_container",
    ],
    parents = ["@io_tweag_rules_nixpkgs//nixpkgs/platforms:host"],
)

py3_image(
    name = "hello_image",
    srcs = [ "hello.py" ],
    base = "@python39_base_image//image",
    main = "hello.py",

    # Currently needs to be built on Linux.
    target_compatible_with = [
        "@platforms//os:linux",
    ],
)

