def _python_package_impl(ctx):
    transitive_imports = []
    transitive_runfiles = []
    transitive_sources = []

    # HACK: short_path returns ../ when operating in external
    # repositories, but this breaks rules_python's assumptions.
    # See https://github.com/bazelbuild/bazel-skylib/issues/303
    # for some discussion.
    store = ctx.file.store_path
    fixed_path = store.short_path[3:]
    import_path = "/".join([ctx.workspace_name, store.short_path])

    for dep in ctx.attr.deps:
        transitive_runfiles.append(dep[DefaultInfo].default_runfiles)
        transitive_imports.append(dep[PyInfo].imports)
        transitive_sources.append(dep[PyInfo].transitive_sources)

    return [
        DefaultInfo(
            # Files that are built when this target is built directly.
            files = depset(ctx.files.files),
            # Files that must be present when this target is executed.
            runfiles = ctx.runfiles(files = ctx.files.files).merge_all(transitive_runfiles),
        ),
        PyInfo(
            # Paths that should compose the python path for packages and modules lookup
            imports = depset(direct = [import_path], transitive = transitive_imports),
            # Unclear semantics, so just forward. We decide to look at nix
            # python packages as binary results that contain no "sources". Can
            # be changed if needed.
            transitive_sources = depset(transitive = transitive_sources),
        ),
    ]

python_package = rule(
    implementation = _python_package_impl,
    attrs = {
        "store_path": attr.label(
            allow_single_file = True,
            doc = "Nix store path of python package",
        ),
        "files": attr.label_list(
            allow_files = True,
            doc = """All the files that compose this package. You probably want
            to use `glob(["**"], exclude=["**/* *"])` to collect them without
            including the strange ones that contain a space in their name.""",
        ),
        "deps": attr.label_list(
            providers = [PyInfo],
            doc = "`python_package`s that are runtime dependencies of this package.",
        ),
    },
    executable = False,
    test = False,
)
