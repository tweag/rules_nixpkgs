load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("//toolchains:runfiles.bzl", "runfiles")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    deps = [
        "@boost.dev//:boost",
        "@zlib.dev//:zlib",
    ],
)

runfiles(
    name = "hello_runfiles",
    binary = ":hello",
    root = "/app"
)

pkg_tar(
    name = "hello_tar",
    srcs = [":hello_runfiles"],
)

oci_image(
    name = "hello_image",
    base = "@alpine",
    tars = [
        ":hello_tar",
        "@nixdeps//:closure.tar",
    ],
    entrypoint = ["/app/hello"],
)

oci_load(
    name = "hello_image_tar",
    image = ":hello_image",
    repo_tags = ["cross_example:latest"],
)

filegroup(
    name = "hello_image_tarball",
    srcs = [":hello_image_tar"],
    output_group = "tarball",
)
