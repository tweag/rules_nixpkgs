load("@rules_nixpkgs_go//:go.bzl", "RULES_GO")

def _go_root_impl(ctx):
    go = ctx.toolchains["@{}//go:toolchain".format(RULES_GO)]
    return [
        DefaultInfo(
            files = depset(direct = [go.sdk.root_file]),
        )
    ]

_go_root = rule(
    _go_root_impl,
    toolchains = ["@{}//go:toolchain".format(RULES_GO)],
)

def _go_root_test(*, name, go_root):
    native.sh_test(
        name = name,
        srcs = ["go-root-test.sh"],
        data = [go_root],
        args = ["$(rootpaths %s)" % go_root],
    )

def go_test_suite(name):
    _go_root(name = "go-root")
    _go_root_test(name = "go-root-test", go_root = ":go-root")
