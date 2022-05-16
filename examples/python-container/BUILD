py_binary(
    name = "hello",
    srcs = ["hello.py"],
    main = "hello.py",
)

load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")

package(default_visibility = ["//visibility:public"])

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

