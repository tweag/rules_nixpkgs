load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _cc_toolchain_test_impl(ctx):
    cc = find_cpp_toolchain(ctx)
    executable = ctx.actions.declare_file(ctx.attr.name + ".sh")
    cc_toolchain_info = ctx.file._cc_toolchain_info
    cc_toolchain_info_path = ctx.expand_location(
        "$(rootpath {})".format(str(ctx.attr._cc_toolchain_info.label)),
        [ctx.attr._cc_toolchain_info],
    )
    ctx.actions.write(executable, content = """\
# Find cc in CC_TOOLCHAIN_INFO
while IFS=: read -a line; do
    if [[ ${{line[0]}} = TOOL_PATHS ]]; then
        for item in ${{line[@]:1}}; do
            if [[ $item = */bin/cc ]]; then
                CC=$item
            fi
        done
    fi
done <{cc_toolchain_info_path}
if [[ {cc} = */cc_wrapper.sh ]]; then
    grep -q "$CC" "{cc}" || {{
        echo "Expected C compiler '$CC' in wrapper script '{cc}'." >&2
        exit 1
    }}
else
    if [[ {cc} != $CC ]]; then
        echo "Expected C compiler '$CC', but found '{cc}'." >&2
        exit 1
    fi
fi
""".format(
        cc = cc.compiler_executable,
        cc_toolchain_info_path = cc_toolchain_info_path,
    ))
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(
            files = [ctx.file._cc_toolchain_info],
            transitive_files = cc.all_files,
        ),
    )]

cc_toolchain_test = rule(
    _cc_toolchain_test_impl,
    attrs = {
        "_cc_toolchain": attr.label(
            default = Label("@rules_cc//cc:current_cc_toolchain"),
        ),
        "_cc_toolchain_info": attr.label(
            allow_single_file = True,
            default = Label("@nixpkgs_config_cc_info//:CC_TOOLCHAIN_INFO"),
        ),
    },
    test = True,
    toolchains = ["@rules_cc//cc:toolchain_type"],
)
