load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@nixpkgs_sh_posix_config//:nixpkgs_sh_posix.bzl", "discovered")

ResolvedPosixToolchainInfo = provider()

def _posix_toolchain_impl(ctx):
    posix = ctx.toolchains["@rules_sh//sh/posix:toolchain_type"]
    return [
        ResolvedPosixToolchainInfo(commands = posix.commands)
    ]

_posix_toolchain = rule(
    _posix_toolchain_impl,
    toolchains = ["@rules_sh//sh/posix:toolchain_type"],
)

def _posix_runtime_test_impl(ctx):
    env = unittest.begin(ctx)

    commands = ctx.attr.toolchain[ResolvedPosixToolchainInfo].commands
    for (command, path) in commands.items():
        asserts.equals(env, path, discovered.get(command), "expected path to {} to match".format(command))

    return unittest.end(env)

_posix_runtime_test = unittest.make(
    _posix_runtime_test_impl,
    attrs = {
        "toolchain": attr.label(),
    },
)

def posix_test_suite(name):
    _posix_toolchain(name = "posix-toolchain")
    unittest.suite(
        name,
        lambda name: _posix_runtime_test(name = name, toolchain = ":posix-toolchain")
    )
