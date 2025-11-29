load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

ResolvedNodeJSToolchainInfo = provider()

def _nodejs_toolchain_impl(ctx):
    nodejs = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"]
    return [
        ResolvedNodeJSToolchainInfo(nodejs = nodejs),
    ]

_nodejs_toolchain = rule(
    _nodejs_toolchain_impl,
    toolchains = ["@rules_nodejs//nodejs:toolchain_type"],
)

def _nodejs_toolchain_test_impl(ctx):
    env = unittest.begin(ctx)

    nodejs = ctx.attr.toolchain[ResolvedNodeJSToolchainInfo].nodejs
    node_path = nodejs.nodeinfo.node.path
    asserts.true(env, node_path.find("nixpkgs_nodejs") != -1, "NodeJS toolchain must be provided by rules_nixpkgs_nodejs.")

    return unittest.end(env)

_nodejs_toolchain_test = unittest.make(
    _nodejs_toolchain_test_impl,
    attrs = {
        "toolchain": attr.label(),
    },
)

def nodejs_test_suite(name):
    _nodejs_toolchain(name = "nodejs-toolchain")
    unittest.suite(
        name,
        lambda name: _nodejs_toolchain_test(name = name, toolchain = ":nodejs-toolchain")
    )
