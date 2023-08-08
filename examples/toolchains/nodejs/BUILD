load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")
nodejs_binary(
    name = "hello",
    entry_point = ":hello.js",
    data = [ "@npm//ololog", ]
)
