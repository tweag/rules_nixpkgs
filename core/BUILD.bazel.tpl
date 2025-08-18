load("@rules_license//rules:license.bzl", "license")

package(
    default_visibility = ["//visibility:public"],
    default_package_metadata = ["//:license"],
)

license(
    name = "license",
    license_text = "LICENSE",
)

filegroup(
    name = "bin",
    srcs = glob(["bin/*"], allow_empty = True),
)

filegroup(
    name = "lib",
    srcs = glob(["lib/**/*.so*", "lib/**/*.dylib", "lib/**/*.a"], allow_empty = True),
)

filegroup(
    name = "include",
    srcs = glob(["include/**/*.h", "include/**/*.hh", "include/**/*.hpp", "include/**/*.hxx"], allow_empty = True),
)
