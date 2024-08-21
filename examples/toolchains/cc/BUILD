load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    # XXX workaround a problem on macos-12, where the resulting executable segfaults when not linking to
    #     the C++ standard library explicitly
    linkopts = ["-lstdc++"],
)
