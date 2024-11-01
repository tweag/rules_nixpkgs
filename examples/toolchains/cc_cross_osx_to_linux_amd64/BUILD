load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    deps = [
        "@boost.dev//:boost",
        "@zlib.dev//:zlib",
    ],
)

pkg_tar(
    name = "hello_tar",
    srcs = [":hello"],
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

oci_tarball(
    name = "hello_image_tarball",
    image = ":hello_image",
    repo_tags = ["cross_example:latest"],
)