def _python_package_impl(ctx):
    import_depsets = []
    store = ctx.file.store_path
    runfiles = ctx.runfiles(files = [store])

    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(dep[DefaultInfo].data_runfiles)
        import_depsets.append(dep[PyInfo].imports)

    # HACK(danny): for some unforunate reason, short_path returns ../ when operating in external
    # repositories. I don't know why. It breaks rules_python's assumptions though.
    # See https://github.com/bazelbuild/bazel-skylib/issues/303 for some discussion.
    fixed_path = store.short_path[3:]
    import_path = "/".join([ctx.workspace_name, store.short_path])

    return [
        DefaultInfo(
            files = depset(ctx.files.files),
            default_runfiles = ctx.runfiles(ctx.files.files, collect_default = True),
        ),
        PyInfo(
            imports = depset(direct = [import_path], transitive = import_depsets),
            transitive_sources = depset(transitive = [
                dep[PyInfo].transitive_sources
                for dep in ctx.attr.deps
            ]),
        ),
    ]

python_package = rule(
    implementation = _python_package_impl,
    attrs = {
        "store_path": attr.label(
            allow_single_file = True,
            doc = "nix store path of python package",
        ),
        "files": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            providers = [PyInfo],
        ),
    },
    executable = False,
    test = False,
)
