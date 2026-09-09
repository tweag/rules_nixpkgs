load("@aspect_rules_py//py:defs.bzl", "py_image_layer")
load("@rules_python//python:py_binary.bzl", "py_binary")
load("@rules_oci//oci:defs.bzl", "oci_image")

package(default_visibility = ["//visibility:public"])

py_binary(
    name = "hello",
    srcs = ["hello.py"],
    main = "hello.py",
)

py_image_layer(
    name = "layers",
    binary = ":hello",
)

oci_image(
    name = "python312_base_image",
    tars = [
        "@raw_python312_base_image//:image",
    ],
    architecture = "amd64",
    os = "linux",
)

oci_image(
    name = "hello_image",
    base = ":python312_base_image",
    entrypoint = ["/oci_python_image/hello"],
    tars = [":layers"],
    target_compatible_with = [
        "@platforms//os:linux",
    ],
)
