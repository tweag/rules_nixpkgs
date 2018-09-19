load("//lib:lib.bzl",
     "executable_path",
     "execute_error",
     "symlink_children")

def _nix_import_fetch_builtin_impl(rep_ctx):
    """Calls `nix eval` with the given nix file,
    which should return a store path, that is use a `fetchX` builtin,
    like `fetchTarball` or `fetchGit`.
    """

    # `rep_ctx` does not contain a `file` attribute like normal
    # `ctx` structs. We know this works because `allow_single_file`
    # is set for `attr.nix_file`.
    nix_file = rep_ctx.path(rep_ctx.attr.nix_file)

    # TODO(Profpatsch): check whether the given nix file
    # actually evaluates to a path

    args = [
        executable_path("nix", rep_ctx),
        "eval",
        "--raw",
        "-f",
        nix_file,
        # this is necessary, because `nix eval` requires an <INSTALLABLE>
        "",
    ]
    eval_res = rep_ctx.execute(args)
    if eval_res.return_code != 0:
        execute_error(
            eval_res,
            "Cannot instantiate the file {}".format(nix_file),
        )

    # stdout should be exactly the path we need
    # if nix_file actually is a direct call to a fetch function
    # (aka returns a path at evaluation time)
    tarball_path = eval_res.stdout

    # symlink to the tarball's nix store path
    symlink_children(
        tarball_path,
        ".",
        rep_ctx,
    )

    # so the store path is recognized as bazel package
    rep_ctx.file(
        "BUILD",
        content = "",
        executable = False,
    )

nix_import_fetch_builtin = repository_rule(
    implementation = _nix_import_fetch_builtin_impl,
    attrs = {
        "nix_file": attr.label(
            allow_single_file = [".nix"],
        ),
    },
    local = True,
)

