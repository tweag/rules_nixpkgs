load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _java_runtime_test_impl(ctx):
    env = unittest.begin(ctx)

    nixpkgs_java_runtime = ctx.attr._nixpkgs_java_runtime[platform_common.ToolchainInfo]

    java_runtime = ctx.attr._java_runtime[java_common.JavaRuntimeInfo]
    asserts.equals(
        env,
        expected = nixpkgs_java_runtime.java_home,
        actual = java_runtime.java_home,
        msg = "Expected selected Java runtime JAVA_HOME to equal Nix provided JAVA_HOME.",
    )
    asserts.equals(
        env,
        expected = nixpkgs_java_runtime.java_executable_exec_path,
        actual = java_runtime.java_executable_exec_path,
        msg = "Expected selected Java runtime java binary to equal Nix provided java.",
    )

    host_java_runtime = ctx.attr._host_java_runtime[java_common.JavaRuntimeInfo]
    asserts.equals(
        env,
        expected = nixpkgs_java_runtime.java_home,
        actual = host_java_runtime.java_home,
        msg = "Expected selected host Java runtime JAVA_HOME to equal Nix provided JAVA_HOME.",
    )
    asserts.equals(
        env,
        expected = nixpkgs_java_runtime.java_executable_exec_path,
        actual = host_java_runtime.java_executable_exec_path,
        msg = "Expected selected host Java runtime java binary to equal Nix provided java.",
    )

    return unittest.end(env)

java_runtime_test = unittest.make(
    _java_runtime_test_impl,
    attrs = {
        "_nixpkgs_java_runtime": attr.label(default = Label("@nixpkgs_java_runtime//:runtime")),
        "_java_runtime": attr.label(default = Label("@bazel_tools//tools/jdk:current_java_runtime")),
        "_host_java_runtime": attr.label(default = Label("@bazel_tools//tools/jdk:current_host_java_runtime")),
    },
)
