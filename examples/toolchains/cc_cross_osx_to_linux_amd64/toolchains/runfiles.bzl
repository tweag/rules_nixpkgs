"""
Workaround for broken runfiles handling in rules_pkg

Adapted from https://github.com/aspect-build/bazel-examples/blob/d1dd2310df5ed06343eb37cf699ced5551ac476f/oci_python_image/workaround_rules_pkg_153/runfiles.bzl

See https://github.com/bazelbuild/rules_pkg/issues/153
"""

load("@rules_pkg//pkg:providers.bzl", "PackageFilegroupInfo", "PackageFilesInfo", "PackageSymlinkInfo")
load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")

def _runfile_path(ctx, file, runfiles_dir):
    return "/".join([runfiles_dir, to_rlocation_path(ctx, file)])

def _should_include(destination, include, exclude):
    included = include in destination or include == ""
    excluded = exclude in destination and exclude != ""
    return included and not excluded

def _runfiles_impl(ctx):
    default = ctx.attr.binary[DefaultInfo]

    executable = default.files_to_run.executable
    executable_path = "/".join([ctx.attr.root, executable.short_path])

    file_map = {}

    if _should_include(executable_path, ctx.attr.include, ctx.attr.exclude):
        file_map[executable_path] = executable

    manifest = default.files_to_run.runfiles_manifest
    runfiles_dir = "/".join([ctx.attr.root, manifest.short_path.replace(manifest.basename, "")[:-1]])

    files = depset(transitive = [default.files, default.default_runfiles.files])

    for file in files.to_list():
        destination = _runfile_path(ctx, file, runfiles_dir)
        if _should_include(destination, ctx.attr.include, ctx.attr.exclude):
            file_map[destination] = file

    # executable should not go into runfiles directory so we add it to files here.
    files = depset([executable], transitive = [files])

    symlinks = []

    # NOTE: symlinks is different than root_symlinks. See: https://bazel.build/rules/rules#runfiles_symlinks for distinction between
    # root_symlinks and symlinks and why they have to be handled differently.
    for symlink in default.data_runfiles.symlinks.to_list():
        destination = "/".join([runfiles_dir, ctx.workspace_name, symlink.path])
        if not _should_include(destination, ctx.attr.include, ctx.attr.exclude):
            continue
        if hasattr(file_map, destination):
            file_map.pop(destination)
        info = PackageSymlinkInfo(
            target = "/%s" % _runfile_path(ctx, symlink.target_file, runfiles_dir),
            destination = destination,
            attributes = {"mode": "0777"},
        )
        symlinks.append([info, symlink.target_file.owner])

    for symlink in default.data_runfiles.root_symlinks.to_list():
        destination = "/".join([runfiles_dir, symlink.path])
        if not _should_include(destination, ctx.attr.include, ctx.attr.exclude):
            continue
        if hasattr(file_map, destination):
            file_map.pop(destination)
        info = PackageSymlinkInfo(
            target = "/%s" % _runfile_path(ctx, symlink.target_file, runfiles_dir),
            destination = destination,
            attributes = {"mode": "0777"},
        )
        symlinks.append([info, symlink.target_file.owner])

    # Add a symlink from the root binary to the binary in the runfiles.
    file_map.pop(executable_path)
    symlinks.append(
        (
            PackageSymlinkInfo(
                target = "/%s" % _runfile_path(ctx, executable, runfiles_dir),
                destination = executable_path,
                attributes = {"mode": "0777"},
            ),
            ctx.attr.binary,
        ),
    )

    return [
        PackageFilegroupInfo(
            pkg_dirs = [],
            pkg_files = [
                [PackageFilesInfo(
                    dest_src_map = file_map,
                    attributes = {},
                ), ctx.label],
            ],
            pkg_symlinks = symlinks,
        ),
        DefaultInfo(files = files),
    ]

runfiles = rule(
    implementation = _runfiles_impl,
    attrs = {
        "binary": attr.label(
            doc = "Binary to generate the runfiles tree for.",
            mandatory = True,
            executable = True,
            cfg = "target",
        ),
        "root": attr.string(
            doc = "Root directory to install runfiles into.",
        ),
        "include": attr.string(
            doc = "If set, only include files that contain this substr.",
        ),
        "exclude": attr.string(
            doc = "If set, exclude files that contain this substr.",
        ),
    },
)
